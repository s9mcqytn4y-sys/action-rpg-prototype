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
		Background = Color3.fromRGB(12, 14, 18),
		Panel = Color3.fromRGB(23, 26, 33),
		PanelAlt = Color3.fromRGB(30, 33, 41),
		Border = Color3.fromRGB(58, 63, 74),
		HeaderBar = Color3.fromRGB(20, 22, 28),
		Text = Color3.fromRGB(233, 236, 242),
		Muted = Color3.fromRGB(160, 166, 179),
		Accent = Color3.fromRGB(245, 176, 0),
		AccentSoft = Color3.fromRGB(54, 46, 24),
		Positive = Color3.fromRGB(110, 210, 150),
		Warning = Color3.fromRGB(245, 176, 0),
		Danger = Color3.fromRGB(255, 110, 110),
	},
	Transparency = {
		Panel = 0.0,
		PanelAlt = 0.04,
		HeaderBar = 0.0,
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
