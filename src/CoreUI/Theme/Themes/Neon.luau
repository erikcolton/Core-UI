--[[
	Neon: deep navy glass, cyan and magenta accents, glowing outlines and techy type.
	Suits sci-fi, cyberpunk, racing and competitive games.
	Only the tokens that differ from Clean are listed.
]]

local rgb = Color3.fromRGB

-- family is a font family file name under rbxasset://fonts/families/ (see the Font docs).
local function font(family: string, weight: Enum.FontWeight?): Font
	return Font.new("rbxasset://fonts/families/" .. family .. ".json", weight or Enum.FontWeight.Regular)
end

return {
	colors = {
		background = rgb(6, 8, 22),
		surface = rgb(14, 18, 42),
		surfaceAlt = rgb(22, 28, 60),
		stroke = rgb(0, 229, 255),
		textStroke = rgb(4, 6, 18),
		text = rgb(226, 246, 255),
		textMuted = rgb(120, 150, 190),
		textInverse = rgb(6, 8, 22),

		primary = rgb(0, 229, 255),
		onPrimary = rgb(6, 8, 22),
		secondary = rgb(40, 46, 96),
		onSecondary = rgb(226, 246, 255),
		buy = rgb(57, 255, 136),
		onBuy = rgb(6, 8, 22),
		danger = rgb(255, 45, 120),
		onDanger = rgb(255, 255, 255),

		success = rgb(57, 255, 136),
		warning = rgb(255, 214, 0),
		error = rgb(255, 45, 120),
		info = rgb(0, 229, 255),
		badge = rgb(255, 45, 120),

		overlay = rgb(0, 0, 8),
		track = rgb(30, 36, 76),
		selection = rgb(255, 45, 220),

		rarity = {
			common = rgb(140, 160, 190),
			uncommon = rgb(57, 255, 136),
			rare = rgb(0, 229, 255),
			epic = rgb(190, 90, 255),
			legendary = rgb(255, 214, 0),
			mythic = rgb(255, 45, 220),
		},
	},

	transparency = {
		surface = 0.06,
		surfaceAlt = 0.1,
		overlay = 0.35,
	},

	fonts = {
		display = font("Michroma"),
		heading = font("TitilliumWeb", Enum.FontWeight.Bold),
		body = font("TitilliumWeb", Enum.FontWeight.SemiBold),
	},

	typography = {
		display = { size = 38, outline = false },
		title = { size = 26, outline = false },
		heading = { size = 22 },
		label = { size = 18, outline = false },
	},

	radius = {
		sm = UDim.new(0, 4),
		md = UDim.new(0, 6),
		lg = UDim.new(0, 8),
	},

	stroke = {
		panel = 2,
		control = 2,
		text = 0,
	},

	shadow = {
		style = "none",
	},

	buttons = {
		fill = "gradient",
		highlight = 0.3,
	},

	effects = {
		panelGradient = 0.08,
	},

	motion = {
		fast = 0.1,
		normal = 0.2,
		easing = Enum.EasingStyle.Cubic,
		pop = Enum.EasingStyle.Cubic,
		hoverScale = 1.04,
		pressScale = 0.97,
		openFrom = 0.95,
		openStyle = "slide",
	},
}
