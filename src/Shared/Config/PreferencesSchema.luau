--!strict

export type PreferenceField = {
	Default: any,
	Min: number?,
	Max: number?,
	Step: number?,
	Type: "number" | "boolean" | "string",
}

export type PreferencesSchema = {
	Sound: {
		Master: PreferenceField,
		Music: PreferenceField,
		SFX: PreferenceField,
	},
	Camera: {
		Sensitivity: PreferenceField,
		InvertY: PreferenceField,
		Fov: PreferenceField,
	},
	Display: {
		ShowDamageText: PreferenceField,
		ShowVfx: PreferenceField,
	},
	Controls: {
		HoldSprint: PreferenceField,
	},
}

local PreferencesSchema: PreferencesSchema = {
	Sound = {
		Master = { Default = 0.85, Min = 0, Max = 1, Step = 0.01, Type = "number" },
		Music = { Default = 0.6, Min = 0, Max = 1, Step = 0.01, Type = "number" },
		SFX = { Default = 0.75, Min = 0, Max = 1, Step = 0.01, Type = "number" },
	},
	Camera = {
		Sensitivity = { Default = 0.0020, Min = 0.001, Max = 0.008, Step = 0.0001, Type = "number" },
		InvertY = { Default = false, Type = "boolean" },
		Fov = { Default = 70, Min = 60, Max = 80, Step = 1, Type = "number" },
	},
	Display = {
		ShowDamageText = { Default = true, Type = "boolean" },
		ShowVfx = { Default = true, Type = "boolean" },
	},
	Controls = {
		HoldSprint = { Default = true, Type = "boolean" },
	},
}

local function clampNumber(value: number, field: PreferenceField): number
	local min = field.Min
	local max = field.Max
	if min and max then
		return math.clamp(value, min, max)
	end
	if min then
		return math.max(min, value)
	end
	if max then
		return math.min(max, value)
	end
	return value
end

local function getDefault(category: string, key: string): any
	local categorySchema = (PreferencesSchema :: any)[category]
	if not categorySchema then
		return nil
	end
	local field = categorySchema[key]
	if not field then
		return nil
	end
	return field.Default
end

local function normalizeValue(category: string, key: string, value: any): any
	local categorySchema = (PreferencesSchema :: any)[category]
	if not categorySchema then
		return nil
	end
	local field: PreferenceField? = categorySchema[key]
	if not field then
		return nil
	end

	if field.Type == "number" then
		local numberValue = if type(value) == "number" then value else tonumber(value)
		if numberValue == nil then
			return field.Default
		end
		return clampNumber(numberValue, field)
	end
	if field.Type == "boolean" then
		if type(value) == "boolean" then
			return value
		end
		return field.Default
	end
	if field.Type == "string" then
		if type(value) == "string" then
			return value
		end
		return field.Default
	end

	return field.Default
end

local defaults = {
	Sound = {
		Master = PreferencesSchema.Sound.Master.Default,
		Music = PreferencesSchema.Sound.Music.Default,
		SFX = PreferencesSchema.Sound.SFX.Default,
	},
	Camera = {
		Sensitivity = PreferencesSchema.Camera.Sensitivity.Default,
		InvertY = PreferencesSchema.Camera.InvertY.Default,
		Fov = PreferencesSchema.Camera.Fov.Default,
	},
	Display = {
		ShowDamageText = PreferencesSchema.Display.ShowDamageText.Default,
		ShowVfx = PreferencesSchema.Display.ShowVfx.Default,
	},
	Controls = {
		HoldSprint = PreferencesSchema.Controls.HoldSprint.Default,
	},
}

return {
	Schema = PreferencesSchema,
	Defaults = defaults,
	GetDefault = getDefault,
	NormalizeValue = normalizeValue,
}
