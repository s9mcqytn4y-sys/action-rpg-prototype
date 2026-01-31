local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

type Props = {
	Text: string,
	IconId: string?,
	IconText: string?,
	Active: boolean,
	LayoutOrder: number?,
	OnActivated: (() -> ())?,
	Ref: any?,
}

local SidebarNavItem = Roact.PureComponent:extend("SidebarNavItem")

function SidebarNavItem:render()
	local props = self.props :: Props
	return Roact.createElement("TextButton", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Theme.Colors.PanelAlt,
		BackgroundTransparency = if props.Active then 0.08 else 0.2,
		BorderSizePixel = 0,
		Text = "",
		Font = Theme.Typography.Body,
		LayoutOrder = props.LayoutOrder,
		AutoButtonColor = true,
		[Roact.Ref] = props.Ref,
		[Roact.Event.Activated] = function()
			if props.OnActivated then
				props.OnActivated()
			end
		end,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, Theme.Radius.S),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = Theme.Colors.Border,
			Transparency = if props.Active then 0.7 else 1,
			Thickness = 1,
		}),
		Icon = Roact.createElement("Frame", {
			BackgroundColor3 = Theme.Colors.PanelAlt,
			BackgroundTransparency = 0.06,
			Position = UDim2.new(0, Theme.Spacing.S, 0.5, -12),
			Size = UDim2.new(0, 24, 0, 24),
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = Theme.Colors.Border,
				Transparency = 0.85,
				Thickness = 1,
			}),
			Image = if props.IconId
				then Roact.createElement("ImageLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Image = props.IconId,
					ImageColor3 = if props.Active then Theme.Colors.Text else Theme.Colors.Muted,
				})
				else Roact.createElement("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Text = props.IconText or "*",
					TextColor3 = if props.Active then Theme.Colors.Text else Theme.Colors.Muted,
					TextSize = Theme.TypographySizes.Small,
					Font = Theme.Typography.Mono,
				}),
		}),
		Label = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, Theme.Spacing.L + 18, 0, 0),
			Size = UDim2.new(1, -(Theme.Spacing.L + 18), 1, 0),
			Text = props.Text,
			TextColor3 = if props.Active then Theme.Colors.Text else Theme.Colors.Muted,
			TextSize = Theme.TypographySizes.Body,
			Font = Theme.Typography.Body,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return SidebarNavItem



