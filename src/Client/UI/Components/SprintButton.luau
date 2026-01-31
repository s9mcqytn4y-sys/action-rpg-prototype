local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("Config"):WaitForChild("UITheme") :: ModuleScript)

local SprintButton = Roact.Component:extend("SprintButton")

function SprintButton:init()
	self.state = {
		isSprinting = false,
	}
end

function SprintButton:_setSprint(nextSprint: boolean)
	self:setState({
		isSprinting = nextSprint,
	})
	local ok, controller = pcall(function()
		return Knit.GetController("SprintController")
	end)
	if ok and controller and controller.SetSprint then
		controller:SetSprint(nextSprint)
	end
end

function SprintButton:render()
	if not UserInputService.TouchEnabled then
		return nil
	end

	local label = if self.state.isSprinting then "RUN" else "RUN"

	return Roact.createElement("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -32),
		Size = UDim2.new(0, 88, 0, 50),
		Text = label,
		TextColor3 = UITheme.Colors.TextPrimary,
		BackgroundColor3 = if self.state.isSprinting then UITheme.Colors.Accent else UITheme.Colors.PanelAlt,
		BackgroundTransparency = self.state.isSprinting and 0.04 or 0.12,
		AutoButtonColor = true,
		Font = UITheme.Typography.Title,
		TextScaled = true,
		[Roact.Event.Activated] = function()
			self:_setSprint(not self.state.isSprinting)
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
		Highlight = Roact.createElement("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.75),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
end

return SprintButton
