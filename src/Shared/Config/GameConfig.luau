local GameConfig = {
	Profile = {
		StoreName = "ActionRPGProfile",
		KeyPrefix = "Player_",
	},
	Stamina = {
		Max = 100,
		RegenPerSecond = 5,
	},
	Sprint = {
		SpeedMultiplier = 1.6,
		DrainPerSecond = 12,
		MinStaminaToStart = 10,
		MinMoveThreshold = 0.15,
	},
}

return GameConfig
