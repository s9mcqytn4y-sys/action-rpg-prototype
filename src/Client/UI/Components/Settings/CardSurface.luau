--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

local Core = script.Parent.Parent:WaitForChild("Core") :: Folder
local Surface = require(Core:WaitForChild("Surface") :: ModuleScript)

type Props = {
	AnchorPoint: Vector2?,
	Size: UDim2?,
	Position: UDim2?,
	LayoutOrder: number?,
	ZIndex: number?,
	Children: any?,
}

local CardSurface = Roact.PureComponent:extend("CardSurface")

function CardSurface:render()
	local props = self.props :: Props
	return Roact.createElement(Surface, {
		AnchorPoint = props.AnchorPoint,
		Size = props.Size or UDim2.new(1, 0, 0, 44),
		Position = props.Position,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = Theme.Transparency.Panel,
		CornerRadius = Theme.Radius.M,
		StrokeColor = Theme.Colors.Border,
		StrokeTransparency = 0.35,
		StrokeThickness = 1,
		Children = props.Children,
	})
end

return CardSurface
