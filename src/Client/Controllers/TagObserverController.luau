--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local DebugConfig = require(Shared:WaitForChild("Config"):WaitForChild("DebugConfig") :: ModuleScript)
local Metrics = require(Shared:WaitForChild("Util"):WaitForChild("Metrics") :: ModuleScript)
local Tags = require(Shared:WaitForChild("Tags") :: ModuleScript)

type TagName = Tags.TagName
type TagSet = { [Instance]: boolean }
type TagRegistry = { [TagName]: TagSet }
type JanitorType = typeof(Janitor.new())
type TagJanitors = { [TagName]: { [Instance]: JanitorType } }

local TagObserverController = Knit.CreateController({
	Name = "TagObserverController",
})

function TagObserverController:KnitInit()
	self._janitor = Janitor.new()
	self._registry = {} :: TagRegistry
	self._instanceJanitors = {} :: TagJanitors
	self._metrics = Metrics.new(DebugConfig.EnableMetrics)
	self._lastLogAt = 0

	for _, tagName in Tags.List do
		self._registry[tagName] = {}
		self._instanceJanitors[tagName] = {}
	end
end

function TagObserverController:KnitStart()
	for _, tagName in Tags.List do
		local tagged = CollectionService:GetTagged(tagName)
		for _, instance in tagged do
			self:_register(tagName, instance)
		end

		self._janitor:Add(CollectionService:GetInstanceAddedSignal(tagName):Connect(function(instance)
			self:_onAdded(tagName, instance)
		end), "Disconnect")

		self._janitor:Add(CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(instance)
			self:_onRemoved(tagName, instance)
		end), "Disconnect")
	end

	self:_logSnapshot("init")
end

function TagObserverController:GetTagged(tagName: TagName): { Instance }
	local set = self._registry[tagName]
	local result = {}
	for instance, _ in pairs(set) do
		table.insert(result, instance)
	end
	return result
end

function TagObserverController:HasTag(instance: Instance, tagName: TagName): boolean
	local set = self._registry[tagName]
	return set[instance] == true
end

function TagObserverController:_onAdded(tagName: TagName, instance: Instance)
	self:_register(tagName, instance)
end

function TagObserverController:_onRemoved(tagName: TagName, instance: Instance)
	self:_unregister(tagName, instance)
end

function TagObserverController:_register(tagName: TagName, instance: Instance)
	if not instance then
		return
	end
	local set = self._registry[tagName]
	if set[instance] then
		return
	end
	set[instance] = true

	local janitorsForTag = self._instanceJanitors[tagName]
	local existing = janitorsForTag[instance]
	if existing then
		existing:Cleanup()
		existing:Destroy()
	end

	local janitor = Janitor.new()
	janitorsForTag[instance] = janitor
	janitor:Add(instance.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			self:_unregister(tagName, instance)
		end
	end), "Disconnect")

	self._metrics:Increment(("TagAdded.%s"):format(tagName))
	self:_logSnapshot("add")
end

function TagObserverController:_unregister(tagName: TagName, instance: Instance)
	if not instance then
		return
	end
	local set = self._registry[tagName]
	if not set[instance] then
		return
	end
	set[instance] = nil

	local janitorsForTag = self._instanceJanitors[tagName]
	local janitor = janitorsForTag[instance]
	if janitor then
		janitor:Destroy()
		janitorsForTag[instance] = nil
	end

	self._metrics:Increment(("TagRemoved.%s"):format(tagName))
	self:_logSnapshot("remove")
end

function TagObserverController:_logSnapshot(reason: string)
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
		local count = 0
		for _, _ in pairs(self._registry[tagName]) do
			count += 1
		end
		table.insert(parts, ("%s=%d"):format(tagName, count))
	end
	print(("[TagObserver:%s] %s"):format(reason, table.concat(parts, ", ")))
end

return TagObserverController
