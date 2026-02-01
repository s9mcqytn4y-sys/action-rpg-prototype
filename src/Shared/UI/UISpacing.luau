--!strict

export type UISpacing = {
	Scale: {
		XXS: number,
		XS: number,
		S: number,
		M: number,
		L: number,
		XL: number,
	},
	Inset: {
		Card: number,
		Panel: number,
		Page: number,
	},
	Gap: {
		Tight: number,
		Regular: number,
		Loose: number,
	},
}

local UISpacing: UISpacing = {
	Scale = {
		XXS = 4,
		XS = 8,
		S = 12,
		M = 16,
		L = 24,
		XL = 32,
	},
	Inset = {
		Card = 16,
		Panel = 20,
		Page = 24,
	},
	Gap = {
		Tight = 8,
		Regular = 12,
		Loose = 16,
	},
}

return UISpacing
