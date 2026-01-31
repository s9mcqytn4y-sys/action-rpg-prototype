--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

local Controls = script.Parent.Parent:WaitForChild("Controls") :: Folder
local Toggle = require(Controls:WaitForChild("Toggle") :: ModuleScript)

local ToggleRow = Roact.PureComponent:extend("ToggleRow")

type Props = {
	Label: string,
	Enabled: boolean,
	OnChanged: (boolean) -> (),
	LayoutOrder: number?,
}

function ToggleRow:render()
	local props = self.props :: Props
return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Theme.Colors.PanelAlt,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, Theme.Radius.S),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = Theme.Colors.Border,
			Transparency = 0.35,
			Thickness = 1,
		}),
		Label = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, Theme.Spacing.M, 0, 0),
			Size = UDim2.new(0.7, 0, 1, 0),
			Text = props.Label,
			TextColor3 = Theme.Colors.Text,
			TextSize = Theme.TypographySizes.Body,
			Font = Theme.Typography.Body,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Toggle = Roact.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 60, 1, 0),
			Position = UDim2.new(1, -Theme.Spacing.M - 52, 0, 0),
		}, {
			Control = Roact.createElement(Toggle, {
				Enabled = props.Enabled,
				OnChanged = props.OnChanged,
			}),
		}),
	})
end

return ToggleRow
