local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)
local RoactRodux = require(Packages:WaitForChild("Roact-Rodux") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

local StaminaBar = Roact.Component:extend("StaminaBar")

-- ====== Tuning ======
local LOW_THRESHOLD = 0.25
local HIDE_AT_RATIO = 0.995

local TWEEN_SHOW = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_FILL = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_TEXT = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_COLOR = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Kalau Theme kamu punya warna khusus, pakai itu. Kalau tidak, fallback.
local function pickColor3(primary: any, fallback: Color3)
	if typeof(primary) == "Color3" then
		return primary
	end
	return fallback
end

local COLOR_TRACK = Color3.fromRGB(38, 42, 52)
local COLOR_LOW = Color3.fromRGB(255, 196, 90)
local COLOR_EXHAUSTED = Color3.fromRGB(255, 90, 90)

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
	self._warningRef = Roact.createRef()
	self._glowRef = Roact.createRef()
	self._glowStrokeRef = Roact.createRef()

	self._tweens = {} :: { [Instance]: Tween }

	self._lastShow = nil
	self._lastRatio = nil
	self._lastLow = nil
	self._pulseTween = nil :: Tween?
end

local function safePlay(self, instance: Instance?, info: TweenInfo, props)
	if not instance then
		return
	end

	-- cancel tween sebelumnya biar ga numpuk
	local old = self._tweens[instance]
	if old then
		old:Cancel()
	end

	local tw = TweenService:Create(instance, info, props)
	self._tweens[instance] = tw
	tw:Play()
end

function StaminaBar:_updateVisual()
	local stamina = self.props.stamina or {}
	local current = stamina.current or 0
	local max = stamina.max or 0
	local state = stamina.state or "Idle"

	local ratio = ratioOf(current, max)
	local show = (ratio < HIDE_AT_RATIO) or (state == "Draining") or (state == "Recovering") or (state == "Exhausted")
	local low = ratio <= LOW_THRESHOLD

	-- Show/hide container
	if show ~= self._lastShow then
		local container = self._containerRef:getValue()
		safePlay(self, container, TWEEN_SHOW, {
			GroupTransparency = (show and 0) or 1,
		})
		self._lastShow = show
	end

	-- Fill size
	if ratio ~= self._lastRatio then
		local fill = self._fillRef:getValue()
		safePlay(self, fill, TWEEN_FILL, {
			Size = UDim2.new(ratio, 0, 1, 0),
		})
		self._lastRatio = ratio
	end

	-- Exhausted badge fade
	if low ~= (self._lastLow == true) then
		local warningLabel = self._warningRef:getValue()
		safePlay(self, warningLabel, TWEEN_TEXT, {
			TextTransparency = (low and 0) or 1,
			BackgroundTransparency = (low and 0.08) or 1,
		})
		self:_setGlow(low)
		self._lastLow = low
	end

	-- Optional: change fill color based on state/low (biar lebih hidup)
	local fill = self._fillRef:getValue()
	if fill then
		local accent = pickColor3(Theme.Colors.Accent, Color3.fromRGB(100, 170, 255))
		local targetColor =
			(state == "Exhausted" and COLOR_EXHAUSTED)
			or (low and COLOR_LOW)
			or accent

		safePlay(self, fill, TWEEN_COLOR, {
			BackgroundColor3 = targetColor,
		})
	end
end

function StaminaBar:_setGlow(active: boolean)
	local glow = self._glowRef:getValue()
	local stroke = self._glowStrokeRef:getValue()

	if active then
		if glow then
			glow.Visible = true
		end
		if stroke then
			stroke.Transparency = 0.85
			stroke.Thickness = 1
			if not self._pulseTween then
				self._pulseTween = TweenService:Create(
					stroke,
					TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{ Transparency = 0.2, Thickness = 2 }
				)
				self._pulseTween:Play()
			end
		end
	else
		if self._pulseTween then
			self._pulseTween:Cancel()
			self._pulseTween = nil
		end
		if stroke then
			stroke.Transparency = 1
			stroke.Thickness = 1
		end
		if glow then
			glow.Visible = false
		end
	end
end

function StaminaBar:didMount()
	self:_updateVisual()
end

function StaminaBar:didUpdate()
	self:_updateVisual()
end

function StaminaBar:willUnmount()
	for _, tw in pairs(self._tweens) do
		tw:Cancel()
	end
	self._tweens = {}
	if self._pulseTween then
		self._pulseTween:Cancel()
		self._pulseTween = nil
	end
end

function StaminaBar:render()
	local stamina = self.props.stamina or {}
	local current = stamina.current or 0
	local max = stamina.max or 0

	local ratio = ratioOf(current, max)

	-- tampilkan angka yang rapi
	local currentInt = math.floor(current + 0.5)
	local maxInt = math.floor(max + 0.5)

	-- lebih solid (tidak terlalu transparan)
	local panelTransparency = 0.12
	local trackTransparency = 0.08 -- lebih solid dari 0.2

	return Roact.createElement("CanvasGroup", {
		Name = "StaminaBar",
		GroupTransparency = 1,

		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -34),
		Size = UDim2.new(0, 300, 0, 34),

		BackgroundTransparency = 1,
		[Roact.Ref] = self._containerRef,
	}, {
		Scale = Roact.createElement("UIScale", { Scale = 1 }),

		Frame = Roact.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Theme.Colors.Panel,
			BackgroundTransparency = panelTransparency,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, Theme.Radius.M),
			}),

			Stroke = Roact.createElement("UIStroke", {
				Color = Theme.Colors.Border,
				Transparency = 0.4,
				Thickness = 1,
			}),

			-- subtle highlight biar keliatan premium
			TopHighlight = Roact.createElement("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.72),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),

			-- Track + Fill
			Track = Roact.createElement("Frame", {
				Name = "Track",
				Size = UDim2.new(1, -94, 0, 9),
				Position = UDim2.new(0, 34, 0.5, -4),

				BackgroundColor3 = COLOR_TRACK,
				BackgroundTransparency = trackTransparency,
				BorderSizePixel = 0,
			}, {
				TrackCorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, Theme.Radius.S),
				}),

				Fill = Roact.createElement("Frame", {
					Name = "Fill",
					Size = UDim2.new(ratio, 0, 1, 0),
					BackgroundColor3 = Theme.Colors.Accent,
					BorderSizePixel = 0,
					[Roact.Ref] = self._fillRef,
				}, {
					FillCorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, Theme.Radius.S),
					}),

					Gradient = Roact.createElement("UIGradient", {
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 205, 255)),
							ColorSequenceKeypoint.new(1, Theme.Colors.Accent),
						}),
						Rotation = 0,
					}),
				}),

				InnerStroke = Roact.createElement("UIStroke", {
					Color = Theme.Colors.Border,
					Transparency = 0.55,
					Thickness = 1,
				}),
			}),

			-- Icon
			Icon = Roact.createElement("Frame", {
				Name = "Icon",
				Position = UDim2.new(0, 6, 0, 6),
				Size = UDim2.new(0, 20, 0, 20),
				BackgroundColor3 = Theme.Colors.AccentSoft,
				BackgroundTransparency = 0.05,
				BorderSizePixel = 0,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
				Stroke = Roact.createElement("UIStroke", {
					Color = Theme.Colors.Accent,
					Transparency = 0.15,
					Thickness = 1,
				}),
				Mark = Roact.createElement("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Text = "ST",
					TextColor3 = Theme.Colors.Text,
					TextSize = Theme.TypographySizes.Small,
					Font = Theme.Typography.Mono,
				}),
			}),

			-- Value Label
			Label = Roact.createElement("TextLabel", {
				Name = "Value",
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -66, 0, 2),
				Size = UDim2.new(0, 62, 1, 0),

				Text = string.format("%d/%d", currentInt, maxInt),
				TextColor3 = Theme.Colors.Text,
				TextSize = Theme.TypographySizes.Small,
				Font = Theme.Typography.Body,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),

			-- Exhausted badge
			Low = Roact.createElement("TextLabel", {
				Name = "Exhausted",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 34, 0.5, -13),
				Size = UDim2.new(0, 76, 0, 16),

				BackgroundColor3 = Theme.Colors.HeaderBar,
				BackgroundTransparency = 1,
				Text = "EXHAUSTED",
				TextColor3 = Theme.Colors.Warning,
				TextTransparency = 1,

				Font = Theme.Typography.Mono,
				TextSize = Theme.TypographySizes.Mono,
				[Roact.Ref] = self._warningRef,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),
				Stroke = Roact.createElement("UIStroke", {
					Color = Theme.Colors.Border,
					Transparency = 0.55,
					Thickness = 1,
				}),
			}),

			Glow = Roact.createElement("Frame", {
				Name = "Glow",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, 8, 1, 8),
				BackgroundTransparency = 1,
				Visible = false,
				[Roact.Ref] = self._glowRef,
			}, {
				Stroke = Roact.createElement("UIStroke", {
					Color = Theme.Colors.Warning,
					Transparency = 1,
					Thickness = 1,
					[Roact.Ref] = self._glowStrokeRef,
				}),
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, Theme.Radius.M + 2),
				}),
			}),
		}),
	})
end

local function mapStateToProps(state)
	return {
		stamina = state.Stamina,
	}
end

-- NOTE:
-- Kalau di project kamu connect({ "Stamina" }, mapStateToProps) memang pattern internal,
-- biarkan seperti aslinya. Kalau tidak perlu, bisa cukup connect(mapStateToProps).
return RoactRodux.connect({ "Stamina" }, mapStateToProps)(StaminaBar)
