--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Rodux = require(Packages:WaitForChild("Rodux") :: ModuleScript)
local TableUtil = require(Packages:WaitForChild("TableUtil") :: ModuleScript)

type StaminaState = {
	current: number,
	max: number,
	state: string,
}

type ViewportState = {
	size: Vector2,
	shortSide: number,
	longSide: number,
	className: string,
	scale: number,
}

type UIState = {
	Viewport: ViewportState,
	MenuOpen: boolean,
}

local initialStamina: StaminaState = {
	current = 0,
	max = 100,
	state = "Idle",
}

local initialUI: UIState = {
	Viewport = {
		size = Vector2.new(0, 0),
		shortSide = 0,
		longSide = 0,
		className = "Desktop",
		scale = 1,
	},
	MenuOpen = false,
}

local staminaReducer = Rodux.createReducer(initialStamina, {
	SetStamina = function(state: StaminaState, action)
		return TableUtil.Assign(state, {
			current = action.current,
			max = action.max,
			state = action.state or state.state,
		})
	end,
})

local uiReducer = Rodux.createReducer(initialUI, {
	SetViewport = function(state: UIState, action)
		return TableUtil.Assign(state, {
			Viewport = {
				size = action.size,
				shortSide = action.shortSide,
				longSide = action.longSide,
				className = action.className,
				scale = action.scale,
			},
		})
	end,
	SetMenuOpen = function(state: UIState, action)
		return TableUtil.Assign(state, {
			MenuOpen = action.isOpen == true,
		})
	end,
})

return Rodux.combineReducers({
	Stamina = staminaReducer,
	UI = uiReducer,
})
