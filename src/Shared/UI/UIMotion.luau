--!strict

export type DurationKey = "Instant" | "Fast" | "Normal" | "Slow" | "Slower"
export type EasingKey = "Standard" | "Decel" | "Accel" | "Overshoot" | "Linear"

export type EasingDef = {
	Style: Enum.EasingStyle,
	Direction: Enum.EasingDirection,
}

export type UIMotion = {
	Duration: { [DurationKey]: number },
	Easing: { [EasingKey]: EasingDef },
	tweenInfo: (durationKey: DurationKey, easingKey: EasingKey, delayTime: number?) -> TweenInfo,
}

local durationMap: { [DurationKey]: number } = {
	Instant = 0.05,
	Fast = 0.12,
	Normal = 0.2,
	Slow = 0.32,
	Slower = 0.45,
}

local easingMap: { [EasingKey]: EasingDef } = {
	Standard = { Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.Out },
	Decel = { Style = Enum.EasingStyle.Quint, Direction = Enum.EasingDirection.Out },
	Accel = { Style = Enum.EasingStyle.Quad, Direction = Enum.EasingDirection.In },
	Overshoot = { Style = Enum.EasingStyle.Back, Direction = Enum.EasingDirection.Out },
	Linear = { Style = Enum.EasingStyle.Linear, Direction = Enum.EasingDirection.Out },
}

local function tweenInfo(durationKey: DurationKey, easingKey: EasingKey, delayTime: number?)
	local duration = durationMap[durationKey]
	local easing = easingMap[easingKey]
	return TweenInfo.new(duration, easing.Style, easing.Direction, 0, false, delayTime or 0)
end

local UIMotion: UIMotion = {
	Duration = durationMap,
	Easing = easingMap,
	tweenInfo = tweenInfo,
}

return UIMotion
