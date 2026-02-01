--!strict

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

Actions.SetViewport = Rodux.makeActionCreator("SetViewport", function(size, className, shortSide, longSide, scale)
	return {
		size = size,
		className = className,
		shortSide = shortSide,
		longSide = longSide,
		scale = scale,
	}
end)

Actions.SetMenuOpen = Rodux.makeActionCreator("SetMenuOpen", function(isOpen)
	return {
		isOpen = isOpen == true,
	}
end)

return Actions
