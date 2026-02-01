--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

local Core = script.Parent.Parent:WaitForChild("Core") :: Folder
local Surface = require(Core:WaitForChild("Surface") :: ModuleScript)
local Text = require(Core:WaitForChild("Text") :: ModuleScript)

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
	return Roact.createElement(Surface, {
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundColor3 = Theme.Colors.PanelAlt,
		BackgroundTransparency = 0,
		CornerRadius = Theme.Radius.S,
		StrokeTransparency = 0.4,
		LayoutOrder = props.LayoutOrder,
		Children = {
			Label = Roact.createElement(Text, {
				Text = props.Label,
				Variant = "Body",
				Color = Theme.Colors.Text,
				Position = UDim2.new(0, Theme.Spacing.M, 0, 0),
				Size = UDim2.new(0.7, 0, 1, 0),
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
		},
	})
end

return ToggleRow
