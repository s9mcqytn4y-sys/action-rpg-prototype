local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)
local RoactRodux = require(Packages:WaitForChild("Roact-Rodux") :: ModuleScript)

local parent = script.Parent
if not parent then
	error("ClientInit must be parented under StarterPlayerScripts")
end

if RunService:IsStudio() then
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Topbar, false)
	end)
end

local Controllers = parent:WaitForChild("Controllers") :: Folder
local State = parent:WaitForChild("State") :: Folder
local UI = parent:WaitForChild("UI") :: Folder

local store = require(State:WaitForChild("Store") :: ModuleScript)
local HUDApp = require(UI:WaitForChild("HUDApp") :: ModuleScript)

Knit.AddControllers(Controllers)

Knit.Start()
	:andThen(function()
		local player = Players.LocalPlayer
		if not player then
			Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
			player = Players.LocalPlayer
		end
		if not player then
			error("LocalPlayer not available")
		end

		local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

		local tree = Roact.createElement(RoactRodux.StoreProvider, {
			store = store,
		}, {
			App = Roact.createElement(HUDApp),
		})

		Roact.mount(tree, playerGui, "HUDApp")
	end)
	:catch(function(err)
		warn("Knit client failed to start", err)
	end)
