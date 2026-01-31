--!strict

export type CharacterConfig = {
	CharacterReadyTimeoutSec: number,
	ResetStaminaOnSpawn: boolean,
	ResetSprintOnSpawn: boolean,
	ResetSprintOnDeath: boolean,
}

local CharacterConfig: CharacterConfig = {
	CharacterReadyTimeoutSec = 5,
	ResetStaminaOnSpawn = true,
	ResetSprintOnSpawn = true,
	ResetSprintOnDeath = true,
}

return CharacterConfig
