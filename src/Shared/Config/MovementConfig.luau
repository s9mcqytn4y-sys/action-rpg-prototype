--!strict

export type MovementConfig = {
	MoveDeadzone: number,

	-- Root turning (1/s, dt-stable)
	TurnSmoothingSpeed: number,

	-- AutoRotate is applied to Humanoid. When false, this module drives root rotation.
	AutoRotate: boolean,

	-- Allow turning in air
	AllowAirTurn: boolean,
	AirTurnMultiplier: number,
}

local MovementConfig: MovementConfig = {
	MoveDeadzone = 0.05,

	TurnSmoothingSpeed = 14.0,

	AutoRotate = false,

	AllowAirTurn = false,
	AirTurnMultiplier = 0.5,
}

return MovementConfig
