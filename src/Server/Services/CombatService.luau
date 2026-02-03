--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local CombatConfig = require(Shared:WaitForChild("Config"):WaitForChild("CombatConfig") :: ModuleScript)
local HitboxUtil = require(Shared:WaitForChild("Util"):WaitForChild("HitboxUtil") :: ModuleScript)
local Tags = require(Shared:WaitForChild("Tags") :: ModuleScript)

local CombatService = Knit.CreateService({
  Name = "CombatService",
  Client = {},
})

function CombatService:KnitInit()
  self._lastHitAt = {}
  self._rateState = {}
end

function CombatService:KnitStart()
  Players.PlayerRemoving:Connect(function(player)
    self._lastHitAt[player] = nil
    self._rateState[player] = nil
  end)
end

function CombatService.Client:RequestHit(player: Player)
  return self.Server:_requestHit(player)
end

local function isAlive(player: Player): boolean
  local character = player.Character
  if not character then
    return false
  end
  if not character:IsDescendantOf(workspace) then
    return false
  end
  local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
  if not humanoid then
    return false
  end
  return humanoid.Health > 0
end

function CombatService:_requestHit(player: Player)
  if not player or not player.Parent then
    return false
  end
  if not isAlive(player) then
    return false
  end

  local now = os.clock()
  local rate = self._rateState[player]
  if not rate then
    rate = {
      tokens = CombatConfig.Server.RateLimit.Capacity,
      lastRefill = now,
      lastRequest = -math.huge,
    }
    self._rateState[player] = rate
  end

  local minInterval = CombatConfig.Server.RequestMinIntervalSec
  if minInterval > 0 and (now - rate.lastRequest) < minInterval then
    return false
  end
  rate.lastRequest = now

  local elapsed = math.max(0, now - rate.lastRefill)
  if elapsed > 0 then
    local refill = elapsed * CombatConfig.Server.RateLimit.RefillPerSec
    rate.tokens = math.min(CombatConfig.Server.RateLimit.Capacity, rate.tokens + refill)
    rate.lastRefill = now
  end
  if rate.tokens < 1 then
    return false
  end
  rate.tokens -= 1

  local last = self._lastHitAt[player] or -math.huge
  local cooldown = CombatConfig.Combo.Punch1CooldownSec
  if cooldown > 0 and (now - last) < cooldown then
    return false
  end
  self._lastHitAt[player] = now

  local character = player.Character
  if not character then
    return false
  end
  local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
  if not root then
    return false
  end

  local hitbox = CombatConfig.Hitbox
  local boxCFrame = root.CFrame * CFrame.new(hitbox.Offset)
  local params = OverlapParams.new()
  params.FilterType = Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances = { character }
  params.RespectCanCollide = false

  local targets = HitboxUtil.GetTargetsInBox(boxCFrame, hitbox.Size, params, hitbox.MaxTargets)
  local hitCount = 0
  for _, target in targets do
    local humanoid = target.humanoid
    if humanoid and humanoid.Health > 0 then
      local model = target.model
      if CollectionService:HasTag(model, Tags.Enemy) then
        if hitbox.Range > 0 then
          local targetRoot = target.root
          if targetRoot then
            local dist = (targetRoot.Position - root.Position).Magnitude
            if dist > hitbox.Range then
              continue
            end
          end
        end

        if hitbox.UseLineOfSight and target.root then
          local rayParams = RaycastParams.new()
          rayParams.FilterType = Enum.RaycastFilterType.Exclude
          rayParams.FilterDescendantsInstances = { character }
          rayParams.IgnoreWater = true
          local dir = target.root.Position - root.Position
          local result = workspace:Raycast(root.Position, dir, rayParams)
          if result and result.Instance and not result.Instance:IsDescendantOf(model) then
            continue
          end
        end

        humanoid:TakeDamage(hitbox.Damage)
        hitCount += 1
      end
    end
  end

  return hitCount > 0, hitCount
end

return CombatService
