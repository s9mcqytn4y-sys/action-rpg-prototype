local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local SettingsConfig = require(Shared:WaitForChild("Config"):WaitForChild("SettingsConfig") :: ModuleScript)
local CameraConfig = require(Shared:WaitForChild("Config"):WaitForChild("CameraConfig") :: ModuleScript)

local Client = script.Parent :: Folder
local ClientRoot = Client.Parent :: Folder
local Settings = require(ClientRoot.Settings.SettingsState :: ModuleScript)

local VFXController = Knit.CreateController({
	Name = "VFXController",
})

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

function VFXController:_attachCamera(camera: Camera?)
	if self._camera == camera then
		return
	end

	self._camera = camera
	self._lastCFrame = nil
	self._lastYaw = nil
	self._lastPitch = nil

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

function VFXController:KnitInit()
	self._janitor = Janitor.new()
	self._blur = nil
	self._camera = nil
	self._lastCFrame = nil
	self._lastYaw = nil
	self._lastPitch = nil
	self._currentBlur = 0
	self._motionBlurMax = 0
	self:_apply(Settings:GetVisual())
end

function VFXController:KnitStart()
	self:_attachCamera(Workspace.CurrentCamera)
	self._janitor:Add(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		self:_attachCamera(Workspace.CurrentCamera)
	end), "Disconnect")

	self._janitor:Add(Settings.Changed:Connect(function(category)
		if category == "Visual" then
			self:_apply(Settings:GetVisual())
		end
	end), "Disconnect")

	self._janitor:Add(RunService.RenderStepped:Connect(function(dt)
		self:_updateBlur(dt)
	end), "Disconnect")
end

function VFXController:_apply(visual)
	self._motionBlurMax = math.clamp(visual.MotionBlur or 0, SettingsConfig.Visual.MotionBlur.Min, SettingsConfig.Visual.MotionBlur.Max)
end

function VFXController:_updateBlur(dt: number)
	if not self._blur then
		return
	end

	local camera = self._camera or Workspace.CurrentCamera
	if not camera then
		self._blur.Size = 0
		return
	end

	local config = CameraConfig.MotionBlur
	if not config.Enabled or self._motionBlurMax <= 0 then
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

		local pitch, yaw, _ = currentCFrame:ToOrientation()
		local lastYaw = self._lastYaw or yaw
		local lastPitch = self._lastPitch or pitch
		local yawRate = math.abs(angleDelta(lastYaw, yaw)) / dt
		local pitchRate = math.abs(angleDelta(lastPitch, pitch)) / dt
		local rotSpeed = yawRate + pitchRate

		local maxAllowed = math.min(self._motionBlurMax, config.MaxSize)
		target = (linearSpeed * config.LinearVelocityScale) + (rotSpeed * config.RotVelocityScale)
		target = math.clamp(target, config.MinSize, maxAllowed)

		self._lastYaw = yaw
		self._lastPitch = pitch
	else
		local pitch, yaw, _ = currentCFrame:ToOrientation()
		self._lastYaw = yaw
		self._lastPitch = pitch
	end

	local alpha = expAlpha(config.SmoothingSpeed, dt)
	self._currentBlur = self._currentBlur + (target - self._currentBlur) * alpha
	self._blur.Size = self._currentBlur
	self._lastCFrame = currentCFrame
end

return VFXController
