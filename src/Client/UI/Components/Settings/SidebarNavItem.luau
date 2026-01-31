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
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Theme.Colors.PanelAlt,
		BackgroundTransparency = if props.Active then 0.08 else 1,
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
		Neon = Roact.createElement("Frame", {
			Position = UDim2.new(0, 0, 0.5, -10),
			Size = UDim2.new(0, 10, 0, 20),
			BackgroundColor3 = Theme.Colors.Accent,
			BackgroundTransparency = if props.Active then 0.75 else 1,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 3),
			}),
			Glow = Roact.createElement("UIStroke", {
				Color = Theme.Colors.Accent,
				Transparency = if props.Active then 0.6 else 1,
				Thickness = 2,
			}),
		}),
		Accent = Roact.createElement("Frame", {
			Position = UDim2.new(0, 0, 0.5, -8),
			Size = UDim2.new(0, 2, 0, 16),
			BackgroundColor3 = Theme.Colors.Accent,
			BackgroundTransparency = if props.Active then 0 else 1,
			BorderSizePixel = 0,
		}),
		Label = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, Theme.Spacing.L, 0, 0),
			Size = UDim2.new(1, -Theme.Spacing.L, 1, 0),
			Text = props.Text,
			TextColor3 = if props.Active then Theme.Colors.Text else Theme.Colors.Muted,
			TextSize = Theme.TypographySizes.Body,
			Font = Theme.Typography.Body,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return SidebarNavItem



