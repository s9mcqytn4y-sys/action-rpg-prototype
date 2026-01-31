--!strict

export type DebugConfig = {
	EnableMetrics: boolean,
	LogModeChanges: boolean,
	LogCharacterBinding: boolean,
	LogWarnings: boolean,
	TagsEnabled: boolean,
	TagsLogFrequencySec: number,
}

local DebugConfig: DebugConfig = {
	EnableMetrics = true,
	LogModeChanges = false,
	LogCharacterBinding = false,
	LogWarnings = true,
	TagsEnabled = true,
	TagsLogFrequencySec = 10,
}

return DebugConfig
