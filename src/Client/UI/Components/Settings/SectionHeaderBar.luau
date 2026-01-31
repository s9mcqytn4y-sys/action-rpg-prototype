local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

type Props = {
	Text: string,
	LayoutOrder: number?,
}

local SectionHeaderBar = Roact.PureComponent:extend("SectionHeaderBar")

function SectionHeaderBar:render()
	local props = self.props :: Props
	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Theme.Colors.HeaderBar,
		BackgroundTransparency = Theme.Transparency.HeaderBar,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, Theme.Radius.S),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = Theme.Colors.Border,
			Transparency = 0.5,
			Thickness = 1,
		}),
		Label = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, Theme.Spacing.S, 0, 0),
			Size = UDim2.new(1, -Theme.Spacing.S * 2, 1, 0),
			Text = props.Text,
			TextColor3 = Theme.Colors.Text,
			TextSize = Theme.TypographySizes.Subtitle,
			Font = Theme.Typography.Title,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return SectionHeaderBar
