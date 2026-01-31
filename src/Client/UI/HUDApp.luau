local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("Config"):WaitForChild("UITheme") :: ModuleScript)

local HUDRoot = require(script.Parent.Components:WaitForChild("HUDRoot") :: ModuleScript)
local SettingsPanel = require(script.Parent.Components:WaitForChild("SettingsPanel") :: ModuleScript)
local AimButton = require(script.Parent.Components:WaitForChild("AimButton") :: ModuleScript)
local AimReticle = require(script.Parent.Components:WaitForChild("AimReticle") :: ModuleScript)
local SprintButton = require(script.Parent.Components:WaitForChild("SprintButton") :: ModuleScript)

local HUDApp = Roact.Component:extend("HUDApp")

function HUDApp:init()
	self.state = {
		showSettings = false,
	}
end

function HUDApp:render()
	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		HUD = Roact.createElement(HUDRoot),
		Reticle = Roact.createElement(AimReticle),
		SettingsButton = Roact.createElement("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -18, 0, 18),
			Size = UDim2.new(0, 36, 0, 36),
			Text = "SET",
			TextColor3 = UITheme.Colors.TextPrimary,
			BackgroundColor3 = UITheme.Colors.PanelAlt,
			AutoButtonColor = true,
			Font = UITheme.Typography.Title,
			TextScaled = true,
			[Roact.Event.Activated] = function()
				self:setState(function(prevState)
					return {
						showSettings = not prevState.showSettings,
					}
				end)
			end,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, UITheme.Radius.M),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = UITheme.Colors.Stroke,
				Transparency = 0.4,
				Thickness = 1,
			}),
		}),
		AimButton = Roact.createElement(AimButton),
		SprintButton = Roact.createElement(SprintButton),
		Settings = Roact.createElement(SettingsPanel, {
			Visible = self.state.showSettings,
			OnClose = function()
				self:setState({
					showSettings = false,
				})
			end,
		}),
	})
end

return HUDApp
