--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages :: Folder
local Shared = ReplicatedStorage.Shared :: Folder

local Roact = require(Packages.Roact :: ModuleScript)
local Janitor = require(Packages.Janitor :: ModuleScript)
local TweenService = game:GetService("TweenService")

local SettingsConfig = require(Shared.Config.SettingsConfig :: ModuleScript)
local SettingsState = require(script.Parent.Parent.Parent.Settings.SettingsState :: ModuleScript)
local UITheme = require(Shared.Config.UITheme :: ModuleScript)
local Slider = require(script.Parent.Controls:WaitForChild("Slider") :: ModuleScript)

type CameraSettings = {
	Distance: number,
	Sensitivity: number,
	AimSensitivity: number,
	TouchSensitivity: number,
	AimTouchSensitivity: number,
}

type VisualSettings = {
	MotionBlur: number,
}

type CameraSettingKey = "Distance" | "Sensitivity" | "AimSensitivity" | "TouchSensitivity" | "AimTouchSensitivity"
type VisualSettingKey = "MotionBlur"

type Props = {
	Visible: boolean,
	OnClose: () -> (),
}

type State = {
	Camera: CameraSettings,
	Visual: VisualSettings,
	isVisible: boolean,
}

local SettingsPanel = Roact.Component:extend("SettingsPanel")

function SettingsPanel:init()
	self._janitor = Janitor.new()
	self._rootRef = Roact.createRef()
	self._scaleRef = Roact.createRef()
	self.state = {
		Camera = SettingsState:GetCamera(),
		Visual = SettingsState:GetVisual(),
		isVisible = false,
	}
end

function SettingsPanel:didMount()
	self._janitor:Add(SettingsState.Changed:Connect(function(category)
		if category == "Camera" then
			self:setState({
				Camera = SettingsState:GetCamera(),
			})
		elseif category == "Visual" then
			self:setState({
				Visual = SettingsState:GetVisual(),
			})
		end
	end), "Disconnect")

	if self.props.Visible then
		self:_open()
	end
end

function SettingsPanel:willUnmount()
	self._janitor:Cleanup()
end

local function formatValue(value: number): string
	local absValue = math.abs(value)
	if absValue < 0.01 then
		return string.format("%.4f", value)
	end
	if absValue < 1 then
		return string.format("%.3f", value)
	end
	return string.format("%.2f", value)
end

function SettingsPanel:_stepCamera(key: CameraSettingKey, delta: number)
	local ranges = SettingsConfig.Camera
	local range = (ranges :: any)[key]
	if not range then
		return
	end
	local current = SettingsState:GetCamera()[key]
	local nextValue = current + delta
	SettingsState:SetCamera(key, nextValue)
end

function SettingsPanel:_stepVisual(key: VisualSettingKey, delta: number)
	local ranges = SettingsConfig.Visual
	local range = (ranges :: any)[key]
	if not range then
		return
	end
	local current = SettingsState:GetVisual()[key]
	local nextValue = current + delta
	SettingsState:SetVisual(key, nextValue)
end

function SettingsPanel:_renderRow(label: string, value: number, _step: number, onMinus: () -> (), onPlus: () -> (), layoutOrder: number?)
	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = UITheme.Colors.PanelAlt,
		BackgroundTransparency = 0.1,
		LayoutOrder = layoutOrder,
	}, {
		Accent = Roact.createElement("Frame", {
			Position = UDim2.new(0, 0, 0, 6),
			Size = UDim2.new(0, 3, 1, -12),
			BackgroundColor3 = UITheme.Colors.Accent,
			BorderSizePixel = 0,
		}),
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, UITheme.Radius.S),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = UITheme.Colors.Stroke,
			Transparency = 0.6,
			Thickness = 1,
		}),
		Label = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.55, 0, 1, 0),
			Text = label,
			TextColor3 = UITheme.Colors.TextPrimary,
			TextScaled = true,
			Font = UITheme.Typography.Body,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Value = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.2, 0, 1, 0),
			Position = UDim2.new(0.55, 0, 0, 0),
			Text = formatValue(value),
			TextColor3 = UITheme.Colors.TextSecondary,
			TextScaled = true,
			Font = UITheme.Typography.Mono,
		}),
		Minus = Roact.createElement("TextButton", {
			Size = UDim2.new(0, 28, 0, 28),
			Position = UDim2.new(0.78, 0, 0, 3),
			Text = "-",
			TextColor3 = UITheme.Colors.TextPrimary,
			BackgroundColor3 = UITheme.Colors.Panel,
			AutoButtonColor = true,
			Font = UITheme.Typography.Title,
			TextScaled = true,
			[Roact.Event.Activated] = onMinus,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, UITheme.Radius.S),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = UITheme.Colors.Stroke,
				Transparency = 0.5,
				Thickness = 1,
			}),
		}),
		Plus = Roact.createElement("TextButton", {
			Size = UDim2.new(0, 28, 0, 28),
			Position = UDim2.new(0.88, 0, 0, 3),
			Text = "+",
			TextColor3 = UITheme.Colors.TextPrimary,
			BackgroundColor3 = UITheme.Colors.AccentSoft,
			AutoButtonColor = true,
			Font = UITheme.Typography.Title,
			TextScaled = true,
			[Roact.Event.Activated] = onPlus,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, UITheme.Radius.S),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = UITheme.Colors.Accent,
				Transparency = 0.35,
				Thickness = 1,
			}),
		}),
	})
end

function SettingsPanel:_renderSliderRow(label: string, value: number, range: { Min: number, Max: number }, onChanged: (number) -> (), layoutOrder: number)
	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = UITheme.Colors.PanelAlt,
		BackgroundTransparency = 0.1,
		LayoutOrder = layoutOrder,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, UITheme.Radius.S),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = UITheme.Colors.Stroke,
			Transparency = 0.6,
			Thickness = 1,
		}),
		Label = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 8, 0, 4),
			Size = UDim2.new(0.6, 0, 0, 16),
			Text = label,
			TextColor3 = UITheme.Colors.TextPrimary,
			TextScaled = true,
			Font = UITheme.Typography.Body,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Value = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.7, 0, 0, 4),
			Size = UDim2.new(0.3, -8, 0, 16),
			Text = formatValue(value),
			TextColor3 = UITheme.Colors.TextSecondary,
			TextScaled = true,
			Font = UITheme.Typography.Mono,
			TextXAlignment = Enum.TextXAlignment.Right,
		}),
		Slider = Roact.createElement(Slider, {
			Min = range.Min,
			Max = range.Max,
			Value = value,
			OnChanged = onChanged,
		}),
	})
end

function SettingsPanel:_renderCameraRow(label: string, key: CameraSettingKey, layoutOrder: number)
	local value = self.state.Camera[key]
	local range = (SettingsConfig.Camera :: any)[key]
	local step = if range then range.Step else 0.01

	return self:_renderRow(label, value, step, function()
		self:_stepCamera(key, -step)
	end, function()
		self:_stepCamera(key, step)
	end, layoutOrder)
end

function SettingsPanel:_renderVisualRow(label: string, key: VisualSettingKey, layoutOrder: number)
	local value = self.state.Visual[key]
	local range = (SettingsConfig.Visual :: any)[key]
	local step = if range then range.Step else 1

	return self:_renderRow(label, value, step, function()
		self:_stepVisual(key, -step)
	end, function()
		self:_stepVisual(key, step)
	end, layoutOrder)
end

function SettingsPanel:_open()
	self:setState({
		isVisible = true,
	})
	local scale = self._scaleRef:getValue()
	if scale then
		scale.Scale = 0.96
		TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
end

function SettingsPanel:_close()
	local scale = self._scaleRef:getValue()
	if scale then
		TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.98 }):Play()
	end
	task.delay(0.12, function()
		self:setState({
			isVisible = false,
		})
	end)
end

function SettingsPanel:didUpdate(prevProps: Props)
	if self.props.Visible and not prevProps.Visible then
		self:_open()
	elseif not self.props.Visible and prevProps.Visible then
		self:_close()
	end
end

function SettingsPanel:render()
	local props = self.props :: Props
	if not self.state.isVisible then
		return nil
	end

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 18),
		Size = UDim2.new(0, 520, 0, 360),
		BackgroundColor3 = UITheme.Colors.Panel,
		BorderSizePixel = 0,
		[Roact.Ref] = self._rootRef,
	}, {
		Gradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, UITheme.Colors.PanelAlt),
				ColorSequenceKeypoint.new(1, UITheme.Colors.Panel),
			}),
			Rotation = 90,
		}),
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, UITheme.Radius.M),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = UITheme.Colors.Stroke,
			Transparency = 0.45,
			Thickness = 1,
		}),
		Scale = Roact.createElement("UIScale", {
			Scale = 1,
			[Roact.Ref] = self._scaleRef,
		}),
		SizeConstraint = Roact.createElement("UISizeConstraint", {
			MaxSize = Vector2.new(620, 420),
			MinSize = Vector2.new(440, 320),
		}),
		Title = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, UITheme.Spacing.M, 0, UITheme.Spacing.S),
			Size = UDim2.new(1, -48, 0, 28),
			Text = "Settings Dashboard",
			TextColor3 = UITheme.Colors.TextPrimary,
			TextScaled = true,
			Font = UITheme.Typography.Title,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		TitleIcon = Roact.createElement("Frame", {
			Position = UDim2.new(0, UITheme.Spacing.M, 0, 10),
			Size = UDim2.new(0, 12, 0, 12),
			BackgroundColor3 = UITheme.Colors.Accent,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 3),
			}),
		}),
		Subtitle = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, UITheme.Spacing.M, 0, 34),
			Size = UDim2.new(1, -48, 0, 18),
			Text = "Performance + Control",
			TextColor3 = UITheme.Colors.TextSecondary,
			TextScaled = true,
			Font = UITheme.Typography.Mono,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Close = Roact.createElement("TextButton", {
			Position = UDim2.new(1, -36, 0, 10),
			Size = UDim2.new(0, 24, 0, 24),
			Text = "X",
			TextColor3 = UITheme.Colors.TextPrimary,
			BackgroundColor3 = UITheme.Colors.PanelAlt,
			AutoButtonColor = true,
			Font = UITheme.Typography.Title,
			TextScaled = true,
			[Roact.Event.Activated] = function()
				props.OnClose()
			end,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, UITheme.Radius.S),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = UITheme.Colors.Stroke,
				Transparency = 0.5,
				Thickness = 1,
			}),
		}),
		Sidebar = Roact.createElement("Frame", {
			Position = UDim2.new(0, UITheme.Spacing.M, 0, 64),
			Size = UDim2.new(0, 120, 1, -82),
			BackgroundColor3 = UITheme.Colors.PanelAlt,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, UITheme.Radius.M),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = UITheme.Colors.Stroke,
				Transparency = 0.6,
				Thickness = 1,
			}),
			List = Roact.createElement("UIListLayout", {
				Padding = UDim.new(0, UITheme.Spacing.S),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
			}),
			Padding = Roact.createElement("UIPadding", {
				PaddingTop = UDim.new(0, UITheme.Spacing.M),
				PaddingLeft = UDim.new(0, UITheme.Spacing.S),
				PaddingRight = UDim.new(0, UITheme.Spacing.S),
			}),
			NavDisplay = Roact.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20),
				Text = "DISPLAY",
				TextColor3 = UITheme.Colors.TextPrimary,
				TextScaled = true,
				Font = UITheme.Typography.Body,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
			}),
			NavControl = Roact.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20),
				Text = "CONTROL",
				TextColor3 = UITheme.Colors.TextSecondary,
				TextScaled = true,
				Font = UITheme.Typography.Body,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 2,
			}),
			NavGame = Roact.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20),
				Text = "GAME",
				TextColor3 = UITheme.Colors.TextSecondary,
				TextScaled = true,
				Font = UITheme.Typography.Body,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 3,
			}),
		}),
		Content = Roact.createElement("Frame", {
			Position = UDim2.new(0, 152, 0, 64),
			Size = UDim2.new(1, -168, 1, -82),
			BackgroundTransparency = 1,
		}, {
			Layout = Roact.createElement("UIListLayout", {
				Padding = UDim.new(0, UITheme.Spacing.S),
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
			}),
			SectionCamera = Roact.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				Text = "CAMERA",
				TextColor3 = UITheme.Colors.TextSecondary,
				TextScaled = true,
				Font = UITheme.Typography.Mono,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
			}),
			Distance = self:_renderCameraRow("Camera Distance", "Distance", 2),
			Sensitivity = self:_renderCameraRow("Sensitivity (Mouse)", "Sensitivity", 3),
			AimSensitivity = self:_renderCameraRow("Aim Sensitivity", "AimSensitivity", 4),
			TouchSensitivity = self:_renderCameraRow("Sensitivity (Touch)", "TouchSensitivity", 5),
			AimTouchSensitivity = self:_renderCameraRow("Aim Sensitivity (Touch)", "AimTouchSensitivity", 6),
			SectionVisual = Roact.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				Text = "VISUALS",
				TextColor3 = UITheme.Colors.TextSecondary,
				TextScaled = true,
				Font = UITheme.Typography.Mono,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 100,
			}),
			MotionBlur = self:_renderSliderRow("Motion Blur (Cinematic)", self.state.Visual.MotionBlur, SettingsConfig.Visual.MotionBlur, function(value)
				SettingsState:SetVisual("MotionBlur", value)
			end, 101),
		}),
	})
end

return SettingsPanel
