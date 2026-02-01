--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage.Packages :: Folder
local Shared = ReplicatedStorage.Shared :: Folder

local Roact = require(Packages.Roact :: ModuleScript)
local RoactRodux = require(Packages:WaitForChild("Roact-Rodux") :: ModuleScript)
local Janitor = require(Packages.Janitor :: ModuleScript)
local Knit = require(Packages.Knit :: ModuleScript)

local SettingsConfig = require(Shared.Config.SettingsConfig :: ModuleScript)
local CameraConfig = require(Shared.Config.CameraConfig :: ModuleScript)
local SettingsState = require(script.Parent.Parent.Parent.Settings.SettingsState :: ModuleScript)
local Theme = require(Shared.Config.EndfieldTheme :: ModuleScript)
local PreferencesSchema = require(Shared.Config.PreferencesSchema :: ModuleScript)

local SettingsComponents = script.Parent:WaitForChild("Settings") :: Folder
local CardSurface = require(SettingsComponents:WaitForChild("CardSurface") :: ModuleScript)
local PanelHeader = require(SettingsComponents:WaitForChild("PanelHeader") :: ModuleScript)
local SidebarNavItem = require(SettingsComponents:WaitForChild("SidebarNavItem") :: ModuleScript)
local SectionHeaderBar = require(SettingsComponents:WaitForChild("SectionHeaderBar") :: ModuleScript)
local SliderRow = require(SettingsComponents:WaitForChild("SliderRow") :: ModuleScript)
local ToggleRow = require(SettingsComponents:WaitForChild("ToggleRow") :: ModuleScript)
local SettingsToast = require(SettingsComponents:WaitForChild("SettingsToast") :: ModuleScript)

local SettingsPanel = Roact.Component:extend("SettingsPanel")

type Props = {
	Visible: boolean,
	OnClose: () -> (),
	Viewport: {
		size: Vector2,
		shortSide: number,
		longSide: number,
		className: string,
		scale: number,
	}?,
}

type State = {
	Camera: any,
	Visual: any,
	Preferences: any,
	isVisible: boolean,
	activeCategory: string,
	toast: {
		text: string,
		context: string?,
		tone: "info" | "success" | "warning" | "danger",
	}?,
}

local CATEGORY_INFO = {
	Sound = { IconText = "SND" },
	Camera = { IconText = "CAM" },
	Display = { IconText = "DSP" },
	Controls = { IconText = "CTL" },
	Other = { IconText = "VFX" },
}

local function coerceNumber(value: any, fallback: number): number
	if type(value) == "number" then
		return value
	end
	local parsed = tonumber(value)
	if parsed then
		return parsed
	end
	return fallback
end

local function getPref(prefs, category: string, key: string)
	if prefs and prefs[category] and prefs[category][key] ~= nil then
		return prefs[category][key]
	end
	local def = PreferencesSchema.GetDefault(category, key)
	if def ~= nil then
		return def
	end
	return nil
end

local function clampAvailable(available: number, minValue: number, maxValue: number): number
	if available <= 0 then
		return maxValue
	end
	local lower = math.min(minValue, available)
	return math.clamp(available, lower, maxValue)
end

function SettingsPanel:init()
	self._janitor = Janitor.new()
	self._scaleRef = Roact.createRef()
	self._toastRef = Roact.createRef()
	self._scrollRef = Roact.createRef()
	self._navRefs = {
		Sound = Roact.createRef(),
		Camera = Roact.createRef(),
		Display = Roact.createRef(),
		Controls = Roact.createRef(),
		Other = Roact.createRef(),
	}
	self._categories = { "Sound", "Camera", "Display", "Controls", "Other" }

	self.state = {
		Camera = SettingsState:GetCamera(),
		Visual = SettingsState:GetVisual(),
		Preferences = PreferencesSchema.Defaults,
		isVisible = false,
		activeCategory = "Sound",
		toast = nil,
	}
end

function SettingsPanel:didMount()
	self._janitor:Add(SettingsState.Changed:Connect(function(category)
		if category == "Camera" then
			self:setState({
				Camera = SettingsState:GetCamera(),
			})
			self:_flash("Camera settings updated", "Camera", "success")
		elseif category == "Visual" then
			self:setState({
				Visual = SettingsState:GetVisual(),
			})
			self:_flash("Visual effects updated", "Display", "success")
		end
	end), "Disconnect")

	local ok, controller = pcall(function()
		return Knit.GetController("PreferencesController")
	end)
	if ok and controller then
		self._prefsController = controller
		self:setState({
			Preferences = controller:GetPreferences(),
		})
		self._janitor:Add(controller.Changed:Connect(function(prefs)
			self:setState({
				Preferences = prefs,
			})
			self:_flash("Preferences saved", "Profile", "success")
		end), "Disconnect")
	end

	self._janitor:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if not self.state.isVisible then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			self.props.OnClose()
		elseif input.KeyCode == Enum.KeyCode.ButtonL1 then
			self:_stepCategory(-1)
		elseif input.KeyCode == Enum.KeyCode.ButtonR1 then
			self:_stepCategory(1)
		end
	end), "Disconnect")

	if self.props.Visible then
		self:_open()
	end
end

function SettingsPanel:willUnmount()
	self._janitor:Cleanup()
end

function SettingsPanel:_resetDefaults()
	if self._prefsController then
		self._prefsController:ResetToDefaults()
	end

	SettingsState:SetCamera("Distance", CameraConfig.Distance)
	SettingsState:SetCamera("Sensitivity", CameraConfig.Sensitivity)
	SettingsState:SetCamera("TouchSensitivity", CameraConfig.TouchSensitivity)
	SettingsState:SetVisual("MotionBlur", 8)

	self:_flash("Defaults restored", "System", "warning")
end

function SettingsPanel:_flash(message: string, context: string?, tone: "info" | "success" | "warning" | "danger"?)
	self:setState({
		toast = {
			text = message,
			context = context,
			tone = tone or "info",
		},
	})
	local toast = self._toastRef:getValue()
	if not toast then
		return
	end
	toast.GroupTransparency = 1
	TweenService:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		GroupTransparency = 0,
	}):Play()
	task.delay(1.2, function()
		local current = self._toastRef:getValue()
		if not current then
			return
		end
		TweenService:Create(current, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			GroupTransparency = 1,
		}):Play()
	end)
end

function SettingsPanel:_open()
	self:setState({ isVisible = true })
	local scale = self._scaleRef:getValue()
	if scale then
		scale.Scale = 0.95
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end

	GuiService.AutoSelectGuiEnabled = true
	local nav = self._navRefs[self.state.activeCategory]
	local selected = nav and nav:getValue() or nil
	if selected then
		GuiService.SelectedObject = selected
	end

	local scroll = self._scrollRef:getValue()
	if scroll then
		scroll.CanvasPosition = Vector2.new(0, 0)
	end
end

function SettingsPanel:_close()
	local scale = self._scaleRef:getValue()
	if scale then
		TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.98 }):Play()
	end
	GuiService.AutoSelectGuiEnabled = false
	task.delay(0.12, function()
		self:setState({ isVisible = false })
	end)
end

function SettingsPanel:didUpdate(prevProps: Props)
	if self.props.Visible and not prevProps.Visible then
		self:_open()
	elseif not self.props.Visible and prevProps.Visible then
		self:_close()
	end
end

function SettingsPanel:_setCategory(category: string)
	self:setState({ activeCategory = category })
	local nav = self._navRefs[category]
	local selected = nav and nav:getValue() or nil
	if selected then
		GuiService.SelectedObject = selected
	end
	local scroll = self._scrollRef:getValue()
	if scroll then
		scroll.CanvasPosition = Vector2.new(0, 0)
	end
end

function SettingsPanel:_stepCategory(delta: number)
	local list = self._categories
	local current = self.state.activeCategory
	local index = 1
	for i, name in ipairs(list) do
		if name == current then
			index = i
			break
		end
	end
	local nextIndex = math.clamp(index + delta, 1, #list)
	self:_setCategory(list[nextIndex])
end

function SettingsPanel:_renderSound()
	local prefs = self.state.Preferences
	local soundSchema = PreferencesSchema.Schema.Sound

	return {
		SoundHeader = Roact.createElement(SectionHeaderBar, {
			Text = "Sound Settings",
			LayoutOrder = 1,
		}),
		Master = Roact.createElement(SliderRow, {
			Label = "Master Volume",
			Value = coerceNumber(getPref(prefs, "Sound", "Master"), soundSchema.Master.Default),
			Range = { Min = soundSchema.Master.Min, Max = soundSchema.Master.Max },
			OnChanged = function(value)
				if self._prefsController then
					self._prefsController:SetPreference("Sound", "Master", value)
				end
			end,
			LayoutOrder = 2,
		}),
		Music = Roact.createElement(SliderRow, {
			Label = "Music Volume",
			Value = coerceNumber(getPref(prefs, "Sound", "Music"), soundSchema.Music.Default),
			Range = { Min = soundSchema.Music.Min, Max = soundSchema.Music.Max },
			OnChanged = function(value)
				if self._prefsController then
					self._prefsController:SetPreference("Sound", "Music", value)
				end
			end,
			LayoutOrder = 3,
		}),
		Sfx = Roact.createElement(SliderRow, {
			Label = "SFX Volume",
			Value = coerceNumber(getPref(prefs, "Sound", "SFX"), soundSchema.SFX.Default),
			Range = { Min = soundSchema.SFX.Min, Max = soundSchema.SFX.Max },
			OnChanged = function(value)
				if self._prefsController then
					self._prefsController:SetPreference("Sound", "SFX", value)
				end
			end,
			LayoutOrder = 4,
		}),
	}
end

function SettingsPanel:_renderCamera()
	local prefs = self.state.Preferences
	local cameraSchema = PreferencesSchema.Schema.Camera

	return {
		CameraHeader = Roact.createElement(SectionHeaderBar, {
			Text = "Camera Settings",
			LayoutOrder = 1,
		}),
		Sensitivity = Roact.createElement(SliderRow, {
			Label = "Sensitivity",
			Value = coerceNumber(getPref(prefs, "Camera", "Sensitivity"), cameraSchema.Sensitivity.Default),
			Range = { Min = cameraSchema.Sensitivity.Min, Max = cameraSchema.Sensitivity.Max },
			OnChanged = function(value)
				if self._prefsController then
					self._prefsController:SetPreference("Camera", "Sensitivity", value)
				end
			end,
			LayoutOrder = 2,
		}),
		Fov = Roact.createElement(SliderRow, {
			Label = "Field of View",
			Value = coerceNumber(getPref(prefs, "Camera", "Fov"), cameraSchema.Fov.Default),
			Range = { Min = cameraSchema.Fov.Min, Max = cameraSchema.Fov.Max },
			OnChanged = function(value)
				if self._prefsController then
					self._prefsController:SetPreference("Camera", "Fov", value)
				end
			end,
			LayoutOrder = 3,
		}),
		InvertY = Roact.createElement(ToggleRow, {
			Label = "Invert Y",
			Enabled = getPref(prefs, "Camera", "InvertY") == true,
			OnChanged = function(value)
				if self._prefsController then
					self._prefsController:SetPreference("Camera", "InvertY", value)
				end
			end,
			LayoutOrder = 4,
		}),
		GameCameraHeader = Roact.createElement(SectionHeaderBar, {
			Text = "Gameplay Camera",
			LayoutOrder = 10,
		}),
		Distance = Roact.createElement(SliderRow, {
			Label = "Camera Distance",
			Value = coerceNumber(self.state.Camera.Distance, SettingsConfig.Camera.Distance.Min),
			Range = { Min = SettingsConfig.Camera.Distance.Min, Max = SettingsConfig.Camera.Distance.Max },
			OnChanged = function(value)
				SettingsState:SetCamera("Distance", value)
			end,
			LayoutOrder = 11,
		}),
		MouseSensitivity = Roact.createElement(SliderRow, {
			Label = "Mouse Sensitivity",
			Value = coerceNumber(self.state.Camera.Sensitivity, SettingsConfig.Camera.Sensitivity.Min),
			Range = { Min = SettingsConfig.Camera.Sensitivity.Min, Max = SettingsConfig.Camera.Sensitivity.Max },
			OnChanged = function(value)
				SettingsState:SetCamera("Sensitivity", value)
			end,
			LayoutOrder = 12,
		}),
		TouchSensitivity = Roact.createElement(SliderRow, {
			Label = "Touch Sensitivity",
			Value = coerceNumber(self.state.Camera.TouchSensitivity, SettingsConfig.Camera.TouchSensitivity.Min),
			Range = { Min = SettingsConfig.Camera.TouchSensitivity.Min, Max = SettingsConfig.Camera.TouchSensitivity.Max },
			OnChanged = function(value)
				SettingsState:SetCamera("TouchSensitivity", value)
			end,
			LayoutOrder = 13,
		}),
	}
end

function SettingsPanel:_renderDisplay()
	local prefs = self.state.Preferences

	return {
		DisplayHeader = Roact.createElement(SectionHeaderBar, {
			Text = "Display Settings",
			LayoutOrder = 1,
		}),
		DamageText = Roact.createElement(ToggleRow, {
			Label = "Show Damage Text",
			Enabled = getPref(prefs, "Display", "ShowDamageText") == true,
			OnChanged = function(value)
				if self._prefsController then
					self._prefsController:SetPreference("Display", "ShowDamageText", value)
				end
			end,
			LayoutOrder = 2,
		}),
		ShowVfx = Roact.createElement(ToggleRow, {
			Label = "Show VFX",
			Enabled = getPref(prefs, "Display", "ShowVfx") == true,
			OnChanged = function(value)
				if self._prefsController then
					self._prefsController:SetPreference("Display", "ShowVfx", value)
				end
			end,
			LayoutOrder = 3,
		}),
	}
end

function SettingsPanel:_renderControls()
	local prefs = self.state.Preferences

	return {
		ControlsHeader = Roact.createElement(SectionHeaderBar, {
			Text = "Controls",
			LayoutOrder = 1,
		}),
		HoldSprint = Roact.createElement(ToggleRow, {
			Label = "Hold to Sprint",
			Enabled = getPref(prefs, "Controls", "HoldSprint") == true,
			OnChanged = function(value)
				if self._prefsController then
					self._prefsController:SetPreference("Controls", "HoldSprint", value)
				end
			end,
			LayoutOrder = 2,
		}),
	}
end

function SettingsPanel:_renderOther()
	return {
		OtherHeader = Roact.createElement(SectionHeaderBar, {
			Text = "Visual Effects",
			LayoutOrder = 1,
		}),
		MotionBlur = Roact.createElement(SliderRow, {
			Label = "Motion Blur",
			Value = coerceNumber(self.state.Visual.MotionBlur, SettingsConfig.Visual.MotionBlur.Min),
			Range = { Min = SettingsConfig.Visual.MotionBlur.Min, Max = SettingsConfig.Visual.MotionBlur.Max },
			OnChanged = function(value)
				SettingsState:SetVisual("MotionBlur", value)
			end,
			LayoutOrder = 2,
		}),
	}
end

function SettingsPanel:_renderContent()
	local category = self.state.activeCategory
	if category == "Sound" then
		return self:_renderSound()
	elseif category == "Camera" then
		return self:_renderCamera()
	elseif category == "Display" then
		return self:_renderDisplay()
	elseif category == "Controls" then
		return self:_renderControls()
	end
	return self:_renderOther()
end

function SettingsPanel:render()
	local props = self.props :: Props
	if not self.state.isVisible then
		return nil
	end
	local toast = self.state.toast
	local viewport = props.Viewport
	local viewportSize = if viewport then viewport.size else Vector2.new(0, 0)
	local viewportClass = if viewport then viewport.className else "Desktop"
	local baseScale = if viewport then viewport.scale else 1

	local isPhone = viewportClass == "Phone"
	local isTablet = viewportClass == "Tablet"

	local panelMaxWidth = 980
	local panelMaxHeight = 560
	local panelMinWidth = if isPhone then 360 else if isTablet then 640 else 760
	local panelMinHeight = if isPhone then 300 else 440
	local outerMargin = if isPhone then (Theme.Spacing.M * 2) else 40
	local availableWidth = math.max(0, viewportSize.X - outerMargin)
	local availableHeight = math.max(0, viewportSize.Y - outerMargin)
	local panelWidth = if isPhone then availableWidth else clampAvailable(availableWidth, panelMinWidth, panelMaxWidth)
	local panelHeight = if isPhone then availableHeight else clampAvailable(availableHeight, panelMinHeight, panelMaxHeight)
	local panelMinConstraintWidth = math.min(panelMinWidth, panelWidth)
	local panelMinConstraintHeight = math.min(panelMinHeight, panelHeight)
	local panelMaxConstraintWidth = math.max(panelWidth, panelMinConstraintWidth)
	local panelMaxConstraintHeight = math.max(panelHeight, panelMinConstraintHeight)

	local headerHeight = if isPhone then 60 else 72
	local bodyTop = headerHeight + 8
	local bodyBottomInset = Theme.Spacing.L + Theme.Spacing.S
	local bodyHeightOffset = bodyTop + bodyBottomInset
	local sidebarIsTop = isPhone
	local sidebarWidth = if sidebarIsTop then (panelWidth - Theme.Spacing.L * 2) else if isTablet then 160 else 180
	local sidebarHeight = if sidebarIsTop then 44 else (panelHeight - bodyHeightOffset)
	local sideInset = Theme.Spacing.L
	local gutter = Theme.Spacing.M
	local contentX = if sidebarIsTop then sideInset else sideInset + sidebarWidth + gutter
	local contentTop = if sidebarIsTop then bodyTop + sidebarHeight + gutter else bodyTop
	local contentWidthOffset = if sidebarIsTop then sideInset * 2 else contentX + sideInset
	local contentHeightOffset = if sidebarIsTop then (contentTop + bodyBottomInset) else bodyHeightOffset

	local toastWidth = if isPhone then 220 else 260
	local toastX = if isPhone then -16 else -28
	local toastY = if isPhone then 72 else 92

	local navCount = #self._categories
	local navItemWidth = if sidebarIsTop then math.max(64, math.floor((panelWidth - (sideInset * 2) - (Theme.Spacing.XS * (navCount - 1))) / navCount)) else 0

	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 50,
	}, {
		Panel = Roact.createElement(CardSurface, {
			Size = if isPhone
				then UDim2.new(1, -(Theme.Spacing.M * 2), 1, -(Theme.Spacing.M * 2))
				else UDim2.fromOffset(panelWidth, panelHeight),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			LayoutOrder = 1,
			ZIndex = 52,
			Children = {
				BaseScale = Roact.createElement("UIScale", {
					Scale = if isPhone then 1 else baseScale,
				}),
				AnimScale = Roact.createElement("UIScale", {
					Scale = 1,
					[Roact.Ref] = self._scaleRef,
				}),
				SizeConstraint = Roact.createElement("UISizeConstraint", {
					MaxSize = Vector2.new(panelMaxConstraintWidth, panelMaxConstraintHeight),
					MinSize = Vector2.new(panelMinConstraintWidth, panelMinConstraintHeight),
				}),
				Header = Roact.createElement(PanelHeader, {
					Title = "Settings",
					Subtitle = "Graphics, Audio, Controls",
					ShortcutHint = if isPhone then nil else "P",
					Compact = isPhone,
					OnClose = function()
						props.OnClose()
					end,
					OnReset = function()
						self:_resetDefaults()
					end,
				}),
				Sidebar = Roact.createElement(CardSurface, {
					Position = if sidebarIsTop then UDim2.new(0, sideInset, 0, bodyTop) else UDim2.new(0, sideInset, 0, bodyTop),
					Size = if sidebarIsTop
						then UDim2.new(1, -(sideInset * 2), 0, sidebarHeight)
						else UDim2.new(0, sidebarWidth, 1, -bodyHeightOffset),
					Children = {
					Layout = Roact.createElement("UIListLayout", {
						Padding = UDim.new(0, Theme.Spacing.XS),
						SortOrder = Enum.SortOrder.LayoutOrder,
						FillDirection = if sidebarIsTop then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
						HorizontalAlignment = if sidebarIsTop then Enum.HorizontalAlignment.Center else Enum.HorizontalAlignment.Left,
						VerticalAlignment = if sidebarIsTop then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top,
					}),
					Padding = Roact.createElement("UIPadding", {
						PaddingTop = UDim.new(0, if sidebarIsTop then Theme.Spacing.XS else Theme.Spacing.S),
						PaddingLeft = UDim.new(0, if sidebarIsTop then Theme.Spacing.S else Theme.Spacing.M),
						PaddingRight = UDim.new(0, if sidebarIsTop then Theme.Spacing.S else Theme.Spacing.M),
						PaddingBottom = UDim.new(0, if sidebarIsTop then Theme.Spacing.XS else Theme.Spacing.S),
					}),
					Sound = Roact.createElement(SidebarNavItem, {
						Text = "Sound",
						IconText = CATEGORY_INFO.Sound.IconText,
						Active = self.state.activeCategory == "Sound",
						LayoutOrder = 1,
						Ref = self._navRefs.Sound,
						Compact = sidebarIsTop,
						Size = if sidebarIsTop then UDim2.new(0, navItemWidth, 1, 0) else nil,
						OnActivated = function()
							self:_setCategory("Sound")
						end,
					}),
					Camera = Roact.createElement(SidebarNavItem, {
						Text = "Camera",
						IconText = CATEGORY_INFO.Camera.IconText,
						Active = self.state.activeCategory == "Camera",
						LayoutOrder = 2,
						Ref = self._navRefs.Camera,
						Compact = sidebarIsTop,
						Size = if sidebarIsTop then UDim2.new(0, navItemWidth, 1, 0) else nil,
						OnActivated = function()
							self:_setCategory("Camera")
						end,
					}),
					Display = Roact.createElement(SidebarNavItem, {
						Text = "Display",
						IconText = CATEGORY_INFO.Display.IconText,
						Active = self.state.activeCategory == "Display",
						LayoutOrder = 3,
						Ref = self._navRefs.Display,
						Compact = sidebarIsTop,
						Size = if sidebarIsTop then UDim2.new(0, navItemWidth, 1, 0) else nil,
						OnActivated = function()
							self:_setCategory("Display")
						end,
					}),
					Controls = Roact.createElement(SidebarNavItem, {
						Text = "Controls",
						IconText = CATEGORY_INFO.Controls.IconText,
						Active = self.state.activeCategory == "Controls",
						LayoutOrder = 4,
						Ref = self._navRefs.Controls,
						Compact = sidebarIsTop,
						Size = if sidebarIsTop then UDim2.new(0, navItemWidth, 1, 0) else nil,
						OnActivated = function()
							self:_setCategory("Controls")
						end,
					}),
					Other = Roact.createElement(SidebarNavItem, {
						Text = "Other",
						IconText = CATEGORY_INFO.Other.IconText,
						Active = self.state.activeCategory == "Other",
						LayoutOrder = 5,
						Ref = self._navRefs.Other,
						Compact = sidebarIsTop,
						Size = if sidebarIsTop then UDim2.new(0, navItemWidth, 1, 0) else nil,
						OnActivated = function()
							self:_setCategory("Other")
						end,
					}),
				},
				}),
				ContentCard = Roact.createElement(CardSurface, {
					Position = UDim2.new(0, contentX, 0, contentTop),
					Size = UDim2.new(1, -contentWidthOffset, 1, -contentHeightOffset),
					ZIndex = 52,
					Children = {
						Scroll = Roact.createElement("ScrollingFrame", {
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							CanvasSize = UDim2.new(0, 0, 0, 0),
							AutomaticCanvasSize = Enum.AutomaticSize.Y,
							ScrollBarThickness = if isPhone then 6 else 8,
							ScrollBarImageColor3 = Theme.Colors.Border,
							ScrollingDirection = Enum.ScrollingDirection.Y,
							ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
							[Roact.Ref] = self._scrollRef,
							ZIndex = 53,
						}, {
					Layout = Roact.createElement("UIListLayout", {
						Padding = UDim.new(0, Theme.Spacing.S),
						SortOrder = Enum.SortOrder.LayoutOrder,
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
					}),
					Padding = Roact.createElement("UIPadding", {
						PaddingTop = UDim.new(0, Theme.Spacing.S),
						PaddingLeft = UDim.new(0, Theme.Spacing.S),
						PaddingRight = UDim.new(0, Theme.Spacing.S),
						PaddingBottom = UDim.new(0, Theme.Spacing.M),
					}),
					Content = Roact.createFragment(self:_renderContent()),
						}),
					},
				}),
			},
		}),
		Toast = Roact.createElement("CanvasGroup", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, toastX, 0, toastY),
			Size = UDim2.new(0, toastWidth, 0, 44),
			GroupTransparency = 1,
			BackgroundTransparency = 1,
			[Roact.Ref] = self._toastRef,
			ZIndex = 60,
		}, {
			Shadow = Roact.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 2, 0.5, 3),
				Size = UDim2.new(1, 4, 1, 4),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
				ZIndex = 59,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, Theme.Radius.S),
				}),
			}),
			Body = Roact.createElement(SettingsToast, {
				Text = toast and toast.text or "",
				Context = toast and toast.context or "",
				Tone = toast and toast.tone or "info",
			}),
		}),
	})
end

local function mapStateToProps(state)
	return {
		Viewport = state.UI and state.UI.Viewport or nil,
	}
end

return RoactRodux.connect({ "UI" }, mapStateToProps)(SettingsPanel)
