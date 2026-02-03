--!strict

local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)
local Janitor = require(Packages:WaitForChild("Janitor") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local CombatConfig = require(Shared:WaitForChild("Config"):WaitForChild("CombatConfig") :: ModuleScript)
local InputConfig = require(Shared:WaitForChild("Config"):WaitForChild("InputConfig") :: ModuleScript)
local SoundUtil = require(Shared:WaitForChild("Util"):WaitForChild("SoundUtil") :: ModuleScript)
local Tags = require(Shared:WaitForChild("Tags") :: ModuleScript)

local ClientRoot = script.Parent.Parent :: Folder
local StateFolder = ClientRoot:WaitForChild("State") :: Folder
local store = require(StateFolder:WaitForChild("Store") :: ModuleScript)
local VFXFolder = ClientRoot:WaitForChild("VFX") :: Folder
local CombatVFX = require(VFXFolder:WaitForChild("CombatVFX") :: ModuleScript)

local CombatController = Knit.CreateController({
  Name = "CombatController",
})

function CombatController:KnitInit()
  self._janitor = Janitor.new()
  self._bindings = Janitor.new()
  self._service = nil
  self._lifecycle = nil
  self._thirdPerson = nil
  self._animator = nil
  self._animation = nil
  self._track = nil
  self._markerConn = nil
  self._lastAttackAt = -math.huge
  self._pendingHitToken = 0
  self._hitSentToken = 0
  self._movementLockUntil = 0
  self._movementLockToken = 0
  self._movementLocked = false
  self._savedWalkSpeed = nil
  self._lockedHumanoid = nil
  self._faceTween = nil
end

function CombatController:KnitStart()
  self._service = Knit.GetService("CombatService")
  local okLifecycle, lifecycle = pcall(function()
    return Knit.GetController("CharacterLifecycleController")
  end)
  if okLifecycle and lifecycle then
    self._lifecycle = lifecycle
  end
  local okThird, third = pcall(function()
    return Knit.GetController("ThirdPersonController")
  end)
  if okThird and third then
    self._thirdPerson = third
  end

  local player = Players.LocalPlayer
  if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
  end
  if player then
    self._janitor:Add(
      player.CharacterAdded:Connect(function()
        self:_resetAnimation()
        self:_clearMovementLock()
      end),
      "Disconnect"
    )
    self._janitor:Add(
      player.CharacterRemoving:Connect(function()
        self:_resetAnimation()
        self:_clearMovementLock()
      end),
      "Disconnect"
    )
    if player.Character then
      self:_resetAnimation()
    end
  end
  self:_bindInput()
end

function CombatController:_bindInput()
  self._bindings:Cleanup()
  self._bindings:Add(function()
    ContextActionService:UnbindAction("CombatHit")
  end)

  local inputList = { Enum.UserInputType.MouseButton1, InputConfig.Combat.GamepadAttack }

  ContextActionService:BindAction("CombatHit", function(_, inputState)
    if inputState ~= Enum.UserInputState.Begin then
      return Enum.ContextActionResult.Pass
    end
    self:RequestAttack()
    return Enum.ContextActionResult.Sink
  end, false, table.unpack(inputList))
end

function CombatController:RequestAttack()
  local okMenu, menuOpen = pcall(function()
    local state = store:getState()
    return state and state.UI and state.UI.MenuOpen == true
  end)
  if okMenu and menuOpen then
    return
  end

  self:_requestHit()
end

function CombatController:_requestHit()
  local now = os.clock()
  local cooldown = CombatConfig.Combo.Punch1CooldownSec
  if cooldown > 0 and (now - self._lastAttackAt) < cooldown then
    return
  end
  self._lastAttackAt = now
  self:_playPunch1()
end

function CombatController:_emitHit(token: number)
  if token <= 0 then
    return
  end
  if self._hitSentToken == token then
    return
  end
  self._hitSentToken = token
  local service = self._service
  if not service then
    return
  end
  local ok, result = pcall(function()
    return service:RequestHit()
  end)
  if not ok then
    return
  end

  if type(result) == "table" and (result :: any).andThen then
    -- Knit promise
    (result :: any):andThen(function(success)
      if success == true or (type(success) == "table" and success[1] == true) then
        self:_playHitFeedback()
      end
    end)
    return
  end

  if result == true then
    self:_playHitFeedback()
  elseif type(result) == "table" then
    local success = result[1] == true or result.success == true
    if success then
      self:_playHitFeedback()
    end
  end
end

function CombatController:_playPunch1()
  local track = self:_ensureTrack()
  if not track then
    return
  end
  local config = CombatConfig.Combo
  if track.IsPlaying then
    track:Stop(0)
  end
  track:Play(config.Punch1FadeTime, config.Punch1Weight, config.Punch1Speed)
  self:_lockMovement(config.Punch1LockMovementSec)

  local vfxConfig = CombatConfig.Vfx.Punch1
  if vfxConfig and vfxConfig.Enabled == true and vfxConfig.EmitOnAttack == true then
    local delaySec = math.max(0, vfxConfig.EmitDelaySec or 0)
    if delaySec == 0 then
      self:_playPunchVfx()
    else
      task.delay(delaySec, function()
        self:_playPunchVfx()
      end)
    end
  end

  self._pendingHitToken += 1
  local token = self._pendingHitToken
  local fallback = config.Punch1HitFallbackSec
  if fallback and fallback > 0 then
    task.delay(fallback, function()
      if self._pendingHitToken ~= token then
        return
      end
      self:_emitHit(token)
    end)
  end
end

function CombatController:_applyCameraHit()
  local thirdPerson = self._thirdPerson
  if not thirdPerson or not thirdPerson.AddCameraImpulse then
    return
  end
  local cameraConfig = CombatConfig.CameraHit
  if not cameraConfig or cameraConfig.Enabled ~= true then
    return
  end
  thirdPerson:AddCameraImpulse(cameraConfig.Rotation, cameraConfig.Offset, cameraConfig.DecaySpeed)
end

function CombatController:_playHitFeedback()
  self:_faceNearestEnemy()
  self:_applyCameraHit()
  self:_playPunchSfx()
  local vfxConfig = CombatConfig.Vfx.Punch1
  if not vfxConfig or vfxConfig.EmitOnAttack ~= true then
    self:_playPunchVfx()
  end
end

function CombatController:_playPunchSfx()
  local config = CombatConfig.Sfx.Punch1
  if not config or type(config.SoundId) ~= "string" or config.SoundId == "" then
    return
  end

  local soundGroup = SoundService:FindFirstChild("SFX")
  if soundGroup and not soundGroup:IsA("SoundGroup") then
    soundGroup = nil
  end

  local origin = self:_getAttackOriginPart()
  SoundUtil.PlayOneShot(config.SoundId, {
    volume = config.Volume,
    playbackSpeed = config.PlaybackSpeed,
    rollOffMaxDistance = config.RollOffMaxDistance,
    emitterSize = config.EmitterSize,
    soundGroup = soundGroup :: SoundGroup?,
    parent = origin,
  })
end

function CombatController:_playPunchVfx()
  local origin = self:_getAttackOriginPart()
  CombatVFX.PlayPunch(origin, CombatConfig.Vfx.Punch1)
end

function CombatController:_resetAnimation()
  self:_clearTrack()
  self._animator = nil
end

function CombatController:_clearTrack()
  local track = self._track
  if track then
    track:Stop(0)
    track:Destroy()
  end
  local markerConn = self._markerConn
  if markerConn then
    markerConn:Disconnect()
    self._markerConn = nil
  end
  local animation = self._animation
  if animation then
    animation:Destroy()
  end
  self._track = nil
  self._animation = nil
end

function CombatController:_ensureTrack(): AnimationTrack?
  local animator = self:_getAnimator()
  if not animator then
    self:_clearTrack()
    self._animator = nil
    return nil
  end

  if self._animator ~= animator then
    self:_clearTrack()
    self._animator = animator
  end

  if self._track then
    return self._track
  end

  local animation = Instance.new("Animation")
  animation.AnimationId = CombatConfig.Combo.Punch1AnimationId
  local track = animator:LoadAnimation(animation)
  track.Priority = CombatConfig.Combo.Punch1Priority
  self._markerConn = track:GetMarkerReachedSignal("hit"):Connect(function()
    self:_emitHit(self._pendingHitToken)
  end)

  self._animation = animation
  self._track = track
  return track
end

function CombatController:_getAnimator(): Animator?
  if self._lifecycle and self._lifecycle.GetState then
    local state = self._lifecycle:GetState()
    if state and state.animator then
      return state.animator
    end
  end

  local player = Players.LocalPlayer
  local character = player and player.Character or nil
  if not character then
    return nil
  end
  local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
  if not humanoid then
    return nil
  end
  local animator = humanoid:FindFirstChildOfClass("Animator") :: Animator?
  if not animator then
    animator = Instance.new("Animator")
    animator.Parent = humanoid
  end
  return animator
end

function CombatController:_getHumanoid(): Humanoid?
  if self._lifecycle and self._lifecycle.GetState then
    local state = self._lifecycle:GetState()
    if state and state.humanoid then
      return state.humanoid
    end
  end

  local player = Players.LocalPlayer
  local character = player and player.Character or nil
  if not character then
    return nil
  end
  return character:FindFirstChildOfClass("Humanoid") :: Humanoid?
end

function CombatController:_getRootPart(): BasePart?
  if self._lifecycle and self._lifecycle.GetState then
    local state = self._lifecycle:GetState()
    if state and state.root then
      return state.root
    end
  end

  local player = Players.LocalPlayer
  local character = player and player.Character or nil
  if not character then
    return nil
  end
  return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function CombatController:_getEnemyRoot(target: Instance): BasePart?
  if target:IsA("Model") then
    local root = target:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
      return root
    end
    local part = target:FindFirstChildWhichIsA("BasePart")
    if part then
      return part
    end
  elseif target:IsA("BasePart") then
    return target
  end
  return nil
end

function CombatController:_findNearestEnemy(): BasePart?
  local root = self:_getRootPart()
  if not root then
    return nil
  end

  local config = CombatConfig.Hitbox
  local range = math.max(0, config.Range)
  local best = nil
  local bestDist = math.huge
  local origin = root.Position

  for _, candidate in CollectionService:GetTagged(Tags.Enemy) do
    if candidate and candidate:IsDescendantOf(workspace) then
      local enemyRoot = self:_getEnemyRoot(candidate)
      if enemyRoot then
        local dist = (enemyRoot.Position - origin).Magnitude
        if dist <= range and dist < bestDist then
          best = enemyRoot
          bestDist = dist
        end
      end
    end
  end

  return best
end

function CombatController:_faceNearestEnemy()
  local config = CombatConfig.AutoFace
  if not config or config.Enabled ~= true then
    return
  end
  local root = self:_getRootPart()
  if not root then
    return
  end

  local targetRoot = self:_findNearestEnemy()
  if not targetRoot then
    return
  end

  local origin = root.Position
  local targetPos = targetRoot.Position
  local flatTarget = Vector3.new(targetPos.X, origin.Y, targetPos.Z)
  local desired = CFrame.new(origin, flatTarget)

  local currentLook = root.CFrame.LookVector
  local desiredLook = desired.LookVector
  local dot = math.clamp(currentLook:Dot(desiredLook), -1, 1)
  local angleDeg = math.deg(math.acos(dot))
  if angleDeg > config.MaxAngleDeg then
    return
  end

  if self._faceTween then
    self._faceTween:Cancel()
    self._faceTween = nil
  end
  local tween = TweenService:Create(root, TweenInfo.new(config.TurnTimeSec, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    CFrame = desired,
  })
  self._faceTween = tween
  tween:Play()
end

function CombatController:_getAttackOriginPart(): BasePart?
  local player = Players.LocalPlayer
  local character = player and player.Character or nil
  if self._lifecycle and self._lifecycle.GetState then
    local state = self._lifecycle:GetState()
    if state and state.character then
      character = state.character
    end
  end
  if character then
    local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if hand and hand:IsA("BasePart") then
      return hand
    end
  end
  return self:_getRootPart()
end

function CombatController:_lockMovement(durationSec: number)
  if durationSec <= 0 then
    return
  end
  local humanoid = self:_getHumanoid()
  if not humanoid then
    return
  end

  local now = os.clock()
  local untilTime = now + durationSec
  if untilTime > self._movementLockUntil then
    self._movementLockUntil = untilTime
  end
  if self._movementLocked then
    return
  end

  self._movementLocked = true
  self._savedWalkSpeed = humanoid.WalkSpeed
  self._lockedHumanoid = humanoid
  humanoid.WalkSpeed = 0

  self._movementLockToken += 1
  local token = self._movementLockToken
  task.spawn(function()
    while os.clock() < self._movementLockUntil do
      local current = self._lockedHumanoid
      if current and current.Parent then
        current.WalkSpeed = 0
        pcall(function()
          current:Move(Vector3.zero, true)
        end)
      end
      task.wait(0.02)
    end
    if self._movementLockToken ~= token then
      return
    end
    self._movementLocked = false
    self._movementLockUntil = 0
    local locked = self._lockedHumanoid
    if locked and locked.Parent then
      locked.WalkSpeed = self._savedWalkSpeed or locked.WalkSpeed
    end
    self._savedWalkSpeed = nil
    self._lockedHumanoid = nil
  end)
end

function CombatController:_clearMovementLock()
  self._movementLockToken += 1
  self._movementLockUntil = 0
  self._movementLocked = false
  local locked = self._lockedHumanoid
  if locked and locked.Parent then
    locked.WalkSpeed = self._savedWalkSpeed or locked.WalkSpeed
  end
  self._savedWalkSpeed = nil
  self._lockedHumanoid = nil
end

return CombatController
