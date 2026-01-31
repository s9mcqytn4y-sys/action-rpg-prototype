--!strict
-- AAA-comfort Third-Person Camera (NO AIM SYSTEM)
-- All *Speed values are in 1/seconds and applied with dt-stable exponential smoothing.

local CameraConfig = {
	-- Distance
	Distance = 9.0,
	MinDistance = 3.0,
	MaxDistance = 16.0,

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
	RotationSmoothingSpeed = 12.0, -- a bit softer than before (comfort)
	CFrameSmoothingSpeed = 16.0,
	DistanceSmoothingSpeed = 14.0,

	-- Auto alignment (comfort tuned)
	AutoAlignMoveThreshold = 0.20,
	AutoAlignSpeed = 4.5,     -- slower: reduces nausea
	AutoAlignIdleSpeed = 2.5, -- gentle recenter
	AutoAlignMaxYawRateDeg = 180, -- hard safety cap (deg/sec)

	-- Backward movement handling:
	-- If moving opposite to character forward (dot < threshold), DON'T align to movement.
	BackwardDotThreshold = -0.25,

	-- Collision
	CollisionBuffer = 0.25,

	-- Input clamp (prevents spikes)
	MaxMouseDelta = 60,
	MaxTouchDelta = 80,

	-- Input deadzone (fix micro-jitter)
	MouseDeadzone = 0.25, -- px (ignore tiny deltas)
	TouchDeadzone = 0.5,  -- px

	-- Sensitivity
	Sensitivity = 0.0026,
	TouchSensitivity = 0.004,
	GamepadSensitivity = 3.2, -- radians/sec at full deflection
	GamepadDeadzone = 0.12,
	GamepadResponseExponent = 1.4,

	-- Free-look binding (RMB). LMB stays UI-safe.
	FreeLookMouseButton = Enum.UserInputType.MouseButton2,

	-- Comfort mouse behavior while freelook:
	-- LockCurrentPosition keeps cursor stable and prevents edge clamping issues.
	FreeLookMouseBehavior = Enum.MouseBehavior.LockCurrentPosition,

	-- Shoulder swap (optional)
	ShoulderSwapKey = Enum.KeyCode.Q,
	ShoulderSwapGamepadButton = Enum.KeyCode.ButtonR1,

	-- Auto align toggle
	AutoAlignEnabled = true,

	-- Motion blur (camera-based)
	MotionBlur = {
		Enabled = true,
		MinSize = 0,
		MaxSize = 14,
		LinearVelocityScale = 0.012, -- studs/sec -> blur size
		RotVelocityScale = 0.35, -- rad/sec -> blur size
		SmoothingSpeed = 10.0,
		QualityLevelCutoff = Enum.QualityLevel.Level04, -- disable if <= this
	},
}

return CameraConfig
