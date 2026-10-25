--[[
	Panel: a themed surface. Put children in panel.Content (or pass the panel as Parent).

		local panel = Panel.new({ Size = UDim2.fromOffset(300, 200), Variant = "surface", Padding = "lg" })

	Variant: surface (raised, with shadow) | inset (flat, for grouping inside a surface)
	Padding: a spacing token name, a number of pixels, or false (default "md")

	Panels need an explicit Size: the shadow and surface fill the root by scale,
	so AutomaticSize on the root has nothing to measure.
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Component = require(script.Parent.Parent.Util.Component)

local Panel = {}
Panel.__index = Panel

function Panel.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, Panel)
	self.Variant = p.Variant or "surface"
	self.Padding = p.Padding
	self.Color = p.Color

	self.Instance = Create("Frame", {
		Name = "Panel",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(300, 200),
	})
	self._shadow = Create("Frame", { Name = "Shadow", ZIndex = 1, BorderSizePixel = 0, Parent = self.Instance })
	self.Surface = Create("Frame", {
		Name = "Surface",
		ZIndex = 2,
		BorderSizePixel = 0,
		ClipsDescendants = p.Clip == true,
		Parent = self.Instance,
	})
	self.Content = self.Surface

	Theme.bind(self.Instance, function(theme)
		self:_style(theme)
	end)
	return Component.finish(self, p)
end

function Panel:_style(theme: any)
	local inset = self.Variant == "inset"
	local surface = self.Surface
	local colorKey = if inset then "surfaceAlt" else "surface"
	local base = Style.color(theme, self.Color, colorKey)
	local radius = if inset then theme.radius.md else theme.radius.lg
	local strokeThickness = if inset then theme.stroke.control else theme.stroke.panel

	Style.corner(surface, radius)
	local skinned = (not inset) and Style.skin(surface, theme.images.panel)
	local sheen = if inset or skinned then 0 else theme.effects.panelGradient
	Style.fill(surface, base, if sheen > 0 then "gradient" else "flat", sheen)
	surface.BackgroundTransparency = if skinned then 1 else theme.transparency[colorKey] or 0
	Style.stroke(surface, if skinned then 0 else strokeThickness, theme.colors.stroke)

	local depth = 0
	if inset or skinned then
		self._shadow.Visible = false
	else
		depth = Style.shadow(self._shadow, theme, base, radius, strokeThickness)
	end
	surface.Size = UDim2.new(1, 0, 1, -depth)
	self._shadow.Size = UDim2.new(1, 0, 1, -depth)
	self._shadow.Position = UDim2.fromOffset(0, depth)

	Style.padding(surface, Style.space(theme, self.Padding, "md"))
end

function Panel:Destroy()
	self.Instance:Destroy()
end

return Panel
