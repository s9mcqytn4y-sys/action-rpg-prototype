--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)
local RoactRodux = require(Packages:WaitForChild("Roact-Rodux") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

local StaminaBar = require(script.Parent:WaitForChild("StaminaBar") :: ModuleScript)

local HUDRoot = Roact.Component:extend("HUDRoot")

type Props = {
	HudScale: number?,
	ViewportClass: string?,
}

function HUDRoot:render()
	local props = self.props :: Props
	local scale = props.HudScale or 1
	local isPhone = props.ViewportClass == "Phone"
	local paddingLeft = Theme.Spacing.L
	local paddingBottom = if isPhone then (Theme.Spacing.L + 64) else Theme.Spacing.L
	local staminaSize = if isPhone then UDim2.new(0, 240, 0, 54) else UDim2.new(0, 320, 0, 60)

	return Roact.createElement("Frame", {
		Name = "HUDRoot",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		-- Safe area padding for all devices
		SafeArea = Roact.createElement("Frame", {
			Name = "SafeArea",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}, {
			Scale = Roact.createElement("UIScale", {
				Scale = scale,
			}),
			Padding = Roact.createElement("UIPadding", {
				PaddingBottom = UDim.new(0, paddingBottom),
				PaddingLeft = UDim.new(0, paddingLeft),
				PaddingRight = UDim.new(0, Theme.Spacing.L),
				PaddingTop = UDim.new(0, 0),
			}),

			-- Bottom stack container (so we can keep things grouped)
			HUDStack = Roact.createElement("Frame", {
				Name = "HUDStack",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, {
				Layout = Roact.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, Theme.Spacing.S),
				}),

				-- HUD Elements (add more later easily)
				Stamina = Roact.createElement(StaminaBar, {
					LayoutOrder = 1,
					Size = staminaSize,
				}),
			}),
		}),
	})
end

local function mapStateToProps(state)
	local viewport = state.UI and state.UI.Viewport or nil
	local scale = viewport and viewport.scale or 1
	local className = viewport and viewport.className or "Desktop"
	if className == "Phone" then
		scale = math.max(scale, 0.9)
	elseif className == "Tablet" then
		scale = math.max(scale, 0.95)
	end
	return {
		HudScale = scale,
		ViewportClass = className,
	}
end

return RoactRodux.connect({ "UI" }, mapStateToProps)(HUDRoot)
