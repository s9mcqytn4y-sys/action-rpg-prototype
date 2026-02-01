--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Core = script.Parent.Parent:WaitForChild("Core") :: Folder
local Toast = require(Core:WaitForChild("Toast") :: ModuleScript)

type ToastTone = "info" | "success" | "warning" | "danger"

type Props = {
	Text: string,
	Context: string?,
	Tone: ToastTone?,
}

local SettingsToast = Roact.PureComponent:extend("SettingsToast")

function SettingsToast:render()
	local props = self.props :: Props
	return Roact.createElement(Toast, {
		Title = props.Context,
		Message = props.Text,
		Tone = props.Tone,
		Size = UDim2.fromScale(1, 1),
	})
end

return SettingsToast
