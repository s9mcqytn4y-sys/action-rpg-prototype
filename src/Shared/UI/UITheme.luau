--!strict

export type UITheme = {
	Colors: {
		Background: Color3,
		Surface: Color3,
		SurfaceAlt: Color3,
		SurfaceRaised: Color3,
		Border: Color3,
		Divider: Color3,
		Header: Color3,
		Text: Color3,
		TextMuted: Color3,
		Accent: Color3,
		AccentSoft: Color3,
		AccentSecondary: Color3,
		Success: Color3,
		Warning: Color3,
		Danger: Color3,
		Info: Color3,
		Focus: Color3,
	},
	Opacity: {
		Surface: number,
		SurfaceAlt: number,
		Header: number,
		Overlay: number,
		Disabled: number,
		Subtle: number,
	},
	Radius: {
		XS: number,
		S: number,
		M: number,
		L: number,
		XL: number,
	},
	Shadow: {
		Soft: {
			Color: Color3,
			Transparency: number,
			Offset: Vector2,
			Blur: number,
		},
	},
}

local UITheme: UITheme = {
	Colors = {
		Background = Color3.fromRGB(10, 12, 16),
		Surface = Color3.fromRGB(18, 22, 29),
		SurfaceAlt = Color3.fromRGB(24, 29, 38),
		SurfaceRaised = Color3.fromRGB(30, 36, 47),
		Border = Color3.fromRGB(46, 54, 68),
		Divider = Color3.fromRGB(36, 42, 54),
		Header = Color3.fromRGB(20, 24, 32),
		Text = Color3.fromRGB(231, 236, 242),
		TextMuted = Color3.fromRGB(166, 176, 190),
		Accent = Color3.fromRGB(72, 180, 255),
		AccentSoft = Color3.fromRGB(19, 46, 68),
		AccentSecondary = Color3.fromRGB(245, 176, 0),
		Success = Color3.fromRGB(107, 214, 154),
		Warning = Color3.fromRGB(245, 176, 0),
		Danger = Color3.fromRGB(255, 110, 110),
		Info = Color3.fromRGB(90, 174, 255),
		Focus = Color3.fromRGB(120, 198, 255),
	},
	Opacity = {
		Surface = 0,
		SurfaceAlt = 0.04,
		Header = 0,
		Overlay = 0.35,
		Disabled = 0.55,
		Subtle = 0.2,
	},
	Radius = {
		XS = 4,
		S = 6,
		M = 10,
		L = 14,
		XL = 18,
	},
	Shadow = {
		Soft = {
			Color = Color3.fromRGB(0, 0, 0),
			Transparency = 0.75,
			Offset = Vector2.new(0, 4),
			Blur = 10,
		},
	},
}

return UITheme
