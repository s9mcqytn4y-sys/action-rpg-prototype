local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)

type ToastTone = "info" | "success" | "warning"

type Props = {
	Text: string,
	Context: string?,
	Tone: ToastTone?,
}

local SettingsToast = Roact.PureComponent:extend("SettingsToast")

local function toneColor(tone: ToastTone?): Color3
	if tone == "success" then
		return Theme.Colors.Positive
	elseif tone == "warning" then
		return Theme.Colors.Warning
	end
	return Theme.Colors.Accent
end

local function toneLabel(tone: ToastTone?): string
	if tone == "success" then
		return "OK"
	elseif tone == "warning" then
		return "WARN"
	end
	return "INFO"
end

function SettingsToast:render()
	local props = self.props :: Props
	local tone = props.Tone
	local accent = toneColor(tone)

	return Roact.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.HeaderBar,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, Theme.Radius.S),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = Theme.Colors.Border,
			Transparency = 0.45,
			Thickness = 1,
		}),
		Accent = Roact.createElement("Frame", {
			Size = UDim2.new(0, 2, 1, -8),
			Position = UDim2.new(0, 6, 0, 4),
			BackgroundColor3 = accent,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
		Badge = Roact.createElement("TextLabel", {
			BackgroundColor3 = Theme.Colors.PanelAlt,
			BackgroundTransparency = 0.12,
			Position = UDim2.new(0, 12, 0.5, -8),
			Size = UDim2.new(0, 34, 0, 16),
			Text = toneLabel(tone),
			TextColor3 = accent,
			TextSize = Theme.TypographySizes.Mono,
			Font = Theme.Typography.Mono,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = Theme.Colors.Border,
				Transparency = 0.6,
				Thickness = 1,
			}),
		}),
		Context = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 52, 0, 6),
			Size = UDim2.new(1, -62, 0, 14),
			Text = props.Context or "",
			TextColor3 = Theme.Colors.Muted,
			TextSize = Theme.TypographySizes.Mono,
			Font = Theme.Typography.Mono,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Message = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 52, 0, 18),
			Size = UDim2.new(1, -62, 0, 16),
			Text = props.Text,
			TextColor3 = Theme.Colors.Text,
			TextSize = Theme.TypographySizes.Small,
			Font = Theme.Typography.Body,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return SettingsToast
