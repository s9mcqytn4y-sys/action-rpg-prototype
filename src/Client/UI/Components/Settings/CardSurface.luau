local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

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
	return Roact.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		Size = props.Size or UDim2.new(1, 0, 0, 44),
		Position = props.Position,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = Theme.Transparency.Panel,
		BorderSizePixel = 0,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, Theme.Radius.M),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = Theme.Colors.Border,
			Transparency = 0.55,
			Thickness = 1,
		}),
		Gradient = Roact.createElement("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.95),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
		Children = Roact.createFragment(props.Children),
	})
end

return CardSurface
