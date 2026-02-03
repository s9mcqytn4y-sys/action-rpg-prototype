--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)
local RoactRodux = require(Packages:WaitForChild("Roact-Rodux") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)
local InteractionConfig = require(Shared:WaitForChild("Config"):WaitForChild("InteractionConfig") :: ModuleScript)
local UIIcons = require(Shared:WaitForChild("UI"):WaitForChild("UIIcons") :: ModuleScript)

local HUDRoot = require(script.Parent.Components:WaitForChild("HUDRoot") :: ModuleScript)
local SettingsPanel = require(script.Parent.Components:WaitForChild("SettingsPanel") :: ModuleScript)
local SprintButton = require(script.Parent.Components:WaitForChild("SprintButton") :: ModuleScript)
local AttackButton = require(script.Parent.Components:WaitForChild("AttackButton") :: ModuleScript)
local InteractButton = require(script.Parent.Components:WaitForChild("InteractButton") :: ModuleScript)
local Core = script.Parent.Components:WaitForChild("Core") :: Folder
local IconButton = require(Core:WaitForChild("IconButton") :: ModuleScript)

local ClientRoot = script.Parent.Parent :: Folder
local State = ClientRoot:WaitForChild("State") :: Folder
local store = require(State:WaitForChild("Store") :: ModuleScript)
local Actions = require(State:WaitForChild("Actions") :: ModuleScript)

local HUDApp = Roact.Component:extend("HUDApp")

type Props = {
  Viewport: {
    className: string,
    scale: number,
  }?,
}

function HUDApp:init()
  self.state = {
    showSettings = false,
  }

  self._settingsSound = nil

  local existingSound = SoundService:FindFirstChild("SettingsToggle")
  if existingSound and existingSound:IsA("Sound") then
    self._settingsSound = existingSound
  elseif InteractionConfig.SfxSoundId ~= "" then
    local sound = Instance.new("Sound")
    sound.Name = "SettingsToggle"
    sound.SoundId = InteractionConfig.SfxSoundId
    sound.Volume = 0.6
    sound.Parent = SoundService
    self._settingsSound = sound
  end

  self.toggleSettings = function()
    self:setState(function(prev)
      local nextOpen = not prev.showSettings
      store:dispatch(Actions.SetMenuOpen(nextOpen))
      if self._settingsSound then
        self._settingsSound.TimePosition = 0
        self._settingsSound:Play()
      end
      return { showSettings = nextOpen }
    end)
  end

  self.closeSettings = function()
    store:dispatch(Actions.SetMenuOpen(false))
    self:setState({ showSettings = false })
  end
end

function HUDApp:didMount()
  store:dispatch(Actions.SetMenuOpen(self.state.showSettings == true))
  self._inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
      return
    end
    if UserInputService:GetFocusedTextBox() then
      return
    end
    if input.UserInputType == Enum.UserInputType.Keyboard then
      if input.KeyCode == Enum.KeyCode.P then
        self.toggleSettings()
      end
    elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
      if input.KeyCode == Enum.KeyCode.ButtonStart then
        self.toggleSettings()
      end
    end
  end)
end

function HUDApp:willUnmount()
  if self._inputConn then
    self._inputConn:Disconnect()
    self._inputConn = nil
  end
  store:dispatch(Actions.SetMenuOpen(false))
end

function HUDApp:render()
  local props = self.props :: Props
  local viewport = props.Viewport
  local className = if viewport then viewport.className else "Desktop"
  local isPhone = className == "Phone"
  local showShortcut = UserInputService.KeyboardEnabled
    and UserInputService.MouseEnabled
    and not UserInputService.TouchEnabled
  local shortcutLabel = if showShortcut then "P" else nil

  local buttonSize = if isPhone then 42 else 34
  local buttonPaddingX = if isPhone then Theme.Spacing.M else Theme.Spacing.L
  local buttonPaddingY = if isPhone then 64 else Theme.Spacing.L
  local inset = GuiService:GetGuiInset()

  return Roact.createElement("ScreenGui", {
    Name = "HUDApp",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 10,
  }, {
    SafeArea = Roact.createElement("Frame", {
      Name = "SafeArea",
      BackgroundTransparency = 1,
      Size = UDim2.fromScale(1, 1),
    }, {
      SettingsButton = Roact.createElement(IconButton, {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -buttonPaddingX, 0, inset.Y + buttonPaddingY),
        Size = UDim2.fromOffset(buttonSize, buttonSize),
        Image = UIIcons.Settings,
        ZIndex = 20,
        Label = "SET",
        Shortcut = shortcutLabel,
        OnActivated = self.toggleSettings,
      }),

      HUD = Roact.createElement(HUDRoot),

      SprintButton = Roact.createElement(SprintButton),
      AttackButton = Roact.createElement(AttackButton),
      InteractButton = Roact.createElement(InteractButton),
      Settings = Roact.createElement(SettingsPanel, {
        Visible = self.state.showSettings,
        OnClose = self.closeSettings,
      }),
    }),
  })
end

local function mapStateToProps(state)
  return {
    Viewport = state.UI and state.UI.Viewport or nil,
  }
end

return RoactRodux.connect({ "UI" }, mapStateToProps)(HUDApp)
