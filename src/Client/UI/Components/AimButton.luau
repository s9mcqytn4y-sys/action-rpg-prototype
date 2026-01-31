local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("Config"):WaitForChild("UITheme") :: ModuleScript)

local AimButton = Roact.Component:extend("AimButton")

function AimButton:init()
	self.state = {
		isAiming = false,
	}
end

function AimButton:_setAim(nextAim: boolean)
	self:setState({
		isAiming = nextAim,
	})
	local ok, controller = pcall(function()
		return Knit.GetController("ThirdPersonController")
	end)
	if ok and controller and controller.SetAim then
		controller:SetAim(nextAim)
	end
end

function AimButton:render()
	if not UserInputService.TouchEnabled then
		return nil
	end

	local label = if self.state.isAiming then "AIM" else "Aim"

	return Roact.createElement("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -90),
		Size = UDim2.new(0, 84, 0, 48),
		Text = label,
		TextColor3 = UITheme.Colors.TextPrimary,
		BackgroundColor3 = if self.state.isAiming then UITheme.Colors.AccentSoft else UITheme.Colors.PanelAlt,
		AutoButtonColor = true,
		Font = UITheme.Typography.Title,
		TextScaled = true,
		[Roact.Event.Activated] = function()
			self:_setAim(not self._isAiming)
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
	})
end

return AimButton
