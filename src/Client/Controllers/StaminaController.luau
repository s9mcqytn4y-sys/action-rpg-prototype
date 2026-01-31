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
	self.StaminaChanged = Signal.new()
	self._staminaVal = Val.new({
		current = 0,
		max = 0,
	})
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

	self._janitor:Add(staminaService.StaminaChanged:Connect(function(player, current, max)
		if player ~= localPlayer then
			return
		end

		self._staminaVal:set({
			current = current,
			max = max,
		})
		store:dispatch(Actions.SetStamina(current, max))
		self.StaminaChanged:Fire(current, max)
	end), "Disconnect")

	local ok, current, max = pcall(function()
		return staminaService:GetStamina()
	end)
	if ok and type(current) == "number" and type(max) == "number" then
		self._staminaVal:set({
			current = current,
			max = max,
		})
		store:dispatch(Actions.SetStamina(current, max))
		self.StaminaChanged:Fire(current, max)
	end
end

function StaminaController:GetStamina()
	return self._staminaVal:get()
end

return StaminaController
