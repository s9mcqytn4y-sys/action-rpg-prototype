local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Rodux = require(Packages:WaitForChild("Rodux") :: ModuleScript)

local Actions = {}

Actions.SetStamina = Rodux.makeActionCreator("SetStamina", function(current, max)
	return {
		current = current,
		max = max,
	}
end)

return Actions
