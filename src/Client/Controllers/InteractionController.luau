--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local SoundService = game:GetService("SoundService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local InteractionConfig = require(Shared:WaitForChild("Config"):WaitForChild("InteractionConfig") :: ModuleScript)
local DebugConfig = require(Shared:WaitForChild("Config"):WaitForChild("DebugConfig") :: ModuleScript)
local Metrics = require(Shared:WaitForChild("Util"):WaitForChild("Metrics") :: ModuleScript)
local Tags = require(Shared:WaitForChild("Tags") :: ModuleScript)

local UI = script.Parent.Parent:WaitForChild("UI") :: Folder
local InteractionPrompt = require(UI:WaitForChild("InteractionPrompt") :: ModuleScript)

type MetricsType = typeof(Metrics.new(false))
type JanitorType = typeof(Janitor.new())
type TagName = Tags.TagName

type CharacterState = {
	character: Model,
	root: BasePart?,
}

type InteractionController = {
	KnitInit: (self: InteractionController) -> (),
	KnitStart: (self: InteractionController) -> (),
}

type InteractionControllerImpl = InteractionController & {
	_janitor: JanitorType,
	_characterJanitor: JanitorType,
	_metrics: MetricsType,
	_lastLogAt: number,
	_player: Player?,
	_prompt: any?,
	_remote: RemoteEvent?,
	_sound: Sound?,
	_currentTarget: Instance?,
	_lastRequestAt: number,
	_scanning: boolean,
	_pendingTarget: Instance?,
	_pendingSince: number,
	_lostSince: number,
	_tagObserver: any?,
	_lifecycle: any?,
	_thirdPerson: any?,

	_getLocalPlayer: (self: InteractionControllerImpl) -> Player?,
	_getCharacterState: (self: InteractionControllerImpl) -> CharacterState?,
	_scanOnce: (self: InteractionControllerImpl) -> (),
	_setTarget: (self: InteractionControllerImpl, target: Instance?) -> (),
	_tryInteract: (self: InteractionControllerImpl) -> (),
	_bindInput: (self: InteractionControllerImpl) -> (),
	_startScanLoop: (self: InteractionControllerImpl) -> (),
	_getTargetPosition: (self: InteractionControllerImpl, target: Instance) -> Vector3?,
	_hasLineOfSight: (self: InteractionControllerImpl, origin: Vector3, target: Instance, position: Vector3) -> boolean,
	_updatePromptText: (self: InteractionControllerImpl, target: Instance?) -> (),
	_isValidInteractable: (self: InteractionControllerImpl, target: Instance?) -> boolean,
	_logSnapshot: (self: InteractionControllerImpl, reason: string) -> (),
}

local InteractionController: InteractionControllerImpl = Knit.CreateController({
	Name = "InteractionController",
}) :: any

local REMOTES_FOLDER_NAME = "Remotes"
local REMOTE_NAME = "InteractRequest"

function InteractionController:KnitInit()
	local selfImpl = self :: InteractionControllerImpl
	selfImpl._janitor = Janitor.new()
	selfImpl._characterJanitor = Janitor.new()
	selfImpl._metrics = Metrics.new(DebugConfig.EnableMetrics)
	selfImpl._lastLogAt = 0
	selfImpl._player = nil
	selfImpl._prompt = nil
	selfImpl._remote = nil
	selfImpl._sound = nil
	selfImpl._currentTarget = nil
	selfImpl._lastRequestAt = -math.huge
	selfImpl._scanning = false
	selfImpl._pendingTarget = nil
	selfImpl._pendingSince = 0
	selfImpl._lostSince = 0
	selfImpl._tagObserver = nil
	selfImpl._lifecycle = nil
	selfImpl._thirdPerson = nil
end

function InteractionController:KnitStart()
	local selfImpl = self :: InteractionControllerImpl

	local okTag, tagObserver = pcall(function()
		return Knit.GetController("TagObserverController")
	end)
	if okTag and tagObserver then
		selfImpl._tagObserver = tagObserver
	end

	local okLife, lifecycle = pcall(function()
		return Knit.GetController("CharacterLifecycleController")
	end)
	if okLife and lifecycle then
		selfImpl._lifecycle = lifecycle
	end

	local okThird, thirdController = pcall(function()
		return Knit.GetController("ThirdPersonController")
	end)
	if okThird and thirdController then
		selfImpl._thirdPerson = thirdController
	end

	local player = selfImpl:_getLocalPlayer()
	selfImpl._player = player
	if not player then
		if DebugConfig.LogWarnings then
			warn("[InteractionController] LocalPlayer missing; interactions disabled.")
		end
		return
	end

	local remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME) :: Folder
	selfImpl._remote = remotesFolder:WaitForChild(REMOTE_NAME) :: RemoteEvent

	selfImpl._janitor:Add(selfImpl._remote.OnClientEvent:Connect(function(success: boolean)
		if success then
			selfImpl._metrics:Increment("interactSuccessCount", 1)
			if selfImpl._sound then
				selfImpl._sound.TimePosition = 0
				selfImpl._sound:Play()
			end
			if selfImpl._prompt and selfImpl._prompt.PulseSuccess then
				selfImpl._prompt:PulseSuccess()
			end
			selfImpl:_logSnapshot("success")
		end
	end), "Disconnect")

	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	selfImpl._prompt = InteractionPrompt.new(playerGui)

	local sound = SoundService:FindFirstChild("InteractSuccess")
	if sound and sound:IsA("Sound") then
		selfImpl._sound = sound
	else
		local newSound = Instance.new("Sound")
		newSound.Name = "InteractSuccess"
		local soundId = InteractionConfig.SfxSoundId
		if type(soundId) == "string" and soundId ~= "" then
			newSound.SoundId = soundId
		else
			newSound:Destroy()
			selfImpl._sound = nil
			soundId = nil
		end
		newSound.Volume = InteractionConfig.SfxVolume
		if soundId then
			newSound.Parent = SoundService
			selfImpl._sound = newSound
		end
	end

	selfImpl._janitor:Add(player.CharacterAdded:Connect(function()
		selfImpl:_setTarget(nil)
	end), "Disconnect")
	selfImpl._janitor:Add(player.CharacterRemoving:Connect(function()
		selfImpl:_setTarget(nil)
		selfImpl._characterJanitor:Cleanup()
	end), "Disconnect")

	selfImpl:_bindInput()
	selfImpl:_startScanLoop()
end

function InteractionController:_getLocalPlayer(): Player?
	local player = Players.LocalPlayer
	if player then
		return player
	end
	local t0 = os.clock()
	while os.clock() - t0 < 5 do
		player = Players.LocalPlayer
		if player then
			return player
		end
		task.wait()
	end
	return nil
end

function InteractionController:_bindInput()
	local selfImpl = self :: InteractionControllerImpl
	selfImpl._janitor:Add(function()
		ContextActionService:UnbindAction("Interact")
	end)

	local keycodes = { InteractionConfig.InteractKey }
	if InteractionConfig.GamepadInteractKey then
		table.insert(keycodes, InteractionConfig.GamepadInteractKey :: Enum.KeyCode)
	end

	ContextActionService:BindAction("Interact", function(_, inputState)
		if inputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		selfImpl:_tryInteract()
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(keycodes))
end

function InteractionController:_startScanLoop()
	local selfImpl = self :: InteractionControllerImpl
	if selfImpl._scanning then
		return
	end
	selfImpl._scanning = true
	selfImpl._janitor:Add(function()
		selfImpl._scanning = false
	end)

	task.spawn(function()
		while selfImpl._scanning do
			selfImpl:_scanOnce()
			task.wait(InteractionConfig.TickRateSec)
		end
	end)
end

function InteractionController:_scanOnce()
	local selfImpl = self :: InteractionControllerImpl
	selfImpl._metrics:Increment("scansCount", 1)

	local state = selfImpl:_getCharacterState()
	if not state or not state.root then
		selfImpl:_setTarget(nil)
		return
	end

	if selfImpl._currentTarget then
		local current = selfImpl._currentTarget
		if not selfImpl:_isValidInteractable(current) or not selfImpl:_getTargetPosition(current) then
			selfImpl._pendingTarget = nil
			selfImpl._pendingSince = 0
			selfImpl._lostSince = 0
			selfImpl:_setTarget(nil)
		end
	end

	local origin = state.root.Position
	local candidates: { Instance }
	if selfImpl._tagObserver then
		candidates = selfImpl._tagObserver:GetTagged(Tags.Interactable)
	else
		candidates = CollectionService:GetTagged(Tags.Interactable)
	end

	local bestTarget = nil
	local bestDist = math.huge
	for _, candidate in candidates do
		if candidate and selfImpl:_isValidInteractable(candidate) then
			local pos = selfImpl:_getTargetPosition(candidate)
			if pos then
				local dist = (pos - origin).Magnitude
				if dist <= InteractionConfig.Radius and dist < bestDist then
					if InteractionConfig.UseLineOfSightClient then
						if not selfImpl:_hasLineOfSight(origin, candidate, pos) then
							continue
						end
					end
					bestTarget = candidate
					bestDist = dist
				end
			end
		end
	end

	local now = os.clock()
	if bestTarget == nil then
		selfImpl._pendingTarget = nil
		if selfImpl._currentTarget then
			if selfImpl._lostSince == 0 then
				selfImpl._lostSince = now
			end
			if now - selfImpl._lostSince >= InteractionConfig.TargetReleaseTimeSec then
				selfImpl:_setTarget(nil)
			end
		else
			selfImpl:_setTarget(nil)
		end
		return
	end

	selfImpl._lostSince = 0
	if bestTarget == selfImpl._currentTarget then
		selfImpl._pendingTarget = nil
		selfImpl._pendingSince = 0
		return
	end

	if bestTarget ~= selfImpl._pendingTarget then
		selfImpl._pendingTarget = bestTarget
		selfImpl._pendingSince = now
		return
	end

	if now - selfImpl._pendingSince >= InteractionConfig.TargetAcquireTimeSec then
		selfImpl:_setTarget(bestTarget)
	end
end

function InteractionController:_setTarget(target: Instance?)
	local selfImpl = self :: InteractionControllerImpl
	if target and not selfImpl:_isValidInteractable(target) then
		target = nil
	end
	if selfImpl._currentTarget == target then
		return
	end
	if target == nil then
		selfImpl._pendingTarget = nil
		selfImpl._pendingSince = 0
	end

	selfImpl._currentTarget = target
	selfImpl._lostSince = 0
	selfImpl._metrics:Increment("targetChangeCount", 1)
	if selfImpl._prompt then
		selfImpl._prompt:SetAdornee(target)
	end
	if selfImpl._thirdPerson then
		local pos = target and selfImpl:_getTargetPosition(target) or nil
		selfImpl._thirdPerson:SetInteractFocus(pos)
	end
	selfImpl:_updatePromptText(target)
	selfImpl:_logSnapshot("target")
end

function InteractionController:_tryInteract()
	local selfImpl = self :: InteractionControllerImpl
	if not selfImpl._remote then
		return
	end
	local target = selfImpl._currentTarget
	if not target then
		return
	end
	local now = os.clock()
	if now - selfImpl._lastRequestAt < InteractionConfig.LocalRequestCooldownSec then
		return
	end
	selfImpl._lastRequestAt = now
	selfImpl._metrics:Increment("interactRequestCount", 1)
	selfImpl._remote:FireServer(target)
end

function InteractionController:_isValidInteractable(target: Instance?): boolean
	local selfImpl = self :: InteractionControllerImpl
	if not target then
		return false
	end
	if not target:IsDescendantOf(workspace) then
		return false
	end
	-- CollectionService is the source of truth for tags.
	return CollectionService:HasTag(target, Tags.Interactable)
end

function InteractionController:_getTargetPosition(target: Instance): Vector3?
	if target:IsA("BasePart") then
		return target.Position
	end
	if target:IsA("Model") then
		local primary = target.PrimaryPart
		if primary then
			return primary.Position
		end
		local part = target:FindFirstChildWhichIsA("BasePart")
		if part then
			return part.Position
		end
	end
	return nil
end

function InteractionController:_hasLineOfSight(origin: Vector3, target: Instance, position: Vector3): boolean
	local state = self:_getCharacterState()
	local character = state and state.character or nil
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = character and { character } or {}
	params.IgnoreWater = true

	local direction = position - origin
	local result = workspace:Raycast(origin, direction, params)
	if not result or not result.Instance then
		return true
	end

	local hit = result.Instance
	if hit == target or hit:IsDescendantOf(target) then
		return true
	end
	return false
end

function InteractionController:_updatePromptText(target: Instance?)
	local selfImpl = self :: InteractionControllerImpl
	if not selfImpl._prompt then
		return
	end
	if not target then
		selfImpl._prompt:SetVisible(false)
		return
	end

	local text = InteractionConfig.PromptText
	if InteractionConfig.ShowInteractId then
		local idValue = target:GetAttribute(InteractionConfig.InteractIdAttribute)
		if type(idValue) == "string" and idValue ~= "" then
			text = InteractionConfig.PromptFormatWithId:format(text, idValue)
		end
	end

	selfImpl._prompt:SetText(text)
	selfImpl._prompt:SetVisible(true)
end

function InteractionController:_getCharacterState(): CharacterState?
	local selfImpl = self :: InteractionControllerImpl
	if selfImpl._lifecycle and selfImpl._lifecycle.GetState then
		local state = selfImpl._lifecycle:GetState()
		if state and state.character then
			return {
				character = state.character,
				root = state.root,
			}
		end
	end

	local player = selfImpl._player
	if not player then
		return nil
	end
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return {
		character = character,
		root = root,
	}
end

function InteractionController:_logSnapshot(reason: string)
	local selfImpl = self :: InteractionControllerImpl
	if not InteractionConfig.DebugEnabled then
		return
	end
	local now = os.clock()
	if now - selfImpl._lastLogAt < InteractionConfig.LogFrequencySec then
		return
	end
	selfImpl._lastLogAt = now

	print(("[Interact:%s] targets=%d requests=%d success=%d"):format(
		reason,
		selfImpl._metrics:Get("targetChangeCount"),
		selfImpl._metrics:Get("interactRequestCount"),
		selfImpl._metrics:Get("interactSuccessCount")
	))
end

return InteractionController
