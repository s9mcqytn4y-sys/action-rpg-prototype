local Lighting = game:GetService("Lighting")

local CameraMotionBlur = {}
CameraMotionBlur.__index = CameraMotionBlur

local function expAlpha(speed: number, dt: number): number
	if speed <= 0 then
		return 1
	end
	return 1 - math.exp(-speed * dt)
end

local function angleDelta(current: number, target: number): number
	return math.atan2(math.sin(target - current), math.cos(target - current))
end

local function getQualityLevel(): Enum.QualityLevel?
	local ok, settings = pcall(function()
		local userSettings = UserSettings()
		if userSettings.GetService then
			return userSettings:GetService("UserGameSettings")
		end
		return userSettings.GameSettings
	end)
	if ok and settings then
		local level = settings.SavedQualityLevel or settings.GraphicsQualityLevel
		return level
	end
	return nil
end

local function isQualityBelowCutoff(level: Enum.QualityLevel?, cutoff: Enum.QualityLevel?): boolean
	if not level or not cutoff then
		return false
	end
	if level == Enum.QualityLevel.Automatic then
		return false
	end
	return level.Value <= cutoff.Value
end

function CameraMotionBlur.new(config)
	local self = setmetatable({}, CameraMotionBlur)
	self._config = config
	self._camera = nil
	self._blur = nil
	self._lastCFrame = nil
	self._lastYaw = nil
	self._lastPitch = nil
	self._lastLinearSpeed = nil
	self._currentBlur = 0
	self._maxSize = 0
	self._enabled = true
	return self
end

function CameraMotionBlur:AttachCamera(camera: Camera?)
	if self._camera == camera then
		return
	end

	self._camera = camera
	self._lastCFrame = nil
	self._lastYaw = nil
	self._lastPitch = nil
	self._lastLinearSpeed = nil

	if not camera then
		self._blur = nil
		return
	end

	local blur = camera:FindFirstChild("MotionBlur") or Lighting:FindFirstChild("MotionBlur")
	if blur and blur:IsA("BlurEffect") then
		self._blur = blur
	else
		self._blur = Instance.new("BlurEffect")
		self._blur.Name = "MotionBlur"
	end
	self._blur.Parent = camera
end

function CameraMotionBlur:SetEnabled(enabled: boolean)
	self._enabled = enabled == true
end

function CameraMotionBlur:SetMaxSize(size: number)
	self._maxSize = math.max(0, size or 0)
end

function CameraMotionBlur:Update(dt: number)
	if not self._blur then
		return
	end

	local camera = self._camera
	if not camera then
		self._blur.Size = 0
		return
	end

	local config = self._config
	if not self._enabled or not config.Enabled or self._maxSize <= 0 then
		self._blur.Size = 0
		self._currentBlur = 0
		self._lastCFrame = camera.CFrame
		return
	end

	local level = getQualityLevel()
	if isQualityBelowCutoff(level, config.QualityLevelCutoff) then
		self._blur.Size = 0
		self._currentBlur = 0
		self._lastCFrame = camera.CFrame
		return
	end

	if dt <= 0 then
		return
	end

	local currentCFrame = camera.CFrame
	local target = 0

	if self._lastCFrame then
		local deltaPos = currentCFrame.Position - self._lastCFrame.Position
		local linearSpeed = deltaPos.Magnitude / dt
		local lastLinear = self._lastLinearSpeed or linearSpeed
		local linearAccel = math.abs(linearSpeed - lastLinear) / dt

		local pitch, yaw, _ = currentCFrame:ToOrientation()
		local lastYaw = self._lastYaw or yaw
		local lastPitch = self._lastPitch or pitch
		local yawRate = math.abs(angleDelta(lastYaw, yaw)) / dt
		local pitchRate = math.abs(angleDelta(lastPitch, pitch)) / dt
		local rotSpeed = yawRate + pitchRate

		local maxAllowed = math.min(self._maxSize, config.MaxSize)
		local base = (linearSpeed * config.LinearVelocityScale) + (rotSpeed * config.RotVelocityScale)
		if config.AccelScale then
			base += (linearAccel * config.AccelScale)
		end
		local normalized = if maxAllowed > 0 then math.clamp(base / maxAllowed, 0, 1) else 0
		local gamma = config.ResponseGamma or 1
		target = (normalized ^ gamma) * maxAllowed
		target = math.clamp(target, config.MinSize, maxAllowed)

		self._lastYaw = yaw
		self._lastPitch = pitch
		self._lastLinearSpeed = linearSpeed
	else
		local pitch, yaw, _ = currentCFrame:ToOrientation()
		self._lastYaw = yaw
		self._lastPitch = pitch
		self._lastLinearSpeed = 0
	end

	local alpha = expAlpha(config.SmoothingSpeed, dt)
	self._currentBlur = self._currentBlur + (target - self._currentBlur) * alpha
	self._blur.Size = self._currentBlur
	self._lastCFrame = currentCFrame
end

return CameraMotionBlur
