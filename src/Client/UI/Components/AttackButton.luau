--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)
local RoactRodux = require(Packages:WaitForChild("Roact-Rodux") :: ModuleScript)
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)
local UITypography = require(Shared:WaitForChild("UI"):WaitForChild("UITypography") :: ModuleScript)
local InputConfig = require(Shared:WaitForChild("Config"):WaitForChild("InputConfig") :: ModuleScript)

local AttackButton = Roact.Component:extend("AttackButton")

type Props = {
  Viewport: {
    className: string,
    scale: number,
  }?,
}

function AttackButton:init()
  self.state = {
    pressed = false,
  }
end

function AttackButton:_attack()
  local ok, controller = pcall(function()
    return Knit.GetController("CombatController")
  end)
  if ok and controller and controller.RequestAttack then
    controller:RequestAttack()
  end
end

function AttackButton:render()
  local props = self.props :: Props
  if not UserInputService.TouchEnabled then
    return nil
  end

  local viewport = props.Viewport
  local className = if viewport then viewport.className else "Desktop"
  local isPhone = className == "Phone"
  local isTablet = className == "Tablet"

  local layout = InputConfig.MobileLayout
  local scale = if viewport then viewport.scale else 1
  local sizeScale = if isPhone then 1.1 else if isTablet then 1.05 else 1

  local baseOffset = layout.RightClusterOffset
  local sprintSize = math.floor(layout.SprintSize * sizeScale * scale)
  local attackSize = math.floor(layout.AttackSize * sizeScale * scale)
  local gap = math.floor(layout.AttackGap * scale)

  local offsetX = math.floor(baseOffset.X * scale)
  local offsetY = math.floor(baseOffset.Y * scale) + sprintSize + gap

  local pressed = self.state.pressed
  local background = if pressed then UITheme.Colors.AccentSecondary else UITheme.Colors.SurfaceRaised
  local textColor = if pressed then UITheme.Colors.Background else UITheme.Colors.Text
  local borderTransparency = if pressed then 0.18 else 0.45
  local scaleDown = if pressed then 0.94 else 1

  return Roact.createElement("TextButton", {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -offsetX, 1, -offsetY),
    Size = UDim2.fromOffset(attackSize, attackSize),
    Text = "",
    BackgroundColor3 = background,
    BackgroundTransparency = 0,
    AutoButtonColor = true,
    Selectable = true,
    [Roact.Event.InputBegan] = function(_, input)
      if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        self:setState({ pressed = true })
      end
    end,
    [Roact.Event.InputEnded] = function(_, input)
      if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        self:setState({ pressed = false })
      end
    end,
    [Roact.Event.Activated] = function()
      self:_attack()
    end,
  }, {
    Scale = Roact.createElement("UIScale", {
      Scale = scaleDown,
    }),
    Aspect = Roact.createElement("UIAspectRatioConstraint", {
      AspectRatio = 1,
    }),
    Corner = Roact.createElement("UICorner", {
      CornerRadius = UDim.new(1, 0),
    }),
    Stroke = Roact.createElement("UIStroke", {
      Color = UITheme.Colors.Border,
      Transparency = borderTransparency,
      Thickness = 1,
    }),
    Ring = Roact.createElement("UIStroke", {
      Color = UITheme.Colors.AccentSecondary,
      Transparency = pressed and 0.2 or 0.55,
      Thickness = 2,
    }),
    Highlight = Roact.createElement("UIGradient", {
      Rotation = 90,
      Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.65),
        NumberSequenceKeypoint.new(1, 1),
      }),
    }),
    Label = Roact.createElement("TextLabel", {
      BackgroundTransparency = 1,
      Size = UDim2.fromScale(1, 1),
      Text = "ATK",
      TextColor3 = textColor,
      TextSize = if isPhone then 18 else 16,
      Font = UITypography.Fonts.Emphasis,
      TextXAlignment = Enum.TextXAlignment.Center,
      TextYAlignment = Enum.TextYAlignment.Center,
    }),
  })
end

local function mapStateToProps(state)
  return {
    Viewport = state.UI and state.UI.Viewport or nil,
  }
end

return RoactRodux.connect({ "UI" }, mapStateToProps)(AttackButton)
