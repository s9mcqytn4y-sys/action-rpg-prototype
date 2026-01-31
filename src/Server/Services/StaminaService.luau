--!strict

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

function StaminaService.Client:RequestAction(player, actionName: string)
	return self.Server:_requestAction(player, actionName)
end

function StaminaService:KnitInit()
	self._stamina = {}
	self._janitors = {}
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

local function now(): number
	return os.clock()
end

local function getMaxStamina(modifiers)
	local base = GameConfig.Stamina.Max
	local bonus = modifiers.MaxBonus or 0
	return math.max(1, base + bonus)
end

local function getRegenRate(modifiers)
	local base = GameConfig.Stamina.RegenRate
	local bonus = modifiers.RegenRateBonus or 0
	return math.max(0, base + bonus)
end

local function getRegenDelay(modifiers)
	local base = GameConfig.Stamina.RegenDelay
	local bonus = modifiers.RegenDelayBonus or 0
	return math.max(0, base + bonus)
end

function StaminaService:_applyAttributes(instance: Instance?, current: number, max: number, state: string)
	if not instance then
		return
	end
	instance:SetAttribute("Stamina", current)
	instance:SetAttribute("MaxStamina", max)
	instance:SetAttribute("StaminaState", state)
end

function StaminaService:_fireStamina(player, current, max, state)
	self.Client.StaminaChanged:Fire(player, current, max, state)
	self.StaminaChanged:Fire(player, current, max, state)
end

function StaminaService:_setAttributes(player: Player, data, force: boolean)
	local config = GameConfig.Stamina
	local timeNow = now()
	if not force then
		local due = timeNow - data.lastAttributeUpdate >= config.AttributeUpdateInterval
		if not due then
			return
		end
	end

	local current = data.current
	local max = data.max
	local state = data.state

	local changed = force
	if math.abs(current - data.lastSentCurrent) >= config.MinRegenDelta then
		changed = true
	end
	if data.lastSentMax ~= max or data.lastSentState ~= state then
		changed = true
	end

	if not changed then
		return
	end

	data.lastAttributeUpdate = timeNow
	data.lastSentCurrent = current
	data.lastSentMax = max
	data.lastSentState = state

	self:_applyAttributes(player, current, max, state)
	self:_applyAttributes(data.character, current, max, state)
	self:_fireStamina(player, current, max, state)
end

function StaminaService:_bindCharacter(player: Player, character: Model)
	local data = self._stamina[player]
	if not data then
		return
	end
	data.character = character
	self:_applyAttributes(character, data.current, data.max, data.state)
end

function StaminaService:_initPlayer(player, profileData)
	local modifiers = table.clone(GameConfig.Stamina.Modifiers)
	local max = getMaxStamina(modifiers)
	local current = max

	if profileData and type(profileData) == "table" and profileData.Stamina and type(profileData.Stamina.Current) == "number" then
		current = math.clamp(profileData.Stamina.Current, 0, max)
	end

	local data = {
		current = current,
		max = max,
		state = "Idle",
		isSprinting = false,
		lastDrainTime = -math.huge,
		exhaustedUntil = 0,
		lastAttributeUpdate = 0,
		lastSentCurrent = -math.huge,
		lastSentMax = -1,
		lastSentState = "",
		lastProfileUpdate = 0,
		lastProfileValue = current,
		character = nil,
		modifiers = modifiers,
	}

	self._stamina[player] = data
	self:_setAttributes(player, data, true)

	local playerDataService = self._playerDataService
	if playerDataService then
		playerDataService:UpdateProfile(player, function(profile)
			profile.Stamina = profile.Stamina or {}
			profile.Stamina.Current = current
		end, false)
	end

	local existingJanitor = self._janitors[player]
	if existingJanitor then
		existingJanitor:Destroy()
	end

	local janitor = Janitor.new()
	self._janitors[player] = janitor

	janitor:Add(player.CharacterAdded:Connect(function(character)
		self:_bindCharacter(player, character)
	end), "Disconnect")
	janitor:Add(player.CharacterRemoving:Connect(function()
		local currentData = self._stamina[player]
		if currentData then
			currentData.character = nil
		end
	end), "Disconnect")

	if player.Character then
		self:_bindCharacter(player, player.Character)
	end

	janitor:Add(RunService.Heartbeat:Connect(function(dt)
		self:_updatePlayer(player, dt)
	end), "Disconnect")
end

function StaminaService:_cleanupPlayer(player)
	self._stamina[player] = nil

	local janitor = self._janitors[player]
	if janitor then
		janitor:Destroy()
		self._janitors[player] = nil
	end
end

function StaminaService:_updatePlayer(player: Player, dt: number)
	local data = self._stamina[player]
	if not data then
		return
	end

	local timeNow = now()
	local modifiers = data.modifiers
	local max = getMaxStamina(modifiers)
	data.max = max

	local exhausted = timeNow < data.exhaustedUntil or data.current <= 0
	local drained = false

	if data.isSprinting and not exhausted then
		local drainRate = GameConfig.Sprint.DrainPerSecond * (modifiers.DrainMultiplier or 1)
		if drainRate > 0 then
			local drain = drainRate * dt
			if drain > 0 then
				data.current = math.max(0, data.current - drain)
				data.lastDrainTime = timeNow
				drained = true
				if data.current <= 0 then
					data.exhaustedUntil = timeNow + GameConfig.Stamina.ExhaustedDuration
					data.current = 0
					data.isSprinting = false
				end
			end
		end
	end

	exhausted = timeNow < data.exhaustedUntil or data.current <= 0

	if not data.isSprinting and not exhausted then
		local regenDelay = getRegenDelay(modifiers)
		local regenRate = getRegenRate(modifiers)
		local canRegen = timeNow - data.lastDrainTime >= regenDelay
		if canRegen and regenRate > 0 and data.current < max then
			local newValue = math.min(max, data.current + (regenRate * dt))
			if newValue ~= data.current then
				data.current = newValue
			end
		end
	end

	if exhausted then
		data.state = "Exhausted"
	elseif data.isSprinting and drained then
		data.state = "Draining"
	elseif data.current < max then
		data.state = "Recovering"
	else
		data.state = "Idle"
	end

	self:_setAttributes(player, data, false)

	local config = GameConfig.Stamina
	if timeNow - data.lastProfileUpdate >= config.ProfileUpdateInterval then
		if math.abs(data.current - data.lastProfileValue) >= 0.5 then
			local playerDataService = self._playerDataService
			if playerDataService then
				playerDataService:UpdateProfile(player, function(profile)
					profile.Stamina = profile.Stamina or {}
					profile.Stamina.Current = data.current
				end, false)
				data.lastProfileUpdate = timeNow
				data.lastProfileValue = data.current
			end
		end
	end
end

function StaminaService:CanConsume(player: Player, cost: number): boolean
	if cost <= 0 then
		return true
	end
	local data = self._stamina[player]
	if not data then
		return false
	end
	if now() < data.exhaustedUntil then
		return false
	end
	return data.current >= cost
end

function StaminaService:Consume(player: Player, cost: number, reason: string?): boolean
	if cost <= 0 then
		return true
	end
	local data = self._stamina[player]
	if not data then
		return false
	end
	if not self:CanConsume(player, cost) then
		return false
	end

	data.current = math.max(0, data.current - cost)
	data.lastDrainTime = now()
	data.state = "Draining"

	if data.current <= 0 then
		data.exhaustedUntil = now() + GameConfig.Stamina.ExhaustedDuration
		data.state = "Exhausted"
	end

	self:_setAttributes(player, data, true)
	return true
end

function StaminaService:_requestAction(player: Player, actionName: string)
	local actions = GameConfig.Stamina.Actions
	local cost = nil
	if actionName == "Dodge" then
		cost = actions.DodgeCost
	elseif actionName == "Heavy" then
		cost = actions.HeavyCost
	end

	if not cost then
		return false
	end

	return self:Consume(player, cost, actionName)
end

function StaminaService:GetStamina(player)
	local data = self._stamina[player]
	if not data then
		local max = GameConfig.Stamina.Max
		return max, max, "Idle"
	end
	return data.current, data.max, data.state
end

function StaminaService:SetStamina(player, value)
	local data = self._stamina[player]
	if not data then
		return
	end
	data.current = math.clamp(value, 0, data.max)
	data.lastDrainTime = now()
	self:_setAttributes(player, data, true)
end

function StaminaService:ResetForSpawn(player: Player)
	local data = self._stamina[player]
	if not data then
		return
	end
	data.current = data.max
	data.state = "Idle"
	data.isSprinting = false
	data.exhaustedUntil = 0
	data.lastDrainTime = -math.huge
	self:_setAttributes(player, data, true)
end

function StaminaService:SetSprinting(player, isSprinting: boolean)
	local data = self._stamina[player]
	if not data then
		return
	end
	data.isSprinting = isSprinting == true
end

function StaminaService:CanSprint(player: Player): boolean
	local data = self._stamina[player]
	if not data then
		return false
	end
	if now() < data.exhaustedUntil then
		return false
	end
	return data.current >= GameConfig.Sprint.MinStaminaToStart
end

return StaminaService
