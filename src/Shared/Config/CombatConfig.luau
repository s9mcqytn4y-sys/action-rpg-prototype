--!strict

export type CombatConfig = {
  Combo: {
    Punch1AnimationId: string,
    Punch1FadeTime: number,
    Punch1Weight: number,
    Punch1Speed: number,
    Punch1Priority: Enum.AnimationPriority,
    Punch1CooldownSec: number,
    Punch1LockMovementSec: number,
    Punch1HitFallbackSec: number,
  },
  Server: {
    RequestMinIntervalSec: number,
    RateLimit: {
      Capacity: number,
      RefillPerSec: number,
    },
  },
  Hitbox: {
    Size: Vector3,
    Offset: Vector3,
    MaxTargets: number,
    Damage: number,
    UseLineOfSight: boolean,
    Range: number,
  },
  AutoFace: {
    Enabled: boolean,
    TurnTimeSec: number,
    MaxAngleDeg: number,
  },
  CameraHit: {
    Enabled: boolean,
    Rotation: Vector3,
    Offset: Vector3,
    DecaySpeed: number,
  },
  Sfx: {
    Punch1: {
      SoundId: string,
      Volume: number,
      PlaybackSpeed: number,
      RollOffMaxDistance: number,
      EmitterSize: number,
    },
  },
  Vfx: {
    Punch1: {
      Enabled: boolean,
      Color: Color3,
      ParticleTexture: string,
      BurstCount: number,
      BeamEnabled: boolean,
      BeamTexture: string,
      BeamWidth0: number,
      BeamWidth1: number,
      BeamLength: number,
      SizeStart: Vector3,
      SizeEnd: Vector3,
      TransparencyStart: number,
      TransparencyEnd: number,
      Lifetime: number,
      Offset: Vector3,
      EmitOnAttack: boolean,
      EmitDelaySec: number,
    },
  },
}

local CombatConfig: CombatConfig = {
  Combo = {
    Punch1AnimationId = "rbxassetid://89357372979292",
    Punch1FadeTime = 0.12,
    Punch1Weight = 0.8,
    Punch1Speed = 1,
    Punch1Priority = Enum.AnimationPriority.Action,
    Punch1CooldownSec = 0.35,
    Punch1LockMovementSec = 0.3,
    Punch1HitFallbackSec = 0.18,
  },
  Server = {
    RequestMinIntervalSec = 0.1,
    RateLimit = {
      Capacity = 6,
      RefillPerSec = 6,
    },
  },
  Hitbox = {
    Size = Vector3.new(5.5, 4, 5.5),
    Offset = Vector3.new(0, 1.2, -3.1),
    MaxTargets = 3,
    Damage = 12,
    UseLineOfSight = true,
    Range = 7,
  },
  AutoFace = {
    Enabled = true,
    TurnTimeSec = 0.12,
    MaxAngleDeg = 75,
  },
  CameraHit = {
    Enabled = true,
    -- Rotation uses radians: Vector3.new(pitch, yaw, roll)
    Rotation = Vector3.new(math.rad(-6), math.rad(1.2), math.rad(1.5)),
    -- Offset is in camera local space (x=right, y=up, z=back)
    Offset = Vector3.new(0.05, 0.03, 0.35),
    DecaySpeed = 14,
  },
  Sfx = {
    Punch1 = {
      -- Replace with your own uploaded punch SFX if you want a different feel.
      SoundId = "rbxasset://sounds/swordhit.wav",
      Volume = 0.8,
      PlaybackSpeed = 1,
      RollOffMaxDistance = 90,
      EmitterSize = 8,
    },
  },
  Vfx = {
    Punch1 = {
      Enabled = true,
      Color = Color3.fromRGB(255, 255, 255),
      ParticleTexture = "rbxasset://textures/particles/sparkles_main.dds",
      BurstCount = 28,
      BeamEnabled = true,
      BeamTexture = "rbxasset://textures/particles/sparkles_main.dds",
      BeamWidth0 = 0.3,
      BeamWidth1 = 0,
      BeamLength = 2.4,
      SizeStart = Vector3.new(0.25, 0.25, 0.25),
      SizeEnd = Vector3.new(2, 2, 2),
      TransparencyStart = 0.1,
      TransparencyEnd = 1,
      Lifetime = 0.22,
      Offset = Vector3.new(0, 0, -1.0),
      EmitOnAttack = false,
      EmitDelaySec = 0,
    },
  },
}

return CombatConfig
