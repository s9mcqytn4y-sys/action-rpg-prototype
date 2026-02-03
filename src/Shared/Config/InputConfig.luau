--!strict

export type InputConfig = {
  Interact: {
    Key: Enum.KeyCode,
    GamepadKey: Enum.KeyCode?,
  },
  Combat: {
    GamepadAttack: Enum.KeyCode,
  },
  Stamina: {
    SprintHoldKey: Enum.KeyCode,
    SprintToggleKey: Enum.KeyCode,
    DodgeKey: Enum.KeyCode,
    HeavyKey: Enum.KeyCode,
    GamepadSprint: Enum.KeyCode,
    GamepadDodge: Enum.KeyCode,
    GamepadHeavy: Enum.KeyCode,
  },
  MobileLayout: {
    RightClusterOffset: Vector2,
    SprintSize: number,
    AttackSize: number,
    AttackGap: number,
    InteractSize: number,
  },
}

local InputConfig: InputConfig = {
  Interact = {
    Key = Enum.KeyCode.E,
    GamepadKey = Enum.KeyCode.ButtonX,
  },
  Combat = {
    -- R2/L2 are reserved for camera zoom in ThirdPersonCamera.
    GamepadAttack = Enum.KeyCode.ButtonR1,
  },
  Stamina = {
    SprintHoldKey = Enum.KeyCode.LeftShift,
    SprintToggleKey = Enum.KeyCode.LeftControl,
    DodgeKey = Enum.KeyCode.Q,
    HeavyKey = Enum.KeyCode.F,
    GamepadSprint = Enum.KeyCode.ButtonL3,
    GamepadDodge = Enum.KeyCode.ButtonB,
    GamepadHeavy = Enum.KeyCode.ButtonY,
  },
  MobileLayout = {
    RightClusterOffset = Vector2.new(32, 120),
    SprintSize = 78,
    AttackSize = 96,
    AttackGap = 14,
    InteractSize = 72,
  },
}

return InputConfig
