local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local AudioController = Knit.CreateController({
	Name = "AudioController",
})

function AudioController:KnitInit()
	self._janitor = Janitor.new()
	self._prefsController = nil
end

function AudioController:KnitStart()
	local ok, prefsController = pcall(function()
		return Knit.GetController("PreferencesController")
	end)
	if not ok or not prefsController then
		return
	end
	self._prefsController = prefsController
	self:_applyPrefs(prefsController:GetPreferences())
	self._janitor:Add(prefsController.Changed:Connect(function(prefs)
		self:_applyPrefs(prefs)
	end), "Disconnect")
end

function AudioController:_applyPrefs(prefs)
	local sound = prefs and prefs.Sound or nil
	if not sound then
		return
	end

	local master = sound.Master or 1
	local music = sound.Music or 1
	local sfx = sound.SFX or 1

	local masterGroup = SoundService:FindFirstChild("Master")
	if masterGroup and masterGroup:IsA("SoundGroup") then
		masterGroup.Volume = master
	end

	local musicGroup = SoundService:FindFirstChild("Music")
	if musicGroup and musicGroup:IsA("SoundGroup") then
		musicGroup.Volume = music * master
	end

	local sfxGroup = SoundService:FindFirstChild("SFX")
	if sfxGroup and sfxGroup:IsA("SoundGroup") then
		sfxGroup.Volume = sfx * master
	end
end

return AudioController
