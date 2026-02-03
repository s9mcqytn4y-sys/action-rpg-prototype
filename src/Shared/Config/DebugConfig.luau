--!strict

export type DebugConfig = {
	EnableMetrics: boolean,
	LogModeChanges: boolean,
	LogCharacterBinding: boolean,
	LogWarnings: boolean,
	TagsEnabled: boolean,
	TagsLogFrequencySec: number,
	LifecycleEnabled: boolean,
	LifecycleLogFrequencySec: number,
}

local DebugConfig: DebugConfig = {
	EnableMetrics = true,
	LogModeChanges = false,
	LogCharacterBinding = false,
	LogWarnings = true,
	TagsEnabled = false,
	TagsLogFrequencySec = 10,
	LifecycleEnabled = false,
	LifecycleLogFrequencySec = 8,
}

return DebugConfig
