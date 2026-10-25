--[[
	What the customizer lets you edit: tabs, sections and fields, each pointing at a
	theme token by its dotted path ("colors.primary", "typography.title.size").
	The editor builds its controls from this table, so adding a token to the kit only
	needs a line here.

	Field types:
		color                       Color3 with picker
		number   min max step       slider plus number box
		udim     min max            UDim offset in pixels (corner radii)
		toggle                      boolean
		choice   options            one of a fixed list of { label, value }
		enum     enum               an Enum item (EasingStyle)
		font                        a Font (family and weight)
		fontRole                    which of fonts.display/heading/body/mono to use
		vector2                     two numbers
		asset    kind               an asset id string, empty = none; kind "sound" adds a play button
		skin                        an optional 9-slice image { Image, SliceCenter, SliceScale }
]]

local Schema = {}

local function color(path: string, label: string)
	return { type = "color", path = path, label = label }
end

local function number(path: string, label: string, min: number, max: number, step: number?)
	return { type = "number", path = path, label = label, min = min, max = max, step = step or 1 }
end

local function choice(path: string, label: string, options: { { any } })
	return { type = "choice", path = path, label = label, options = options }
end

local ROLES = {
	{ "display", "Display (big titles)" },
	{ "title", "Title (window titles)" },
	{ "heading", "Heading" },
	{ "label", "Label (counters, tags)" },
	{ "body", "Body" },
	{ "caption", "Caption (small print)" },
}

local function roleSections()
	local sections = {}
	for _, role in ROLES do
		local key = role[1]
		table.insert(sections, {
			title = role[2],
			collapsed = key ~= "title" and key ~= "body",
			fields = {
				{ type = "fontRole", path = "typography." .. key .. ".font", label = "Font" },
				number("typography." .. key .. ".size", "Size", 8, 72),
				{ type = "toggle", path = "typography." .. key .. ".outline", label = "Outline" },
			},
		})
	end
	return sections
end

Schema.tabs = {
	{ id = "themes", label = "Themes" },
	{
		id = "colors",
		label = "Colors",
		sections = {
			{
				title = "Surfaces",
				fields = {
					color("colors.background", "Background"),
					color("colors.surface", "Panel"),
					color("colors.surfaceAlt", "Inset panel"),
					color("colors.stroke", "Outline"),
					color("colors.track", "Bar track"),
					color("colors.overlay", "Backdrop"),
				},
			},
			{
				title = "Text",
				fields = {
					color("colors.text", "Text"),
					color("colors.textMuted", "Muted text"),
					color("colors.textInverse", "Text on dark"),
					color("colors.textStroke", "Text outline"),
				},
			},
			{
				title = "Buttons",
				fields = {
					color("colors.primary", "Primary"),
					color("colors.onPrimary", "Primary text"),
					color("colors.secondary", "Secondary"),
					color("colors.onSecondary", "Secondary text"),
					color("colors.buy", "Buy"),
					color("colors.onBuy", "Buy text"),
					color("colors.danger", "Danger"),
					color("colors.onDanger", "Danger text"),
				},
			},
			{
				title = "States",
				fields = {
					color("colors.success", "Success"),
					color("colors.warning", "Warning"),
					color("colors.error", "Error"),
					color("colors.info", "Info"),
					color("colors.badge", "Badge"),
					color("colors.onBadge", "Badge text"),
					color("colors.selection", "Gamepad selection"),
				},
			},
			{
				title = "Rarity",
				collapsed = true,
				fields = {
					color("colors.rarity.common", "Common"),
					color("colors.rarity.uncommon", "Uncommon"),
					color("colors.rarity.rare", "Rare"),
					color("colors.rarity.epic", "Epic"),
					color("colors.rarity.legendary", "Legendary"),
					color("colors.rarity.mythic", "Mythic"),
				},
			},
		},
	},
	{
		id = "shapes",
		label = "Shapes",
		sections = {
			{
				title = "Corners",
				fields = {
					{ type = "udim", path = "radius.sm", label = "Small", min = 0, max = 40 },
					{ type = "udim", path = "radius.md", label = "Medium (buttons)", min = 0, max = 40 },
					{ type = "udim", path = "radius.lg", label = "Large (panels)", min = 0, max = 48 },
					choice("radius.pill", "Pills (toggles, bars)", {
						{ "Round", UDim.new(1, 0) },
						{ "Square", UDim.new(0, 0) },
						{ "Slightly round", UDim.new(0, 6) },
					}),
				},
			},
			{
				title = "Outlines",
				fields = {
					number("stroke.panel", "Panel border", 0, 10, 0.5),
					number("stroke.control", "Button border", 0, 8, 0.5),
					number("stroke.text", "Text outline", 0, 5, 0.5),
				},
			},
			{
				title = "Button sizes",
				fields = {
					number("buttons.heights.sm", "Small height", 20, 90),
					number("buttons.heights.md", "Medium height", 20, 90),
					number("buttons.heights.lg", "Large height", 20, 110),
					number("buttons.widths.sm", "Small width", 40, 320),
					number("buttons.widths.md", "Medium width", 40, 360),
					number("buttons.widths.lg", "Large width", 40, 420),
					number("buttons.textSizes.sm", "Small text", 8, 40),
					number("buttons.textSizes.md", "Medium text", 8, 44),
					number("buttons.textSizes.lg", "Large text", 8, 48),
				},
			},
			{
				title = "Spacing",
				collapsed = true,
				fields = {
					number("spacing.xs", "Extra small", 0, 24),
					number("spacing.sm", "Small", 0, 32),
					number("spacing.md", "Medium", 0, 40),
					number("spacing.lg", "Large", 0, 48),
					number("spacing.xl", "Extra large", 0, 64),
				},
			},
			{
				title = "Screen scaling",
				collapsed = true,
				fields = {
					{ type = "vector2", path = "layout.referenceSize", label = "Design size" },
					number("layout.minScale", "Smallest scale", 0.3, 1.5, 0.01),
					number("layout.maxScale", "Largest scale", 0.5, 3, 0.01),
				},
			},
		},
	},
	{
		id = "text",
		label = "Fonts",
		sections = {
			{
				title = "Font families",
				fields = {
					{ type = "font", path = "fonts.display", label = "Display" },
					{ type = "font", path = "fonts.heading", label = "Heading" },
					{ type = "font", path = "fonts.body", label = "Body" },
					{ type = "font", path = "fonts.mono", label = "Numbers / code" },
					{ type = "fontRole", path = "buttons.font", label = "Button font" },
				},
			},
			table.unpack(roleSections()),
		},
	},
	{
		id = "effects",
		label = "Effects",
		sections = {
			{
				title = "Shadows",
				fields = {
					choice("shadow.style", "Style", {
						{ "None", "none" },
						{ "Soft drop shadow", "soft" },
						{ "Solid 3D lip", "lip" },
					}),
					number("shadow.offset", "Depth", 0, 14),
					number("shadow.transparency", "Transparency", 0, 1, 0.01),
				},
			},
			{
				title = "Fills and gradients",
				fields = {
					choice("buttons.fill", "Button fill", {
						{ "Flat", "flat" },
						{ "Two-tone (cartoon)", "twoTone" },
						{ "Smooth gradient", "gradient" },
					}),
					number("buttons.highlight", "Highlight", 0, 0.6, 0.01),
					number("effects.panelGradient", "Panel sheen", 0, 0.5, 0.01),
				},
			},
			{
				title = "Transparency",
				fields = {
					number("transparency.surface", "Panels", 0, 0.9, 0.01),
					number("transparency.surfaceAlt", "Inset panels", 0, 0.9, 0.01),
					number("transparency.overlay", "Backdrop", 0, 1, 0.01),
					number("transparency.disabled", "Disabled", 0, 1, 0.01),
				},
			},
		},
	},
	{
		id = "motion",
		label = "Motion",
		sections = {
			{
				title = "Windows",
				fields = {
					choice("motion.openStyle", "Open animation", {
						{ "Pop", "pop" },
						{ "Slide up", "slide" },
						{ "None", "none" },
					}),
					number("motion.openFrom", "Pop start size", 0.3, 1, 0.01),
					{ type = "enum", path = "motion.pop", label = "Pop easing", enum = "EasingStyle" },
				},
			},
			{
				title = "Buttons",
				fields = {
					number("motion.hoverScale", "Hover grow", 1, 1.25, 0.01),
					number("motion.pressScale", "Press shrink", 0.75, 1, 0.01),
				},
			},
			{
				title = "Timing",
				fields = {
					number("motion.fast", "Fast (seconds)", 0, 1, 0.01),
					number("motion.normal", "Normal (seconds)", 0, 1.5, 0.01),
					number("motion.slow", "Slow (seconds)", 0, 2, 0.01),
					{ type = "enum", path = "motion.easing", label = "Easing", enum = "EasingStyle" },
				},
			},
		},
	},
	{
		id = "assets",
		label = "Sounds & Skins",
		sections = {
			{
				title = "Sounds",
				fields = {
					{ type = "asset", kind = "sound", path = "sounds.click", label = "Click" },
					{ type = "asset", kind = "sound", path = "sounds.open", label = "Window open" },
					{ type = "asset", kind = "sound", path = "sounds.close", label = "Window close" },
					{ type = "asset", kind = "sound", path = "sounds.notify", label = "Notification" },
					number("sounds.volume", "Volume", 0, 1, 0.01),
				},
			},
			{
				title = "9-slice skins (optional)",
				hint = "Upload a frame image and set its slice margins. A skin replaces the flat fill and border.",
				fields = {
					{ type = "skin", path = "images.panel", label = "Panels" },
					{ type = "skin", path = "images.button", label = "Buttons" },
					{ type = "skin", path = "images.slot", label = "Item slots" },
				},
			},
		},
	},
}

-- Path helpers -------------------------------------------------------------------

function Schema.split(path: string): { string }
	local parts = {}
	for part in string.gmatch(path, "[^%.]+") do
		table.insert(parts, part)
	end
	return parts
end

function Schema.get(theme: any, path: string): any
	local node = theme
	for _, part in Schema.split(path) do
		if type(node) ~= "table" then
			return nil
		end
		node = node[part]
	end
	return node
end

-- Sets a token, creating missing parent tables. nil removes it.
function Schema.set(theme: any, path: string, value: any)
	local parts = Schema.split(path)
	local node = theme
	for index = 1, #parts - 1 do
		local part = parts[index]
		if type(node[part]) ~= "table" then
			node[part] = {}
		end
		node = node[part]
	end
	node[parts[#parts]] = value
end

-- Every field, for tests and search.
function Schema.fields(): { any }
	local all = {}
	for _, tab in Schema.tabs do
		for _, section in tab.sections or {} do
			for _, field in section.fields do
				table.insert(all, field)
			end
		end
	end
	return all
end

-- The types a token must have for each field type.
Schema.valueTypes = {
	color = { "Color3" },
	number = { "number" },
	udim = { "UDim" },
	toggle = { "boolean" },
	choice = nil,
	enum = { "EnumItem" },
	font = { "Font" },
	fontRole = { "string" },
	vector2 = { "Vector2" },
	asset = { "string", "nil" },
	skin = { "table", "nil" },
}

return Schema
