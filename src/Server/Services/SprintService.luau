local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local GameConfig = require(Shared:WaitForChild("Config"):WaitForChild("GameConfig") :: ModuleScript)

local SprintService = Knit.CreateService({
	Name = "SprintService",
	Client = {},
})

local function expAlpha(speed: number, dt: number): number
	if speed <= 0 then
		return 1
	end
	return 1 - math.exp(-speed * dt)
end

function SprintService:KnitInit()
	self._janitors = {}
	self._state = {}
end

function SprintService:KnitStart()
	self._staminaService = Knit.GetService("StaminaService")

	Players.PlayerAdded:Connect(function(player)
		self:_initPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_cleanupPlayer(player)
	end)

	for _, player in Players:GetPlayers() do
		self:_initPlayer(player)
	end
end

function SprintService.Client:RequestSprint(player, wantsSprint: boolean)
	return self.Server:_requestSprint(player, wantsSprint)
end

function SprintService:_initPlayer(player: Player)
	local janitor = Janitor.new()
	self._janitors[player] = janitor
	self._state[player] = {
		wantsSprint = false,
		baseSpeed = nil,
		currentSpeed = nil,
		humanoid = nil,
		root = nil,
	}

	janitor:Add(player.CharacterAdded:Connect(function(character)
		self:_bindCharacter(player, character)
	end), "Disconnect")
	janitor:Add(player.CharacterRemoving:Connect(function()
		self:_unbindCharacter(player)
	end), "Disconnect")

	if player.Character then
		self:_bindCharacter(player, player.Character)
	end

	janitor:Add(RunService.Heartbeat:Connect(function(dt)
		self:_updatePlayer(player, dt)
	end), "Disconnect")
end

function SprintService:_cleanupPlayer(player: Player)
	local janitor = self._janitors[player]
	if janitor then
		janitor:Destroy()
		self._janitors[player] = nil
	end
	self._state[player] = nil
end

function SprintService:_bindCharacter(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return
	end
	local data = self._state[player]
	if not data then
		return
	end
	data.humanoid = humanoid
	data.root = root
	data.baseSpeed = humanoid.WalkSpeed
	data.currentSpeed = humanoid.WalkSpeed
end

function SprintService:_unbindCharacter(player: Player)
	local data = self._state[player]
	if not data then
		return
	end
	data.humanoid = nil
	data.root = nil
	data.currentSpeed = nil
end

function SprintService:_requestSprint(player: Player, wantsSprint: boolean)
	local data = self._state[player]
	if not data then
		return false
	end
	data.wantsSprint = wantsSprint == true
	return true
end

function SprintService:_updatePlayer(player: Player, dt: number)
	local data = self._state[player]
	if not data or not data.humanoid or not data.root then
		return
	end

	local humanoid = data.humanoid
	local baseSpeed = data.baseSpeed or humanoid.WalkSpeed

	-- Sprint only when requested, stamina sufficient, and actually moving.
	local moving = humanoid.MoveDirection.Magnitude > GameConfig.Sprint.MinMoveThreshold
	local canStart = self._staminaService:CanSprint(player)
	local isSprinting = data.wantsSprint and moving and canStart

	local targetSpeed = baseSpeed
	if isSprinting then
		targetSpeed = baseSpeed * GameConfig.Sprint.SpeedMultiplier
	end

	local current = data.currentSpeed or humanoid.WalkSpeed
	local alpha = expAlpha(GameConfig.Sprint.SpeedBlendSpeed, dt)
	current = current + (targetSpeed - current) * alpha
	data.currentSpeed = current

	-- Server authority: smooth WalkSpeed for comfort.
	if math.abs(humanoid.WalkSpeed - current) > 0.01 then
		humanoid.WalkSpeed = current
	end

	self._staminaService:SetSprinting(player, isSprinting)
end

return SprintService
