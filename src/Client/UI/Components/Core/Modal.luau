--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)

local Surface = require(script.Parent:WaitForChild("Surface") :: ModuleScript)

export type Props = {
	Visible: boolean,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	ZIndex: number?,
	Children: any?,
	OnClose: (() -> ())?,
}

local Modal = Roact.PureComponent:extend("Modal")

function Modal:render()
	local props = self.props :: Props
	if not props.Visible then
		return nil
	end

	local zIndex = props.ZIndex or 80

	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = zIndex,
	}, {
		Overlay = Roact.createElement("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = UITheme.Colors.Background,
			BackgroundTransparency = UITheme.Opacity.Overlay,
			BorderSizePixel = 0,
			Text = "",
			ZIndex = zIndex,
			[Roact.Event.Activated] = function()
				if props.OnClose then
					props.OnClose()
				end
			end,
		}),
		Body = Roact.createElement(Surface, {
			Size = props.Size or UDim2.fromOffset(520, 320),
			Position = props.Position or UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
			ZIndex = zIndex + 1,
			BackgroundColor3 = UITheme.Colors.Surface,
			BackgroundTransparency = UITheme.Opacity.Surface,
			StrokeTransparency = 0.4,
			Children = props.Children,
		}),
	})
end

return Modal
