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
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = Theme.Colors.HeaderBar,
		BackgroundTransparency = Theme.Transparency.HeaderBar,
		BorderSizePixel = 0,
	}, {
		Line = Roact.createElement("Frame", {
			Position = UDim2.new(0, Theme.Spacing.M, 1, -1),
			Size = UDim2.new(1, -(Theme.Spacing.M * 2), 0, 1),
			BackgroundColor3 = Theme.Colors.Border,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
		}),
		Left = Roact.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, Theme.Spacing.L, 0, 0),
			Size = UDim2.new(1, -260, 1, 0),
		}, {
			Title = Roact.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 8),
				Size = UDim2.new(1, 0, 0, 24),
				Text = props.Title,
				TextColor3 = Theme.Colors.Text,
				TextSize = Theme.TypographySizes.Title,
				Font = Theme.Typography.Title,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Subtitle = Roact.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 34),
				Size = UDim2.new(1, 0, 0, 18),
				Text = props.Subtitle,
				TextColor3 = Theme.Colors.Muted,
				TextSize = Theme.TypographySizes.Small,
				Font = Theme.Typography.Mono,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),
		Right = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -Theme.Spacing.L, 0.5, 0),
			Size = UDim2.new(0, 240, 0, 32),
			BackgroundTransparency = 1,
		}, {
			Layout = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, Theme.Spacing.XS),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Shortcut = Roact.createElement("TextLabel", {
				BackgroundColor3 = Theme.Colors.PanelAlt,
				BackgroundTransparency = 0.1,
				Size = UDim2.new(0, 86, 0, 24),
				Text = props.ShortcutHint or "",
				TextColor3 = Theme.Colors.Muted,
				TextSize = Theme.TypographySizes.Mono,
				Font = Theme.Typography.Mono,
				TextXAlignment = Enum.TextXAlignment.Center,
				LayoutOrder = 1,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, Theme.Radius.S),
				}),
				Stroke = Roact.createElement("UIStroke", {
					Color = Theme.Colors.Border,
					Transparency = 0.7,
					Thickness = 1,
				}),
			}),
			Reset = Roact.createElement("TextButton", {
				Size = UDim2.new(0, 72, 0, 24),
				Text = "Reset",
				TextColor3 = Theme.Colors.Text,
				BackgroundColor3 = Theme.Colors.PanelAlt,
				BackgroundTransparency = 0.06,
				AutoButtonColor = true,
				Font = Theme.Typography.Body,
				TextSize = Theme.TypographySizes.Small,
				LayoutOrder = 2,
				[Roact.Event.Activated] = props.OnReset,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, Theme.Radius.S),
				}),
				Stroke = Roact.createElement("UIStroke", {
					Color = Theme.Colors.Border,
					Transparency = 0.6,
					Thickness = 1,
				}),
			}),
			Close = Roact.createElement("TextButton", {
				Size = UDim2.new(0, 28, 0, 24),
				Text = "X",
				TextColor3 = Theme.Colors.Text,
				TextSize = Theme.TypographySizes.Small,
				Font = Theme.Typography.Title,
				BackgroundColor3 = Theme.Colors.PanelAlt,
				BackgroundTransparency = 0.04,
				AutoButtonColor = true,
				LayoutOrder = 3,
				[Roact.Event.Activated] = props.OnClose,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, Theme.Radius.S),
				}),
				Stroke = Roact.createElement("UIStroke", {
					Color = Theme.Colors.Border,
					Transparency = 0.6,
					Thickness = 1,
				}),
			}),
		}),
	})
end

return PanelHeader
