local GameConfig = {
	Profile = {
		StoreName = "ActionRPGProfile",
		KeyPrefix = "Player_",
	},
	Stamina = {
		Max = 100,
		RegenRate = 18,
		RegenDelay = 0.8,
		ExhaustedDuration = 0.6,
		MinRegenDelta = 0.05,
		AttributeUpdateInterval = 0.1,
		ProfileUpdateInterval = 4.0,
		Actions = {
			DodgeCost = 30,
			HeavyCost = 20,
		},
		Modifiers = {
			MaxBonus = 0,
			RegenRateBonus = 0,
			DrainMultiplier = 1,
			RegenDelayBonus = 0,
		},
		Input = {
			SprintHoldKey = Enum.KeyCode.LeftShift,
			SprintToggleKey = Enum.KeyCode.LeftControl,
			DodgeKey = Enum.KeyCode.Q,
			HeavyKey = Enum.KeyCode.F,
			GamepadSprint = Enum.KeyCode.ButtonL3,
			GamepadDodge = Enum.KeyCode.ButtonB,
			GamepadHeavy = Enum.KeyCode.ButtonX,
		},
	},
	Sprint = {
		SpeedMultiplier = 1.6,
		DrainPerSecond = 12,
		MinStaminaToStart = 10,
		MinMoveThreshold = 0.15,
		SpeedBlendSpeed = 10,
	},
}

return GameConfig
