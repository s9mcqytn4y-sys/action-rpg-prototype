local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local TableUtil = require(Packages:WaitForChild("TableUtil") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Config = Shared:WaitForChild("Config") :: Folder
local PreferencesSchema = require(Config:WaitForChild("PreferencesSchema") :: ModuleScript)

local PreferencesService = Knit.CreateService({
	Name = "PreferencesService",
	Client = {},
})

function PreferencesService:KnitInit()
	self._prefs = {}
end

function PreferencesService:KnitStart()
	self._playerDataService = Knit.GetService("PlayerDataService")

	self._playerDataService.ProfileLoaded:Connect(function(player, data)
		self:_initPlayer(player, data)
	end)

	self._playerDataService.ProfileReleased:Connect(function(player)
		self:_cleanupPlayer(player)
	end)

	for _, player in Players:GetPlayers() do
		local data = self._playerDataService:GetProfile(player)
		if data then
			self:_initPlayer(player, data)
		end
	end
end

function PreferencesService:_initPlayer(player: Player, data)
	local defaults = PreferencesSchema.Defaults
	local prefs = TableUtil.Copy(defaults, true)

	if data and type(data) == "table" and type(data.Preferences) == "table" then
		prefs = TableUtil.Reconcile(data.Preferences, defaults)
	end

	self._prefs[player] = prefs

	local playerDataService = self._playerDataService
	if playerDataService then
		playerDataService:UpdateProfile(player, function(profile)
			profile.Preferences = TableUtil.Copy(prefs, true)
		end, false)
	end
end

function PreferencesService:_cleanupPlayer(player: Player)
	self._prefs[player] = nil
end

function PreferencesService.Client:GetPreferences(player: Player)
	return self.Server:GetPreferences(player)
end

function PreferencesService.Client:SetPreference(player: Player, category: string, key: string, value: any)
	return self.Server:SetPreference(player, category, key, value)
end

function PreferencesService.Client:ResetPreferences(player: Player)
	return self.Server:ResetPreferences(player)
end

function PreferencesService:GetPreferences(player: Player)
	local prefs = self._prefs[player]
	if not prefs then
		return TableUtil.Copy(PreferencesSchema.Defaults, true)
	end
	return TableUtil.Copy(prefs, true)
end

function PreferencesService:SetPreference(player: Player, category: string, key: string, value: any)
	local prefs = self._prefs[player]
	if not prefs then
		return false
	end

	local normalized = PreferencesSchema.NormalizeValue(category, key, value)
	if normalized == nil then
		return false
	end

	prefs[category] = prefs[category] or {}
	prefs[category][key] = normalized

	local playerDataService = self._playerDataService
	if playerDataService then
		playerDataService:UpdateProfile(player, function(profile)
			profile.Preferences = profile.Preferences or {}
			profile.Preferences[category] = profile.Preferences[category] or {}
			profile.Preferences[category][key] = normalized
		end, false)
	end

	return true
end

function PreferencesService:ResetPreferences(player: Player)
	local prefs = self._prefs[player]
	if not prefs then
		return false
	end

	local defaults = TableUtil.Copy(PreferencesSchema.Defaults, true)
	self._prefs[player] = defaults

	local playerDataService = self._playerDataService
	if playerDataService then
		playerDataService:UpdateProfile(player, function(profile)
			profile.Preferences = TableUtil.Copy(defaults, true)
		end, false)
	end

	return true
end

return PreferencesService
