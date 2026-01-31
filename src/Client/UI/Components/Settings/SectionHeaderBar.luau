--!strict

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
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
	}, {
		Line = Roact.createElement("Frame", {
			Position = UDim2.new(0, Theme.Spacing.S, 0.5, 0),
			Size = UDim2.new(1, -Theme.Spacing.S * 2, 0, 1),
			BackgroundColor3 = Theme.Colors.Border,
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
		}),
		Accent = Roact.createElement("Frame", {
			Position = UDim2.new(0, Theme.Spacing.S, 0.5, -1),
			Size = UDim2.new(0, 40, 0, 2),
			BackgroundColor3 = Theme.Colors.Accent,
			BorderSizePixel = 0,
		}),
		Label = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, Theme.Spacing.S + 48, 0, 0),
			Size = UDim2.new(1, -Theme.Spacing.S * 2, 1, 0),
			Text = props.Text,
			TextColor3 = Theme.Colors.Text,
			TextSize = Theme.TypographySizes.Subtitle,
			Font = Theme.Typography.Body,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return SectionHeaderBar
