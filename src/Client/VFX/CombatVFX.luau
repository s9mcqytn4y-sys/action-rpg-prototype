--!strict

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

export type PunchVfxConfig = {
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
}

local CombatVFX = {}

function CombatVFX.PlayPunch(root: BasePart?, config: PunchVfxConfig)
  if not root or not root.Parent then
    return
  end
  if not config or config.Enabled ~= true then
    return
  end

  local cf = root.CFrame * CFrame.new(config.Offset)

  local part = Instance.new("Part")
  part.Name = "PunchVFX"
  part.Anchored = true
  part.CanCollide = false
  part.CanQuery = false
  part.CanTouch = false
  part.Material = Enum.Material.Neon
  part.Color = config.Color
  part.Transparency = math.clamp(config.TransparencyStart, 0, 1)
  part.Size = config.SizeStart
  part.Shape = Enum.PartType.Ball
  part.CFrame = cf
  part.Parent = Workspace

  -- Burst particles (uses built-in texture path by default).
  local texture = config.ParticleTexture
  if type(texture) == "string" and texture ~= "" then
    local attachment = Instance.new("Attachment")
    attachment.Name = "PunchVFX_Attachment"
    attachment.Parent = part

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "PunchBurst"
    emitter.Texture = texture
    emitter.Color = ColorSequence.new(config.Color)
    emitter.LightEmission = 0.85
    emitter.Lifetime = NumberRange.new(math.max(0.08, config.Lifetime * 0.6), math.max(0.12, config.Lifetime))
    emitter.Speed = NumberRange.new(6, 12)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Rate = 0
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-180, 180)
    emitter.Size = NumberSequence.new({
      NumberSequenceKeypoint.new(0, 0.6),
      NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
      NumberSequenceKeypoint.new(0, 0.15),
      NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment

    local burst = math.clamp(config.BurstCount, 0, 80)
    if burst > 0 then
      emitter:Emit(burst)
    end
  end

  -- Simple beam streak for extra punch "snap".
  if config.BeamEnabled == true then
    local beamTexture = config.BeamTexture
    if type(beamTexture) == "string" and beamTexture ~= "" then
      local a0 = Instance.new("Attachment")
      a0.Name = "PunchBeam0"
      a0.Parent = part

      local a1 = Instance.new("Attachment")
      a1.Name = "PunchBeam1"
      a1.Position = Vector3.new(0, 0, -math.max(0.2, config.BeamLength))
      a1.Parent = part

      local beam = Instance.new("Beam")
      beam.Name = "PunchBeam"
      beam.Attachment0 = a0
      beam.Attachment1 = a1
      beam.Texture = beamTexture
      beam.FaceCamera = true
      beam.LightEmission = 0.85
      beam.Color = ColorSequence.new(config.Color)
      beam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1),
      })
      beam.Width0 = math.max(0, config.BeamWidth0)
      beam.Width1 = math.max(0, config.BeamWidth1)
      beam.Parent = part
    end
  end

  local tween = TweenService:Create(
    part,
    TweenInfo.new(math.max(0.05, config.Lifetime), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    {
      Size = config.SizeEnd,
      Transparency = math.clamp(config.TransparencyEnd, 0, 1),
    }
  )
  tween:Play()

  Debris:AddItem(part, (config.Lifetime or 0.18) + 0.1)
end

return CombatVFX
