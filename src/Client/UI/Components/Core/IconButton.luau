--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)
local UITypography = require(Shared:WaitForChild("UI"):WaitForChild("UITypography") :: ModuleScript)
local Badge = require(script.Parent:WaitForChild("Badge") :: ModuleScript)

export type Props = {
	Image: string,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
	Disabled: boolean?,
	OnActivated: (() -> ())?,
	Label: string?,
	Shortcut: string?,
}

local IconButton = Roact.PureComponent:extend("IconButton")

function IconButton:render()
	local props = self.props :: Props
	local disabled = props.Disabled == true
	local shortcut = props.Shortcut
	local showShortcut = shortcut ~= nil and UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled

	return Roact.createElement("ImageButton", {
		BackgroundColor3 = UITheme.Colors.SurfaceAlt,
		BackgroundTransparency = 0.08,
		Size = props.Size or UDim2.fromOffset(32, 32),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		Image = props.Image,
		ImageColor3 = UITheme.Colors.Text,
		ImageTransparency = disabled and UITheme.Opacity.Disabled or 0,
		AutoButtonColor = not disabled,
		Selectable = not disabled,
		BorderSizePixel = 0,
		[Roact.Event.Activated] = function()
			if disabled then
				return
			end
			if props.OnActivated then
				props.OnActivated()
			end
		end,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, UITheme.Radius.S),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = UITheme.Colors.Border,
			Transparency = 0.6,
			Thickness = 1,
		}),
		Label = props.Label and Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = props.Label,
			TextColor3 = UITheme.Colors.Text,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}) or nil,
		Shortcut = showShortcut and Roact.createElement(Badge, {
			Text = shortcut :: string,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 6),
			Size = UDim2.new(0, math.clamp(14 + (#(shortcut :: string) * 6), 22, 52), 0, 16),
			ZIndex = (props.ZIndex or 1) + 1,
			BackgroundColor3 = UITheme.Colors.SurfaceAlt,
			BackgroundTransparency = 0.2,
			TextColor3 = UITheme.Colors.Text,
			TextSize = 10,
			Font = UITypography.Fonts.Mono,
			StrokeTransparency = 1,
			CornerRadius = UITheme.Radius.XS,
		}) or nil,
	})
end

return IconButton
