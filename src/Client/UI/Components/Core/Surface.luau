--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)

export type Props = {
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
	BackgroundColor3: Color3?,
	BackgroundTransparency: number?,
	CornerRadius: number?,
	StrokeColor: Color3?,
	StrokeTransparency: number?,
	StrokeThickness: number?,
	Children: any?,
}

local Surface = Roact.PureComponent:extend("Surface")

function Surface:render()
	local props = self.props :: Props
	local radius = props.CornerRadius or UITheme.Radius.M

	return Roact.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		Position = props.Position,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		BackgroundColor3 = props.BackgroundColor3 or UITheme.Colors.Surface,
		BackgroundTransparency = if props.BackgroundTransparency ~= nil then props.BackgroundTransparency else UITheme.Opacity.Surface,
		BorderSizePixel = 0,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, radius),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = props.StrokeColor or UITheme.Colors.Border,
			Transparency = if props.StrokeTransparency ~= nil then props.StrokeTransparency else 0.35,
			Thickness = props.StrokeThickness or 1,
		}),
		Children = Roact.createFragment(props.Children),
	})
end

return Surface
