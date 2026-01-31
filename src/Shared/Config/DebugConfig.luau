--!strict

export type DebugConfig = {
	EnableMetrics: boolean,
	LogModeChanges: boolean,
	LogCharacterBinding: boolean,
	LogWarnings: boolean,
}

local DebugConfig: DebugConfig = {
	EnableMetrics = true,
	LogModeChanges = false,
	LogCharacterBinding = false,
	LogWarnings = true,
}

return DebugConfig
