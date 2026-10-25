--[[
	Cartoony: thick outlines, two-tone buttons with a solid lip, outlined text and
	bouncy motion. The house style of most Roblox simulators.
	Only the tokens that differ from Clean are listed.
]]

local rgb = Color3.fromRGB

-- family is a font family file name under rbxasset://fonts/families/ (see the Font docs).
local function font(family: string, weight: Enum.FontWeight?): Font
	return Font.new("rbxasset://fonts/families/" .. family .. ".json", weight or Enum.FontWeight.Regular)
end

local outline = rgb(27, 42, 74)

return {
	colors = {
		background = rgb(76, 172, 245),
		surface = rgb(244, 248, 255),
		surfaceAlt = rgb(219, 232, 252),
		stroke = outline,
		textStroke = outline,
		text = rgb(27, 42, 74),
		textMuted = rgb(77, 98, 140),

		primary = rgb(255, 201, 39),
		onPrimary = rgb(255, 255, 255),
		secondary = rgb(98, 179, 255),
		onSecondary = rgb(255, 255, 255),
		buy = rgb(84, 201, 52),
		onBuy = rgb(255, 255, 255),
		danger = rgb(255, 82, 82),
		onDanger = rgb(255, 255, 255),

		success = rgb(84, 201, 52),
		warning = rgb(255, 170, 30),
		error = rgb(255, 82, 82),
		info = rgb(98, 179, 255),
		badge = rgb(255, 59, 59),

		overlay = rgb(8, 18, 40),
		track = rgb(27, 42, 74),
		selection = rgb(255, 255, 255),
	},

	transparency = {
		overlay = 0.5,
	},

	fonts = {
		display = font("LuckiestGuy"),
		heading = font("FredokaOne"),
		body = font("FredokaOne"),
	},

	typography = {
		display = { size = 48 },
		title = { size = 34 },
		heading = { size = 24, outline = true },
		label = { size = 20 },
		body = { size = 17 },
		caption = { size = 14 },
	},

	radius = {
		sm = UDim.new(0, 10),
		md = UDim.new(0, 14),
		lg = UDim.new(0, 20),
	},

	stroke = {
		panel = 4,
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
		highlight = 0.22,
		heights = { sm = 38, md = 52, lg = 64 },
	},

	motion = {
		normal = 0.28,
		hoverScale = 1.07,
		pressScale = 0.92,
		openFrom = 0.75,
	},
}
