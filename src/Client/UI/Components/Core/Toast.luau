--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local UITheme = require(Shared:WaitForChild("UI"):WaitForChild("UITheme") :: ModuleScript)
local UITypography = require(Shared:WaitForChild("UI"):WaitForChild("UITypography") :: ModuleScript)

export type ToastTone = "info" | "success" | "warning" | "danger"

export type Props = {
	Title: string?,
	Message: string,
	Tone: ToastTone?,
	Size: UDim2?,
}

local Toast = Roact.PureComponent:extend("Toast")

local function toneColor(tone: ToastTone?): Color3
	if tone == "success" then
		return UITheme.Colors.Success
	elseif tone == "warning" then
		return UITheme.Colors.Warning
	elseif tone == "danger" then
		return UITheme.Colors.Danger
	end
	return UITheme.Colors.Info
end

local function toneLabel(tone: ToastTone?): string
	if tone == "success" then
		return "OK"
	elseif tone == "warning" then
		return "WARN"
	elseif tone == "danger" then
		return "ERROR"
	end
	return "INFO"
end

function Toast:render()
	local props = self.props :: Props
	local accent = toneColor(props.Tone)

	return Roact.createElement("Frame", {
		Size = props.Size or UDim2.new(0, 260, 0, 44),
		BackgroundColor3 = UITheme.Colors.Header,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, UITheme.Radius.S),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = UITheme.Colors.Border,
			Transparency = 0.5,
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
			BackgroundColor3 = UITheme.Colors.SurfaceAlt,
			BackgroundTransparency = 0.12,
			Position = UDim2.new(0, 12, 0.5, -8),
			Size = UDim2.new(0, 42, 0, 16),
			Text = toneLabel(props.Tone),
			TextColor3 = accent,
			TextSize = UITypography.Sizes.Caption,
			Font = UITypography.Fonts.Mono,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, UITheme.Radius.XS),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = UITheme.Colors.Border,
				Transparency = 0.6,
				Thickness = 1,
			}),
		}),
		Title = props.Title and Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 60, 0, 6),
			Size = UDim2.new(1, -70, 0, 14),
			Text = props.Title,
			TextColor3 = UITheme.Colors.TextMuted,
			TextSize = UITypography.Sizes.Caption,
			Font = UITypography.Fonts.Mono,
			TextXAlignment = Enum.TextXAlignment.Left,
		}) or nil,
		Message = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 60, 0, 18),
			Size = UDim2.new(1, -70, 0, 18),
			Text = props.Message,
			TextColor3 = UITheme.Colors.Text,
			TextSize = UITypography.Sizes.BodySmall,
			Font = UITypography.Fonts.Body,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
	})
end

return Toast
