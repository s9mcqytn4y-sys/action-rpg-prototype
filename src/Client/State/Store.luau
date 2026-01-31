local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Rodux = require(Packages:WaitForChild("Rodux") :: ModuleScript)

local reducer = require(script.Parent:WaitForChild("Reducer") :: ModuleScript)

local store = Rodux.Store.new(reducer)

return store
