local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Rodux = require(Packages:WaitForChild("Rodux") :: ModuleScript)
local TableUtil = require(Packages:WaitForChild("TableUtil") :: ModuleScript)

local initialState = {
	Stamina = {
		current = 0,
		max = 100,
		state = "Idle",
	},
}

local reducer = Rodux.createReducer(initialState, {
	SetStamina = function(state, action)
		return TableUtil.Assign(state, {
			Stamina = {
				current = action.current,
				max = action.max,
				state = action.state or state.Stamina.state,
			},
		})
	end,
})

return reducer
