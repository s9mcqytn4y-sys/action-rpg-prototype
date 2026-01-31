local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local DisplayController = Knit.CreateController({
	Name = "DisplayController",
})

function DisplayController:KnitInit()
	self._janitor = Janitor.new()
	self._prefsController = nil
end

function DisplayController:KnitStart()
	local ok, prefsController = pcall(function()
		return Knit.GetController("PreferencesController")
	end)
	if not ok or not prefsController then
		return
	end
	self._prefsController = prefsController

	local player = Players.LocalPlayer
	if not player then
		Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		player = Players.LocalPlayer
	end
	if not player then
		return
	end

	self:_applyPrefs(player, prefsController:GetPreferences())
	self._janitor:Add(prefsController.Changed:Connect(function(prefs)
		self:_applyPrefs(player, prefs)
	end), "Disconnect")
end

function DisplayController:_applyPrefs(player: Player, prefs)
	local display = prefs and prefs.Display or nil
	if not display then
		return
	end

	local showDamage = display.ShowDamageText ~= false
	local showVfx = display.ShowVfx ~= false

	player:SetAttribute("ShowDamageText", showDamage)
	player:SetAttribute("ShowVfx", showVfx)
end

return DisplayController
