--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)
local UITypography = require(Shared:WaitForChild("UI"):WaitForChild("UITypography") :: ModuleScript)
local Badge = require(script.Parent:WaitForChild("Badge") :: ModuleScript)

export type ButtonVariant = "Primary" | "Secondary" | "Ghost" | "Danger"

export type Props = {
	Text: string,
	Variant: ButtonVariant?,
	Size: UDim2?,
	Position: UDim2?,	
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
	Disabled: boolean?,
	OnActivated: (() -> ())?,
	LeadingIcon: string?,
	Shortcut: string?,
}

local Button = Roact.PureComponent:extend("Button")

local function getColors(variant: ButtonVariant, disabled: boolean)
	if disabled then
		return {
			Background = UITheme.Colors.SurfaceAlt,
			BackgroundTransparency = 0.2,
			Text = UITheme.Colors.TextMuted,
			Stroke = UITheme.Colors.Border,
			StrokeTransparency = 0.7,
		}
	end

	if variant == "Primary" then
		return {
			Background = UITheme.Colors.Accent,
			BackgroundTransparency = 0,
			Text = UITheme.Colors.Background,
			Stroke = UITheme.Colors.Border,
			StrokeTransparency = 0.5,
		}
	elseif variant == "Danger" then
		return {
			Background = UITheme.Colors.Danger,
			BackgroundTransparency = 0,
			Text = UITheme.Colors.Background,
			Stroke = UITheme.Colors.Border,
			StrokeTransparency = 0.5,
		}
	elseif variant == "Ghost" then
		return {
			Background = UITheme.Colors.SurfaceAlt,
			BackgroundTransparency = 1,
			Text = UITheme.Colors.Text,
			Stroke = UITheme.Colors.Border,
			StrokeTransparency = 0.7,
		}
	end

	return {
		Background = UITheme.Colors.SurfaceAlt,
		BackgroundTransparency = 0.08,
		Text = UITheme.Colors.Text,
		Stroke = UITheme.Colors.Border,
		StrokeTransparency = 0.55,
	}
end

function Button:render()
	local props = self.props :: Props
	local variant = props.Variant or "Secondary"
	local disabled = props.Disabled == true
	local colors = getColors(variant, disabled)
	local shortcut = props.Shortcut
	local showShortcut = shortcut ~= nil and UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
	local badgeBackground = if variant == "Ghost" then UITheme.Colors.SurfaceAlt else colors.Background
	local badgeTransparency = if variant == "Ghost"
		then 0.2
		else math.clamp(colors.BackgroundTransparency + 0.15, 0, 0.35)
	local badgeText = if variant == "Primary" or variant == "Danger" then UITheme.Colors.Background else colors.Text

	return Roact.createElement("TextButton", {
		Size = props.Size or UDim2.new(0, 120, 0, 36),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		Text = props.Text,
		TextColor3 = colors.Text,
		TextSize = UITypography.Sizes.Body,
		Font = UITypography.Fonts.Emphasis,
		BackgroundColor3 = colors.Background,
		BackgroundTransparency = colors.BackgroundTransparency,
		BorderSizePixel = 0,
		AutoButtonColor = not disabled,
		Selectable = not disabled,
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
			Color = colors.Stroke,
			Transparency = colors.StrokeTransparency,
			Thickness = 1,
		}),
		Icon = props.LeadingIcon and Roact.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Image = props.LeadingIcon,
			Size = UDim2.fromOffset(14, 14),
			Position = UDim2.new(0, 10, 0.5, -7),
			ImageColor3 = colors.Text,
		}) or nil,
		Shortcut = showShortcut and Roact.createElement(Badge, {
			Text = shortcut :: string,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 6),
			Size = UDim2.new(0, math.clamp(14 + (#(shortcut :: string) * 6), 22, 60), 0, 16),
			ZIndex = (props.ZIndex or 1) + 1,
			BackgroundColor3 = badgeBackground,
			BackgroundTransparency = badgeTransparency,
			TextColor3 = badgeText,
			TextSize = 10,
			Font = UITypography.Fonts.Mono,
			StrokeTransparency = 1,
			CornerRadius = UITheme.Radius.XS,
		}) or nil,
	})
end

return Button
