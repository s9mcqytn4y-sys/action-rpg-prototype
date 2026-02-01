--!strict

local UI = script.Parent.Parent:WaitForChild("UI") :: Folder
local UITheme = require(UI:WaitForChild("UITheme") :: ModuleScript)
local UISpacing = require(UI:WaitForChild("UISpacing") :: ModuleScript)
local UITypography = require(UI:WaitForChild("UITypography") :: ModuleScript)

export type EndfieldTheme = {
	Colors: {
		Background: Color3,
		Panel: Color3,
		PanelAlt: Color3,
		Border: Color3,
		HeaderBar: Color3,
		Text: Color3,
		Muted: Color3,
		Accent: Color3,
		AccentSoft: Color3,
		Positive: Color3,
		Warning: Color3,
		Danger: Color3,
	},
	Transparency: {
		Panel: number,
		PanelAlt: number,
		HeaderBar: number,
	},
	Typography: {
		Title: Enum.Font,
		Body: Enum.Font,
		Mono: Enum.Font,
	},
	TypographySizes: {
		Title: number,
		Subtitle: number,
		Body: number,
		Small: number,
		Mono: number,
	},
	Spacing: {
		XS: number,
		S: number,
		M: number,
		L: number,
		XL: number,
		XXL: number,
	},
	Radius: {
		S: number,
		M: number,
		L: number,
	},
}

local EndfieldTheme: EndfieldTheme = {
	Colors = {
		Background = UITheme.Colors.Background,
		Panel = UITheme.Colors.Surface,
		PanelAlt = UITheme.Colors.SurfaceAlt,
		Border = UITheme.Colors.Border,
		HeaderBar = UITheme.Colors.Header,
		Text = UITheme.Colors.Text,
		Muted = UITheme.Colors.TextMuted,
		Accent = UITheme.Colors.Accent,
		AccentSoft = UITheme.Colors.AccentSoft,
		Positive = UITheme.Colors.Success,
		Warning = UITheme.Colors.Warning,
		Danger = UITheme.Colors.Danger,
	},
	Transparency = {
		Panel = UITheme.Opacity.Surface,
		PanelAlt = UITheme.Opacity.SurfaceAlt,
		HeaderBar = UITheme.Opacity.Header,
	},
	Typography = {
		Title = UITypography.Fonts.Heading,
		Body = UITypography.Fonts.Body,
		Mono = UITypography.Fonts.Mono,
	},
	TypographySizes = {
		Title = UITypography.Sizes.H2,
		Subtitle = UITypography.Sizes.H3,
		Body = UITypography.Sizes.Body,
		Small = UITypography.Sizes.BodySmall,
		Mono = UITypography.Sizes.Mono,
	},
	Spacing = {
		XS = UISpacing.Scale.XXS,
		S = UISpacing.Scale.XS,
		M = UISpacing.Scale.S,
		L = UISpacing.Scale.M,
		XL = UISpacing.Scale.L,
		XXL = UISpacing.Scale.XL,
	},
	Radius = {
		S = UITheme.Radius.S,
		M = UITheme.Radius.M,
		L = UITheme.Radius.L,
	},
}

return EndfieldTheme
