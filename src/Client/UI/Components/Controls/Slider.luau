local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)
local TweenUtil = require(Shared:WaitForChild("Util"):WaitForChild("TweenUtil") :: ModuleScript)

type Props = {
	Min: number,
	Max: number,
	Value: number,
	OnChanged: (value: number) -> (),

	-- optional
	Step: number?, -- contoh: 1, 5, 0.1
	Disabled: boolean?,
}

local Slider = Roact.Component:extend("Slider")

-- ====== Tweaks ======
local TWEEN_POS = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SCALE = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function clamp01(x: number): number
	return math.clamp(x, 0, 1)
end

local function getRatio(minV: number, maxV: number, value: number): number
	local range = maxV - minV
	if range <= 0 then
		return 0
	end
	return clamp01((value - minV) / range)
end

local function snap(value: number, step: number?): number
	if not step or step <= 0 then
		return value
	end
	return math.floor((value / step) + 0.5) * step
end

function Slider:init()
	self._dragging = false

	self._barRef = Roact.createRef()
	self._fillRef = Roact.createRef()
	self._knobRef = Roact.createRef()
	self._knobScaleRef = Roact.createRef()

	self._lastRatio = nil
	self._conn = nil
	self._tweens = {}

	self._setFromInput = function(input: InputObject)
		local props = self.props :: Props
		if props.Disabled then
			return
		end

		local bar = self._barRef:getValue()
		if not bar then
			return
		end

		local absPos = bar.AbsolutePosition
		local absSize = bar.AbsoluteSize
		if absSize.X <= 0 then
			return
		end

		local x = clamp01((input.Position.X - absPos.X) / absSize.X)
		local rawValue = props.Min + (props.Max - props.Min) * x
		local newValue = snap(rawValue, props.Step)

		-- pastikan masih dalam range
		newValue = math.clamp(newValue, props.Min, props.Max)

		props.OnChanged(newValue)
	end

	self._beginDrag = function(input: InputObject)
		local props = self.props :: Props
		if props.Disabled then
			return
		end

		self._dragging = true
		self._setFromInput(input)

		if not self._conn then
			self._conn = UserInputService.InputChanged:Connect(function(changed)
				if not self._dragging then
					return
				end
				if changed.UserInputType == Enum.UserInputType.MouseMovement or changed.UserInputType == Enum.UserInputType.Touch then
					self._setFromInput(changed)
				end
			end)
		end

		local knobScale = self._knobScaleRef:getValue()
		if knobScale then
			TweenUtil.play(self._tweens, knobScale, TWEEN_SCALE, { Scale = 0.92 })
		end
	end

	self._endDrag = function()
		self._dragging = false

		if self._conn then
			self._conn:Disconnect()
			self._conn = nil
		end

		local knobScale = self._knobScaleRef:getValue()
		if knobScale then
			TweenUtil.play(self._tweens, knobScale, TWEEN_SCALE, { Scale = 1 })
		end
	end
end

function Slider:_applyTween(ratio: number)
	local fill = self._fillRef:getValue()
	local knob = self._knobRef:getValue()

	if fill then
		TweenUtil.play(self._tweens, fill, TWEEN_POS, {
			Size = UDim2.new(ratio, 0, 1, 0),
		})
	end

	if knob then
		TweenUtil.play(self._tweens, knob, TWEEN_POS, {
			Position = UDim2.new(ratio, 0, 0.5, 0),
		})
	end
end

function Slider:didMount()
	local props = self.props :: Props
	local ratio = getRatio(props.Min, props.Max, props.Value)
	self._lastRatio = ratio
	self:_applyTween(ratio)
end

function Slider:didUpdate()
	local props = self.props :: Props
	local ratio = getRatio(props.Min, props.Max, props.Value)

	if self._lastRatio ~= ratio then
		self._lastRatio = ratio
		self:_applyTween(ratio)
	end
end

function Slider:willUnmount()
	self._dragging = false
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end

	if self._tweens then
		TweenUtil.cancelAll(self._tweens)
		self._tweens = nil
	end
end

function Slider:render()
	local props = self.props :: Props
	local ratio = getRatio(props.Min, props.Max, props.Value)

	local disabled = props.Disabled == true
	local barTransparency = disabled and 0.55 or 0.08
	local fillTransparency = disabled and 0.55 or 0
	local knobTransparency = disabled and 0.35 or 0

	return Roact.createElement("Frame", {
		Name = "Slider",
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
	}, {
		Bar = Roact.createElement("Frame", {
			Name = "Bar",
			Size = UDim2.new(1, 0, 0, 6),
			Position = UDim2.new(0, 0, 0.5, -3),

			BackgroundColor3 = Theme.Colors.PanelAlt,
			BackgroundTransparency = barTransparency,
			BorderSizePixel = 0,

			[Roact.Ref] = self._barRef,

			[Roact.Event.InputBegan] = function(_, input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					self._beginDrag(input)
				end
			end,

			[Roact.Event.InputEnded] = function(_, input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					self._endDrag()
				end
			end,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),

			Stroke = Roact.createElement("UIStroke", {
				Color = Theme.Colors.Border,
				Transparency = 0.6,
				Thickness = 1,
			}),

			Fill = Roact.createElement("Frame", {
				Name = "Fill",
				Size = UDim2.new(ratio, 0, 1, 0),

				BackgroundColor3 = Theme.Colors.Accent,
				BackgroundTransparency = fillTransparency,
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
						ColorSequenceKeypoint.new(1, Theme.Colors.Accent),
					}),
				}),
			}),

			Knob = Roact.createElement("Frame", {
				Name = "Knob",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(ratio, 0, 0.5, 0),
				Size = UDim2.new(0, 16, 0, 16),

				BackgroundColor3 = Color3.fromRGB(235, 240, 250),
				BackgroundTransparency = knobTransparency,
				BorderSizePixel = 0,

				[Roact.Ref] = self._knobRef,

				[Roact.Event.InputBegan] = function(_, input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						self._beginDrag(input)
					end
				end,

				[Roact.Event.InputEnded] = function(_, input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						self._endDrag()
					end
				end,
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
					Transparency = 0.3,
					Thickness = 1,
				}),

				Highlight = Roact.createElement("UIGradient", {
					Rotation = 90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.65),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
			}),
		}),
	})
end

return Slider
