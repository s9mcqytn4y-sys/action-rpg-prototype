local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)
local Signal = require(Packages:WaitForChild("Signal") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Config = Shared:WaitForChild("Config") :: Folder
local GameConfig = require(Config:WaitForChild("GameConfig") :: ModuleScript)

local StaminaService = Knit.CreateService({
	Name = "StaminaService",
	Client = {
		StaminaChanged = Knit.CreateSignal(),
	},
})

function StaminaService.Client:GetStamina(player)
	return self.Server:GetStamina(player)
end

function StaminaService:KnitInit()
	self._stamina = {}
	self._janitors = {}
	self._isSprinting = {}
	self.StaminaChanged = Signal.new()
end

function StaminaService:KnitStart()
	self._playerDataService = Knit.GetService("PlayerDataService")

	self._playerDataService.ProfileLoaded:Connect(function(player, data)
		self:_initPlayer(player, data)
	end)

	self._playerDataService.ProfileReleased:Connect(function(player)
		self:_cleanupPlayer(player)
	end)

	for _, player in Players:GetPlayers() do
		local data = self._playerDataService:GetProfile(player)
		if data then
			self:_initPlayer(player, data)
		end
	end
end

function StaminaService:_initPlayer(player, data)
	local max = GameConfig.Stamina.Max
	local current = max

	if data and type(data) == "table" and data.Stamina and type(data.Stamina.Current) == "number" then
		current = math.clamp(data.Stamina.Current, 0, max)
	end

	self._stamina[player] = current
	self._isSprinting[player] = false
	self:_fireStamina(player, current, max)

	local playerDataService = self._playerDataService
	if playerDataService then
		playerDataService:UpdateProfile(player, function(profileData)
			profileData.Stamina = profileData.Stamina or {}
			profileData.Stamina.Current = current
		end, false)
	end

	local existingJanitor = self._janitors[player]
	if existingJanitor then
		existingJanitor:Destroy()
	end

	local janitor = Janitor.new()
	self._janitors[player] = janitor

	janitor:Add(RunService.Heartbeat:Connect(function(dt)
		local value = self._stamina[player]
		if not value then
			return
		end

		if value < max then
			if not self._isSprinting[player] then
				local newValue = math.min(max, value + (GameConfig.Stamina.RegenPerSecond * dt))
				if newValue ~= value then
					self:_setStaminaInternal(player, newValue, max)
				end
			end
		end
	end), "Disconnect")
end

function StaminaService:_cleanupPlayer(player)
	self._stamina[player] = nil
	self._isSprinting[player] = nil

	local janitor = self._janitors[player]
	if janitor then
		janitor:Destroy()
		self._janitors[player] = nil
	end
end

function StaminaService:_fireStamina(player, current, max)
	self.Client.StaminaChanged:Fire(player, current, max)
	self.StaminaChanged:Fire(player, current, max)
end

function StaminaService:_setStaminaInternal(player, value, max)
	local clamped = math.clamp(value, 0, max)
	self._stamina[player] = clamped

	local playerDataService = self._playerDataService
	if playerDataService then
		playerDataService:UpdateProfile(player, function(data)
			data.Stamina = data.Stamina or {}
			data.Stamina.Current = clamped
		end, false)
	end

	self:_fireStamina(player, clamped, max)
end

function StaminaService:GetStamina(player)
	local max = GameConfig.Stamina.Max
	return self._stamina[player] or max, max
end

function StaminaService:SetStamina(player, value)
	local max = GameConfig.Stamina.Max
	self:_setStaminaInternal(player, value, max)
end

function StaminaService:SetSprinting(player, isSprinting: boolean)
	self._isSprinting[player] = isSprinting
end

return StaminaService
