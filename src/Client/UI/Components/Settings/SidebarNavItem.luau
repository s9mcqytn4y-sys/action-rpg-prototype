--!strict

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
	Compact: boolean?,
	Size: UDim2?,
}

local SidebarNavItem = Roact.PureComponent:extend("SidebarNavItem")

function SidebarNavItem:render()
	local props = self.props :: Props
	local compact = props.Compact == true

	return Roact.createElement("TextButton", {
		Size = props.Size or UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Theme.Colors.PanelAlt,
		BackgroundTransparency = if props.Active then 0.06 else 1,
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
		ActiveBg = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Theme.Colors.AccentSoft,
			BackgroundTransparency = if props.Active then 0.65 else 1,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, Theme.Radius.S),
			}),
		}),
		Accent = Roact.createElement("Frame", {
			Position = UDim2.new(0, 0, 0.5, -9),
			Size = UDim2.new(0, 3, 0, 18),
			BackgroundColor3 = Theme.Colors.Accent,
			BackgroundTransparency = if props.Active then 0 else 1,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}),
		}),
		Label = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = if compact then UDim2.new(0, 0, 0, 0) else UDim2.new(0, Theme.Spacing.L + 20, 0, 0),
			Size = if compact then UDim2.new(1, 0, 1, 0) else UDim2.new(1, -(Theme.Spacing.L + 20), 1, 0),
			Text = props.Text,
			TextColor3 = if props.Active then Theme.Colors.Text else Theme.Colors.Muted,
			TextSize = if compact then Theme.TypographySizes.Small else Theme.TypographySizes.Body,
			Font = Theme.Typography.Body,
			TextXAlignment = if compact then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
		}),
		IconText = (not compact and props.IconText) and Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 8, 0.5, -7),
			Size = UDim2.new(0, 24, 0, 14),
			Text = props.IconText,
			TextColor3 = if props.Active then Theme.Colors.Accent else Theme.Colors.Muted,
			TextSize = Theme.TypographySizes.Small,
			Font = Theme.Typography.Mono,
			TextXAlignment = Enum.TextXAlignment.Center,
		}) or nil,
	})
end

return SidebarNavItem



