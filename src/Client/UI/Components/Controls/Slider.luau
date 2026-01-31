local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("Config"):WaitForChild("UITheme") :: ModuleScript)

type Props = {
	Min: number,
	Max: number,
	Value: number,
	OnChanged: (value: number) -> (),
}

local Slider = Roact.Component:extend("Slider")

function Slider:init()
	self._dragging = false
	self._barRef = Roact.createRef()
end

function Slider:_setFromInput(input: InputObject)
	local bar = self._barRef:getValue()
	if not bar then
		return
	end
	local absPos = bar.AbsolutePosition
	local absSize = bar.AbsoluteSize
	local x = math.clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
	local value = self.props.Min + (self.props.Max - self.props.Min) * x
	self.props.OnChanged(value)
end

function Slider:render()
	local props = self.props :: Props
	local ratio = 0
	if props.Max > props.Min then
		ratio = math.clamp((props.Value - props.Min) / (props.Max - props.Min), 0, 1)
	end

	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
	}, {
		Bar = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 8),
			Position = UDim2.new(0, 0, 0.5, -4),
			BackgroundColor3 = UITheme.Colors.PanelAlt,
			BorderSizePixel = 0,
			[Roact.Ref] = self._barRef,
			[Roact.Event.InputBegan] = function(_, input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					self._dragging = true
					self:_setFromInput(input)
				end
			end,
			[Roact.Event.InputEnded] = function(_, input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					self._dragging = false
				end
			end,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			Fill = Roact.createElement("Frame", {
				Size = UDim2.new(ratio, 0, 1, 0),
				BackgroundColor3 = UITheme.Colors.Accent,
				BorderSizePixel = 0,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}),
		}),
		Drag = Roact.createElement("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Text = "",
			AutoButtonColor = false,
			[Roact.Event.InputChanged] = function(_, input)
				if not self._dragging then
					return
				end
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					self:_setFromInput(input)
				end
			end,
		}),
	})
end

return Slider
