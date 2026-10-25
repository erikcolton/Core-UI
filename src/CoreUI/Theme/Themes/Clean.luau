--[[
	Clean: the base theme. Every token the kit reads is defined here; other themes
	only override what they change. Copy this file as the starting point for a new theme.
]]

local rgb = Color3.fromRGB

-- family is a font family file name under rbxasset://fonts/families/ (see the Font docs).
local function font(family: string, weight: Enum.FontWeight?): Font
	return Font.new("rbxasset://fonts/families/" .. family .. ".json", weight or Enum.FontWeight.Regular)
end

return {
	colors = {
		background = rgb(238, 241, 246),
		surface = rgb(255, 255, 255),
		surfaceAlt = rgb(243, 245, 249),
		stroke = rgb(214, 219, 229),
		textStroke = rgb(29, 36, 51), -- outline color for outlined text
		text = rgb(29, 36, 51),
		textMuted = rgb(107, 115, 133),
		textInverse = rgb(255, 255, 255),

		primary = rgb(37, 99, 235), -- the main action on a screen
		onPrimary = rgb(255, 255, 255),
		secondary = rgb(226, 231, 240), -- neutral actions, unselected tabs
		onSecondary = rgb(29, 36, 51),
		buy = rgb(22, 163, 74), -- spending currency or Robux
		onBuy = rgb(255, 255, 255),
		danger = rgb(220, 38, 38), -- delete, close, destructive
		onDanger = rgb(255, 255, 255),

		success = rgb(22, 163, 74),
		warning = rgb(245, 158, 11),
		error = rgb(220, 38, 38),
		info = rgb(37, 99, 235),
		badge = rgb(239, 68, 68),
		onBadge = rgb(255, 255, 255),

		overlay = rgb(10, 14, 24), -- backdrop behind windows
		track = rgb(226, 231, 240), -- empty part of bars, toggles, sliders
		selection = rgb(37, 99, 235), -- gamepad selection outline

		rarity = {
			common = rgb(156, 163, 175),
			uncommon = rgb(34, 197, 94),
			rare = rgb(59, 130, 246),
			epic = rgb(168, 85, 247),
			legendary = rgb(245, 158, 11),
			mythic = rgb(236, 72, 153),
		},
	},

	transparency = {
		surface = 0,
		surfaceAlt = 0,
		overlay = 0.45,
		disabled = 0.45,
	},

	fonts = {
		display = font("BuilderSans", Enum.FontWeight.ExtraBold),
		heading = font("BuilderSans", Enum.FontWeight.Bold),
		body = font("BuilderSans", Enum.FontWeight.Regular),
		mono = font("RobotoMono", Enum.FontWeight.Regular),
	},

	-- Text roles. Sizes are at the reference resolution; the layer UIScale adapts them.
	typography = {
		display = { font = "display", size = 44, outline = true },
		title = { font = "display", size = 30, outline = true },
		heading = { font = "heading", size = 22, outline = false },
		label = { font = "heading", size = 18, outline = true },
		body = { font = "body", size = 17, outline = false },
		caption = { font = "body", size = 14, outline = false },
	},

	radius = {
		sm = UDim.new(0, 6),
		md = UDim.new(0, 10),
		lg = UDim.new(0, 14),
		pill = UDim.new(1, 0),
	},

	stroke = {
		panel = 1, -- window and panel border
		control = 0, -- buttons, slots, inputs
		text = 0, -- outline on text roles marked outline = true; 0 turns it off
	},

	shadow = {
		style = "soft", -- "soft" (faint offset shadow), "lip" (solid darker base), or "none"
		offset = 3,
		transparency = 0.86,
	},

	buttons = {
		fill = "flat", -- "flat", "twoTone" (hard stop in the middle) or "gradient" (smooth)
		highlight = 0.18, -- how much lighter the top is for twoTone and gradient fills
		heights = { sm = 34, md = 46, lg = 58 },
		widths = { sm = 104, md = 156, lg = 216 },
		textSizes = { sm = 15, md = 18, lg = 22 },
		font = "heading",
	},

	-- Extra surface effects.
	effects = {
		panelGradient = 0, -- 0 = flat panels; up to ~0.4 lightens the top of each panel
	},

	spacing = {
		xs = 4,
		sm = 8,
		md = 12,
		lg = 16,
		xl = 24,
	},

	motion = {
		fast = 0.12,
		normal = 0.22,
		slow = 0.4,
		easing = Enum.EasingStyle.Quad,
		pop = Enum.EasingStyle.Back, -- windows opening, counters pulsing
		hoverScale = 1.03,
		pressScale = 0.96,
		openFrom = 0.9, -- window scale when it starts opening
		openStyle = "pop", -- how windows and dialogs appear: "pop", "slide" or "none"
	},

	-- Each layer gets one UIScale: min(viewport / referenceSize), clamped.
	layout = {
		referenceSize = Vector2.new(1100, 620),
		minScale = 0.62,
		maxScale = 1.5,
	},

	-- Sound asset ids (e.g. "rbxassetid://123"). nil = silent.
	sounds = {
		click = nil,
		open = nil,
		close = nil,
		notify = nil,
		volume = 0.5,
	},

	-- Optional 9-slice skins. Each is { Image = "rbxassetid://...", SliceCenter = Rect.new(...), SliceScale = 1 }.
	-- When set, the skin replaces the flat fill and border of that surface.
	images = {
		panel = nil,
		button = nil,
		slot = nil,
	},
}
