--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local DebugConfig = require(Shared:WaitForChild("Config"):WaitForChild("DebugConfig") :: ModuleScript)
local CharacterConfig = require(Shared:WaitForChild("Config"):WaitForChild("CharacterConfig") :: ModuleScript)
local Metrics = require(Shared:WaitForChild("Util"):WaitForChild("Metrics") :: ModuleScript)

type MetricsType = typeof(Metrics.new(false))
type JanitorType = typeof(Janitor.new())

type CharacterLifecycleService = {
	KnitInit: (self: CharacterLifecycleService) -> (),
	KnitStart: (self: CharacterLifecycleService) -> (),
}

type CharacterLifecycleServiceImpl = CharacterLifecycleService & {
	_janitor: JanitorType,
	_playerJanitors: { [Player]: JanitorType },
	_characterJanitors: { [Player]: JanitorType },
	_currentCharacters: { [Player]: Model? },
	_bindTokens: { [Player]: number },
	_metrics: MetricsType,
	_lastLogAt: number,
	_sprintService: any?,
	_staminaService: any?,

	_initPlayer: (self: CharacterLifecycleServiceImpl, player: Player) -> (),
	_cleanupPlayer: (self: CharacterLifecycleServiceImpl, player: Player) -> (),
	_bindCharacterAsync: (self: CharacterLifecycleServiceImpl, player: Player, character: Model) -> (),
	_bindCharacter: (self: CharacterLifecycleServiceImpl, player: Player, character: Model, humanoid: Humanoid) -> (),
	_cleanupCharacter: (self: CharacterLifecycleServiceImpl, player: Player, reason: string) -> (),
	_waitForHumanoid: (self: CharacterLifecycleServiceImpl, character: Model, timeoutSec: number) -> Humanoid?,
	_logSnapshot: (self: CharacterLifecycleServiceImpl, reason: string) -> (),
}

local CharacterLifecycleService: CharacterLifecycleServiceImpl = Knit.CreateService({
	Name = "CharacterLifecycleService",
}) :: any

function CharacterLifecycleService:KnitInit()
	local selfImpl = self :: CharacterLifecycleServiceImpl
	selfImpl._janitor = Janitor.new()
	selfImpl._playerJanitors = {}
	selfImpl._characterJanitors = {}
	selfImpl._currentCharacters = {}
	selfImpl._bindTokens = {}
	selfImpl._metrics = Metrics.new(DebugConfig.EnableMetrics)
	selfImpl._lastLogAt = 0
	selfImpl._sprintService = nil
	selfImpl._staminaService = nil
end

function CharacterLifecycleService:KnitStart()
	local selfImpl = self :: CharacterLifecycleServiceImpl
	if not RunService:IsServer() then
		if DebugConfig.LogWarnings then
			warn("[CharacterLifecycleService] Started outside server context")
		end
		return
	end

	selfImpl._sprintService = Knit.GetService("SprintService")
	selfImpl._staminaService = Knit.GetService("StaminaService")

	selfImpl._janitor:Add(Players.PlayerAdded:Connect(function(player)
		selfImpl:_initPlayer(player)
	end), "Disconnect")

	selfImpl._janitor:Add(Players.PlayerRemoving:Connect(function(player)
		selfImpl:_cleanupPlayer(player)
	end), "Disconnect")

	for _, player in Players:GetPlayers() do
		selfImpl:_initPlayer(player)
	end
end

function CharacterLifecycleService:_initPlayer(player: Player)
	local selfImpl = self :: CharacterLifecycleServiceImpl
	local existing = selfImpl._playerJanitors[player]
	if existing then
		existing:Destroy()
	end

	local janitor = Janitor.new()
	selfImpl._playerJanitors[player] = janitor
	selfImpl._bindTokens[player] = 0

	janitor:Add(player.CharacterAdded:Connect(function(character)
		selfImpl:_bindCharacterAsync(player, character)
	end), "Disconnect")

	janitor:Add(player.CharacterRemoving:Connect(function(character)
		if selfImpl._currentCharacters[player] == character then
			selfImpl:_cleanupCharacter(player, "remove")
		end
	end), "Disconnect")

	if player.Character then
		selfImpl:_bindCharacterAsync(player, player.Character)
	end
end

function CharacterLifecycleService:_cleanupPlayer(player: Player)
	local selfImpl = self :: CharacterLifecycleServiceImpl
	selfImpl:_cleanupCharacter(player, "playerRemove")

	local janitor = selfImpl._playerJanitors[player]
	if janitor then
		janitor:Destroy()
		selfImpl._playerJanitors[player] = nil
	end
	selfImpl._bindTokens[player] = nil
end

function CharacterLifecycleService:_bindCharacterAsync(player: Player, character: Model)
	local selfImpl = self :: CharacterLifecycleServiceImpl
	selfImpl._bindTokens[player] = (selfImpl._bindTokens[player] or 0) + 1
	local token = selfImpl._bindTokens[player]

	task.spawn(function()
		local humanoid = selfImpl:_waitForHumanoid(character, CharacterConfig.CharacterReadyTimeoutSec)
		if not humanoid then
			return
		end
		if token ~= selfImpl._bindTokens[player] then
			return
		end
		selfImpl:_bindCharacter(player, character, humanoid)
	end)
end

function CharacterLifecycleService:_bindCharacter(player: Player, character: Model, humanoid: Humanoid)
	local selfImpl = self :: CharacterLifecycleServiceImpl
	if selfImpl._currentCharacters[player] == character then
		return
	end

	selfImpl:_cleanupCharacter(player, "rebind")
	selfImpl._currentCharacters[player] = character

	local charJanitor = Janitor.new()
	selfImpl._characterJanitors[player] = charJanitor

	charJanitor:Add(humanoid.Died:Connect(function()
		selfImpl:_cleanupCharacter(player, "died")
	end), "Disconnect")

	charJanitor:Add(character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			selfImpl:_cleanupCharacter(player, "ancestry")
		end
	end), "Disconnect")

	if CharacterConfig.ResetSprintOnSpawn and selfImpl._sprintService then
		selfImpl._sprintService:SetWantsSprint(player, false)
	end

	if CharacterConfig.ResetStaminaOnSpawn and selfImpl._staminaService then
		selfImpl._staminaService:ResetForSpawn(player)
	end

	selfImpl._metrics:Increment("characterBindCount", 1)
	selfImpl:_logSnapshot("bind")
end

function CharacterLifecycleService:_cleanupCharacter(player: Player, reason: string)
	local selfImpl = self :: CharacterLifecycleServiceImpl
	local current = selfImpl._currentCharacters[player]
	if not current then
		return
	end

	local charJanitor = selfImpl._characterJanitors[player]
	if charJanitor then
		charJanitor:Destroy()
		selfImpl._characterJanitors[player] = nil
	end

	if reason == "died" then
		selfImpl._metrics:Increment("diedEventCount", 1)
	end

	if CharacterConfig.ResetSprintOnDeath and selfImpl._sprintService then
		selfImpl._sprintService:SetWantsSprint(player, false)
	end
	if selfImpl._staminaService then
		selfImpl._staminaService:SetSprinting(player, false)
	end

	selfImpl._currentCharacters[player] = nil
	selfImpl._metrics:Increment("cleanupCount", 1)
	selfImpl:_logSnapshot(reason)
end

function CharacterLifecycleService:_waitForHumanoid(character: Model, timeoutSec: number): Humanoid?
	local t0 = os.clock()
	while os.clock() - t0 < timeoutSec do
		if character.Parent == nil then
			return nil
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return humanoid
		end
		task.wait()
	end
	return nil
end

function CharacterLifecycleService:_logSnapshot(reason: string)
	local selfImpl = self :: CharacterLifecycleServiceImpl
	if not DebugConfig.LifecycleEnabled then
		return
	end
	local now = os.clock()
	if now - selfImpl._lastLogAt < DebugConfig.LifecycleLogFrequencySec then
		return
	end
	selfImpl._lastLogAt = now

	print(("[CharacterLifecycle:%s] binds=%d died=%d cleanups=%d"):format(
		reason,
		selfImpl._metrics:Get("characterBindCount"),
		selfImpl._metrics:Get("diedEventCount"),
		selfImpl._metrics:Get("cleanupCount")
	))
end

return CharacterLifecycleService
