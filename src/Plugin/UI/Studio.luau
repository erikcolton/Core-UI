--[[
	Studio look for the plugin's own controls: colors from the current Studio theme
	(light or dark), refreshed when the user switches Studio themes.

		Studio.bind(frame, function(c)
			frame.BackgroundColor3 = c.background
		end)
]]

local Studio = {}

Studio.font = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular)
Studio.fontBold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
Studio.fontMono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular)
Studio.textSize = 14

local Guide = Enum.StudioStyleGuideColor
local Modifier = Enum.StudioStyleGuideModifier

-- name = { style guide color, modifier, fallback for when the color is unavailable }
local SPEC: { [string]: { any } } = {
	background = { "MainBackground", "Default", Color3.fromRGB(46, 46, 46) },
	header = { "Titlebar", "Default", Color3.fromRGB(53, 53, 53) },
	section = { "CategoryItem", "Default", Color3.fromRGB(53, 53, 53) },
	hover = { "Item", "Hover", Color3.fromRGB(66, 66, 66) },
	border = { "Border", "Default", Color3.fromRGB(34, 34, 34) },
	text = { "MainText", "Default", Color3.fromRGB(204, 204, 204) },
	dim = { "DimmedText", "Default", Color3.fromRGB(120, 120, 120) },
	input = { "InputFieldBackground", "Default", Color3.fromRGB(37, 37, 37) },
	inputBorder = { "InputFieldBorder", "Default", Color3.fromRGB(26, 26, 26) },
	button = { "Button", "Default", Color3.fromRGB(60, 60, 60) },
	buttonHover = { "Button", "Hover", Color3.fromRGB(70, 70, 70) },
	buttonText = { "ButtonText", "Default", Color3.fromRGB(220, 220, 220) },
	accent = { "DialogMainButton", "Default", Color3.fromRGB(0, 162, 255) },
	accentHover = { "DialogMainButton", "Hover", Color3.fromRGB(50, 181, 255) },
	accentText = { "DialogMainButtonText", "Default", Color3.fromRGB(255, 255, 255) },
	scrollBar = { "ScrollBar", "Default", Color3.fromRGB(85, 85, 85) },
	error = { "ErrorText", "Default", Color3.fromRGB(255, 68, 68) },
	warning = { "WarningText", "Default", Color3.fromRGB(255, 170, 0) },
	success = { "DialogMainButton", "Default", Color3.fromRGB(0, 162, 255) },
}

local colors: { [string]: Color3 } = {}

local function studioTheme(): any?
	local ok, theme = pcall(function()
		return (settings() :: any).Studio.Theme
	end)
	return if ok then theme else nil
end

local function read()
	local theme = studioTheme()
	for name, spec in SPEC do
		local color = spec[3]
		if theme then
			local ok, value = pcall(function()
				return theme:GetColor((Guide :: any)[spec[1]], (Modifier :: any)[spec[2]])
			end)
			if ok and typeof(value) == "Color3" then
				color = value
			end
		end
		colors[name] = color
	end
	colors.danger = Color3.fromRGB(214, 64, 64)
	colors.dangerHover = Color3.fromRGB(230, 86, 86)
end
read()

Studio.colors = colors

local stylers: { [Instance]: { (any) -> () } } = setmetatable({}, { __mode = "k" }) :: any

function Studio.bind(instance: Instance, styler: (any) -> ())
	local list = stylers[instance]
	if not list then
		list = {}
		stylers[instance] = list
		instance.Destroying:Once(function()
			stylers[instance] = nil
		end)
	end
	table.insert(list, styler)
	styler(colors)
end

local connection: RBXScriptConnection? = nil
pcall(function()
	connection = (settings() :: any).Studio.ThemeChanged:Connect(function()
		read()
		for _, list in stylers do
			for _, styler in list do
				pcall(styler, colors)
			end
		end
	end)
end)

function Studio.destroy()
	if connection then
		connection:Disconnect()
	end
end

return Studio
