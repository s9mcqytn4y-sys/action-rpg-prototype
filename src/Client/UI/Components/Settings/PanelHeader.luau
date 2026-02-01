--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages") :: Folder
local Roact = require(Packages:WaitForChild("Roact") :: ModuleScript)

local Shared = ReplicatedStorage:WaitForChild("Shared") :: Folder
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("EndfieldTheme") :: ModuleScript)
local UIIcons = require(Shared:WaitForChild("UI"):WaitForChild("UIIcons") :: ModuleScript)

local Core = script.Parent.Parent:WaitForChild("Core") :: Folder
local Text = require(Core:WaitForChild("Text") :: ModuleScript)
local Button = require(Core:WaitForChild("Button") :: ModuleScript)
local IconButton = require(Core:WaitForChild("IconButton") :: ModuleScript)

type Props = {
	Title: string,
	Subtitle: string,
	ShortcutHint: string?,
	OnClose: () -> (),
	OnReset: () -> (),
	Compact: boolean?,
}

local PanelHeader = Roact.PureComponent:extend("PanelHeader")

function PanelHeader:render()
	local props = self.props :: Props
	local compact = props.Compact == true
	local height = if compact then 60 else 72
	local titleVariant = if compact then "H3" else "H2"
	local subtitleVariant = if compact then "BodySmall" else "Caption"

	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		TopLine = Roact.createElement("Frame", {
			Position = UDim2.new(0, Theme.Spacing.L, 0, if compact then 8 else 12),
			Size = UDim2.new(1, -(Theme.Spacing.L * 2), 0, 1),
			BackgroundColor3 = Theme.Colors.Border,
			BackgroundTransparency = 0.65,
			BorderSizePixel = 0,
		}),

		Accent = Roact.createElement("Frame", {
			Position = UDim2.new(0, Theme.Spacing.L, 0, if compact then 6 else 10),
			Size = UDim2.new(0, if compact then 96 else 120, 0, 3),
			BackgroundColor3 = Theme.Colors.Accent,
			BorderSizePixel = 0,
		}),

		Left = Roact.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, Theme.Spacing.L, 0, if compact then 16 else 20),
			Size = UDim2.new(1, -Theme.Spacing.L * 2, 1, 0),
		}, {
			Title = Roact.createElement(Text, {
				Text = props.Title,
				Variant = titleVariant,
				Color = Theme.Colors.Text,
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, if compact then 22 else 26),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Subtitle = Roact.createElement(Text, {
				Text = props.Subtitle,
				Variant = subtitleVariant,
				Color = Theme.Colors.Muted,
				Position = UDim2.new(0, 0, 0, if compact then 22 else 28),
				Size = UDim2.new(1, 0, 0, 18),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),

		Right = Roact.createElement("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -Theme.Spacing.L, 0, if compact then 12 else 18),
			Size = UDim2.new(0, if compact then 170 else 220, 0, 36),
		}, {
			Layout = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, Theme.Spacing.S),
			}),
			Shortcut = props.ShortcutHint and Roact.createElement(Text, {
				Text = props.ShortcutHint,
				Variant = "Caption",
				Color = Theme.Colors.Muted,
				LayoutOrder = 1,
				Size = UDim2.new(0, if compact then 60 else 90, 1, 0),
				TextXAlignment = Enum.TextXAlignment.Right,
			}) or nil,
			Reset = Roact.createElement(Button, {
				Text = "Reset",
				Variant = "Ghost",
				LayoutOrder = 2,
				Size = UDim2.new(0, if compact then 60 else 70, 0, 30),
				OnActivated = function()
					props.OnReset()
				end,
			}),
			Close = Roact.createElement(IconButton, {
				Image = UIIcons.Close,
				LayoutOrder = 3,
				Size = UDim2.fromOffset(30, 30),
				Label = "X",
				OnActivated = function()
					props.OnClose()
				end,
			}),
		}),
	})
end

return PanelHeader
