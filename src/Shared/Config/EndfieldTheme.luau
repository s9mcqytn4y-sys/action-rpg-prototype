--!strict

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
	},
	Radius: {
		S: number,
		M: number,
		L: number,
	},
}

local EndfieldTheme: EndfieldTheme = {
	Colors = {
		Background = Color3.fromRGB(10, 12, 16),
		Panel = Color3.fromRGB(20, 24, 32),
		PanelAlt = Color3.fromRGB(26, 31, 42),
		Border = Color3.fromRGB(64, 74, 96),
		HeaderBar = Color3.fromRGB(18, 22, 30),
		Text = Color3.fromRGB(228, 234, 248),
		Muted = Color3.fromRGB(148, 162, 188),
		Accent = Color3.fromRGB(110, 175, 255),
		AccentSoft = Color3.fromRGB(46, 58, 78),
		Positive = Color3.fromRGB(92, 210, 150),
		Warning = Color3.fromRGB(255, 196, 90),
		Danger = Color3.fromRGB(255, 110, 110),
	},
	Transparency = {
		Panel = 0.04,
		PanelAlt = 0.06,
		HeaderBar = 0.02,
	},
	Typography = {
		Title = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
		Mono = Enum.Font.Code,
	},
	TypographySizes = {
		Title = 20,
		Subtitle = 14,
		Body = 13,
		Small = 11,
		Mono = 11,
	},
	Spacing = {
		XS = 6,
		S = 10,
		M = 14,
		L = 20,
		XL = 28,
	},
	Radius = {
		S = 6,
		M = 10,
		L = 14,
	},
}

return EndfieldTheme
