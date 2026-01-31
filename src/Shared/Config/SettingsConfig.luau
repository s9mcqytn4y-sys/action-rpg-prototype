--!strict

export type Range = {
	Min: number,
	Max: number,
	Step: number,
}

export type SettingsConfig = {
	Camera: {
		Distance: Range,
		Sensitivity: Range,
		TouchSensitivity: Range,
	},
	Visual: {
		MotionBlur: Range,
	},
}

local SettingsConfig: SettingsConfig = {
	Camera = {
		Distance = { Min = 4, Max = 11, Step = 0.5 },
		Sensitivity = { Min = 0.0015, Max = 0.008, Step = 0.0005 },
		TouchSensitivity = { Min = 0.003, Max = 0.012, Step = 0.0005 },
	},
	Visual = {
		MotionBlur = { Min = 0, Max = 24, Step = 1 },
	},
}

return SettingsConfig
