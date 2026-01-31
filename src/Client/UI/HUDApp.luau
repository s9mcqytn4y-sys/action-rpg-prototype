local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local StaminaBar = require(script.Parent.Components:WaitForChild("StaminaBar") :: ModuleScript)

local HUDApp = Roact.PureComponent:extend("HUDApp")

function HUDApp:render()
	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
	}, {
		Stamina = Roact.createElement(StaminaBar),
	})
end

return HUDApp
