local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("Config"):WaitForChild("UITheme") :: ModuleScript)

type Props = {
	Enabled: boolean,
	OnChanged: (enabled: boolean) -> (),
}

local Toggle = Roact.Component:extend("Toggle")

function Toggle:render()
	local props = self.props :: Props
	local knobX = if props.Enabled then 18 else 2

	return Roact.createElement("TextButton", {
		Size = UDim2.new(0, 36, 0, 18),
		BackgroundColor3 = if props.Enabled then UITheme.Colors.AccentSoft else UITheme.Colors.PanelAlt,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = true,
		[Roact.Event.Activated] = function()
			props.OnChanged(not props.Enabled)
		end,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		Knob = Roact.createElement("Frame", {
			Position = UDim2.new(0, knobX, 0, 2),
			Size = UDim2.new(0, 14, 0, 14),
			BackgroundColor3 = UITheme.Colors.TextPrimary,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
	})
end

return Toggle
