--[[
	Dark: low saturation, no fills on secondary controls, hairline borders and quiet
	motion. Suits horror, story and tactical games.
	Only the tokens that differ from Clean are listed.
]]

local rgb = Color3.fromRGB

-- family is a font family file name under rbxasset://fonts/families/ (see the Font docs).
local function font(family: string, weight: Enum.FontWeight?): Font
	return Font.new("rbxasset://fonts/families/" .. family .. ".json", weight or Enum.FontWeight.Regular)
end

return {
	colors = {
		background = rgb(8, 8, 9),
		surface = rgb(20, 20, 22),
		surfaceAlt = rgb(30, 30, 33),
		stroke = rgb(58, 56, 54),
		textStroke = rgb(0, 0, 0),
		text = rgb(222, 216, 204),
		textMuted = rgb(130, 124, 116),
		textInverse = rgb(12, 12, 13),

		primary = rgb(222, 216, 204),
		onPrimary = rgb(12, 12, 13),
		secondary = rgb(38, 37, 40),
		onSecondary = rgb(222, 216, 204),
		buy = rgb(160, 132, 82),
		onBuy = rgb(12, 12, 13),
		danger = rgb(178, 58, 46),
		onDanger = rgb(240, 232, 220),

		success = rgb(110, 150, 100),
		warning = rgb(190, 140, 60),
		error = rgb(178, 58, 46),
		info = rgb(120, 140, 160),
		badge = rgb(178, 58, 46),
		onBadge = rgb(240, 232, 220),

		overlay = rgb(0, 0, 0),
		track = rgb(42, 40, 38),
		selection = rgb(222, 216, 204),

		rarity = {
			common = rgb(120, 118, 112),
			uncommon = rgb(110, 150, 100),
			rare = rgb(100, 130, 170),
			epic = rgb(140, 110, 170),
			legendary = rgb(190, 150, 70),
			mythic = rgb(178, 58, 46),
		},
	},

	transparency = {
		surface = 0.08,
		surfaceAlt = 0.1,
		overlay = 0.3,
	},

	fonts = {
		display = font("Oswald", Enum.FontWeight.Medium),
		heading = font("Oswald", Enum.FontWeight.Regular),
		body = font("BuilderSans", Enum.FontWeight.Regular),
	},

	typography = {
		display = { size = 42, outline = false },
		title = { size = 28, outline = false },
		heading = { size = 20 },
		label = { size = 16, outline = false },
	},

	radius = {
		sm = UDim.new(0, 2),
		md = UDim.new(0, 3),
		lg = UDim.new(0, 4),
	},

	stroke = {
		panel = 1,
		control = 1,
		text = 0,
	},

	shadow = {
		style = "none",
	},

	buttons = {
		heights = { sm = 32, md = 42, lg = 52 },
	},

	motion = {
		fast = 0.18,
		normal = 0.35,
		slow = 0.6,
		easing = Enum.EasingStyle.Sine,
		pop = Enum.EasingStyle.Sine,
		hoverScale = 1.0,
		pressScale = 0.98,
		openFrom = 0.97,
	},
}
