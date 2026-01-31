--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local DebugConfig = require(Shared:WaitForChild("Config"):WaitForChild("DebugConfig") :: ModuleScript)
local CharacterConfig = require(Shared:WaitForChild("Config"):WaitForChild("CharacterConfig") :: ModuleScript)
local Metrics = require(Shared:WaitForChild("Util"):WaitForChild("Metrics") :: ModuleScript)

type MetricsType = typeof(Metrics.new(false))
type JanitorType = typeof(Janitor.new())

type CharacterState = {
	character: Model,
	humanoid: Humanoid,
	root: BasePart?,
	animator: Animator?,
}

type CharacterLifecycleController = {
	KnitInit: (self: CharacterLifecycleController) -> (),
	KnitStart: (self: CharacterLifecycleController) -> (),
	GetState: (self: CharacterLifecycleController) -> CharacterState?,
}

type CharacterLifecycleControllerImpl = CharacterLifecycleController & {
	_janitor: JanitorType,
	_characterJanitor: JanitorType,
	_metrics: MetricsType,
	_lastLogAt: number,
	_player: Player?,
	_state: CharacterState?,
	_bindToken: number,
	_sprintController: any?,

	_getLocalPlayer: (self: CharacterLifecycleControllerImpl) -> Player?,
	_bindCharacterAsync: (self: CharacterLifecycleControllerImpl, character: Model) -> (),
	_bindCharacter: (self: CharacterLifecycleControllerImpl, character: Model, humanoid: Humanoid, root: BasePart?) -> (),
	_cleanupCharacter: (self: CharacterLifecycleControllerImpl, reason: string) -> (),
	_waitForCharacterReady: (self: CharacterLifecycleControllerImpl, character: Model, timeoutSec: number) -> (Humanoid?, BasePart?),
	_resetRuntimeState: (self: CharacterLifecycleControllerImpl, reason: string) -> (),
	_logSnapshot: (self: CharacterLifecycleControllerImpl, reason: string) -> (),
}

local CharacterLifecycleController: CharacterLifecycleControllerImpl = Knit.CreateController({
	Name = "CharacterLifecycleController",
}) :: any

function CharacterLifecycleController:KnitInit()
	local selfImpl = self :: CharacterLifecycleControllerImpl
	selfImpl._janitor = Janitor.new()
	selfImpl._characterJanitor = Janitor.new()
	selfImpl._metrics = Metrics.new(DebugConfig.EnableMetrics)
	selfImpl._lastLogAt = 0
	selfImpl._player = nil
	selfImpl._state = nil
	selfImpl._bindToken = 0
	selfImpl._sprintController = nil
end

function CharacterLifecycleController:KnitStart()
	local selfImpl = self :: CharacterLifecycleControllerImpl

	local okSprint, sprintController = pcall(function()
		return Knit.GetController("SprintController")
	end)
	if okSprint and sprintController then
		selfImpl._sprintController = sprintController
	end

	local player = selfImpl:_getLocalPlayer()
	selfImpl._player = player
	if not player then
		if DebugConfig.LogWarnings then
			warn("[CharacterLifecycleController] LocalPlayer missing; lifecycle bind skipped.")
		end
		return
	end

	selfImpl._janitor:Add(player.CharacterAdded:Connect(function(character)
		selfImpl:_bindCharacterAsync(character)
	end), "Disconnect")

	selfImpl._janitor:Add(player.CharacterRemoving:Connect(function(character)
		if selfImpl._state and selfImpl._state.character == character then
			selfImpl:_cleanupCharacter("remove")
		end
	end), "Disconnect")

	if player.Character then
		selfImpl:_bindCharacterAsync(player.Character)
	end
end

function CharacterLifecycleController:GetState(): CharacterState?
	return (self :: CharacterLifecycleControllerImpl)._state
end

function CharacterLifecycleController:_getLocalPlayer(): Player?
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

function CharacterLifecycleController:_bindCharacterAsync(character: Model)
	local selfImpl = self :: CharacterLifecycleControllerImpl
	selfImpl._bindToken += 1
	local token = selfImpl._bindToken

	task.spawn(function()
		local humanoid, root = selfImpl:_waitForCharacterReady(character, CharacterConfig.CharacterReadyTimeoutSec)
		if not humanoid then
			return
		end
		if token ~= selfImpl._bindToken then
			return
		end
		selfImpl:_bindCharacter(character, humanoid, root)
	end)
end

function CharacterLifecycleController:_bindCharacter(character: Model, humanoid: Humanoid, root: BasePart?)
	local selfImpl = self :: CharacterLifecycleControllerImpl
	if selfImpl._state and selfImpl._state.character == character then
		return
	end

	selfImpl:_cleanupCharacter("rebind")

	local animator = humanoid:FindFirstChildOfClass("Animator") :: Animator?
	selfImpl._state = {
		character = character,
		humanoid = humanoid,
		root = root,
		animator = animator,
	}

	selfImpl._characterJanitor:Add(humanoid.Died:Connect(function()
		selfImpl._metrics:Increment("diedEventCount", 1)
		selfImpl:_resetRuntimeState("died")
		selfImpl:_cleanupCharacter("died")
	end), "Disconnect")

	selfImpl._characterJanitor:Add(character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			selfImpl:_cleanupCharacter("ancestry")
		end
	end), "Disconnect")

	selfImpl:_resetRuntimeState("spawn")
	selfImpl._metrics:Increment("characterBindCount", 1)
	selfImpl:_logSnapshot("bind")
end

function CharacterLifecycleController:_cleanupCharacter(reason: string)
	local selfImpl = self :: CharacterLifecycleControllerImpl
	if not selfImpl._state then
		return
	end

	selfImpl._characterJanitor:Cleanup()
	selfImpl._state = nil
	selfImpl._metrics:Increment("cleanupCount", 1)
	selfImpl:_logSnapshot(reason)
end

function CharacterLifecycleController:_waitForCharacterReady(character: Model, timeoutSec: number): (Humanoid?, BasePart?)
	local t0 = os.clock()
	while os.clock() - t0 < timeoutSec do
		if character.Parent == nil then
			return nil, nil
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoid then
			return humanoid, root
		end
		task.wait()
	end
	return nil, nil
end

function CharacterLifecycleController:_resetRuntimeState(reason: string)
	local selfImpl = self :: CharacterLifecycleControllerImpl
	if (reason == "spawn" and CharacterConfig.ResetSprintOnSpawn)
		or (reason == "died" and CharacterConfig.ResetSprintOnDeath)
	then
		if selfImpl._sprintController then
			selfImpl._sprintController:SetSprint(false)
		end
	end
end

function CharacterLifecycleController:_logSnapshot(reason: string)
	local selfImpl = self :: CharacterLifecycleControllerImpl
	if not DebugConfig.LifecycleEnabled then
		return
	end
	local now = os.clock()
	if now - selfImpl._lastLogAt < DebugConfig.LifecycleLogFrequencySec then
		return
	end
	selfImpl._lastLogAt = now

	print(("[CharacterLifecycleClient:%s] binds=%d died=%d cleanups=%d"):format(
		reason,
		selfImpl._metrics:Get("characterBindCount"),
		selfImpl._metrics:Get("diedEventCount"),
		selfImpl._metrics:Get("cleanupCount")
	))
end

return CharacterLifecycleController
