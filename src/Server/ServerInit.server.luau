local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)

local parent = script.Parent
if not parent then
	error("ServerInit must be parented under ServerScriptService")
end

local Services = parent:WaitForChild("Services") :: Folder

-- Prefer R6 but avoid hard failure if property isn't available in this place/version.
local okRig = pcall(function()
	StarterPlayer.CharacterRigType = Enum.HumanoidRigType.R6
end)
if not okRig then
	pcall(function()
		StarterPlayer.CharacterAppearance = "R6"
	end)
end

Knit.AddServices(Services)

Knit.Start():catch(function(err)
	warn("Knit failed to start", err)
end)
