local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

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
	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = Theme.Transparency.Panel,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, Theme.Radius.S),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = Theme.Colors.Border,
			Transparency = 0.45,
			Thickness = 1,
		}),
		Label = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, Theme.Spacing.M, 0, 6),
			Size = UDim2.new(0.62, 0, 0, 18),
			Text = props.Label,
			TextColor3 = Theme.Colors.Text,
			TextSize = Theme.TypographySizes.Body,
			Font = Theme.Typography.Body,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Value = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.7, 0, 0, 6),
			Size = UDim2.new(0.3, -Theme.Spacing.M, 0, 18),
			Text = formatValue(props.Value),
			TextColor3 = Theme.Colors.Muted,
			TextSize = Theme.TypographySizes.Mono,
			Font = Theme.Typography.Mono,
			TextXAlignment = Enum.TextXAlignment.Right,
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
	})
end

return SliderRow
