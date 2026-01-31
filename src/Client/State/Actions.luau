local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Rodux = require(Packages:WaitForChild("Rodux") :: ModuleScript)

local Actions = {}

Actions.SetStamina = Rodux.makeActionCreator("SetStamina", function(current, max, state)
	return {
		current = current,
		max = max,
		state = state,
	}
end)

return Actions
