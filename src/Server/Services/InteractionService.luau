--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local InteractionConfig = require(Shared:WaitForChild("Config"):WaitForChild("InteractionConfig") :: ModuleScript)
local DebugConfig = require(Shared:WaitForChild("Config"):WaitForChild("DebugConfig") :: ModuleScript)
local Metrics = require(Shared:WaitForChild("Util"):WaitForChild("Metrics") :: ModuleScript)
local Tags = require(Shared:WaitForChild("Tags") :: ModuleScript)

type MetricsType = typeof(Metrics.new(false))
type JanitorType = typeof(Janitor.new())
type TagName = Tags.TagName

local InteractionService = Knit.CreateService({
	Name = "InteractionService",
})

local REMOTES_FOLDER_NAME = "Remotes"
local REMOTE_NAME = "InteractRequest"

local function ensureRemotesFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = REMOTES_FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

local function ensureRemoteEvent(folder: Folder): RemoteEvent
	local existing = folder:FindFirstChild(REMOTE_NAME)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = REMOTE_NAME
	remote.Parent = folder
	return remote
end

local function isValidInstance(instance: Instance?): boolean
	if not instance then
		return false
	end
	return instance:IsDescendantOf(game)
end

local function getTargetPosition(target: Instance): Vector3?
	if target:IsA("BasePart") then
		return target.Position
	end
	if target:IsA("Model") then
		local primary = target.PrimaryPart
		if primary then
			return primary.Position
		end
		local part = target:FindFirstChildWhichIsA("BasePart")
		if part then
			return part.Position
		end
	end
	return nil
end

local function hasInteractableTag(target: Instance, tagName: TagName): boolean
	if CollectionService:HasTag(target, tagName) then
		return true
	end
	return false
end

function InteractionService:KnitInit()
	self._janitor = Janitor.new()
	self._metrics = Metrics.new(DebugConfig.EnableMetrics)
	self._lastLogAt = 0
	self._cooldowns = {} :: { [Player]: number }
	self._remote = nil
end

function InteractionService:KnitStart()
	local remotesFolder = ensureRemotesFolder()
	local remote = ensureRemoteEvent(remotesFolder)
	self._remote = remote

	self._janitor:Add(remote.OnServerEvent:Connect(function(player, target)
		self:_handleRequest(player, target)
	end), "Disconnect")

	self._janitor:Add(Players.PlayerRemoving:Connect(function(player)
		self._cooldowns[player] = nil
	end), "Disconnect")
end

function InteractionService:_handleRequest(player: Player, target: Instance?)
	self._metrics:Increment("interactRequestCount", 1)

	if not isValidInstance(target) then
		return
	end
	if not hasInteractableTag(target :: Instance, Tags.Interactable) then
		return
	end

	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local position = getTargetPosition(target :: Instance)
	if not position then
		return
	end

	local distance = (root.Position - position).Magnitude
	if distance > InteractionConfig.Radius then
		return
	end

	if InteractionConfig.UseLineOfSightServer then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Blacklist
		params.FilterDescendantsInstances = { character }
		params.IgnoreWater = true

		local direction = position - root.Position
		local result = workspace:Raycast(root.Position, direction, params)
		if result and result.Instance then
			local hit = result.Instance
			local ok = (hit == target) or hit:IsDescendantOf(target :: Instance)
			if not ok then
				return
			end
		end
	end

	local last = self._cooldowns[player] or -math.huge
	local now = os.clock()
	if now - last < InteractionConfig.ServerCooldownSec then
		return
	end
	self._cooldowns[player] = now

	self._metrics:Increment("interactSuccessCount", 1)
	self:_logSnapshot("success")

	if self._remote then
		self._remote:FireClient(player, true, target)
	end
end

function InteractionService:_logSnapshot(reason: string)
	if not InteractionConfig.DebugEnabled then
		return
	end
	local now = os.clock()
	if now - self._lastLogAt < InteractionConfig.LogFrequencySec then
		return
	end
	self._lastLogAt = now

	print(("[Interact:%s] requests=%d success=%d"):format(
		reason,
		self._metrics:Get("interactRequestCount"),
		self._metrics:Get("interactSuccessCount")
	))
end

return InteractionService
