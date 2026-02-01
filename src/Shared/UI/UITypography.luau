--!strict

export type UITypography = {
	Fonts: {
		Display: Enum.Font,
		Heading: Enum.Font,
		Body: Enum.Font,
		Emphasis: Enum.Font,
		Mono: Enum.Font,
	},
	Sizes: {
		H1: number,
		H2: number,
		H3: number,
		Body: number,
		BodySmall: number,
		Caption: number,
		Mono: number,
	},
}

local UITypography: UITypography = {
	Fonts = {
		Display = Enum.Font.GothamBlack,
		Heading = Enum.Font.GothamBold,
		Body = Enum.Font.GothamMedium,
		Emphasis = Enum.Font.GothamSemibold,
		Mono = Enum.Font.Code,
	},
	Sizes = {
		H1 = 28,
		H2 = 22,
		H3 = 18,
		Body = 14,
		BodySmall = 12,
		Caption = 11,
		Mono = 12,
	},
}

return UITypography
