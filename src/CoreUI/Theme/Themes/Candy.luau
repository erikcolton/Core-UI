--[[
	Candy: pastel pinks and lilacs, soft outlines, pill shapes and springy motion.
	Suits cute pet, dress-up and roleplay games.
	Only the tokens that differ from Clean are listed.
]]

local rgb = Color3.fromRGB

-- family is a font family file name under rbxasset://fonts/families/ (see the Font docs).
local function font(family: string, weight: Enum.FontWeight?): Font
	return Font.new("rbxasset://fonts/families/" .. family .. ".json", weight or Enum.FontWeight.Regular)
end

local outline = rgb(150, 72, 130)

return {
	colors = {
		background = rgb(255, 214, 232),
		surface = rgb(255, 247, 251),
		surfaceAlt = rgb(255, 228, 241),
		stroke = rgb(240, 160, 200),
		textStroke = outline,
		text = rgb(110, 50, 98),
		textMuted = rgb(170, 110, 150),

		primary = rgb(255, 120, 180),
		onPrimary = rgb(255, 255, 255),
		secondary = rgb(190, 160, 255),
		onSecondary = rgb(255, 255, 255),
		buy = rgb(110, 214, 160),
		onBuy = rgb(255, 255, 255),
		danger = rgb(255, 110, 120),
		onDanger = rgb(255, 255, 255),

		success = rgb(110, 214, 160),
		warning = rgb(255, 190, 90),
		error = rgb(255, 110, 120),
		info = rgb(150, 170, 255),
		badge = rgb(255, 90, 140),

		overlay = rgb(90, 30, 70),
		track = rgb(250, 205, 228),
		selection = rgb(255, 120, 180),
	},

	transparency = {
		overlay = 0.55,
	},

	fonts = {
		display = font("FredokaOne"),
		heading = font("FredokaOne"),
		body = font("Nunito", Enum.FontWeight.Bold),
	},

	typography = {
		display = { size = 46 },
		title = { size = 32 },
		heading = { size = 23, outline = false },
		label = { size = 19 },
	},

	radius = {
		sm = UDim.new(0, 12),
		md = UDim.new(0, 18),
		lg = UDim.new(0, 24),
	},

	stroke = {
		panel = 3,
		control = 2,
		text = 2,
	},

	shadow = {
		style = "lip",
		offset = 4,
		transparency = 0,
	},

	buttons = {
		fill = "gradient",
		highlight = 0.25,
	},

	effects = {
		panelGradient = 0.06,
	},

	motion = {
		normal = 0.3,
		pop = Enum.EasingStyle.Back,
		hoverScale = 1.06,
		pressScale = 0.93,
		openFrom = 0.7,
	},
}
