--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)
local RoactRodux = require(Packages:WaitForChild("Roact-Rodux") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)
local UITypography = require(Shared:WaitForChild("UI"):WaitForChild("UITypography") :: ModuleScript)
local TweenUtil = require(Shared:WaitForChild("Util"):WaitForChild("TweenUtil") :: ModuleScript)

local Core = script.Parent:WaitForChild("Core") :: Folder
local Surface = require(Core:WaitForChild("Surface") :: ModuleScript)

local StaminaBar = Roact.Component:extend("StaminaBar")

type Props = {
	LayoutOrder: number?,
	Size: UDim2?,
}

local LOW_THRESHOLD = 0.25
local HIDE_AT_RATIO = 1.01

local TWEEN_SHOW = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_FILL = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_TEXT = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_COLOR = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function clamp01(x: number): number
	return math.clamp(x, 0, 1)
end

local function ratioOf(current: number, max: number): number
	if max <= 0 then
		return 0
	end
	return clamp01(current / max)
end

function StaminaBar:init()
	self._containerRef = Roact.createRef()
	self._fillRef = Roact.createRef()
	self._badgeRef = Roact.createRef()
	self._scaleRef = Roact.createRef()

	self._tweens = {} :: { [Instance]: Tween }

	self._lastShow = nil
	self._lastRatio = nil
	self._lastLow = nil
end

function StaminaBar:_updateVisual()
	local stamina = self.props.stamina or {}
	local current = stamina.current or 0
	local max = stamina.max or 0
	local state = stamina.state or "Idle"

	local ratio = ratioOf(current, max)
	local show = (ratio < HIDE_AT_RATIO) or (state == "Draining") or (state == "Recovering") or (state == "Exhausted")
	local low = ratio <= LOW_THRESHOLD or state == "Exhausted"

	if show ~= self._lastShow then
		local container = self._containerRef:getValue()
		TweenUtil.play(self._tweens, container, TWEEN_SHOW, {
			GroupTransparency = (show and 0) or 1,
		})
		self._lastShow = show
	end

	if ratio ~= self._lastRatio then
		local fill = self._fillRef:getValue()
		TweenUtil.play(self._tweens, fill, TWEEN_FILL, {
			Size = UDim2.new(ratio, 0, 1, 0),
		})
		self._lastRatio = ratio
	end

	if low ~= (self._lastLow == true) then
		local badge = self._badgeRef:getValue()
		TweenUtil.play(self._tweens, badge, TWEEN_TEXT, {
			TextTransparency = (low and 0) or 1,
			BackgroundTransparency = (low and 0.15) or 1,
		})
		self._lastLow = low
	end

	local fill = self._fillRef:getValue()
	if fill then
		local targetColor = if state == "Exhausted" then UITheme.Colors.Danger elseif low then UITheme.Colors.Warning else UITheme.Colors.Accent
		TweenUtil.play(self._tweens, fill, TWEEN_COLOR, {
			BackgroundColor3 = targetColor,
		})
	end
end

function StaminaBar:didMount()
	self:_updateVisual()
end

function StaminaBar:didUpdate()
	self:_updateVisual()
end

function StaminaBar:willUnmount()
	TweenUtil.cancelAll(self._tweens)
	self._tweens = {}
end

function StaminaBar:render()
	local props = self.props :: Props
	local stamina = self.props.stamina or {}
	local current = stamina.current or 0
	local max = stamina.max or 0

	local ratio = ratioOf(current, max)
	local currentInt = math.floor(current + 0.5)
	local maxInt = math.floor(max + 0.5)

	return Roact.createElement("CanvasGroup", {
		Name = "StaminaBar",
		GroupTransparency = 1,
		Size = props.Size or UDim2.new(0, 300, 0, 60),
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		[Roact.Ref] = self._containerRef,
	}, {
		Scale = Roact.createElement("UIScale", {
			Scale = 1,
			[Roact.Ref] = self._scaleRef,
		}),
		Body = Roact.createElement(Surface, {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = UITheme.Colors.Surface,
			BackgroundTransparency = 0,
			StrokeTransparency = 0.45,
			Children = {
				Title = Roact.createElement("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 14, 0, 8),
					Size = UDim2.new(0.6, 0, 0, 16),
					Text = "STAMINA",
					TextColor3 = UITheme.Colors.TextMuted,
					TextSize = UITypography.Sizes.Caption,
					Font = UITypography.Fonts.Mono,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Value = Roact.createElement("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.new(1, -14, 0, 8),
					Size = UDim2.new(0, 80, 0, 16),
					Text = string.format("%d/%d", currentInt, maxInt),
					TextColor3 = UITheme.Colors.Text,
					TextSize = UITypography.Sizes.Caption,
					Font = UITypography.Fonts.Mono,
					TextXAlignment = Enum.TextXAlignment.Right,
				}),
				Track = Roact.createElement("Frame", {
					Position = UDim2.new(0, 14, 0, 28),
					Size = UDim2.new(1, -28, 0, 10),
					BackgroundColor3 = UITheme.Colors.SurfaceAlt,
					BackgroundTransparency = 0.2,
					BorderSizePixel = 0,
				}, {
					Corner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),
					Stroke = Roact.createElement("UIStroke", {
						Color = UITheme.Colors.Border,
						Transparency = 0.6,
						Thickness = 1,
					}),
					Fill = Roact.createElement("Frame", {
						Size = UDim2.new(ratio, 0, 1, 0),
						BackgroundColor3 = UITheme.Colors.Accent,
						BorderSizePixel = 0,
						[Roact.Ref] = self._fillRef,
					}, {
						Corner = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(1, 0),
						}),
						Gradient = Roact.createElement("UIGradient", {
							Rotation = 0,
							Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 190, 255)),
								ColorSequenceKeypoint.new(1, UITheme.Colors.Accent),
							}),
						}),
					}),
				}),
				LowBadge = Roact.createElement("TextLabel", {
					BackgroundColor3 = UITheme.Colors.SurfaceAlt,
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 14, 0, 40),
					Size = UDim2.new(0, 70, 0, 14),
					Text = "LOW",
					TextColor3 = UITheme.Colors.Warning,
					TextTransparency = 1,
					TextSize = UITypography.Sizes.Caption,
					Font = UITypography.Fonts.Mono,
					TextXAlignment = Enum.TextXAlignment.Left,
					[Roact.Ref] = self._badgeRef,
				}),
			},
		}),
	})
end

local function mapStateToProps(state)
	return {
		stamina = state.Stamina,
	}
end

return RoactRodux.connect({ "Stamina" }, mapStateToProps)(StaminaBar)
