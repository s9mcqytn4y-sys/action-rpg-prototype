local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

local StaminaBar = require(script.Parent:WaitForChild("StaminaBar") :: ModuleScript)

local HUDRoot = Roact.Component:extend("HUDRoot")

function HUDRoot:render()
	return Roact.createElement("Frame", {
		Name = "HUDRoot",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		-- Safe area padding for all devices
		SafeArea = Roact.createElement("Frame", {
			Name = "SafeArea",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			Padding = Roact.createElement("UIPadding", {
				PaddingBottom = UDim.new(0, Theme.Spacing.XL + 8),
				PaddingLeft = UDim.new(0, Theme.Spacing.L),
				PaddingRight = UDim.new(0, Theme.Spacing.L),
				PaddingTop = UDim.new(0, 0),
			}),

			-- Bottom stack container (so we can keep things grouped)
			BottomStack = Roact.createElement("Frame", {
				Name = "BottomStack",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, {
				Layout = Roact.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, Theme.Spacing.M),
				}),

				-- HUD Elements (add more later easily)
				Stamina = Roact.createElement(StaminaBar, {
					LayoutOrder = 1,
				}),
			}),
		}),
	})
end

return HUDRoot
