--[[
	Helpers that apply theme tokens to instances. Each helper finds or creates its
	decorator child by name, so stylers can run again on every theme change.
]]

local Color = require(script.Parent.Color)
local Create = require(script.Parent.Create)

local Style = {}

local WHITE = Color3.new(1, 1, 1)

function Style.child(parent: Instance, className: string, name: string): any
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	return Create(className, { Name = name, Parent = parent })
end

function Style.remove(parent: Instance, name: string)
	local existing = parent:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
end

function Style.corner(instance: Instance, radius: UDim?)
	if radius then
		Style.child(instance, "UICorner", "Corner").CornerRadius = radius
	else
		Style.remove(instance, "Corner")
	end
end

-- Border stroke. Thickness 0 disables it but keeps the instance for the next theme.
function Style.stroke(instance: Instance, thickness: number, color: Color3, transparency: number?): UIStroke
	local stroke = Style.child(instance, "UIStroke", "Stroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Thickness = thickness
	stroke.Color = color
	stroke.Transparency = transparency or 0
	stroke.Enabled = thickness > 0
	return stroke
end

-- Padding from a single number or { top, right, bottom, left }.
function Style.padding(instance: Instance, value: number | { number })
	local padding = Style.child(instance, "UIPadding", "Padding")
	local top, right, bottom, left
	if type(value) == "number" then
		top, right, bottom, left = value, value, value, value
	else
		top, right, bottom, left =
			value[1], value[2] or value[1], value[3] or value[1], value[4] or value[2] or value[1]
	end
	padding.PaddingTop = UDim.new(0, top)
	padding.PaddingRight = UDim.new(0, right)
	padding.PaddingBottom = UDim.new(0, bottom)
	padding.PaddingLeft = UDim.new(0, left)
end

-- Resolve a padding prop: "md" -> theme.spacing.md, number -> number, false -> 0.
function Style.space(theme: any, value: any, default: string?): number
	if value == false then
		return 0
	elseif type(value) == "number" then
		return value
	end
	return theme.spacing[value or default or "md"] or 0
end

-- Outline on the glyphs themselves (not the box).
function Style.textOutline(label: Instance, theme: any, enabled: boolean, color: Color3?)
	local thickness = if enabled then theme.stroke.text else 0
	local stroke = Style.child(label, "UIStroke", "TextStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Thickness = thickness
	stroke.Color = color or theme.colors.textStroke
	stroke.Enabled = thickness > 0
end

-- Font, size and outline for a typography role. outline overrides the role default when not nil.
function Style.text(label: any, theme: any, role: string, outline: boolean?)
	local spec = theme.typography[role] or theme.typography.body
	label.FontFace = theme.fonts[spec.font] or theme.fonts.body
	label.TextSize = spec.size
	local useOutline = if outline ~= nil then outline else spec.outline == true
	Style.textOutline(label, theme, useOutline)
end

local function lookup(colors: any, path: string): Color3?
	local node = colors
	for part in string.gmatch(path, "[^%.]+") do
		if type(node) ~= "table" then
			return nil
		end
		node = node[part]
	end
	return if typeof(node) == "Color3" then node else nil
end

-- Resolve a color prop: a Color3 is used as is; a string is a theme.colors key,
-- with dots for nested tables ("rarity.epic").
function Style.color(theme: any, value: any, default: string): Color3
	if typeof(value) == "Color3" then
		return value
	end
	return lookup(theme.colors, value or default) or lookup(theme.colors, default) or theme.colors.text
end

-- Fill a surface with a flat color or a gradient. mode is a buttons.fill token:
-- "flat", "twoTone" (hard stop in the middle) or "gradient" (smooth, lighter at the top).
-- true and false are accepted as "twoTone" and "flat".
function Style.fill(surface: any, color: Color3, mode: (string | boolean)?, highlight: number?)
	local existing = surface:FindFirstChild("Gradient")
	local kind = if mode == true then "twoTone" elseif type(mode) == "string" then mode else "flat"
	if kind == "twoTone" or kind == "gradient" then
		surface.BackgroundColor3 = WHITE
		local uiGradient = existing or Create("UIGradient", { Name = "Gradient", Rotation = 90, Parent = surface })
		uiGradient.Color = if kind == "twoTone"
			then Color.twoTone(color, highlight or 0.18)
			else Color.smooth(color, highlight or 0.18)
	else
		surface.BackgroundColor3 = color
		if existing then
			existing:Destroy()
		end
	end
end

--[[
	Optional 9-slice skin image behind a surface's content.
	Returns true when a skin is applied, so the caller can hide its flat fill and border.
]]
function Style.skin(surface: Instance, spec: any?, tint: Color3?): boolean
	if not spec then
		Style.remove(surface, "Skin")
		return false
	end
	local image = Style.child(surface, "ImageLabel", "Skin")
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.ZIndex = 0
	image.Image = spec.Image
	image.ScaleType = Enum.ScaleType.Slice
	image.SliceCenter = spec.SliceCenter or Rect.new(0, 0, 0, 0)
	image.SliceScale = spec.SliceScale or 1
	image.ImageColor3 = tint or WHITE
	return true
end

--[[
	Shadow frame that sits behind a surface (as a sibling, lower ZIndex).
	Returns the depth in pixels that the surface should leave free at the bottom.
]]
function Style.shadow(shadow: any, theme: any, base: Color3, radius: UDim?, strokeThickness: number?): number
	local spec = theme.shadow
	if spec.style == "none" then
		shadow.Visible = false
		return 0
	end
	shadow.Visible = true
	shadow.BorderSizePixel = 0
	Style.corner(shadow, radius)
	if spec.style == "lip" then
		shadow.BackgroundColor3 = Color.darken(base, 0.35)
		shadow.BackgroundTransparency = spec.transparency
		Style.stroke(shadow, strokeThickness or 0, theme.colors.stroke)
	else
		shadow.BackgroundColor3 = theme.colors.overlay
		shadow.BackgroundTransparency = spec.transparency
		Style.stroke(shadow, 0, theme.colors.stroke)
	end
	return spec.offset
end

return Style
