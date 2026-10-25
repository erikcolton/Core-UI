--[[
	One editor control per schema field type (see Schema.luau). Each control reads
	its token with ctx.get(path), writes with ctx.set(path, value, final), and has a
	refresh() that re-reads the token after undo or a theme switch.

	ctx provides: get, set, overlay, theme(), recentColors(), addRecentColor(color), playSound(id)
]]

local Studio = require(script.Parent.Studio)
local Controls = require(script.Parent.Controls)
local ColorPicker = require(script.Parent.ColorPicker)
local Create = require(script.Parent.Parent.CoreUI.Util.Create)
local Color = require(script.Parent.Parent.CoreUI.Util.Color)
local Serialize = require(script.Parent.Parent.CoreUI.Theme.Serialize)

local Fields = {}

type Field = { [string]: any }
type Editor = { refresh: () -> () }

-- Fonts --------------------------------------------------------------------------

local fontFamilies: { { label: string, family: string } }? = nil

-- Every built-in font family, named after its Enum.Font item.
function Fields.fontFamilies(): { { label: string, family: string } }
	if fontFamilies then
		return fontFamilies
	end
	local seen = {}
	local list = {}
	for _, item in Enum.Font:GetEnumItems() do
		local ok, font = pcall(Font.fromEnum, item)
		if ok and font and not seen[font.Family] and item.Name ~= "Unknown" and item.Name ~= "Legacy" then
			seen[font.Family] = true
			table.insert(list, { label = item.Name, family = font.Family })
		end
	end
	table.sort(list, function(a, b)
		return a.label < b.label
	end)
	fontFamilies = list
	return list
end

local function familyLabel(family: string): string
	for _, entry in Fields.fontFamilies() do
		if entry.family == family then
			return entry.label
		end
	end
	local id = string.match(family, "rbxassetid://(%d+)")
	return if id then "Custom font " .. id else family
end

-- Shared bits ----------------------------------------------------------------------

local function decimals(step: number): number
	if step >= 1 then
		return 0
	end
	return math.clamp(math.ceil(-math.log10(step) - 1e-9), 0, 4)
end

local function formatNumber(value: number, step: number): string
	local places = decimals(step)
	if places == 0 then
		return tostring(math.round(value))
	end
	local text = string.format("%." .. places .. "f", value)
	text = string.gsub(text, "0+$", "")
	return (string.gsub(text, "%.$", ""))
end

local function snap(value: number, field: Field): number
	local step = field.step or 1
	local snapped = field.min + math.round((value - field.min) / step) * step
	-- Trim float noise like 0.30000000000000004.
	local places = decimals(step)
	local factor = 10 ^ places
	return math.clamp(math.round(snapped * factor) / factor, field.min, field.max)
end

--[[
	A dropdown button. options = { { label, value, font? } }. current() returns the
	selected value; pick(value) is called with the chosen one.
]]
function Fields.dropdown(
	ctx: any,
	parent: Instance,
	options: { any } | () -> { any },
	current: () -> any,
	pick: (any) -> (),
	props: { [string]: any }?
): (TextButton, () -> ())
	local p = props or {}
	local button = Create("TextButton", {
		Name = "Dropdown",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Text = "",
		Size = p.Size or UDim2.new(1, 0, 0, 24),
		Position = p.Position,
		LayoutOrder = p.LayoutOrder or 0,
		Parent = parent,
	})
	Controls.corner(button, 3)
	Controls.stroke(button, "inputBorder")
	Studio.bind(button, function(c)
		button.BackgroundColor3 = c.input
	end)
	local label = Controls.label({
		Text = "",
		TextSize = 13,
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(6, 0),
		Parent = button,
	})
	Controls.label({
		Text = "▾",
		Dim = true,
		AlignX = Enum.TextXAlignment.Center,
		Size = UDim2.new(0, 18, 1, 0),
		Position = UDim2.new(1, -20, 0, 0),
		Parent = button,
	})

	local function list(): { any }
		return if type(options) == "function" then options() else options
	end

	local function refresh()
		local value = current()
		label.Text = p.Placeholder or "—"
		label.FontFace = Studio.font
		for _, option in list() do
			if Serialize.equals(option[2], value) then
				label.Text = option[1]
				if option[3] then
					label.FontFace = option[3]
				end
				return
			end
		end
		if p.Describe then
			label.Text = p.Describe(value)
		end
	end

	button.Activated:Connect(function()
		local entries = list()
		local rowHeight = if p.RowHeight then p.RowHeight else 24
		local height = math.min(#entries * rowHeight + 8, p.MaxHeight or 280)
		ctx.overlay:popover(button, math.max(button.AbsoluteSize.X, p.MinWidth or 0), height, function(frame, close)
			local scroll = Create("ScrollingFrame", {
				Name = "Options",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 6,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Parent = frame,
			})
			Studio.bind(scroll, function(c)
				scroll.ScrollBarImageColor3 = c.scrollBar
			end)
			Controls.padding(scroll, 4)
			Controls.list(scroll)
			local value = current()
			local selectedIndex = 0
			for index, option in entries do
				local selected = Serialize.equals(option[2], value)
				if selected then
					selectedIndex = index
				end
				local row = Create("TextButton", {
					Name = "Option",
					AutoButtonColor = false,
					BorderSizePixel = 0,
					Text = "",
					Size = UDim2.new(1, 0, 0, rowHeight),
					LayoutOrder = index,
					Parent = scroll,
				})
				Controls.corner(row, 3)
				local function paint(hover: boolean)
					local c = Studio.colors
					row.BackgroundColor3 = if selected then c.accent elseif hover then c.hover else c.background
					row.BackgroundTransparency = if selected or hover then 0 else 1
				end
				paint(false)
				row.MouseEnter:Connect(function()
					paint(true)
				end)
				row.MouseLeave:Connect(function()
					paint(false)
				end)
				local text = Controls.label({
					Text = option[1],
					TextSize = if option[3] then 15 else 13,
					Size = UDim2.new(1, -8, 1, 0),
					Position = UDim2.fromOffset(6, 0),
					Color = if selected then "accentText" else nil,
					Parent = row,
				})
				if option[3] then
					text.FontFace = option[3]
				end
				row.Activated:Connect(function()
					close()
					pick(option[2])
					refresh()
				end)
			end
			if selectedIndex > 0 then
				scroll.CanvasPosition = Vector2.new(0, math.max(0, (selectedIndex - 3) * rowHeight))
			end
		end)
	end)

	refresh()
	return button, refresh
end

-- Field editors -------------------------------------------------------------------

local editors: { [string]: (any, Instance, Field, number) -> Editor } = {}

editors.color = function(ctx, parent, field, order)
	local _, control = Controls.row(parent, field.label, nil, order)
	local swatch = Controls.swatch(Color3.new(), 22, { Position = UDim2.fromOffset(0, 3), Parent = control })
	local hex = Controls.textBox({
		Mono = true,
		Size = UDim2.new(1, -30, 0, 24),
		Position = UDim2.fromOffset(30, 2),
		Parent = control,
		OnCommit = function(text)
			local parsed = Color.fromHex(text)
			if parsed then
				ctx.set(field.path, parsed, true)
				ctx.addRecentColor(parsed)
			end
		end,
	})
	local function refresh()
		local value = ctx.get(field.path)
		if typeof(value) == "Color3" then
			swatch.BackgroundColor3 = value
			hex.Text = Color.toHex(value)
		end
	end
	swatch.Activated:Connect(function()
		local value = ctx.get(field.path)
		local theme = ctx.theme()
		local palette = {}
		for _, key in
			{ "primary", "secondary", "buy", "danger", "surface", "surfaceAlt", "text", "stroke", "background" }
		do
			local paletteColor = theme.colors[key]
			if typeof(paletteColor) == "Color3" then
				table.insert(palette, paletteColor)
			end
		end
		ColorPicker.open(ctx.overlay, swatch, {
			Color = if typeof(value) == "Color3" then value else Color3.new(1, 1, 1),
			Palette = palette,
			Recent = ctx.recentColors(),
			OnChange = function(color, final)
				ctx.set(field.path, color, final)
				if final then
					ctx.addRecentColor(color)
				end
				refresh()
			end,
		})
	end)
	refresh()
	return { refresh = refresh }
end

-- Slider plus number box. read/write convert between the token and a plain number.
local function numberEditor(ctx, parent, field, order, read: (any) -> number?, write: (number) -> any)
	local _, control = Controls.row(parent, field.label, nil, order)
	local track = Create("TextButton", {
		Name = "Track",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Text = "",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 6, 0.5, 0),
		Size = UDim2.new(1, -72, 0, 4),
		Parent = control,
	})
	Controls.corner(track, 2)
	local fill = Create("Frame", {
		Name = "Fill",
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		Parent = track,
	})
	Controls.corner(fill, 2)
	local knob = Create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromScale(0, 0.5),
		Parent = track,
	})
	Controls.corner(knob, 6)
	Studio.bind(track, function(c)
		track.BackgroundColor3 = c.input
		fill.BackgroundColor3 = c.accent
		knob.BackgroundColor3 = c.text
	end)
	-- A bigger invisible hit area around the thin track.
	local hit = Create("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Text = "",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Parent = control,
	})
	local box
	local function render(value: number)
		local ratio = math.clamp((value - field.min) / (field.max - field.min), 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
		knob.Position = UDim2.fromScale(ratio, 0.5)
		box.Text = formatNumber(value, field.step or 1)
	end
	box = Controls.textBox({
		Mono = true,
		Size = UDim2.fromOffset(54, 24),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 2),
		Parent = control,
		OnCommit = function(text)
			local typed = tonumber(text)
			if typed then
				local value = math.clamp(typed, field.min, field.max)
				ctx.set(field.path, write(value), true)
				render(value)
			else
				render(read(ctx.get(field.path)) or field.min)
			end
		end,
	})
	local function refresh()
		render(read(ctx.get(field.path)) or field.min)
	end
	hit.MouseButton1Down:Connect(function()
		local last = nil
		ctx.overlay:drag(function(mouse: Vector2)
			local ratio = math.clamp((mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			local value = snap(field.min + ratio * (field.max - field.min), field)
			if value ~= last then
				last = value
				render(value)
				ctx.set(field.path, write(value), false)
			end
		end, function()
			if last ~= nil then
				ctx.set(field.path, write(last), true)
			end
		end)
	end)
	refresh()
	return { refresh = refresh }
end

editors.number = function(ctx, parent, field, order)
	return numberEditor(ctx, parent, field, order, function(value)
		return if type(value) == "number" then value else nil
	end, function(value)
		return value
	end)
end

editors.udim = function(ctx, parent, field, order)
	return numberEditor(ctx, parent, field, order, function(value)
		return if typeof(value) == "UDim" then value.Offset else nil
	end, function(value)
		return UDim.new(0, value)
	end)
end

editors.toggle = function(ctx, parent, field, order)
	local _, control = Controls.row(parent, field.label, nil, order)
	local box = Create("TextButton", {
		Name = "Check",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		FontFace = Studio.fontBold,
		TextSize = 14,
		Text = "",
		Position = UDim2.fromOffset(0, 5),
		Size = UDim2.fromOffset(18, 18),
		Parent = control,
	})
	Controls.corner(box, 3)
	Controls.stroke(box, "inputBorder")
	local function refresh()
		local on = ctx.get(field.path) == true
		local c = Studio.colors
		box.BackgroundColor3 = if on then c.accent else c.input
		box.TextColor3 = c.accentText
		box.Text = if on then "✓" else ""
	end
	Studio.bind(box, function()
		refresh()
	end)
	box.Activated:Connect(function()
		ctx.set(field.path, not (ctx.get(field.path) == true), true)
		refresh()
	end)
	return { refresh = refresh }
end

editors.choice = function(ctx, parent, field, order)
	local _, control = Controls.row(parent, field.label, nil, order)
	local _, refresh = Fields.dropdown(ctx, control, field.options, function()
		return ctx.get(field.path)
	end, function(value)
		ctx.set(field.path, value, true)
	end, { Position = UDim2.fromOffset(0, 2), Describe = tostring })
	return { refresh = refresh }
end

editors.enum = function(ctx, parent, field, order)
	local options = {}
	for _, item in (Enum :: any)[field.enum]:GetEnumItems() do
		table.insert(options, { item.Name, item })
	end
	local _, control = Controls.row(parent, field.label, nil, order)
	local _, refresh = Fields.dropdown(ctx, control, options, function()
		return ctx.get(field.path)
	end, function(value)
		ctx.set(field.path, value, true)
	end, { Position = UDim2.fromOffset(0, 2) })
	return { refresh = refresh }
end

local ROLE_OPTIONS = {
	{ "Display font", "display" },
	{ "Heading font", "heading" },
	{ "Body font", "body" },
	{ "Numbers / code font", "mono" },
}

editors.fontRole = function(ctx, parent, field, order)
	local _, control = Controls.row(parent, field.label, nil, order)
	local _, refresh = Fields.dropdown(ctx, control, ROLE_OPTIONS, function()
		return ctx.get(field.path)
	end, function(value)
		ctx.set(field.path, value, true)
	end, { Position = UDim2.fromOffset(0, 2) })
	return { refresh = refresh }
end

editors.font = function(ctx, parent, field, order)
	local _, control = Controls.row(parent, field.label, 56, order)
	local function currentFont(): Font
		local value = ctx.get(field.path)
		return if typeof(value) == "Font" then value else Font.fromEnum(Enum.Font.BuilderSans)
	end
	local familyOptions = function()
		local options = {}
		for _, entry in Fields.fontFamilies() do
			table.insert(options, { entry.label, entry.family, Font.new(entry.family) })
		end
		local family = currentFont().Family
		if string.find(family, "rbxassetid://", 1, true) then
			table.insert(options, 1, { familyLabel(family), family })
		end
		return options
	end
	local _, refreshFamily = Fields.dropdown(ctx, control, familyOptions, function()
		return currentFont().Family
	end, function(family)
		local font = currentFont()
		ctx.set(field.path, Font.new(family, font.Weight, font.Style), true)
	end, {
		Size = UDim2.new(1, -60, 0, 24),
		Position = UDim2.fromOffset(0, 2),
		MinWidth = 220,
		RowHeight = 26,
		MaxHeight = 360,
		Describe = familyLabel,
	})
	Controls.button("Custom", {
		Width = 56,
		Height = 24,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 2),
		Parent = control,
		OnClick = function()
			ctx.overlay:modal({
				Title = "Use a Creator Store font",
				Message = "Paste the font's asset id (the number in its Creator Store link) or an rbxassetid:// link.",
				Input = { Text = "", Placeholder = "e.g. 12187365364" },
				Buttons = {
					{ Text = "Cancel" },
					{
						Text = "Use font",
						Style = "primary",
						OnClick = function(text)
							local id = string.match(text or "", "(%d+)")
							if not id then
								return true
							end
							local font = currentFont()
							ctx.set(field.path, Font.new("rbxassetid://" .. id, font.Weight, font.Style), true)
							ctx.refresh()
							return false
						end,
					},
				},
			})
		end,
	})
	local weights = {}
	for _, item in Enum.FontWeight:GetEnumItems() do
		table.insert(weights, { item.Name, item })
	end
	local _, refreshWeight = Fields.dropdown(ctx, control, weights, function()
		return currentFont().Weight
	end, function(weight)
		local font = currentFont()
		ctx.set(field.path, Font.new(font.Family, weight, font.Style), true)
	end, { Size = UDim2.new(0.5, -2, 0, 24), Position = UDim2.fromOffset(0, 30) })
	local _, refreshStyle = Fields.dropdown(ctx, control, {
		{ "Normal", Enum.FontStyle.Normal },
		{ "Italic", Enum.FontStyle.Italic },
	}, function()
		return currentFont().Style
	end, function(style)
		local font = currentFont()
		ctx.set(field.path, Font.new(font.Family, font.Weight, style), true)
	end, { Size = UDim2.new(0.5, -2, 0, 24), Position = UDim2.new(0.5, 2, 0, 30) })
	local function refresh()
		refreshFamily()
		refreshWeight()
		refreshStyle()
	end
	return { refresh = refresh }
end

editors.vector2 = function(ctx, parent, field, order)
	local _, control = Controls.row(parent, field.label, nil, order)
	local boxes = {}
	local function commit()
		local x = tonumber(boxes[1].Text)
		local y = tonumber(boxes[2].Text)
		if x and y and x > 0 and y > 0 then
			ctx.set(field.path, Vector2.new(math.round(x), math.round(y)), true)
		end
	end
	for index = 1, 2 do
		boxes[index] = Controls.textBox({
			Mono = true,
			Size = UDim2.new(0.5, -2, 0, 24),
			Position = UDim2.new((index - 1) * 0.5, if index == 2 then 2 else 0, 0, 2),
			Parent = control,
			OnCommit = commit,
		})
	end
	local function refresh()
		local value = ctx.get(field.path)
		if typeof(value) == "Vector2" then
			boxes[1].Text = tostring(value.X)
			boxes[2].Text = tostring(value.Y)
		end
	end
	refresh()
	return { refresh = refresh }
end

-- "123" -> "rbxassetid://123", "" -> nil, anything else as typed.
function Fields.normalizeAsset(text: string?): string?
	local trimmed = string.match(text or "", "^%s*(.-)%s*$") or ""
	if trimmed == "" then
		return nil
	elseif string.match(trimmed, "^%d+$") then
		return "rbxassetid://" .. trimmed
	end
	return trimmed
end

editors.asset = function(ctx, parent, field, order)
	local _, control = Controls.row(parent, field.label, nil, order)
	local sound = field.kind == "sound"
	local box = Controls.textBox({
		Placeholder = "asset id, blank = none",
		Size = UDim2.new(1, if sound then -30 else 0, 0, 24),
		Position = UDim2.fromOffset(0, 2),
		Parent = control,
		OnCommit = function(text)
			ctx.set(field.path, Fields.normalizeAsset(text), true)
		end,
	})
	if sound then
		Controls.button("▶", {
			Width = 26,
			Height = 24,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 2),
			Parent = control,
			OnClick = function()
				local id = ctx.get(field.path)
				if type(id) == "string" and id ~= "" then
					ctx.playSound(id)
				end
			end,
		})
	end
	local function refresh()
		local value = ctx.get(field.path)
		box.Text = if type(value) == "string" then value else ""
	end
	refresh()
	return { refresh = refresh }
end

local function rectText(rect: Rect?): string
	if not rect then
		return ""
	end
	return string.format("%d, %d, %d, %d", rect.Min.X, rect.Min.Y, rect.Max.X, rect.Max.Y)
end

editors.skin = function(ctx, parent, field, order)
	local holder = Create("Frame", {
		Name = "Skin_" .. field.label,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = parent,
	})
	Controls.list(holder, 4)
	local _, imageControl = Controls.row(holder, field.label .. " image", nil, 1)
	local _, sliceControl = Controls.row(holder, "  Slice margins", nil, 2)
	local _, scaleControl = Controls.row(holder, "  Slice scale", nil, 3)

	local function current(): any?
		local value = ctx.get(field.path)
		return if type(value) == "table" then value else nil
	end
	local function update(change: (any) -> ())
		local skin = current()
		local copy = if skin then table.clone(skin) else { SliceScale = 1 }
		change(copy)
		ctx.set(field.path, if copy.Image then copy else nil, true)
	end

	local imageBox = Controls.textBox({
		Placeholder = "image asset id, blank = no skin",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 2),
		Parent = imageControl,
		OnCommit = function(text)
			update(function(skin)
				skin.Image = Fields.normalizeAsset(text)
			end)
		end,
	})
	local sliceBox = Controls.textBox({
		Mono = true,
		Placeholder = "left, top, right, bottom",
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.fromOffset(0, 2),
		Parent = sliceControl,
		OnCommit = function(text)
			local values: { number } = {}
			for n in string.gmatch(text, "-?%d+%.?%d*") do
				table.insert(values, tonumber(n) :: number)
			end
			update(function(skin)
				skin.SliceCenter = if #values == 4 then Rect.new(values[1], values[2], values[3], values[4]) else nil
			end)
		end,
	})
	local scaleBox = Controls.textBox({
		Mono = true,
		Size = UDim2.fromOffset(60, 24),
		Position = UDim2.fromOffset(0, 2),
		Parent = scaleControl,
		OnCommit = function(text)
			local n = tonumber(text)
			update(function(skin)
				skin.SliceScale = if n and n > 0 then n else 1
			end)
		end,
	})
	local function refresh()
		local skin = current()
		imageBox.Text = if skin and skin.Image then skin.Image else ""
		sliceBox.Text = rectText(skin and skin.SliceCenter)
		scaleBox.Text = tostring(if skin and skin.SliceScale then skin.SliceScale else 1)
	end
	refresh()
	return { refresh = refresh }
end

-- Builds the editor for one field. Returns { refresh }.
function Fields.build(ctx: any, parent: Instance, field: Field, order: number): Editor
	local editor = editors[field.type]
	assert(editor, "no editor for field type " .. tostring(field.type))
	return editor(ctx, parent, field, order)
end

Fields.types = editors

return Fields
