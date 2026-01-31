local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("Config"):WaitForChild("UITheme") :: ModuleScript)

local StaminaBar = require(script.Parent:WaitForChild("StaminaBar") :: ModuleScript)

local HUDRoot = Roact.Component:extend("HUDRoot")

function HUDRoot:render()
	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		SafePadding = Roact.createElement("UIPadding", {
			PaddingBottom = UDim.new(0, UITheme.Spacing.L),
			PaddingLeft = UDim.new(0, UITheme.Spacing.L),
			PaddingRight = UDim.new(0, UITheme.Spacing.L),
		}),
		Layout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, UITheme.Spacing.S),
		}),
		Stamina = Roact.createElement(StaminaBar),
	})
end

return HUDRoot
