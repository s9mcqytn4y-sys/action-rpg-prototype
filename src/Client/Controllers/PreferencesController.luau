local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Signal = require(Packages:WaitForChild("Signal") :: ModuleScript)
local TableUtil = require(Packages:WaitForChild("TableUtil") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Config = Shared:WaitForChild("Config") :: Folder
local PreferencesSchema = require(Config:WaitForChild("PreferencesSchema") :: ModuleScript)

local PreferencesController = Knit.CreateController({
	Name = "PreferencesController",
})

function PreferencesController:KnitInit()
	self._prefs = TableUtil.Copy(PreferencesSchema.Defaults, true)
	self.Changed = Signal.new()
	self._pending = {}
	self._debounceToken = 0
end

function PreferencesController:KnitStart()
	self._service = Knit.GetService("PreferencesService")

	local ok, prefs = pcall(function()
		return self._service:GetPreferences()
	end)
	if ok and type(prefs) == "table" then
		self._prefs = TableUtil.Reconcile(prefs, PreferencesSchema.Defaults)
		self.Changed:Fire(self:GetPreferences())
	end
end

function PreferencesController:GetPreferences()
	return TableUtil.Copy(self._prefs, true)
end

function PreferencesController:GetPreference(category: string, key: string, fallback)
	local current = self._prefs[category]
	if current and current[key] ~= nil then
		return current[key]
	end
	local defaultValue = PreferencesSchema.GetDefault(category, key)
	if defaultValue ~= nil then
		return defaultValue
	end
	return fallback
end

function PreferencesController:SetPreference(category: string, key: string, value: any)
	local normalized = PreferencesSchema.NormalizeValue(category, key, value)
	if normalized == nil then
		return false
	end

	self._prefs[category] = self._prefs[category] or {}
	self._prefs[category][key] = normalized
	self.Changed:Fire(self:GetPreferences())

	if self._service then
		self._pending[category] = self._pending[category] or {}
		self._pending[category][key] = normalized
		self._debounceToken += 1
		local token = self._debounceToken
		task.delay(0.25, function()
			if token ~= self._debounceToken then
				return
			end
			for pendingCategory, entries in pairs(self._pending) do
				for pendingKey, pendingValue in pairs(entries) do
					self._service:SetPreference(pendingCategory, pendingKey, pendingValue)
				end
			end
			self._pending = {}
		end)
	end

	return true
end

function PreferencesController:ResetToDefaults()
	self._prefs = TableUtil.Copy(PreferencesSchema.Defaults, true)
	self.Changed:Fire(self:GetPreferences())

	if self._service and self._service.ResetPreferences then
		pcall(function()
			self._service:ResetPreferences()
		end)
	elseif self._service then
		for category, entries in pairs(self._prefs) do
			for key, value in pairs(entries) do
				self._service:SetPreference(category, key, value)
			end
		end
	end
end

return PreferencesController
