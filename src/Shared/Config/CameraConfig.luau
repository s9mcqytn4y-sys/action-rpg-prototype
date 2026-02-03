--!strict
-- AAA-comfort Third-Person Camera (NO AIM SYSTEM)
-- All *Speed values are in 1/seconds and applied with dt-stable exponential smoothing.

local CameraConfig = {
	-- Distance
	Distance = 8.5,
	MinDistance = 3.0,
	MaxDistance = 14.0,

	-- FOV
	Fov = 70,
	MinFov = 60,
	MaxFov = 80,
	FovSmoothingSpeed = 8.0,

	-- Zoom
	ZoomStep = 1.0,        -- studs per mouse wheel notch
	PinchZoomSpeed = 10.0, -- pinch response
	GamepadZoomSpeed = 8.0, -- studs per second (triggers)

	-- Offsets
	-- ShoulderOffset is in camera basis (right/up/back).
	-- Z positive = behind the focus (Roblox forward = -Z).
	ShoulderOffset = Vector3.new(1.45, 0.0, 0.0),
	FocusOffset = Vector3.new(0.0, 2.0, 0.0),
	ShoulderSide = 1, -- 1 = right, -1 = left
	ShoulderSwapSpeed = 12.0,
	ShoulderCollisionEnabled = true,
	ShoulderCollisionBuffer = 0.25,
	ShoulderCollisionSmoothingSpeed = 16.0,

	-- Pitch
	DefaultPitch = math.rad(-10),
	PitchMin = math.rad(-70),
	PitchMax = math.rad(25),

	-- Smoothing (dt-stable)
	RotationSmoothingSpeed = 10.5, -- smoother but still responsive
	CFrameSmoothingSpeed = 15.0,
	DistanceSmoothingSpeed = 12.5,
	DistanceCollisionSmoothingSpeed = 20.0,
	FocusSmoothingSpeed = 16.0,
	MoveDirectionSmoothingSpeed = 8.5,

	-- Auto alignment (comfort tuned)
	AutoAlignMoveThreshold = 0.35,
	AutoAlignMoveStopThreshold = 0.12,
	AutoAlignSpeed = 1.35,     -- snappier but still soft
	AutoAlignIdleSpeed = 0.7, -- gentle recenter
	AutoAlignMaxYawRateDeg = 40, -- safety cap (deg/sec)

	-- Backward movement handling:
	-- If moving opposite to character forward (dot < threshold), DON'T align to movement.
	BackwardDotThreshold = 0.1,
	-- If movement is opposite camera forward, suppress auto-align to avoid spin.
	BackwardCameraDotThreshold = 0.15,

	-- Collision
	CollisionBuffer = 0.25,

	-- Input clamp (prevents spikes)
	MaxMouseDelta = 24,
	MaxTouchDelta = 60,

	-- Input deadzone (fix micro-jitter)
	MouseDeadzone = 0.5, -- px (ignore tiny deltas)
	TouchDeadzone = 1.2,  -- px
	TouchInputSmoothingSpeed = 18.0, -- higher = faster response
	TouchInputGrace = 0.1,
	MouseInputSmoothingSpeed = 19.5,
	MouseInputGrace = 0.09,
	ManualInputGrace = 0.6, -- seconds to suppress auto-align after manual input

	-- Sensitivity
	Sensitivity = 0.0022,
	TouchSensitivity = 0.0035,
	GamepadSensitivity = 2.8, -- radians/sec at full deflection
	GamepadDeadzone = 0.12,
	GamepadResponseExponent = 1.4,

	-- Mouse behavior while gameplay camera is active (cursor hidden).
	-- LockCurrentPosition keeps cursor stable and prevents edge clamping issues.
	GameplayMouseBehavior = Enum.MouseBehavior.LockCurrentPosition,
	MouseSensitivityMultiplier = 1.0,

	-- Shoulder swap (optional)
	ShoulderSwapKey = Enum.KeyCode.Q,
	ShoulderSwapGamepadButton = Enum.KeyCode.ButtonL1,

	-- Auto align toggle
	AutoAlignEnabled = true,

	-- Interaction focus hint (subtle nudge toward interactable)
	InteractionFocusEnabled = true,
	InteractionFocusWeight = 0.1,
	InteractionFocusMaxOffset = 0.8,
	InteractionFocusSmoothingSpeed = 10.0,
	InteractionFocusDeadzone = 1.5,

	-- Motion blur (camera-based)
	MotionBlur = {
		Enabled = true,
		MinSize = 0,
		MaxSize = 20,
		LinearVelocityScale = 0.018, -- studs/sec -> blur size
		RotVelocityScale = 0.85, -- rad/sec -> blur size
		AccelScale = 0.005, -- boosts blur on sudden speed changes
		ResponseGamma = 0.85, -- <1 = stronger low-speed blur
		SmoothingSpeed = 10.0,
		QualityLevelCutoff = Enum.QualityLevel.Level02, -- disable if <= this
	},
}

return CameraConfig
