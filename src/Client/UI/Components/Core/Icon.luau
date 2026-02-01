--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)

export type Props = {
	Image: string,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
	Color: Color3?,
	Transparency: number?,
}

local Icon = Roact.PureComponent:extend("Icon")

function Icon:render()
	local props = self.props :: Props
	return Roact.createElement("ImageLabel", {
		BackgroundTransparency = 1,
		Image = props.Image,
		Size = props.Size or UDim2.fromOffset(18, 18),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		ImageColor3 = props.Color or UITheme.Colors.Text,
		ImageTransparency = props.Transparency or 0,
	})
end

return Icon
