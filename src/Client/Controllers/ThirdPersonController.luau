--!strict

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages :: Folder
local Knit = require(Packages.Knit :: ModuleScript)
local Janitor = require(Packages.Janitor :: ModuleScript)

local Shared = ReplicatedStorage.Shared :: Folder
local DebugConfig = require(Shared.Config.DebugConfig :: ModuleScript)
local Metrics = require(Shared.Util.Metrics :: ModuleScript)

local Client = script.Parent :: Folder
local ClientRoot = Client.Parent :: Folder

local ThirdPersonCamera = require(ClientRoot.Camera.ThirdPersonCamera :: ModuleScript)
local ThirdPersonMovement = require(ClientRoot.Movement.ThirdPersonMovement :: ModuleScript)
local SettingsState = require(ClientRoot.Settings.SettingsState :: ModuleScript)

type Metrics = typeof(Metrics.new(false))
type ThirdPersonCameraType = typeof(ThirdPersonCamera.new(Metrics.new(false)))
type ThirdPersonMovementType = typeof(ThirdPersonMovement.new(Metrics.new(false)))
type SettingsStateType = typeof(SettingsState)

type ThirdPersonController = {
	KnitInit: (self: ThirdPersonController) -> (),
	KnitStart: (self: ThirdPersonController) -> (),
	SetInteractFocus: (self: ThirdPersonController, position: Vector3?) -> (),
}

type ThirdPersonControllerImpl = ThirdPersonController & {
	_name: string,
	_janitor: any,
	_characterJanitor: any,
	_metrics: Metrics,
	_camera: ThirdPersonCameraType,
	_movement: ThirdPersonMovementType,
	_settings: SettingsStateType,
	_prefsController: any?,

	_player: Player?,
	_boundCharacter: Model?,
	_bindToken: number,

	_getLocalPlayer: (self: ThirdPersonControllerImpl) -> Player?,
	_waitForCharacterReady: (self: ThirdPersonControllerImpl, character: Model, timeoutSec: number) -> boolean,
	_applySettings: (self: ThirdPersonControllerImpl) -> (),
	_applyPreferences: (self: ThirdPersonControllerImpl, prefs: any) -> (),
	_bindCharacterAsync: (self: ThirdPersonControllerImpl, character: Model) -> (),
	_bindCharacter: (self: ThirdPersonControllerImpl, character: Model) -> (),
	_unbindCharacter: (self: ThirdPersonControllerImpl) -> (),
}

local ThirdPersonController: ThirdPersonControllerImpl = Knit.CreateController({
	Name = "ThirdPersonController",
}) :: any

-- Robust readiness check: character must have Humanoid + HumanoidRootPart, and be parented.
function ThirdPersonController:_waitForCharacterReady(character: Model, timeoutSec: number): boolean
	local t0 = os.clock()
	while os.clock() - t0 < timeoutSec do
		if character.Parent == nil then
			return false
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if humanoid and root then
			return true
		end
		task.wait()
	end
	return false
end

function ThirdPersonController:_getLocalPlayer(): Player?
	-- In LocalScripts, Players.LocalPlayer is typically available, but keep it safe.
	local player = Players.LocalPlayer
	if player then
		return player
	end

	-- Fallback: wait briefly for LocalPlayer to become available.
	local t0 = os.clock()
	while os.clock() - t0 < 5 do
		player = Players.LocalPlayer
		if player then
			return player
		end
		task.wait()
	end
	return nil
end

function ThirdPersonController:_applySettings()
	local selfImpl = self :: ThirdPersonControllerImpl
	-- Camera settings
	local okCam, camSettings = pcall(function()
		return selfImpl._settings:GetCamera()
	end)
	if okCam and camSettings then
		selfImpl._camera:ApplySettings(camSettings)
	else
		if DebugConfig.LogWarnings then
			warn("[ThirdPersonController] Failed to read/apply camera settings.")
		end
	end

	-- Movement settings (apply only if SettingsState exposes it; safe to ignore otherwise)
	-- If your SettingsState has GetMovement(), this will automatically start working.
	local okMove, moveSettings = pcall(function()
		-- @ts-ignore - optional API
		return (selfImpl._settings :: any).GetMovement and (selfImpl._settings :: any):GetMovement() or nil
	end)
	if okMove and moveSettings and (selfImpl._movement :: any).ApplySettings then
		pcall(function()
			(selfImpl._movement :: any):ApplySettings(moveSettings)
		end)
	end
end

function ThirdPersonController:_applyPreferences(prefs: any)
	local selfImpl = self :: ThirdPersonControllerImpl
	if not prefs or not prefs.Camera then
		return
	end
	local cameraPrefs = prefs.Camera
	selfImpl._camera:ApplyPreferences({
		Sensitivity = cameraPrefs.Sensitivity,
		InvertY = cameraPrefs.InvertY,
		Fov = cameraPrefs.Fov,
	})
end

function ThirdPersonController:KnitInit()
	local selfImpl = self :: ThirdPersonControllerImpl
	selfImpl._name = "ThirdPersonController"
	selfImpl._janitor = Janitor.new()
	selfImpl._characterJanitor = Janitor.new()
	selfImpl._metrics = Metrics.new(DebugConfig.EnableMetrics)

	selfImpl._camera = ThirdPersonCamera.new(selfImpl._metrics)
	selfImpl._movement = ThirdPersonMovement.new(selfImpl._metrics)
	selfImpl._settings = SettingsState
	selfImpl._prefsController = nil

	selfImpl._player = nil
	selfImpl._boundCharacter = nil
	selfImpl._bindToken = 0
end

function ThirdPersonController:KnitStart()
	local selfImpl = self :: ThirdPersonControllerImpl

	-- Start subsystems (idempotent in your camera/movement modules already)
	selfImpl._camera:Start()
	selfImpl._movement:Start()

	-- Apply initial settings (camera + optional movement)
	selfImpl:_applySettings()

	-- Settings hot-reload (guarded)
	selfImpl._janitor:Add(selfImpl._settings.Changed:Connect(function(category, _, _)
		if category == "Camera" or category == "Movement" or category == nil then
			selfImpl:_applySettings()
		end
	end), "Disconnect")

	local okPrefs, prefsController = pcall(function()
		return Knit.GetController("PreferencesController")
	end)
	if okPrefs and prefsController then
		selfImpl._prefsController = prefsController
		selfImpl:_applyPreferences(prefsController:GetPreferences())
		selfImpl._janitor:Add(prefsController.Changed:Connect(function(prefs)
			selfImpl:_applyPreferences(prefs)
		end), "Disconnect")
	end

	local player = selfImpl:_getLocalPlayer()
	selfImpl._player = player
	if not player then
		if DebugConfig.LogWarnings then
			warn("[ThirdPersonController] LocalPlayer missing; controller will not bind character.")
		end
		return
	end

	-- Character lifecycle
	selfImpl._janitor:Add(player.CharacterAdded:Connect(function(character)
		-- Bind async to avoid race conditions during spawn.
		selfImpl:_bindCharacterAsync(character)
	end), "Disconnect")

	selfImpl._janitor:Add(player.CharacterRemoving:Connect(function(character)
		-- Only unbind if this is the currently bound one.
		if selfImpl._boundCharacter == character then
			selfImpl:_unbindCharacter()
		end
	end), "Disconnect")

	-- If already spawned
	if player.Character then
		selfImpl:_bindCharacterAsync(player.Character)
	end
end

function ThirdPersonController:_bindCharacterAsync(character: Model)
	local selfImpl = self :: ThirdPersonControllerImpl
	selfImpl._bindToken += 1
	local token = selfImpl._bindToken

	task.spawn(function()
		-- Wait for character readiness (humanoid + HRP)
		local ready = selfImpl:_waitForCharacterReady(character, 5)
		if not ready then
			return
		end
		-- Cancel if a newer bind request happened
		if token ~= selfImpl._bindToken then
			return
		end
		selfImpl:_bindCharacter(character)
	end)
end

function ThirdPersonController:_bindCharacter(character: Model)
	local selfImpl = self :: ThirdPersonControllerImpl

	-- If we're already bound to this character, do nothing.
	if selfImpl._boundCharacter == character then
		return
	end

	-- Unbind previous
	selfImpl:_unbindCharacter()

	selfImpl._boundCharacter = character
	selfImpl._metrics:Increment("characterBinds", 1)

	if DebugConfig.LogCharacterBinding then
		print(("[ThirdPersonController] Binding character %s"):format(character.Name))
	end

	-- Bind systems
	selfImpl._camera:BindCharacter(character)
	selfImpl._movement:BindCharacter(character)

	-- Auto-cleanup if character gets removed unexpectedly
	selfImpl._characterJanitor:Add(character.AncestryChanged:Connect(function(_, parent)
		if parent == nil and selfImpl._boundCharacter == character then
			selfImpl:_unbindCharacter()
		end
	end), "Disconnect")
end

function ThirdPersonController:_unbindCharacter()
	local selfImpl = self :: ThirdPersonControllerImpl

	selfImpl._characterJanitor:Cleanup()
	selfImpl._boundCharacter = nil

	-- Unbind subsystems
	selfImpl._camera:BindCharacter(nil)
	selfImpl._movement:BindCharacter(nil)

	selfImpl._metrics:Increment("characterUnbinds", 1)
end

function ThirdPersonController:SetInteractFocus(position: Vector3?)
	local selfImpl = self :: ThirdPersonControllerImpl
	selfImpl._camera:SetFocusHint(position)
end

return ThirdPersonController
