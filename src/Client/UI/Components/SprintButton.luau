--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)
local RoactRodux = require(Packages:WaitForChild("Roact-Rodux") :: ModuleScript)
local Knit = require(Packages:WaitForChild("Knit") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)
local UITypography = require(Shared:WaitForChild("UI"):WaitForChild("UITypography") :: ModuleScript)

local SprintButton = Roact.Component:extend("SprintButton")

type Props = {
	Viewport: {
		className: string,
	}?,
}

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
	local props = self.props :: Props
	if not UserInputService.TouchEnabled then
		return nil
	end

	local viewport = props.Viewport
	local className = if viewport then viewport.className else "Desktop"
	local isPhone = className == "Phone"
	local isTablet = className == "Tablet"

	local size = if isPhone then 92 else if isTablet then 88 else 84
	local offsetX = if isPhone then 24 else if isTablet then 28 else 32
	local offsetY = if isPhone then 160 else if isTablet then 150 else 140

	local active = self.state.isSprinting
	local background = if active then UITheme.Colors.Accent else UITheme.Colors.SurfaceAlt
	local textColor = if active then UITheme.Colors.Background else UITheme.Colors.Text
	local borderTransparency = if active then 0.35 else 0.65

	return Roact.createElement("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -offsetX, 1, -offsetY),
		Size = UDim2.fromOffset(size, size),
		Text = "",
		TextColor3 = textColor,
		BackgroundColor3 = background,
		BackgroundTransparency = 0.05,
		AutoButtonColor = true,
		Font = UITypography.Fonts.Emphasis,
		TextSize = 16,
		Selectable = true,
		[Roact.Event.Activated] = function()
			self:_setSprint(not self.state.isSprinting)
		end,
	}, {
		Aspect = Roact.createElement("UIAspectRatioConstraint", {
			AspectRatio = 1,
		}),
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = UITheme.Colors.Border,
			Transparency = borderTransparency,
			Thickness = 1,
		}),
		Ring = Roact.createElement("UIStroke", {
			Color = UITheme.Colors.Accent,
			Transparency = active and 0.4 or 1,
			Thickness = 2,
		}),
		Highlight = Roact.createElement("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.7),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
		Label = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = if active then "SPRINT" else "RUN",
			TextColor3 = textColor,
			TextSize = if isPhone then 16 else 15,
			Font = UITypography.Fonts.Emphasis,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),
	})
end

local function mapStateToProps(state)
	return {
		Viewport = state.UI and state.UI.Viewport or nil,
	}
end

return RoactRodux.connect({ "UI" }, mapStateToProps)(SprintButton)
