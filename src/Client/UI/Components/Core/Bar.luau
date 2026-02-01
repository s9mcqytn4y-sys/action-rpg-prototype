--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)

export type Props = {
	Value: number,
	Max: number?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
	FillColor: Color3?,
	TrackColor: Color3?,
	TrackTransparency: number?,
	FillTransparency: number?,
	CornerRadius: number?,
}

local Bar = Roact.PureComponent:extend("Bar")

local function clamp01(x: number): number
	return math.clamp(x, 0, 1)
end

function Bar:render()
	local props = self.props :: Props
	local maxValue = props.Max or 1
	local ratio = 0
	if maxValue > 0 then
		ratio = clamp01(props.Value / maxValue)
	end

	local radius = props.CornerRadius or UITheme.Radius.S
	local trackTransparency = if props.TrackTransparency ~= nil then props.TrackTransparency else 0.2
	local fillTransparency = if props.FillTransparency ~= nil then props.FillTransparency else 0

	return Roact.createElement("Frame", {
		BackgroundColor3 = props.TrackColor or UITheme.Colors.SurfaceAlt,
		BackgroundTransparency = trackTransparency,
		Size = props.Size or UDim2.new(1, 0, 0, 6),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		BorderSizePixel = 0,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, radius),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = UITheme.Colors.Border,
			Transparency = 0.6,
			Thickness = 1,
		}),
		Fill = Roact.createElement("Frame", {
			BackgroundColor3 = props.FillColor or UITheme.Colors.Accent,
			BackgroundTransparency = fillTransparency,
			Size = UDim2.new(ratio, 0, 1, 0),
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, radius),
			}),
		}),
	})
end

return Bar
