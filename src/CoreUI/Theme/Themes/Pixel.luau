--[[
	Pixel: square corners, chunky borders, an 8-bit font and snappy motion.
	Suits retro, arcade, obby and tycoon games.
	Only the tokens that differ from Clean are listed. The pixel font is wide, so
	text sizes are smaller than in the other themes.
]]

local rgb = Color3.fromRGB

-- family is a font family file name under rbxasset://fonts/families/ (see the Font docs).
local function font(family: string, weight: Enum.FontWeight?): Font
	return Font.new("rbxasset://fonts/families/" .. family .. ".json", weight or Enum.FontWeight.Regular)
end

local pixel = font("PressStart2P")
local black = rgb(16, 12, 32)

return {
	colors = {
		background = rgb(40, 30, 90),
		surface = rgb(60, 48, 128),
		surfaceAlt = rgb(78, 64, 156),
		stroke = black,
		textStroke = black,
		text = rgb(255, 255, 255),
		textMuted = rgb(186, 176, 236),
		textInverse = rgb(255, 255, 255),

		primary = rgb(255, 196, 0),
		onPrimary = rgb(255, 255, 255),
		secondary = rgb(56, 152, 255),
		onSecondary = rgb(255, 255, 255),
		buy = rgb(52, 200, 84),
		onBuy = rgb(255, 255, 255),
		danger = rgb(232, 56, 56),
		onDanger = rgb(255, 255, 255),

		success = rgb(52, 200, 84),
		warning = rgb(255, 196, 0),
		error = rgb(232, 56, 56),
		info = rgb(56, 152, 255),
		badge = rgb(232, 56, 56),

		overlay = rgb(8, 6, 20),
		track = rgb(26, 20, 60),
		selection = rgb(255, 255, 255),
	},

	transparency = {
		overlay = 0.4,
	},

	fonts = {
		display = pixel,
		heading = pixel,
		body = pixel,
		mono = pixel,
	},

	typography = {
		display = { size = 30 },
		title = { size = 22 },
		heading = { size = 16, outline = true },
		label = { size = 14 },
		body = { size = 12 },
		caption = { size = 10 },
	},

	radius = {
		sm = UDim.new(0, 0),
		md = UDim.new(0, 0),
		lg = UDim.new(0, 0),
		pill = UDim.new(0, 0),
	},

	stroke = {
		panel = 4,
		control = 3,
		text = 2,
	},

	shadow = {
		style = "lip",
		offset = 4,
		transparency = 0,
	},

	buttons = {
		fill = "twoTone",
		highlight = 0.15,
		textSizes = { sm = 11, md = 13, lg = 16 },
	},

	motion = {
		fast = 0.06,
		normal = 0.12,
		slow = 0.25,
		easing = Enum.EasingStyle.Linear,
		pop = Enum.EasingStyle.Linear,
		hoverScale = 1.0,
		pressScale = 1.0,
		openStyle = "none",
	},
}
