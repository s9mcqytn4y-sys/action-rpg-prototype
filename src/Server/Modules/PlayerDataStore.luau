local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local TableUtil = require(Packages:WaitForChild("TableUtil") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Config = Shared:WaitForChild("Config") :: Folder
local GameConfig = require(Config:WaitForChild("GameConfig") :: ModuleScript)

local PlayerDataStore = {}

PlayerDataStore.Template = {
	Level = 1,
	XP = 0,
	Gold = 0,
	Stamina = {
		Current = GameConfig.Stamina.Max,
	},
}

function PlayerDataStore:CloneTemplate()
	return TableUtil.Copy(self.Template, true)
end

function PlayerDataStore:Reconcile(data)
	return TableUtil.Reconcile(data, self.Template)
end

return PlayerDataStore
