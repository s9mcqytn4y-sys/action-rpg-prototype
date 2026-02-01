--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)
local InteractionConfig = require(Shared:WaitForChild("Config"):WaitForChild("InteractionConfig") :: ModuleScript)
local TweenUtil = require(Shared:WaitForChild("Util"):WaitForChild("TweenUtil") :: ModuleScript)

type TweenMap = { [Instance]: Tween }

type InteractionPrompt = {
	SetVisible: (self: InteractionPrompt, isVisible: boolean) -> (),
	SetText: (self: InteractionPrompt, text: string) -> (),
	SetAdornee: (self: InteractionPrompt, target: Instance?) -> (),
	PulseSuccess: (self: InteractionPrompt) -> (),
	Destroy: (self: InteractionPrompt) -> (),
}

type InteractionPromptImpl = InteractionPrompt & {
	_gui: BillboardGui,
	_frame: Frame,
	_label: TextLabel,
	_keyLabel: TextLabel,
	_scale: UIScale,
	_stroke: UIStroke,
	_shadow: Frame,
	_tweens: TweenMap,
}

local InteractionPrompt = {}
InteractionPrompt.__index = InteractionPrompt

local GUI_NAME = "InteractionPromptGui"

local function getAdornee(target: Instance?): BasePart?
	if not target then
		return nil
	end
	if target:IsA("BasePart") then
		return target
	end
	if target:IsA("Model") then
		local primary = target.PrimaryPart
		if primary then
			return primary
		end
		local part = target:FindFirstChildWhichIsA("BasePart")
		if part then
			return part
		end
	end
	return nil
end

function InteractionPrompt.new(playerGui: PlayerGui): InteractionPrompt
	local existing = playerGui:FindFirstChild(GUI_NAME)
	if existing and existing:IsA("BillboardGui") then
		local label = existing:FindFirstChild("PromptLabel", true)
		local keyLabel = existing:FindFirstChild("KeyLabel", true)
		local frame = existing:FindFirstChild("PromptFrame", true)
		if label and keyLabel and frame and label:IsA("TextLabel") and keyLabel:IsA("TextLabel") and frame:IsA("Frame") then
			return setmetatable({
				_gui = existing,
				_frame = frame,
				_label = label,
				_keyLabel = keyLabel,
				_tweens = {},
			}, InteractionPrompt) :: InteractionPromptImpl
		end
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = GUI_NAME
	gui.ResetOnSpawn = false
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Size = InteractionConfig.PromptBillboardSize
	gui.StudsOffset = InteractionConfig.PromptStudsOffset
	gui.Enabled = false

	local frame = Instance.new("Frame")
	frame.Name = "PromptFrame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Theme.Colors.Panel
	frame.BackgroundTransparency = InteractionConfig.PromptHiddenTransparency
	frame.Parent = gui

	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.fromScale(0.5, 0.55)
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.BackgroundColor3 = Theme.Colors.Background
	shadow.BackgroundTransparency = 1
	shadow.ZIndex = frame.ZIndex - 1
	shadow.Parent = gui

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, Theme.Radius.M)
	shadowCorner.Parent = shadow

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Radius.M)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.Border
	stroke.Transparency = 0.3
	stroke.Thickness = 1
	stroke.Parent = frame

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, InteractionConfig.PromptPadding)
	padding.PaddingRight = UDim.new(0, InteractionConfig.PromptPadding)
	padding.Parent = frame

	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	gradient.Parent = frame

	local keycap = Instance.new("Frame")
	keycap.Name = "Keycap"
	keycap.BackgroundColor3 = Theme.Colors.Accent
	keycap.BackgroundTransparency = 0
	keycap.Size = UDim2.fromOffset(34, 28)
	keycap.Parent = frame

	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, Theme.Radius.S)
	keyCorner.Parent = keycap

	local keyStroke = Instance.new("UIStroke")
	keyStroke.Color = Theme.Colors.Border
	keyStroke.Transparency = 0.5
	keyStroke.Thickness = 1
	keyStroke.Parent = keycap

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Name = "KeyLabel"
	keyLabel.BackgroundTransparency = 1
	keyLabel.TextColor3 = Theme.Colors.Background
	keyLabel.TextSize = InteractionConfig.PromptTextSize
	keyLabel.Font = Theme.Typography.Title
	keyLabel.TextXAlignment = Enum.TextXAlignment.Center
	keyLabel.TextYAlignment = Enum.TextYAlignment.Center
	keyLabel.Size = UDim2.fromScale(1, 1)
	keyLabel.Text = "E"
	keyLabel.TextTransparency = InteractionConfig.PromptHiddenTransparency
	keyLabel.Parent = keycap

	local label = Instance.new("TextLabel")
	label.Name = "PromptLabel"
	label.BackgroundTransparency = 1
	label.TextColor3 = Theme.Colors.Text
	label.TextSize = InteractionConfig.PromptTextSize
	label.Font = Theme.Typography.Body
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Size = UDim2.fromScale(1, 1)
	label.Text = InteractionConfig.PromptText
	label.TextTransparency = InteractionConfig.PromptHiddenTransparency
	label.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = frame

	gui.Parent = playerGui

	return setmetatable({
		_gui = gui,
		_frame = frame,
		_label = label,
		_keyLabel = keyLabel,
		_scale = scale,
		_stroke = stroke,
		_shadow = shadow,
		_tweens = {},
	}, InteractionPrompt) :: InteractionPromptImpl
end

function InteractionPrompt:SetVisible(isVisible: boolean)
	self._gui.Enabled = true
	if not isVisible then
		self._gui.Adornee = nil
	end
	local targetTransparency = if isVisible then Theme.Transparency.PanelAlt else InteractionConfig.PromptHiddenTransparency
	local labelTransparency = if isVisible then 0 else InteractionConfig.PromptHiddenTransparency
	local shadowTransparency = if isVisible then 0.6 else 1
	local info = TweenInfo.new(InteractionConfig.PromptTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenUtil.play(self._tweens, self._frame, info, {
		BackgroundTransparency = targetTransparency,
	})
	TweenUtil.play(self._tweens, self._label, info, {
		TextTransparency = labelTransparency,
	})
	TweenUtil.play(self._tweens, self._keyLabel, info, {
		TextTransparency = labelTransparency,
	})
	TweenUtil.play(self._tweens, self._shadow, info, {
		BackgroundTransparency = shadowTransparency,
	})
	if not isVisible then
		task.delay(InteractionConfig.PromptTweenTime, function()
			if self._frame.BackgroundTransparency >= InteractionConfig.PromptHiddenTransparency then
				self._gui.Enabled = false
			end
		end)
	end
end

function InteractionPrompt:SetText(text: string)
	self._label.Text = text
end

function InteractionPrompt:SetAdornee(target: Instance?)
	self._gui.Adornee = getAdornee(target)
end

function InteractionPrompt:PulseSuccess()
	local infoUp = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local infoDown = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenUtil.play(self._tweens, self._scale, infoUp, {
		Scale = 1.06,
	})
	TweenUtil.play(self._tweens, self._stroke, infoUp, {
		Color = Theme.Colors.Accent,
		Transparency = 0.05,
	})
	task.delay(0.08, function()
		TweenUtil.play(self._tweens, self._scale, infoDown, {
			Scale = 1,
		})
		TweenUtil.play(self._tweens, self._stroke, infoDown, {
			Color = Theme.Colors.Border,
			Transparency = 0.3,
		})
	end)
end

function InteractionPrompt:Destroy()
	TweenUtil.cancelAll(self._tweens)
	self._gui:Destroy()
end

return InteractionPrompt
