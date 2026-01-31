--!strict

export type UITheme = {
	Colors: {
		Background: Color3,
		Panel: Color3,
		PanelAlt: Color3,
		Stroke: Color3,
		TextPrimary: Color3,
		TextSecondary: Color3,
		Accent: Color3,
		AccentSoft: Color3,
		Positive: Color3,
		Shadow: Color3,
	},
	Typography: {
		Title: Enum.Font,
		Body: Enum.Font,
		Mono: Enum.Font,
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

local UITheme: UITheme = {
	Colors = {
		Background = Color3.fromRGB(8, 10, 16),
		Panel = Color3.fromRGB(18, 20, 28),
		PanelAlt = Color3.fromRGB(26, 30, 42),
		Stroke = Color3.fromRGB(80, 92, 120),
		TextPrimary = Color3.fromRGB(232, 238, 255),
		TextSecondary = Color3.fromRGB(150, 170, 200),
		Accent = Color3.fromRGB(255, 196, 76),
		AccentSoft = Color3.fromRGB(62, 72, 96),
		Positive = Color3.fromRGB(88, 210, 140),
		Shadow = Color3.fromRGB(0, 0, 0),
	},
	Typography = {
		Title = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
		Mono = Enum.Font.Code,
	},
	Spacing = {
		XS = 6,
		S = 10,
		M = 14,
		L = 18,
		XL = 24,
	},
	Radius = {
		S = 6,
		M = 10,
		L = 14,
	},
}

return UITheme
