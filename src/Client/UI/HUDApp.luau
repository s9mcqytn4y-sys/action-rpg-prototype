local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)
local AssetIds = require(Shared:WaitForChild("Config"):WaitForChild("AssetIds") :: ModuleScript)

local HUDRoot = require(script.Parent.Components:WaitForChild("HUDRoot") :: ModuleScript)
local SettingsPanel = require(script.Parent.Components:WaitForChild("SettingsPanel") :: ModuleScript)
local SprintButton = require(script.Parent.Components:WaitForChild("SprintButton") :: ModuleScript)

local HUDApp = Roact.Component:extend("HUDApp")

function HUDApp:init()
	self.state = {
		showSettings = false,
		pressed = false,
	}

	self.toggleSettings = function()
		self:setState(function(prev)
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
	local pressed = self.state.pressed
	local buttonScale = pressed and 0.96 or 1
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

			HUD = Roact.createElement(HUDRoot),

			SprintButton = Roact.createElement(SprintButton),

			SettingsButton = Roact.createElement("ImageButton", {
				Name = "SettingsButton",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -18, 0, 18),
				Size = UDim2.new(0, 40, 0, 36),

				Image = AssetIds.Icons.Settings,
				ImageColor3 = Theme.Colors.Text,
				BackgroundColor3 = Theme.Colors.PanelAlt,
				BackgroundTransparency = 0.08,
				AutoButtonColor = true,


				Selectable = true,
				SelectionOrder = 1,

				[Roact.Event.Activated] = self.toggleSettings,

				-- tiny press feedback
				[Roact.Event.MouseButton1Down] = function()
					self:setState({ pressed = true })
				end,
				[Roact.Event.MouseButton1Up] = function()
					self:setState({ pressed = false })
				end,
				[Roact.Event.MouseLeave] = function()
					if self.state.pressed then
						self:setState({ pressed = false })
					end
				end,
				[Roact.Event.TouchLongPress] = function(_, state)
					-- optional: treat long press as "pressed" while holding
					self:setState({ pressed = state == Enum.UserInputState.Begin })
				end,
			}, {
				Scale = Roact.createElement("UIScale", {
					Scale = buttonScale,
				}),

				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, Theme.Radius.M),
				}),

				Stroke = Roact.createElement("UIStroke", {
					Color = Theme.Colors.Border,
					Transparency = 0.35,
					Thickness = 1,
				}),

				Highlight = Roact.createElement("UIGradient", {
					Rotation = 90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.8),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
			}),

			Settings = Roact.createElement(SettingsPanel, {
				Visible = self.state.showSettings,
				OnClose = self.closeSettings,
			}),
		}),
	})
end

return HUDApp
