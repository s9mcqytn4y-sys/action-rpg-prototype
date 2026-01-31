local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)
local InteractionConfig = require(Shared:WaitForChild("Config"):WaitForChild("InteractionConfig") :: ModuleScript)

local HUDRoot = require(script.Parent.Components:WaitForChild("HUDRoot") :: ModuleScript)
local SettingsPanel = require(script.Parent.Components:WaitForChild("SettingsPanel") :: ModuleScript)
local SprintButton = require(script.Parent.Components:WaitForChild("SprintButton") :: ModuleScript)

local HUDApp = Roact.Component:extend("HUDApp")

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
			if self._settingsSound then
				self._settingsSound.TimePosition = 0
				self._settingsSound:Play()
			end
			return { showSettings = not prev.showSettings }
		end)
	end

	self.closeSettings = function()
		self:setState({ showSettings = false })
	end
end

function HUDApp:didMount()
	self._inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.F10 or input.KeyCode == Enum.KeyCode.P then
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
end

function HUDApp:render()
	local guiInset = GuiService:GetGuiInset()

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
			UIPadding = Roact.createElement("UIPadding", {
				PaddingTop = UDim.new(0, guiInset.Y),
				PaddingBottom = UDim.new(0, 0),
				PaddingLeft = UDim.new(0, guiInset.X),
				PaddingRight = UDim.new(0, 0),
			}),

			SettingsButton = Roact.createElement("ImageButton", {
				Name = "SettingsButton",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -18, 0, 18),
				Size = UDim2.new(0, 36, 0, 36),

				Image = "rbxasset://textures/ui/SettingsIcon.png",
				ImageColor3 = Theme.Colors.Text,
				BackgroundTransparency = 1,
				AutoButtonColor = true,

				Selectable = true,
				SelectionOrder = 1,

				[Roact.Event.Activated] = self.toggleSettings,
			}),

			HUD = Roact.createElement(HUDRoot),

			SprintButton = Roact.createElement(SprintButton),

			Settings = Roact.createElement(SettingsPanel, {
				Visible = self.state.showSettings,
				OnClose = self.closeSettings,
			}),
		}),
	})
end

return HUDApp
