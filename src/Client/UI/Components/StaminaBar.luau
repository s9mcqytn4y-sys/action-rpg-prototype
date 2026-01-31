local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)
local RoactRodux = require(Packages:WaitForChild("Roact-Rodux") :: ModuleScript)

local StaminaBar = Roact.PureComponent:extend("StaminaBar")

function StaminaBar:render()
	local stamina = self.props.stamina
	local current = stamina.current or 0
	local max = stamina.max or 0

	local ratio = 0
	if max > 0 then
		ratio = math.clamp(current / max, 0, 1)
	end

	return Roact.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.new(0, 300, 0, 20),
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BorderSizePixel = 0,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		Fill = Roact.createElement("Frame", {
			Size = UDim2.new(ratio, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(63, 201, 96),
			BorderSizePixel = 0,
		}, {
			FillCorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
		}),
		Label = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = string.format("Stamina %d / %d", current, max),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}),
	})
end

local function mapStateToProps(state)
	return {
		stamina = state.Stamina,
	}
end

return RoactRodux.connect({ "Stamina" }, mapStateToProps)(StaminaBar)
