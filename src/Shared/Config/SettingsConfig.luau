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
		AimSensitivity: Range,
		TouchSensitivity: Range,
		AimTouchSensitivity: Range,
	},
	Visual: {
		MotionBlur: Range,
	},
}

local SettingsConfig: SettingsConfig = {
	Camera = {
		Distance = { Min = 4, Max = 11, Step = 0.5 },
		Sensitivity = { Min = 0.002, Max = 0.008, Step = 0.0005 },
		AimSensitivity = { Min = 0.0015, Max = 0.006, Step = 0.0005 },
		TouchSensitivity = { Min = 0.003, Max = 0.012, Step = 0.0005 },
		AimTouchSensitivity = { Min = 0.0025, Max = 0.009, Step = 0.0005 },
	},
	Visual = {
		MotionBlur = { Min = 0, Max = 24, Step = 1 },
	},
}

return SettingsConfig
