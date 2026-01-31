local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local ProfileStore = require(Packages:WaitForChild("ProfileStore") :: ModuleScript)
local Promise = require(Packages:WaitForChild("Promise") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)
local Signal = require(Packages:WaitForChild("Signal") :: ModuleScript)
local TableUtil = require(Packages:WaitForChild("TableUtil") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Config = Shared:WaitForChild("Config") :: Folder
local GameConfig = require(Config:WaitForChild("GameConfig") :: ModuleScript)

local servicesFolder = script.Parent
if not servicesFolder then
	error("PlayerDataService must be parented under Server/Services")
end

local serverFolder = servicesFolder.Parent
if not serverFolder then
	error("PlayerDataService must be parented under Server")
end

local modulesFolder = serverFolder:WaitForChild("Modules") :: Folder
local PlayerDataStore = require(modulesFolder:WaitForChild("PlayerDataStore") :: ModuleScript)

local PlayerDataService = Knit.CreateService({
	Name = "PlayerDataService",
	Client = {
		ProfileLoaded = Knit.CreateSignal(),
		ProfileUpdated = Knit.CreateSignal(),
	},
})

function PlayerDataService:KnitInit()
	self._profiles = {}
	self._janitors = {}
	self.ProfileLoaded = Signal.new()
	self.ProfileReleased = Signal.new()
	self._profileStore = ProfileStore.New(GameConfig.Profile.StoreName, PlayerDataStore.Template)
end

function PlayerDataService:KnitStart()
	Players.PlayerAdded:Connect(function(player)
		self:_loadProfile(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_releaseProfile(player)
	end)

	for _, player in Players:GetPlayers() do
		self:_loadProfile(player)
	end
end

function PlayerDataService:_loadProfile(player)
	local profileKey = GameConfig.Profile.KeyPrefix .. tostring(player.UserId)

	Promise.new(function(resolve, reject)
		local profile = self._profileStore:StartSessionAsync(profileKey, {
			Cancel = function()
				return not player:IsDescendantOf(Players)
			end,
		})

		if not profile then
			reject("Failed to load profile for " .. player.Name)
			return
		end

		profile:Reconcile()
		profile:AddUserId(player.UserId)
		resolve(profile)
	end)
		:andThen(function(profile)
			if not player:IsDescendantOf(Players) then
				profile:EndSession()
				return
			end

			local janitor = Janitor.new()
			self._janitors[player] = janitor
			self._profiles[player] = profile

			janitor:Add(profile.OnSessionEnd:Connect(function()
				self:_onSessionEnd(player)
			end), "Disconnect")

			local snapshot = TableUtil.Copy(profile.Data, true)
			self.ProfileLoaded:Fire(player, snapshot)
			self.Client.ProfileLoaded:Fire(player, snapshot)
		end)
		:catch(function(err)
			warn("[PlayerDataService] " .. tostring(err))
			if player:IsDescendantOf(Players) then
				player:Kick("Data failed to load. Please rejoin.")
			end
		end)
end

function PlayerDataService:_onSessionEnd(player)
	self._profiles[player] = nil

	local janitor = self._janitors[player]
	if janitor then
		janitor:Destroy()
		self._janitors[player] = nil
	end

	self.ProfileReleased:Fire(player)
end

function PlayerDataService:_releaseProfile(player)
	local profile = self._profiles[player]
	if profile then
		profile:EndSession()
	end

	self:_onSessionEnd(player)
end

function PlayerDataService:GetProfile(player)
	local profile = self._profiles[player]
	return profile and profile.Data or nil
end

function PlayerDataService:UpdateProfile(player, updater, broadcast)
	local profile = self._profiles[player]
	if not profile then
		return false
	end

	updater(profile.Data)

	if broadcast ~= false then
		local snapshot = TableUtil.Copy(profile.Data, true)
		self.Client.ProfileUpdated:Fire(player, snapshot)
	end

	return true
end

return PlayerDataService
