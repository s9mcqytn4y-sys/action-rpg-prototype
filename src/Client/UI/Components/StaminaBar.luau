local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)
local RoactRodux = require(Packages:WaitForChild("Roact-Rodux") :: ModuleScript)
local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("Config"):WaitForChild("UITheme") :: ModuleScript)

local StaminaBar = Roact.PureComponent:extend("StaminaBar")

function StaminaBar:render()
	local stamina = self.props.stamina
	local current = stamina.current or 0
	local max = stamina.max or 0

	local ratio = 0
	if max > 0 then
		ratio = math.clamp(current / max, 0, 1)
	end
	local fillVisible = ratio > 0
	local fillWidthOffset = 0
	if ratio > 0.02 then
		fillWidthOffset = -4
	end

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.new(0, 340, 0, 26),
		BackgroundColor3 = UITheme.Colors.Panel,
		BorderSizePixel = 0,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = UITheme.Colors.Stroke,
			Transparency = 0.5,
			Thickness = 1,
		}),
		Track = Roact.createElement("Frame", {
			Size = UDim2.new(1, -34, 1, -6),
			Position = UDim2.new(0, 30, 0, 3),
			BackgroundColor3 = UITheme.Colors.PanelAlt,
			BorderSizePixel = 0,
		}, {
			TrackCorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 7),
			}),
		}),
		Fill = Roact.createElement("Frame", {
			Size = UDim2.new(ratio, fillWidthOffset, 1, -6),
			Position = UDim2.new(0, 30, 0, 3),
			BackgroundColor3 = UITheme.Colors.Positive,
			BorderSizePixel = 0,
			Visible = fillVisible,
		}, {
			FillCorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 7),
			}),
			Gradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 240, 150)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 170, 105)),
				}),
				Rotation = 0,
			}),
			Gloss = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0.45, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.8,
				BorderSizePixel = 0,
			}, {
				GlossCorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 7),
				}),
			}),
		}),
		Icon = Roact.createElement("Frame", {
			Position = UDim2.new(0, 6, 0, 5),
			Size = UDim2.new(0, 18, 0, 18),
			BackgroundColor3 = UITheme.Colors.AccentSoft,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = UITheme.Colors.Accent,
				Transparency = 0.2,
				Thickness = 1,
			}),
			Mark = Roact.createElement("TextLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = "ST",
				TextColor3 = UITheme.Colors.TextPrimary,
				TextScaled = true,
				Font = UITheme.Typography.Mono,
			}),
		}),
		Label = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = string.format("STAMINA %d / %d", current, max),
			TextColor3 = UITheme.Colors.TextPrimary,
			TextScaled = true,
			Font = UITheme.Typography.Title,
		}),
	})
end

local function mapStateToProps(state)
	return {
		stamina = state.Stamina,
	}
end

return RoactRodux.connect({ "Stamina" }, mapStateToProps)(StaminaBar)
