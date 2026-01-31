local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
local CameraMotionBlur = require(ClientRoot.VFX.CameraMotionBlur :: ModuleScript)

local VFXController = Knit.CreateController({
	Name = "VFXController",
})

function VFXController:KnitInit()
	self._janitor = Janitor.new()
	self._motionBlur = CameraMotionBlur.new(CameraConfig.MotionBlur)
	self._motionBlurMax = 0
	self._showVfx = true
	self._prefsController = nil
	self:_applyVisual(Settings:GetVisual())
end

function VFXController:KnitStart()
	self:_attachCamera(Workspace.CurrentCamera)
	self._janitor:Add(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		self:_attachCamera(Workspace.CurrentCamera)
	end), "Disconnect")

	self._janitor:Add(Settings.Changed:Connect(function(category)
		if category == "Visual" then
			self:_applyVisual(Settings:GetVisual())
		end
	end), "Disconnect")

	local ok, prefsController = pcall(function()
		return Knit.GetController("PreferencesController")
	end)
	if ok and prefsController then
		self._prefsController = prefsController
		self:_applyPrefs(prefsController:GetPreferences())
		self._janitor:Add(prefsController.Changed:Connect(function(prefs)
			self:_applyPrefs(prefs)
		end), "Disconnect")
	end

	self._janitor:Add(RunService.RenderStepped:Connect(function(dt)
		self._motionBlur:Update(dt)
	end), "Disconnect")
end

function VFXController:_attachCamera(camera: Camera?)
	self._motionBlur:AttachCamera(camera)
end

function VFXController:_applyVisual(visual)
	self._motionBlurMax = math.clamp(
		visual.MotionBlur or 0,
		SettingsConfig.Visual.MotionBlur.Min,
		SettingsConfig.Visual.MotionBlur.Max
	)
	self:_refreshBlurEnabled()
end

function VFXController:_applyPrefs(prefs)
	local display = prefs and prefs.Display or nil
	if display and display.ShowVfx ~= nil then
		self._showVfx = display.ShowVfx == true
	else
		self._showVfx = true
	end
	self:_refreshBlurEnabled()
end

function VFXController:_refreshBlurEnabled()
	local enabled = self._showVfx and self._motionBlurMax > 0
	self._motionBlur:SetEnabled(enabled)
	self._motionBlur:SetMaxSize(self._motionBlurMax)
end

return VFXController
