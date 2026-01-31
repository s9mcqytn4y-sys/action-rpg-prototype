--!strict

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local DebugConfig = require(Shared:WaitForChild("Config"):WaitForChild("DebugConfig") :: ModuleScript)
local Metrics = require(Shared:WaitForChild("Util"):WaitForChild("Metrics") :: ModuleScript)
local Tags = require(Shared:WaitForChild("Tags") :: ModuleScript)

type TagName = Tags.TagName

local TagService = Knit.CreateService({
	Name = "TagService",
})

local function isValidInstance(instance: Instance?): boolean
	if not instance then
		return false
	end
	return instance:IsDescendantOf(game)
end

function TagService:KnitInit()
	self._janitor = Janitor.new()
	self._metrics = Metrics.new(DebugConfig.EnableMetrics)
	self._counts = {} :: { [TagName]: number }
	self._lastLogAt = 0
end

function TagService:KnitStart()
	if not RunService:IsServer() then
		if DebugConfig.LogWarnings then
			warn("TagService started outside server context")
		end
		return
	end

	for _, tagName in Tags.List do
		local tagged = CollectionService:GetTagged(tagName)
		self._counts[tagName] = #tagged
	end

	for _, tagName in Tags.List do
		self._janitor:Add(CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance)
			self:_onTaggedAdded(tagName, instance)
		end), "Disconnect")

		self._janitor:Add(CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(instance)
			self:_onTaggedRemoved(tagName, instance)
		end), "Disconnect")
	end

	self:_logSnapshot("init")
end

function TagService:Tag(instance: Instance?, tagName: string): boolean
	if not RunService:IsServer() then
		return false
	end
	if not isValidInstance(instance) then
		if DebugConfig.LogWarnings then
			warn("TagService.Tag called with invalid instance")
		end
		return false
	end
	if not Tags.IsValid(tagName) then
		if DebugConfig.LogWarnings then
			warn(("TagService.Tag invalid tag name: %s"):format(tagName))
		end
		return false
	end
	CollectionService:AddTag(instance :: Instance, tagName)
	return true
end

function TagService:Untag(instance: Instance?, tagName: string): boolean
	if not RunService:IsServer() then
		return false
	end
	if not isValidInstance(instance) then
		if DebugConfig.LogWarnings then
			warn("TagService.Untag called with invalid instance")
		end
		return false
	end
	if not Tags.IsValid(tagName) then
		if DebugConfig.LogWarnings then
			warn(("TagService.Untag invalid tag name: %s"):format(tagName))
		end
		return false
	end
	CollectionService:RemoveTag(instance :: Instance, tagName)
	return true
end

function TagService:_onTaggedAdded(tagName: TagName, instance: Instance)
	if not isValidInstance(instance) then
		return
	end
	self._counts[tagName] = (self._counts[tagName] or 0) + 1
	self._metrics:Increment(("TagAdded.%s"):format(tagName))
	self:_logSnapshot("add")
end

function TagService:_onTaggedRemoved(tagName: TagName, instance: Instance)
	if not isValidInstance(instance) then
		return
	end
	self._counts[tagName] = math.max((self._counts[tagName] or 1) - 1, 0)
	self._metrics:Increment(("TagRemoved.%s"):format(tagName))
	self:_logSnapshot("remove")
end

function TagService:_logSnapshot(reason: string)
	if not DebugConfig.TagsEnabled then
		return
	end
	local now = os.clock()
	if now - self._lastLogAt < DebugConfig.TagsLogFrequencySec then
		return
	end
	self._lastLogAt = now

	local parts = {}
	for _, tagName in Tags.List do
		table.insert(parts, ("%s=%d"):format(tagName, self._counts[tagName] or 0))
	end
	print(("[TagService:%s] %s"):format(reason, table.concat(parts, ", ")))
end

return TagService
