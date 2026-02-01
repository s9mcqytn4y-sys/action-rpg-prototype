--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

local Core = script.Parent.Parent:WaitForChild("Core") :: Folder
local Surface = require(Core:WaitForChild("Surface") :: ModuleScript)
local Text = require(Core:WaitForChild("Text") :: ModuleScript)
local Badge = require(Core:WaitForChild("Badge") :: ModuleScript)

local Controls = script.Parent.Parent:WaitForChild("Controls") :: Folder
local Slider = require(Controls:WaitForChild("Slider") :: ModuleScript)

local SliderRow = Roact.PureComponent:extend("SliderRow")

type Props = {
	Label: string,
	Value: number,
	Range: { Min: number, Max: number },
	OnChanged: (number) -> (),
	LayoutOrder: number?,
}

local function formatValue(value: number): string
	local absValue = math.abs(value)
	if absValue < 0.01 then
		return string.format("%.4f", value)
	end
	if absValue < 1 then
		return string.format("%.3f", value)
	end
	return string.format("%.2f", value)
end

function SliderRow:render()
	local props = self.props :: Props
	return Roact.createElement(Surface, {
		Size = UDim2.new(1, 0, 0, 58),
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
				Position = UDim2.new(0, Theme.Spacing.M, 0, 6),
				Size = UDim2.new(0.62, 0, 0, 18),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Value = Roact.createElement(Badge, {
				Text = formatValue(props.Value),
				Position = UDim2.new(1, -Theme.Spacing.M, 0, 6),
				AnchorPoint = Vector2.new(1, 0),
				Size = UDim2.new(0, 62, 0, 18),
				TextColor3 = Theme.Colors.Accent,
				BackgroundColor3 = Theme.Colors.AccentSoft,
				BackgroundTransparency = 0.25,
			}),
			Slider = Roact.createElement("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, Theme.Spacing.M, 0, 30),
				Size = UDim2.new(1, -Theme.Spacing.M * 2, 0, 26),
			}, {
				Control = Roact.createElement(Slider, {
					Min = props.Range.Min,
					Max = props.Range.Max,
					Value = props.Value,
					OnChanged = props.OnChanged,
				}),
			}),
		},
	})
end

return SliderRow
