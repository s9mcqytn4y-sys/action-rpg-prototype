--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)
local UITypography = require(Shared:WaitForChild("UI"):WaitForChild("UITypography") :: ModuleScript)

export type TextVariant = "H1" | "H2" | "H3" | "Body" | "BodySmall" | "Caption" | "Mono"

export type Props = {
	Text: string,
	Variant: TextVariant?,
	Color: Color3?,
	Transparency: number?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	LayoutOrder: number?,
	ZIndex: number?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
	TextWrapped: boolean?,
	TextTruncate: Enum.TextTruncate?,
}

local Text = Roact.PureComponent:extend("Text")

local function resolveFont(variant: TextVariant?): Enum.Font
	if variant == "H1" then
		return UITypography.Fonts.Display
	elseif variant == "H2" or variant == "H3" then
		return UITypography.Fonts.Heading
	elseif variant == "Mono" then
		return UITypography.Fonts.Mono
	end
	return UITypography.Fonts.Body
end

local function resolveSize(variant: TextVariant?): number
	if variant == "H1" then
		return UITypography.Sizes.H1
	elseif variant == "H2" then
		return UITypography.Sizes.H2
	elseif variant == "H3" then
		return UITypography.Sizes.H3
	elseif variant == "BodySmall" then
		return UITypography.Sizes.BodySmall
	elseif variant == "Caption" then
		return UITypography.Sizes.Caption
	elseif variant == "Mono" then
		return UITypography.Sizes.Mono
	end
	return UITypography.Sizes.Body
end

function Text:render()
	local props = self.props :: Props
	local variant = props.Variant

	return Roact.createElement("TextLabel", {
		BackgroundTransparency = 1,
		Size = props.Size or UDim2.new(1, 0, 0, resolveSize(variant) + 6),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		Text = props.Text,
		TextColor3 = props.Color or UITheme.Colors.Text,
		TextTransparency = props.Transparency or 0,
		TextSize = resolveSize(variant),
		Font = resolveFont(variant),
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left,
		TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
		TextWrapped = props.TextWrapped ~= false,
		TextTruncate = props.TextTruncate,
	})
end

return Text
