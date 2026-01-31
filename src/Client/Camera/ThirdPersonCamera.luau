--!strict

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages :: Folder
local Shared = ReplicatedStorage.Shared :: Folder

local Janitor = require(Packages.Janitor :: ModuleScript)
local CameraConfig = require(Shared.Config.CameraConfig :: ModuleScript)
local DebugConfig = require(Shared.Config.DebugConfig :: ModuleScript)
local Metrics = require(Shared.Util.Metrics :: ModuleScript)

type CameraConfig = typeof(CameraConfig)
type Metrics = typeof(Metrics.new(false))

type CameraSettings = {
	Distance: number,
	Sensitivity: number,
	TouchSensitivity: number,
}

export type ThirdPersonCamera = {
	Start: (self: ThirdPersonCamera) -> (),
	Stop: (self: ThirdPersonCamera) -> (),
	BindCharacter: (self: ThirdPersonCamera, character: Model?) -> (),
	GetCameraCFrame: (self: ThirdPersonCamera) -> CFrame?,
	ApplySettings: (self: ThirdPersonCamera, settings: CameraSettings) -> (),
	_getCameraBasis: (self: ThirdPersonCamera) -> CFrame,
	_update: (self: ThirdPersonCamera, dt: number) -> (),
}

type CharacterContext = {
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
}

type ThirdPersonCameraImpl = ThirdPersonCamera & {
	_config: CameraConfig,
	_debug: typeof(DebugConfig),
	_metrics: Metrics,
	_janitor: any,

	_camera: Camera?,
	_originalCameraType: Enum.CameraType?,
	_originalFov: number?,
	_character: CharacterContext?,

	_yaw: number,
	_pitch: number,
	_yawTarget: number,
	_pitchTarget: number,

	_settings: CameraSettings,
	_targetDistance: number,
	_currentDistance: number,
	_targetFov: number,
	_currentFov: number,
	_prefSensitivity: number,
	_hasPrefSensitivity: boolean,
	_prefInvertY: boolean,
	_prefFov: number,
	_settingsSensitivityScale: number,

	_lastRayHit: boolean,
	_lastCFrame: CFrame?,

	_mouseBehavior: Enum.MouseBehavior?,
	_mouseIconEnabled: boolean?,

	_freeLook: boolean,
	_shoulderSide: number,

	_lastInputType: Enum.UserInputType?,
	_lastManualInputTime: number,
	_gamepadLook: Vector2,
	_gamepadZoomAxis: number,
	_gamepadTriggerL2: number,
	_gamepadTriggerR2: number,

	_raycastParams: RaycastParams,
}

local ThirdPersonCamera = {}
ThirdPersonCamera.__index = ThirdPersonCamera

local function expAlpha(speed: number, dt: number): number
	if speed <= 0 then
		return 1
	end
	return 1 - math.exp(-speed * dt)
end

local function lerpNumber(current: number, target: number, alpha: number): number
	return current + (target - current) * alpha
end

local function lerpAngle(current: number, target: number, alpha: number): number
	local delta = math.atan2(math.sin(target - current), math.cos(target - current))
	return current + delta * alpha
end

local function angleDelta(current: number, target: number): number
	return math.atan2(math.sin(target - current), math.cos(target - current))
end

local function clampDeltaVec2(delta: Vector2, maxDelta: number): Vector2
	if maxDelta <= 0 then
		return delta
	end
	return Vector2.new(
		math.clamp(delta.X, -maxDelta, maxDelta),
		math.clamp(delta.Y, -maxDelta, maxDelta)
	)
end

local function applyDeadzone(delta: Vector2, deadzone: number): Vector2
	if deadzone <= 0 then
		return delta
	end
	local x = (math.abs(delta.X) < deadzone) and 0 or delta.X
	local y = (math.abs(delta.Y) < deadzone) and 0 or delta.Y
	return Vector2.new(x, y)
end

local function getCharacterContext(character: Model): CharacterContext?
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return nil
	end
	return {
		character = character,
		humanoid = humanoid,
		root = root,
	}
end

function ThirdPersonCamera.new(metrics: Metrics): ThirdPersonCameraImpl
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	local self: ThirdPersonCameraImpl = setmetatable({
		_config = CameraConfig,
		_debug = DebugConfig,
		_metrics = metrics,
		_janitor = Janitor.new(),

		_camera = nil,
		_originalCameraType = nil,
		_originalFov = nil,
		_character = nil,

		_yaw = 0,
		_pitch = 0,
		_yawTarget = 0,
		_pitchTarget = 0,

		_settings = {
			Distance = CameraConfig.Distance,
			Sensitivity = CameraConfig.Sensitivity,
			TouchSensitivity = CameraConfig.TouchSensitivity,
		},
		_targetDistance = CameraConfig.Distance,
		_currentDistance = CameraConfig.Distance,
		_targetFov = math.clamp(CameraConfig.Fov, CameraConfig.MinFov, CameraConfig.MaxFov),
		_currentFov = math.clamp(CameraConfig.Fov, CameraConfig.MinFov, CameraConfig.MaxFov),
		_prefSensitivity = CameraConfig.Sensitivity,
		_hasPrefSensitivity = false,
		_prefInvertY = false,
		_prefFov = math.clamp(CameraConfig.Fov, CameraConfig.MinFov, CameraConfig.MaxFov),
		_settingsSensitivityScale = 1,

		_lastRayHit = false,
		_lastCFrame = nil,

		_mouseBehavior = nil,
		_mouseIconEnabled = nil,

		_freeLook = false,
		_shoulderSide = CameraConfig.ShoulderSide,

		_lastInputType = nil,
		_lastManualInputTime = 0,
		_gamepadLook = Vector2.zero,
		_gamepadZoomAxis = 0,
		_gamepadTriggerL2 = 0,
		_gamepadTriggerR2 = 0,

		_raycastParams = raycastParams,
	}, ThirdPersonCamera)

	return self
end

function ThirdPersonCamera:_attachCamera(camera: Camera?)
	local selfImpl = self :: ThirdPersonCameraImpl
	if selfImpl._camera == camera then
		return
	end

	selfImpl._camera = camera
	if camera then
		selfImpl._originalCameraType = camera.CameraType
		selfImpl._originalFov = camera.FieldOfView
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = selfImpl._currentFov
	end
end

function ThirdPersonCamera:_getPreferredInputType(): Enum.UserInputType?
	local selfImpl = self :: ThirdPersonCameraImpl
	local ok, preferred = pcall(function()
		local inputServiceAny = UserInputService :: any
		if inputServiceAny.GetPreferredInputType then
			return inputServiceAny:GetPreferredInputType()
		end
		if inputServiceAny.PreferredInputType then
			return inputServiceAny.PreferredInputType
		end
		return nil
	end)
	if ok and preferred then
		return preferred
	end

	local okLast, last = pcall(function()
		return UserInputService:GetLastInputType()
	end)
	if okLast and last then
		return last
	end
	return selfImpl._lastInputType
end

function ThirdPersonCamera:Start()
	local selfImpl = self :: ThirdPersonCameraImpl
	if selfImpl._camera then
		return
	end

	selfImpl:_attachCamera(Workspace.CurrentCamera)

	selfImpl._mouseBehavior = UserInputService.MouseBehavior
	selfImpl._mouseIconEnabled = UserInputService.MouseIconEnabled

	local okLast, lastInput = pcall(function()
		return UserInputService:GetLastInputType()
	end)
	if okLast then
		selfImpl._lastInputType = lastInput
	end

	if UserInputService.LastInputTypeChanged then
		selfImpl._janitor:Add(UserInputService.LastInputTypeChanged:Connect(function(inputType)
			selfImpl._lastInputType = inputType
		end), "Disconnect")
	end

	selfImpl._janitor:Add(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		selfImpl:_attachCamera(Workspace.CurrentCamera)
	end), "Disconnect")

	selfImpl._janitor:Add(UserInputService.InputChanged:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end

		local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
		local isTouch = input.UserInputType == Enum.UserInputType.Touch
		local isMouseWheel = input.UserInputType == Enum.UserInputType.MouseWheel
		local isGamepad = input.UserInputType == Enum.UserInputType.Gamepad1

		-- Zoom
		if isMouseWheel then
			local zoomDelta = input.Position.Z
			if zoomDelta ~= 0 then
				selfImpl._targetDistance = math.clamp(
					selfImpl._targetDistance - (zoomDelta * selfImpl._config.ZoomStep),
					selfImpl._config.MinDistance,
					selfImpl._config.MaxDistance
				)
			end
			return
		end

		if isGamepad then
			if input.KeyCode == Enum.KeyCode.Thumbstick2 then
				selfImpl._gamepadLook = Vector2.new(input.Position.X, input.Position.Y)
				return
			end
			if input.KeyCode == Enum.KeyCode.ButtonL2 then
				selfImpl._gamepadTriggerL2 = math.clamp(input.Position.Z, 0, 1)
				selfImpl._gamepadZoomAxis = selfImpl._gamepadTriggerR2 - selfImpl._gamepadTriggerL2
				return
			end
			if input.KeyCode == Enum.KeyCode.ButtonR2 then
				selfImpl._gamepadTriggerR2 = math.clamp(input.Position.Z, 0, 1)
				selfImpl._gamepadZoomAxis = selfImpl._gamepadTriggerR2 - selfImpl._gamepadTriggerL2
				return
			end
		end

		-- Rotation input:
		-- Mouse rotates ONLY while RMB free-look is held (handled in RenderStep to avoid jitter).
		-- Touch drag rotates (typical mobile), UI blocks via gameProcessed.
		if isMouse then
			return
		end
		if not isTouch then
			return
		end

		local sensitivity: number
		local maxDelta: number
		local deadzone: number
		if isTouch then
			sensitivity = selfImpl._settings.TouchSensitivity
			maxDelta = selfImpl._config.MaxTouchDelta
			deadzone = selfImpl._config.TouchDeadzone
		else
			sensitivity = selfImpl._prefSensitivity * selfImpl._settingsSensitivityScale * selfImpl._config.FreeLookSensitivityMultiplier
			maxDelta = selfImpl._config.MaxMouseDelta
			deadzone = selfImpl._config.MouseDeadzone
		end

		local delta = clampDeltaVec2(input.Delta, maxDelta)
		delta = applyDeadzone(delta, deadzone)

		-- If it becomes zero after deadzone, do nothing (fix micro-jitter while RMB held).
		if delta.X == 0 and delta.Y == 0 then
			return
		end

		local invert = if selfImpl._prefInvertY then -1 else 1
		selfImpl._yawTarget -= delta.X * sensitivity
		selfImpl._pitchTarget -= delta.Y * sensitivity * invert
		selfImpl._pitchTarget = math.clamp(selfImpl._pitchTarget, selfImpl._config.PitchMin, selfImpl._config.PitchMax)
		selfImpl._lastManualInputTime = os.clock()
	end), "Disconnect")

	-- RMB free-look begin
	selfImpl._janitor:Add(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		if input.UserInputType == selfImpl._config.FreeLookMouseButton then
			selfImpl._freeLook = true
			if UserInputService.MouseEnabled then
				UserInputService.MouseBehavior = selfImpl._config.FreeLookMouseBehavior
			end
			return
		end

		if input.KeyCode == selfImpl._config.ShoulderSwapKey then
			selfImpl._shoulderSide *= -1
			return
		end

		if input.KeyCode == selfImpl._config.ShoulderSwapGamepadButton then
			selfImpl._shoulderSide *= -1
			return
		end
	end), "Disconnect")

	-- RMB free-look end
	selfImpl._janitor:Add(UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		if input.UserInputType == selfImpl._config.FreeLookMouseButton then
			selfImpl._freeLook = false
			if UserInputService.MouseEnabled then
				UserInputService.MouseBehavior = selfImpl._mouseBehavior or Enum.MouseBehavior.Default
			end
			return
		end

		if input.UserInputType == Enum.UserInputType.Gamepad1 then
			if input.KeyCode == Enum.KeyCode.Thumbstick2 then
				selfImpl._gamepadLook = Vector2.zero
			elseif input.KeyCode == Enum.KeyCode.ButtonL2 or input.KeyCode == Enum.KeyCode.ButtonR2 then
				selfImpl._gamepadTriggerL2 = 0
				selfImpl._gamepadTriggerR2 = 0
				selfImpl._gamepadZoomAxis = 0
			end
		end
	end), "Disconnect")

	-- Pinch zoom (mobile)
	if UserInputService.TouchEnabled then
		selfImpl._janitor:Add(UserInputService.TouchPinch:Connect(function(_, scale, _, state)
			if state == Enum.UserInputState.Change then
				local pinchDelta = (1 - scale) * selfImpl._config.PinchZoomSpeed
				selfImpl._targetDistance = math.clamp(
					selfImpl._targetDistance + pinchDelta,
					selfImpl._config.MinDistance,
					selfImpl._config.MaxDistance
				)
			end
		end), "Disconnect")
	end

	RunService:BindToRenderStep("ThirdPersonCamera", Enum.RenderPriority.Camera.Value, function(dt)
		selfImpl:_update(dt)
	end)
	selfImpl._janitor:Add(function()
		RunService:UnbindFromRenderStep("ThirdPersonCamera")
	end)
end

function ThirdPersonCamera:Stop()
	local selfImpl = self :: ThirdPersonCameraImpl
	selfImpl._janitor:Cleanup()

	if selfImpl._camera and selfImpl._originalCameraType then
		selfImpl._camera.CameraType = selfImpl._originalCameraType
		if selfImpl._originalFov then
			selfImpl._camera.FieldOfView = selfImpl._originalFov
		end
	end

	if UserInputService.MouseEnabled then
		UserInputService.MouseBehavior = selfImpl._mouseBehavior or Enum.MouseBehavior.Default
		if selfImpl._mouseIconEnabled ~= nil then
			UserInputService.MouseIconEnabled = selfImpl._mouseIconEnabled
		end
	end

	selfImpl._camera = nil
end

function ThirdPersonCamera:BindCharacter(character: Model?)
	local selfImpl = self :: ThirdPersonCameraImpl
	if not character then
		selfImpl._character = nil
		return
	end

	local context = getCharacterContext(character)
	if not context then
		if selfImpl._debug.LogWarnings then
			warn("[ThirdPersonCamera] Character missing humanoid/root; camera not bound.")
		end
		selfImpl._character = nil
		return
	end

	selfImpl._character = context
	selfImpl._raycastParams.FilterDescendantsInstances = { context.character }

	local root = context.root
	local _, yaw, _ = root.CFrame:ToOrientation()

	selfImpl._yaw = yaw
	selfImpl._pitch = selfImpl._config.DefaultPitch
	selfImpl._yawTarget = yaw
	selfImpl._pitchTarget = selfImpl._config.DefaultPitch

	selfImpl._targetDistance = math.clamp(selfImpl._settings.Distance, selfImpl._config.MinDistance, selfImpl._config.MaxDistance)
	selfImpl._currentDistance = selfImpl._targetDistance
	selfImpl._targetFov = math.clamp(selfImpl._prefFov, selfImpl._config.MinFov, selfImpl._config.MaxFov)
	selfImpl._currentFov = selfImpl._targetFov
	selfImpl._shoulderSide = selfImpl._config.ShoulderSide

	selfImpl._lastCFrame = nil
	selfImpl._lastRayHit = false
end

function ThirdPersonCamera:GetCameraCFrame(): CFrame?
	local selfImpl = self :: ThirdPersonCameraImpl
	return selfImpl._lastCFrame
end

function ThirdPersonCamera:ApplySettings(settings: CameraSettings)
	local selfImpl = self :: ThirdPersonCameraImpl
	selfImpl._settings = settings
	selfImpl._targetDistance = math.clamp(settings.Distance, selfImpl._config.MinDistance, selfImpl._config.MaxDistance)
	if not selfImpl._hasPrefSensitivity then
		selfImpl._prefSensitivity = math.clamp(settings.Sensitivity, 0.0005, 0.02)
	end
	if selfImpl._config.Sensitivity > 0 then
		local scale = settings.Sensitivity / selfImpl._config.Sensitivity
		selfImpl._settingsSensitivityScale = math.clamp(scale, 0.5, 2.0)
	end
end

function ThirdPersonCamera:ApplyPreferences(preferences: { Sensitivity: number?, InvertY: boolean?, Fov: number? })
	local selfImpl = self :: ThirdPersonCameraImpl
	if preferences.Sensitivity then
		selfImpl._prefSensitivity = math.clamp(preferences.Sensitivity, 0.0005, 0.02)
		selfImpl._hasPrefSensitivity = true
	end
	if preferences.InvertY ~= nil then
		selfImpl._prefInvertY = preferences.InvertY
	end
	if preferences.Fov then
		selfImpl._prefFov = math.clamp(preferences.Fov, selfImpl._config.MinFov, selfImpl._config.MaxFov)
		selfImpl._targetFov = selfImpl._prefFov
	end
end

function ThirdPersonCamera:_getCameraBasis(): CFrame
	local selfImpl = self :: ThirdPersonCameraImpl
	local yawCFrame = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), selfImpl._yaw)
	local pitchCFrame = CFrame.fromAxisAngle(Vector3.new(1, 0, 0), selfImpl._pitch)
	return yawCFrame * pitchCFrame
end

function ThirdPersonCamera:_update(dt: number)
	local selfImpl = self :: ThirdPersonCameraImpl
	local camera = selfImpl._camera
	if not camera then
		return
	end

	local character = selfImpl._character
	if not character then
		return
	end

	local root = character.root
	if not root or not root.Parent then
		return
	end

	local preferredInput = selfImpl:_getPreferredInputType()
	local preferGamepad = preferredInput == Enum.UserInputType.Gamepad1
		or preferredInput == Enum.UserInputType.Gamepad2
		or preferredInput == Enum.UserInputType.Gamepad3
		or preferredInput == Enum.UserInputType.Gamepad4

	local hasGamepadLook = false
	local gamepadLook = selfImpl._gamepadLook
	if (preferGamepad or UserInputService.GamepadEnabled) and gamepadLook.Magnitude > 0 then
		local deadzone = selfImpl._config.GamepadDeadzone
		if gamepadLook.Magnitude <= deadzone then
			gamepadLook = Vector2.zero
		else
			local normalized = (gamepadLook.Magnitude - deadzone) / (1 - deadzone)
			local curve = normalized ^ selfImpl._config.GamepadResponseExponent
			gamepadLook = gamepadLook.Unit * curve
		end

		local sensitivity = selfImpl._config.GamepadSensitivity
		local invert = if selfImpl._prefInvertY then -1 else 1
		selfImpl._yawTarget -= gamepadLook.X * sensitivity * dt
		selfImpl._pitchTarget -= gamepadLook.Y * sensitivity * dt * invert
		selfImpl._pitchTarget = math.clamp(selfImpl._pitchTarget, selfImpl._config.PitchMin, selfImpl._config.PitchMax)
		hasGamepadLook = gamepadLook.Magnitude > 0
		selfImpl._lastManualInputTime = os.clock()
	end

	-- Mouse free-look (RMB): use GetMouseDelta per-frame to avoid jitter.
	if selfImpl._freeLook and UserInputService.MouseEnabled then
		local delta = UserInputService:GetMouseDelta()
		local maxDelta = selfImpl._config.MaxMouseDelta
		local deadzone = selfImpl._config.MouseDeadzone
		local sensitivity = selfImpl._prefSensitivity * selfImpl._settingsSensitivityScale * selfImpl._config.FreeLookSensitivityMultiplier
		delta = clampDeltaVec2(delta, maxDelta)
		delta = applyDeadzone(delta, deadzone)
		if delta.X ~= 0 or delta.Y ~= 0 then
			local invert = if selfImpl._prefInvertY then -1 else 1
			selfImpl._yawTarget -= delta.X * sensitivity
			selfImpl._pitchTarget -= delta.Y * sensitivity * invert
			selfImpl._pitchTarget = math.clamp(selfImpl._pitchTarget, selfImpl._config.PitchMin, selfImpl._config.PitchMax)
			selfImpl._lastManualInputTime = os.clock()
		end
	end

	if (preferGamepad or UserInputService.GamepadEnabled) and math.abs(selfImpl._gamepadZoomAxis) > 0.01 then
		selfImpl._targetDistance = math.clamp(
			selfImpl._targetDistance - (selfImpl._gamepadZoomAxis * selfImpl._config.GamepadZoomSpeed * dt),
			selfImpl._config.MinDistance,
			selfImpl._config.MaxDistance
		)
	end

	-- AUTO-ALIGN (comfort-safe):
	-- 1) Disabled while RMB free-look.
	-- 2) Disabled for backward movement (press S) to prevent 180 snap.
	-- 3) Rate-limited to prevent fast spinning.
	local manualGrace = (os.clock() - selfImpl._lastManualInputTime) < selfImpl._config.ManualInputGrace
	if selfImpl._config.AutoAlignEnabled and not selfImpl._freeLook and not hasGamepadLook and not manualGrace then
		local humanoid = character.humanoid
		local moveDir = humanoid.MoveDirection
		local flatMove = Vector3.new(moveDir.X, 0, moveDir.Z)
		local camLook = selfImpl:_getCameraBasis().LookVector
		local camForward = Vector3.new(camLook.X, 0, camLook.Z)

		local _, rootYaw, _ = root.CFrame:ToOrientation()
		local rootForward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		local isMoving = flatMove.Magnitude > selfImpl._config.AutoAlignMoveThreshold
		local movingBackToCamera = false
		if isMoving and camForward.Magnitude > 1e-4 then
			local dotCam = flatMove.Unit:Dot(camForward.Unit)
			if dotCam < selfImpl._config.BackwardCameraDotThreshold then
				movingBackToCamera = true
			end
		end

		if not movingBackToCamera then
			local desiredYaw = rootYaw
			local useMoveAlign = false

			if isMoving then
				-- Detect backward movement relative to character facing.
				local dot = 0
				if rootForward.Magnitude > 1e-4 then
					dot = flatMove.Unit:Dot(rootForward.Unit)
				end

				if dot > selfImpl._config.BackwardDotThreshold then
					-- Not moving backward -> align to movement direction (common AAA feel)
					desiredYaw = math.atan2(-flatMove.X, -flatMove.Z)
					useMoveAlign = true
				else
					-- Moving backward -> keep aligning gently to root (NOT movement)
					desiredYaw = rootYaw
					useMoveAlign = false
				end
			else
				desiredYaw = rootYaw
			end

			-- First: smooth toward desiredYaw
			local speed = if useMoveAlign then selfImpl._config.AutoAlignSpeed else selfImpl._config.AutoAlignIdleSpeed
			local a = expAlpha(speed, dt)
			local nextYawTarget = lerpAngle(selfImpl._yawTarget, desiredYaw, a)

			-- Second: hard rate limit (deg/sec) to prevent fast spin
			local maxRateRad = math.rad(selfImpl._config.AutoAlignMaxYawRateDeg)
			local d = angleDelta(selfImpl._yawTarget, nextYawTarget)
			local maxStep = maxRateRad * dt
			d = math.clamp(d, -maxStep, maxStep)
			selfImpl._yawTarget = selfImpl._yawTarget + d
		end
	end

	-- Smooth yaw/pitch toward targets (dt-stable)
	local rotA = expAlpha(selfImpl._config.RotationSmoothingSpeed, dt)
	selfImpl._yaw = lerpAngle(selfImpl._yaw, selfImpl._yawTarget, rotA)
	selfImpl._pitch = lerpAngle(selfImpl._pitch, selfImpl._pitchTarget, rotA)

	local rotation = selfImpl:_getCameraBasis()

	-- Focus point
	local shoulderBase = selfImpl._config.ShoulderOffset
	local shoulderOffset = rotation:VectorToWorldSpace(Vector3.new(shoulderBase.X * selfImpl._shoulderSide, shoulderBase.Y, shoulderBase.Z))
	local focus = root.Position + selfImpl._config.FocusOffset + shoulderOffset

	-- Camera BEHIND focus:
	-- Roblox forward = -Z, so "behind" is local +Z.
	local intendedDistance = math.clamp(selfImpl._targetDistance, selfImpl._config.MinDistance, selfImpl._config.MaxDistance)
	local desiredOffset = rotation:VectorToWorldSpace(Vector3.new(0, 0, intendedDistance)) -- +Z = behind
	local desiredPosition = focus + desiredOffset

	-- Collision
	local rayDirection = desiredPosition - focus
	local result = Workspace:Raycast(focus, rayDirection, selfImpl._raycastParams)

	local targetDistance = intendedDistance
	local hitThisFrame = false
	if result then
		local hitDistance = (result.Position - focus).Magnitude - selfImpl._config.CollisionBuffer
		targetDistance = math.clamp(hitDistance, selfImpl._config.MinDistance, intendedDistance)
		hitThisFrame = true
	end

	if hitThisFrame and not selfImpl._lastRayHit then
		selfImpl._metrics:Increment("cameraRayHits", 1)
	end
	selfImpl._lastRayHit = hitThisFrame

	-- Smooth distance
	local distA = expAlpha(selfImpl._config.DistanceSmoothingSpeed, dt)
	selfImpl._currentDistance = lerpNumber(selfImpl._currentDistance, targetDistance, distA)

	local finalOffset = rotation:VectorToWorldSpace(Vector3.new(0, 0, selfImpl._currentDistance)) -- +Z behind
	local finalPosition = focus + finalOffset

	local targetCFrame = CFrame.new(finalPosition, focus)

	-- Smooth final cframe
	local cA = expAlpha(selfImpl._config.CFrameSmoothingSpeed, dt)
	local finalCFrame = if selfImpl._lastCFrame then selfImpl._lastCFrame:Lerp(targetCFrame, cA) else targetCFrame

	selfImpl._lastCFrame = finalCFrame
	camera.CFrame = finalCFrame
	camera.Focus = CFrame.new(focus)

	local fovA = expAlpha(selfImpl._config.FovSmoothingSpeed, dt)
	selfImpl._currentFov = lerpNumber(selfImpl._currentFov, selfImpl._targetFov, fovA)
	camera.FieldOfView = selfImpl._currentFov
end

return ThirdPersonCamera
