local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local GameConfig = require(Shared:WaitForChild("Config"):WaitForChild("GameConfig") :: ModuleScript)

local SprintController = Knit.CreateController({
	Name = "SprintController",
})

function SprintController:KnitInit()
	self._janitor = Janitor.new()
	self._bindings = Janitor.new()
	self._wantsSprint = false
	self._holdSprint = true
	self._service = nil
	self._staminaService = nil
	self._prefsController = nil
end

function SprintController:KnitStart()
	self._service = Knit.GetService("SprintService")
	self._staminaService = Knit.GetService("StaminaService")

	local ok, prefsController = pcall(function()
		return Knit.GetController("PreferencesController")
	end)
	if ok and prefsController then
		self._prefsController = prefsController
		self:_applyPreferences(prefsController:GetPreferences())
		self._janitor:Add(prefsController.Changed:Connect(function(prefs)
			self:_applyPreferences(prefs)
		end), "Disconnect")
	end

	self:_bindActions()
end

function SprintController:_applyPreferences(prefs)
	local controls = prefs and prefs.Controls or nil
	local nextHold = true
	if controls and controls.HoldSprint ~= nil then
		nextHold = controls.HoldSprint == true
	end
	if nextHold ~= self._holdSprint then
		self._holdSprint = nextHold
		self:_setSprint(false)
		self:_bindActions()
	end
end

function SprintController:_bindActions()
	self._bindings:Cleanup()

	local input = GameConfig.Stamina.Input

	if self._holdSprint then
		ContextActionService:BindAction("SprintHold", function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				self:_setSprint(true)
			elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
				self:_setSprint(false)
			end
			return Enum.ContextActionResult.Sink
		end, false, input.SprintHoldKey, input.GamepadSprint)
		self._bindings:Add(function()
			ContextActionService:UnbindAction("SprintHold")
		end)
	else
		ContextActionService:BindAction("SprintToggle", function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				self:_setSprint(not self._wantsSprint)
			end
			return Enum.ContextActionResult.Sink
		end, false, input.SprintToggleKey, input.GamepadSprint)
		self._bindings:Add(function()
			ContextActionService:UnbindAction("SprintToggle")
		end)
	end

	ContextActionService:BindAction("Dodge", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:_requestAction("Dodge")
		end
		return Enum.ContextActionResult.Sink
	end, true, input.DodgeKey, input.GamepadDodge)
	self._bindings:Add(function()
		ContextActionService:UnbindAction("Dodge")
	end)

	ContextActionService:BindAction("Heavy", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			self:_requestAction("Heavy")
		end
		return Enum.ContextActionResult.Sink
	end, true, input.HeavyKey, input.GamepadHeavy)
	self._bindings:Add(function()
		ContextActionService:UnbindAction("Heavy")
	end)

	ContextActionService:SetTitle("Dodge", "Dodge")
	ContextActionService:SetTitle("Heavy", "Heavy")
	ContextActionService:SetPosition("Dodge", UDim2.new(1, -140, 1, -160))
	ContextActionService:SetPosition("Heavy", UDim2.new(1, -60, 1, -160))
end

function SprintController:SetSprint(wantsSprint: boolean)
	self:_setSprint(wantsSprint)
end

function SprintController:_setSprint(wantsSprint: boolean)
	if self._wantsSprint == wantsSprint then
		return
	end
	self._wantsSprint = wantsSprint
	if self._service then
		self._service:RequestSprint(wantsSprint)
	end
end

function SprintController:_requestAction(actionName: string)
	if self._staminaService then
		self._staminaService:RequestAction(actionName)
	end
end

return SprintController
