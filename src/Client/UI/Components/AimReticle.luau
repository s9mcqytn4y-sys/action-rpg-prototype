local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("Config"):WaitForChild("UITheme") :: ModuleScript)

local AimReticle = Roact.Component:extend("AimReticle")

function AimReticle:init()
	self._controller = nil
	self._conn = nil
	self.state = {
		visible = false,
	}
end

function AimReticle:didMount()
	local ok, controller = pcall(function()
		return Knit.GetController("ThirdPersonController")
	end)
	if ok then
		self._controller = controller
	end
	self._conn = RunService.RenderStepped:Connect(function()
		if self._controller and self._controller.IsAiming then
			local isAiming = self._controller:IsAiming()
			if isAiming ~= self.state.visible then
				self:setState({
					visible = isAiming,
				})
			end
		end
	end)
end

function AimReticle:willUnmount()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end
end

function AimReticle:render()
	if not self.state.visible then
		return nil
	end

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
	}, {
		Outer = Roact.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			Stroke = Roact.createElement("UIStroke", {
				Color = UITheme.Colors.TextPrimary,
				Transparency = 0.2,
				Thickness = 2,
			}),
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
		Dot = Roact.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(4, 4),
			BackgroundColor3 = UITheme.Colors.TextPrimary,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
	})
end

return AimReticle
