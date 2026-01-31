local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)
local Signal = require(Packages:WaitForChild("Signal") :: ModuleScript)
local Val = require(Packages:WaitForChild("Val") :: ModuleScript)

local parent = script.Parent
if not parent then
	error("StaminaController must be parented under Client/Controllers")
end

local clientFolder = parent.Parent
if not clientFolder then
	error("StaminaController must be parented under Client")
end

local stateFolder = clientFolder:WaitForChild("State") :: Folder
local store = require(stateFolder:WaitForChild("Store") :: ModuleScript)
local Actions = require(stateFolder:WaitForChild("Actions") :: ModuleScript)

local StaminaController = Knit.CreateController({
	Name = "StaminaController",
})

function StaminaController:KnitInit()
	self._janitor = Janitor.new()
	self._attributeJanitor = Janitor.new()
	self.StaminaChanged = Signal.new()
	self._staminaVal = Val.new({
		current = 0,
		max = 0,
		state = "Idle",
	})
end

function StaminaController:_applyStamina(current: number, max: number, state: string)
	self._staminaVal:set({
		current = current,
		max = max,
		state = state,
	})
	store:dispatch(Actions.SetStamina(current, max, state))
	self.StaminaChanged:Fire(current, max, state)
end

function StaminaController:_readAttributes(instance: Instance?)
	if not instance then
		return
	end
	local current = instance:GetAttribute("Stamina")
	local max = instance:GetAttribute("MaxStamina")
	local state = instance:GetAttribute("StaminaState")
	if type(current) == "number" and type(max) == "number" and type(state) == "string" then
		self:_applyStamina(current, max, state)
	end
end

function StaminaController:_bindAttributes(instance: Instance)
	self._attributeJanitor:Cleanup()

	local function refresh()
		self:_readAttributes(instance)
	end

	self._attributeJanitor:Add(instance:GetAttributeChangedSignal("Stamina"):Connect(refresh), "Disconnect")
	self._attributeJanitor:Add(instance:GetAttributeChangedSignal("MaxStamina"):Connect(refresh), "Disconnect")
	self._attributeJanitor:Add(instance:GetAttributeChangedSignal("StaminaState"):Connect(refresh), "Disconnect")

	refresh()
end

function StaminaController:KnitStart()
	local staminaService = Knit.GetService("StaminaService")
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		localPlayer = Players.LocalPlayer
	end
	if not localPlayer then
		return
	end

	self._janitor:Add(localPlayer.CharacterAdded:Connect(function(character)
		self:_bindAttributes(character)
	end), "Disconnect")

	if localPlayer.Character then
		self:_bindAttributes(localPlayer.Character)
	else
		self:_bindAttributes(localPlayer)
	end

	self._janitor:Add(staminaService.StaminaChanged:Connect(function(player, current, max, state)
		if player ~= localPlayer then
			return
		end
		if type(current) == "number" and type(max) == "number" and type(state) == "string" then
			self:_applyStamina(current, max, state)
		end
	end), "Disconnect")

	local ok, current, max, state = pcall(function()
		return staminaService:GetStamina()
	end)
	if ok and type(current) == "number" and type(max) == "number" then
		self:_applyStamina(current, max, if type(state) == "string" then state else "Idle")
	end
end

function StaminaController:GetStamina()
	return self._staminaVal:get()
end

return StaminaController
