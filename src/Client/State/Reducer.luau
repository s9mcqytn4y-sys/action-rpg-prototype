local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Rodux = require(Packages:WaitForChild("Rodux") :: ModuleScript)
local TableUtil = require(Packages:WaitForChild("TableUtil") :: ModuleScript)

local initialState = {
	Stamina = {
		current = 0,
		max = 100,
	},
}

local reducer = Rodux.createReducer(initialState, {
	SetStamina = function(state, action)
		return TableUtil.Assign(state, {
			Stamina = {
				current = action.current,
				max = action.max,
			},
		})
	end,
})

return reducer
