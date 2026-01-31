--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

type Props = {
	Title: string,
	Subtitle: string,
	ShortcutHint: string?,
	OnClose: () -> (),
	OnReset: () -> (),
}

local PanelHeader = Roact.PureComponent:extend("PanelHeader")

function PanelHeader:render()
	local props = self.props :: Props
	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		TopLine = Roact.createElement("Frame", {
			Position = UDim2.new(0, Theme.Spacing.L, 0, 12),
			Size = UDim2.new(1, -(Theme.Spacing.L * 2), 0, 1),
			BackgroundColor3 = Theme.Colors.Border,
			BackgroundTransparency = 0.65,
			BorderSizePixel = 0,
		}),

		Accent = Roact.createElement("Frame", {
			Position = UDim2.new(0, Theme.Spacing.L, 0, 10),
			Size = UDim2.new(0, 120, 0, 3),
			BackgroundColor3 = Theme.Colors.Accent,
			BorderSizePixel = 0,
		}),

		Left = Roact.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, Theme.Spacing.L, 0, 20),
			Size = UDim2.new(1, -Theme.Spacing.L * 2, 1, 0),
		}, {
			Title = Roact.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 4),
				Size = UDim2.new(1, 0, 0, 24),
				Text = props.Title,
				TextColor3 = Theme.Colors.Text,
				TextSize = Theme.TypographySizes.Title,
				Font = Theme.Typography.Title,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Subtitle = Roact.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 30),
				Size = UDim2.new(1, 0, 0, 18),
				Text = props.Subtitle,
				TextColor3 = Theme.Colors.Muted,
				TextSize = Theme.TypographySizes.Small,
				Font = Theme.Typography.Mono,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),
	})
end

return PanelHeader
