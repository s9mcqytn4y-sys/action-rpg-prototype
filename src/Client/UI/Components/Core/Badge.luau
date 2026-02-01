--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)
local UITypography = require(Shared:WaitForChild("UI"):WaitForChild("UITypography") :: ModuleScript)

export type Props = {
	Text: string,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
	BackgroundColor3: Color3?,
	BackgroundTransparency: number?,
	TextColor3: Color3?,
	TextSize: number?,
	Font: Enum.Font?,
	StrokeTransparency: number?,
	StrokeColor: Color3?,
	CornerRadius: number?,
}

local Badge = Roact.PureComponent:extend("Badge")

function Badge:render()
	local props = self.props :: Props
	return Roact.createElement("TextLabel", {
		BackgroundColor3 = props.BackgroundColor3 or UITheme.Colors.SurfaceAlt,
		BackgroundTransparency = props.BackgroundTransparency or 0.1,
		Size = props.Size or UDim2.new(0, 40, 0, 18),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		Text = props.Text,
		TextColor3 = props.TextColor3 or UITheme.Colors.Text,
		TextSize = props.TextSize or UITypography.Sizes.Caption,
		Font = props.Font or UITypography.Fonts.Mono,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, props.CornerRadius or UITheme.Radius.XS),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = props.StrokeColor or UITheme.Colors.Border,
			Transparency = if props.StrokeTransparency ~= nil then props.StrokeTransparency else 0.6,
			Thickness = 1,
		}),
	})
end

return Badge
