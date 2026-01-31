local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

type Props = {
	LayoutOrder: number?,
}

local Divider = Roact.PureComponent:extend("Divider")

function Divider:render()
	local props = self.props :: Props
	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Colors.Border,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
	})
end

return Divider
