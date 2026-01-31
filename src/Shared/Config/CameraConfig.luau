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
	ShoulderOffset = Vector3.new(1.6, 0.0, 0.0),
	FocusOffset = Vector3.new(0.0, 2.2, 0.0),
	ShoulderSide = 1, -- 1 = right, -1 = left

	-- Pitch
	DefaultPitch = math.rad(-10),
	PitchMin = math.rad(-70),
	PitchMax = math.rad(25),

	-- Smoothing (dt-stable)
	RotationSmoothingSpeed = 9.5, -- softer for comfort
	CFrameSmoothingSpeed = 14.0,
	DistanceSmoothingSpeed = 14.0,
	FocusSmoothingSpeed = 16.0,
	MoveDirectionSmoothingSpeed = 12.0,

	-- Auto alignment (comfort tuned)
	AutoAlignMoveThreshold = 0.25,
	AutoAlignSpeed = 2.1,     -- slower: reduces nausea
	AutoAlignIdleSpeed = 1.1, -- gentle recenter
	AutoAlignMaxYawRateDeg = 60, -- safety cap (deg/sec)

	-- Backward movement handling:
	-- If moving opposite to character forward (dot < threshold), DON'T align to movement.
	BackwardDotThreshold = 0.1,
	-- If movement is opposite camera forward, suppress auto-align to avoid spin.
	BackwardCameraDotThreshold = 0.15,

	-- Collision
	CollisionBuffer = 0.25,

	-- Input clamp (prevents spikes)
	MaxMouseDelta = 28,
	MaxTouchDelta = 70,

	-- Input deadzone (fix micro-jitter)
	MouseDeadzone = 0.3, -- px (ignore tiny deltas)
	TouchDeadzone = 0.5,  -- px
	ManualInputGrace = 0.35, -- seconds to suppress auto-align after manual input

	-- Sensitivity
	Sensitivity = 0.0018,
	TouchSensitivity = 0.0035,
	GamepadSensitivity = 2.8, -- radians/sec at full deflection
	GamepadDeadzone = 0.12,
	GamepadResponseExponent = 1.4,

	-- Free-look binding (RMB). LMB stays UI-safe.
	FreeLookMouseButton = Enum.UserInputType.MouseButton2,

	-- Comfort mouse behavior while freelook:
	-- LockCurrentPosition keeps cursor stable and prevents edge clamping issues.
	FreeLookMouseBehavior = Enum.MouseBehavior.LockCurrentPosition,
	FreeLookSensitivityMultiplier = 0.8,

	-- Shoulder swap (optional)
	ShoulderSwapKey = Enum.KeyCode.Q,
	ShoulderSwapGamepadButton = Enum.KeyCode.ButtonR1,

	-- Auto align toggle
	AutoAlignEnabled = true,

	-- Interaction focus hint (subtle nudge toward interactable)
	InteractionFocusEnabled = false,
	InteractionFocusWeight = 0.1,
	InteractionFocusMaxOffset = 0.8,
	InteractionFocusSmoothingSpeed = 10.0,
	InteractionFocusDeadzone = 1.5,

	-- Motion blur (camera-based)
	MotionBlur = {
		Enabled = true,
		MinSize = 0,
		MaxSize = 12,
		LinearVelocityScale = 0.015, -- studs/sec -> blur size
		RotVelocityScale = 0.45, -- rad/sec -> blur size
		SmoothingSpeed = 10.0,
		QualityLevelCutoff = Enum.QualityLevel.Level02, -- disable if <= this
	},
}

return CameraConfig
