--[[
	Wood: parchment panels, dark wood outlines, gold buttons and chunky serif titles.
	Suits fantasy, RPG, farming and adventure games.
	Only the tokens that differ from Clean are listed. For real wood grain, upload a
	9-slice frame image and set it under images.panel.
]]

local rgb = Color3.fromRGB

-- family is a font family file name under rbxasset://fonts/families/ (see the Font docs).
local function font(family: string, weight: Enum.FontWeight?): Font
	return Font.new("rbxasset://fonts/families/" .. family .. ".json", weight or Enum.FontWeight.Regular)
end

local wood = rgb(78, 46, 24)

return {
	colors = {
		background = rgb(120, 80, 46),
		surface = rgb(246, 230, 196),
		surfaceAlt = rgb(234, 212, 168),
		stroke = wood,
		textStroke = rgb(60, 32, 14),
		text = rgb(84, 46, 20),
		textMuted = rgb(140, 100, 64),

		primary = rgb(240, 182, 40),
		onPrimary = rgb(255, 255, 255),
		secondary = rgb(166, 108, 62),
		onSecondary = rgb(255, 244, 222),
		buy = rgb(110, 184, 52),
		onBuy = rgb(255, 255, 255),
		danger = rgb(204, 62, 40),
		onDanger = rgb(255, 255, 255),

		success = rgb(110, 184, 52),
		warning = rgb(240, 182, 40),
		error = rgb(204, 62, 40),
		info = rgb(70, 140, 200),
		badge = rgb(204, 62, 40),

		overlay = rgb(30, 16, 6),
		track = rgb(110, 70, 40),
		selection = rgb(255, 220, 90),
	},

	transparency = {
		overlay = 0.45,
	},

	fonts = {
		display = font("Merriweather", Enum.FontWeight.Heavy),
		heading = font("Merriweather", Enum.FontWeight.Bold),
		body = font("Nunito", Enum.FontWeight.Bold),
	},

	typography = {
		display = { size = 44 },
		title = { size = 30 },
		heading = { size = 22, outline = true },
		label = { size = 18 },
	},

	radius = {
		sm = UDim.new(0, 6),
		md = UDim.new(0, 8),
		lg = UDim.new(0, 12),
	},

	stroke = {
		panel = 5,
		control = 3,
		text = 2.5,
	},

	shadow = {
		style = "lip",
		offset = 5,
		transparency = 0,
	},

	buttons = {
		fill = "twoTone",
		highlight = 0.2,
	},

	effects = {
		panelGradient = 0.12,
	},

	motion = {
		normal = 0.26,
		hoverScale = 1.05,
		pressScale = 0.94,
		openFrom = 0.8,
	},
}
