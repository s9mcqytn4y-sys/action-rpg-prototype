--!strict

local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages :: Folder
local Shared = ReplicatedStorage.Shared :: Folder

local Janitor = require(Packages.Janitor :: ModuleScript)
local MovementConfig = require(Shared.Config.MovementConfig :: ModuleScript)
local DebugConfig = require(Shared.Config.DebugConfig :: ModuleScript)
local Metrics = require(Shared.Util.Metrics :: ModuleScript)

type MovementConfig = typeof(MovementConfig)
type Metrics = typeof(Metrics.new(false))

export type ThirdPersonMovement = {
	Start: (self: ThirdPersonMovement) -> (),
	Stop: (self: ThirdPersonMovement) -> (),
	BindCharacter: (self: ThirdPersonMovement, character: Model?) -> (),
}

type CharacterContext = {
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	baseAutoRotate: boolean,
	baseWalkSpeed: number,
}

type ThirdPersonMovementImpl = ThirdPersonMovement & {
	_config: MovementConfig,
	_debug: typeof(DebugConfig),
	_metrics: Metrics,
	_janitor: any,

	_character: CharacterContext?,
	_turnYaw: number,
}

local ThirdPersonMovement = {}
ThirdPersonMovement.__index = ThirdPersonMovement

local function expAlpha(speed: number, dt: number): number
	if speed <= 0 then
		return 1
	end
	return 1 - math.exp(-speed * dt)
end

local function lerpAngle(current: number, target: number, alpha: number): number
	local delta = math.atan2(math.sin(target - current), math.cos(target - current))
	return current + delta * alpha
end

local function getCharacterContext(character: Model): CharacterContext?
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return nil
	end
	return {
		character = character,
		humanoid = humanoid,
		root = root,
		baseAutoRotate = humanoid.AutoRotate,
		baseWalkSpeed = humanoid.WalkSpeed,
	}
end

function ThirdPersonMovement.new(metrics: Metrics): ThirdPersonMovementImpl
	local self: ThirdPersonMovementImpl = setmetatable({
		_config = MovementConfig,
		_debug = DebugConfig,
		_metrics = metrics,
		_janitor = Janitor.new(),

		_character = nil,
		_turnYaw = 0,
	}, ThirdPersonMovement)

	return self
end

function ThirdPersonMovement:Start()
	local selfImpl = self :: ThirdPersonMovementImpl
	RunService:BindToRenderStep("ThirdPersonMovement", Enum.RenderPriority.Character.Value, function(dt)
		selfImpl:_update(dt)
	end)
	selfImpl._janitor:Add(function()
		RunService:UnbindFromRenderStep("ThirdPersonMovement")
	end)
end

function ThirdPersonMovement:Stop()
	local selfImpl = self :: ThirdPersonMovementImpl
	selfImpl:_restoreCharacter()
	selfImpl._janitor:Cleanup()
end

function ThirdPersonMovement:BindCharacter(character: Model?)
	local selfImpl = self :: ThirdPersonMovementImpl
	selfImpl:_restoreCharacter()

	if not character then
		selfImpl._character = nil
		return
	end

	local context = getCharacterContext(character)
	if not context then
		if selfImpl._debug.LogWarnings then
			warn("[ThirdPersonMovement] Character missing humanoid/root; movement not bound.")
		end
		selfImpl._character = nil
		return
	end

	selfImpl._character = context
	context.humanoid.AutoRotate = selfImpl._config.AutoRotate

	local _, yaw, _ = context.root.CFrame:ToOrientation()
	selfImpl._turnYaw = yaw
end

function ThirdPersonMovement:_restoreCharacter()
	local selfImpl = self :: ThirdPersonMovementImpl
	local context = selfImpl._character
	if not context then
		return
	end
	context.humanoid.AutoRotate = context.baseAutoRotate
	context.humanoid.WalkSpeed = context.baseWalkSpeed
end

function ThirdPersonMovement:_update(dt: number)
	local selfImpl = self :: ThirdPersonMovementImpl
	local context = selfImpl._character
	if not context then
		return
	end

	local humanoid = context.humanoid
	local root = context.root
	if not humanoid or not root or not root.Parent then
		return
	end

	local inAir = humanoid.FloorMaterial == Enum.Material.Air
	if inAir and not selfImpl._config.AllowAirTurn then
		return
	end

	local moveDir = humanoid.MoveDirection
	local flatMove = Vector3.new(moveDir.X, 0, moveDir.Z)
	if flatMove.Magnitude < selfImpl._config.MoveDeadzone then
		return
	end

	local desiredYaw = math.atan2(-flatMove.X, -flatMove.Z)
	local speed = selfImpl._config.TurnSmoothingSpeed * (if inAir then selfImpl._config.AirTurnMultiplier else 1)
	local a = expAlpha(speed, dt)
	selfImpl._turnYaw = lerpAngle(selfImpl._turnYaw, desiredYaw, a)

	local pos = root.Position
	root.CFrame = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), selfImpl._turnYaw) + pos
end

return ThirdPersonMovement
