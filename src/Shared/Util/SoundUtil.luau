--!strict

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

export type OneShotOptions = {
	volume: number?,
	playbackSpeed: number?,
	rollOffMaxDistance: number?,
	emitterSize: number?,
	cleanupDelaySec: number?,
	soundGroup: SoundGroup?,
	parent: Instance?,
	position: Vector3?,
}

local SoundUtil = {}

function SoundUtil.PlayOneShot(soundId: string, options: OneShotOptions?): Sound?
	if type(soundId) ~= "string" or soundId == "" then
		return nil
	end

	local opts = options or {}
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = opts.volume or 1
	sound.PlaybackSpeed = opts.playbackSpeed or 1
	sound.RollOffMaxDistance = opts.rollOffMaxDistance or 80
	sound.EmitterSize = opts.emitterSize or 6
	if opts.soundGroup then
		sound.SoundGroup = opts.soundGroup
	end

	local parent = opts.parent
	local tempPart = nil
	if not parent then
		local position = opts.position
		if position then
			tempPart = Instance.new("Part")
			tempPart.Name = "SfxEmitter"
			tempPart.Size = Vector3.new(0.2, 0.2, 0.2)
			tempPart.Transparency = 1
			tempPart.Anchored = true
			tempPart.CanCollide = false
			tempPart.CanQuery = false
			tempPart.CanTouch = false
			tempPart.CFrame = CFrame.new(position)
			tempPart.Parent = Workspace
			parent = tempPart
		else
			parent = SoundService
		end
	end

	sound.Parent = parent
	sound:Play()

	local cleanupDelay = opts.cleanupDelaySec or 3
	Debris:AddItem(sound, cleanupDelay)
	if tempPart then
		Debris:AddItem(tempPart, cleanupDelay)
	end

	return sound
end

return SoundUtil
