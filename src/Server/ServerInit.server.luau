local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)

local parent = script.Parent
if not parent then
	error("ServerInit must be parented under ServerScriptService")
end

local Services = parent:WaitForChild("Services") :: Folder

Knit.AddServices(Services)

Knit.Start():catch(function(err)
	warn("Knit failed to start", err)
end)
