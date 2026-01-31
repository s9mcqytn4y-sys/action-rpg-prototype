--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages :: Folder
local Shared = ReplicatedStorage.Shared :: Folder

local Signal = require(Packages.Signal :: ModuleScript)

local CameraConfig = require(Shared.Config.CameraConfig :: ModuleScript)
local SettingsConfig = require(Shared.Config.SettingsConfig :: ModuleScript)

type CameraSettings = {
	Distance: number,
	Sensitivity: number,
	AimSensitivity: number,
	TouchSensitivity: number,
	AimTouchSensitivity: number,
}

type VisualSettings = {
	MotionBlur: number,
}

type CameraSettingKey = "Distance" | "Sensitivity" | "AimSensitivity" | "TouchSensitivity" | "AimTouchSensitivity"
type VisualSettingKey = "MotionBlur"

export type SettingsState = {
	Changed: typeof(Signal.new()),
	GetCamera: (self: SettingsState) -> CameraSettings,
	SetCamera: (self: SettingsState, key: CameraSettingKey, value: number) -> (),
	GetVisual: (self: SettingsState) -> VisualSettings,
	SetVisual: (self: SettingsState, key: VisualSettingKey, value: number) -> (),
}

type SettingsStateImpl = SettingsState & {
	_camera: CameraSettings,
	_visual: VisualSettings,
}

local SettingsState = {}
SettingsState.__index = SettingsState

local function clampRange(value: number, range: { Min: number, Max: number }): number
	return math.clamp(value, range.Min, range.Max)
end

function SettingsState.new(): SettingsState
	local self: SettingsStateImpl = setmetatable({}, SettingsState)
	self.Changed = Signal.new()
	self._camera = {
		Distance = CameraConfig.Distance,
		Sensitivity = CameraConfig.Sensitivity,
		AimSensitivity = CameraConfig.AimSensitivity,
		TouchSensitivity = CameraConfig.TouchSensitivity,
		AimTouchSensitivity = CameraConfig.AimTouchSensitivity,
	}
	self._visual = {
		MotionBlur = 8,
	}
	return self
end

function SettingsState:GetCamera(): CameraSettings
	local selfImpl = self :: SettingsStateImpl
	return {
		Distance = selfImpl._camera.Distance,
		Sensitivity = selfImpl._camera.Sensitivity,
		AimSensitivity = selfImpl._camera.AimSensitivity,
		TouchSensitivity = selfImpl._camera.TouchSensitivity,
		AimTouchSensitivity = selfImpl._camera.AimTouchSensitivity,
	}
end

function SettingsState:SetCamera(key: CameraSettingKey, value: number)
	local selfImpl = self :: SettingsStateImpl
	local ranges = SettingsConfig.Camera
	local range = (ranges :: any)[key]
	if range then
		value = clampRange(value, range)
	end

	if selfImpl._camera[key] == value then
		return
	end

	selfImpl._camera[key] = value
	selfImpl.Changed:Fire("Camera", key, value)
end

function SettingsState:GetVisual(): VisualSettings
	local selfImpl = self :: SettingsStateImpl
	return {
		MotionBlur = selfImpl._visual.MotionBlur,
	}
end

function SettingsState:SetVisual(key: VisualSettingKey, value: number)
	local selfImpl = self :: SettingsStateImpl
	local ranges = SettingsConfig.Visual
	local range = (ranges :: any)[key]
	if range then
		value = clampRange(value, range)
	end

	if selfImpl._visual[key] == value then
		return
	end

	selfImpl._visual[key] = value
	selfImpl.Changed:Fire("Visual", key, value)
end

local settings = SettingsState.new()

return settings
