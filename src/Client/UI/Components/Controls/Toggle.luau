local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

type Props = {
	Enabled: boolean,
	OnChanged: (enabled: boolean) -> (),

	-- optional
	Disabled: boolean
}

local Toggle = Roact.Component:extend("Toggle")

-- ====== Tuning ======
local SIZE = UDim2.new(0, 56, 0, 26)
local KNOB_SIZE = UDim2.new(0, 20, 0, 20)
local KNOB_Y = 3
local KNOB_X_ON = 30
local KNOB_X_OFF = 3

local TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_PRESS = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local COLOR_KNOB = Color3.fromRGB(235, 240, 250)
local COLOR_TRACK = Color3.fromRGB(24, 30, 40)

local function safeTween(self, instance: Instance, info: TweenInfo, props)
	if not instance then
		return
	end

	self._tweens = self._tweens or {}
	local old = self._tweens[instance]
	if old then
		old:Cancel()
	end

	local tw = TweenService:Create(instance, info, props)
	self._tweens[instance] = tw
	tw:Play()
end

local function knobX(enabled: boolean): number
	return enabled and KNOB_X_ON or KNOB_X_OFF
end

function Toggle:init()
	self._buttonRef = Roact.createRef()
	self._knobRef = Roact.createRef()
	self._knobScaleRef = Roact.createRef()
	self._trackRef = Roact.createRef()

	self._lastEnabled = nil
	self._pressed = false
	self._tweens = {} :: { [Instance]: Tween }
end

function Toggle:_apply(enabled: boolean)
	local button = self._buttonRef:getValue()
	local knob = self._knobRef:getValue()
	local track = self._trackRef:getValue()

	local bgColor = enabled and Theme.Colors.Accent or Theme.Colors.PanelAlt
	local bgTrans = enabled and 0.04 or 0.14

	-- sedikit hidup pas enabled: track lebih jelas
	local trackTrans = enabled and 0.32 or 0.6

	safeTween(self, button, TWEEN, {
		BackgroundColor3 = bgColor,
		BackgroundTransparency = bgTrans,
	})

	safeTween(self, knob, TWEEN, {
		Position = UDim2.new(0, knobX(enabled), 0, KNOB_Y),
	})

	safeTween(self, track, TWEEN, {
		BackgroundTransparency = trackTrans,
	})
end

function Toggle:_setPressed(isPressed: boolean)
	self._pressed = isPressed
	local scale = self._knobScaleRef:getValue()
	if scale then
		safeTween(self, scale, TWEEN_PRESS, { Scale = isPressed and 0.92 or 1 })
	end
end

function Toggle:didMount()
	self._lastEnabled = self.props.Enabled
	self:_apply(self.props.Enabled)
end

function Toggle:didUpdate()
	if self._lastEnabled ~= self.props.Enabled then
		self._lastEnabled = self.props.Enabled
		self:_apply(self.props.Enabled)
	end
end

function Toggle:willUnmount()
	if self._tweens then
		for _, tw in pairs(self._tweens) do
			tw:Cancel()
		end
	end
	self._tweens = {}
end

function Toggle:render()
	local props = self.props :: Props
	local enabled = props.Enabled
	local disabled = props.Disabled == true

	return Roact.createElement("TextButton", {
		Name = "Toggle",
		Size = SIZE,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),

		Text = "",
		AutoButtonColor = not disabled,

		BackgroundColor3 = enabled and Theme.Colors.Accent or Theme.Colors.PanelAlt,
		BackgroundTransparency = enabled and 0.04 or 0.14,
		BorderSizePixel = 0,

		Selectable = true,

		[Roact.Ref] = self._buttonRef,

		[Roact.Event.Activated] = function()
			if disabled then
				return
			end
			props.OnChanged(not enabled)
		end,

		-- press feedback
		[Roact.Event.MouseButton1Down] = function()
			if disabled then
				return
			end
			self:_setPressed(true)
		end,
		[Roact.Event.MouseButton1Up] = function()
			self:_setPressed(false)
		end,
		[Roact.Event.MouseLeave] = function()
			self:_setPressed(false)
		end,
		[Roact.Event.TouchLongPress] = function(_, state)
			if disabled then
				return
			end
			self:_setPressed(state == Enum.UserInputState.Begin)
		end,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),

		Stroke = Roact.createElement("UIStroke", {
			Color = Theme.Colors.Border,
			Transparency = disabled and 0.75 or 0.5,
			Thickness = 1,
		}),

		-- subtle highlight biar keliatan premium
		Highlight = Roact.createElement("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.78),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),

		Track = Roact.createElement("Frame", {
			Name = "Track",
			BackgroundColor3 = COLOR_TRACK,
			BackgroundTransparency = enabled and 0.32 or 0.6,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 2, 0.5, -6),
			Size = UDim2.new(1, -4, 0, 12),
			[Roact.Ref] = self._trackRef,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = Theme.Colors.Border,
				Transparency = 0.65,
				Thickness = 1,
			}),
		}),

		Knob = Roact.createElement("Frame", {
			Name = "Knob",
			Position = UDim2.new(0, knobX(enabled), 0, KNOB_Y),
			Size = KNOB_SIZE,

			BackgroundColor3 = COLOR_KNOB,
			BackgroundTransparency = disabled and 0.25 or 0,
			BorderSizePixel = 0,

			[Roact.Ref] = self._knobRef,
		}, {
			Scale = Roact.createElement("UIScale", {
				Scale = 1,
				[Roact.Ref] = self._knobScaleRef,
			}),

			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 5),
			}),

			Stroke = Roact.createElement("UIStroke", {
				Color = Theme.Colors.Border,
				Transparency = 0.4,
				Thickness = 1,
			}),

			KnobHighlight = Roact.createElement("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.55),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}),
	})
end

return Toggle
