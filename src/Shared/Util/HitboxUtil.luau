--!strict

export type HitTarget = {
	model: Model,
	humanoid: Humanoid,
	root: BasePart?,
}

local HitboxUtil = {}

local function getCharacterModel(part: BasePart): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	if model:FindFirstChildOfClass("Humanoid") then
		return model
	end
	return nil
end

function HitboxUtil.GetTargetsInBox(boxCFrame: CFrame, size: Vector3, params: OverlapParams, maxCount: number?): { HitTarget }
	local parts = workspace:GetPartBoundsInBox(boxCFrame, size, params)
	local results: { HitTarget } = {}
	local seen: { [Model]: boolean } = {}
	local limit = maxCount or math.huge

	for _, part in parts do
		if #results >= limit then
			break
		end
		if part and part:IsA("BasePart") then
			local model = getCharacterModel(part)
			if model and not seen[model] then
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
					table.insert(results, {
						model = model,
						humanoid = humanoid,
						root = root,
					})
					seen[model] = true
				end
			end
		end
	end

	return results
end

return HitboxUtil
