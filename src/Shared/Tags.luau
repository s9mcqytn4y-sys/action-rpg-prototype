--!strict

export type TagName = "Interactable" | "Enemy" | "Loot" | "SpawnPoint"

export type TagMap = {
	Interactable: TagName,
	Enemy: TagName,
	Loot: TagName,
	SpawnPoint: TagName,
}

local Tags: TagMap & {
	List: { TagName },
	IsValid: (value: string) -> boolean,
} = {
	Interactable = "Interactable",
	Enemy = "Enemy",
	Loot = "Loot",
	SpawnPoint = "SpawnPoint",
	List = {} :: { TagName },
	IsValid = function(_value: string): boolean
		return false
	end,
}

Tags.List = {
	Tags.Interactable,
	Tags.Enemy,
	Tags.Loot,
	Tags.SpawnPoint,
}

function Tags.IsValid(value: string): boolean
	for _, tag in Tags.List do
		if tag == value then
			return true
		end
	end
	return false
end

return Tags
