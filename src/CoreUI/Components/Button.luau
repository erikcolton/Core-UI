--[[
	Button: the kit's main control.

		Button.new({
			Text = "Play",
			Variant = "primary",   -- primary | secondary | buy | danger | ghost
			ButtonSize = "lg",     -- sm | md | lg (default md)
			Icon = "rbxassetid://...",
			OnClick = function(button) end,
			Parent = frame,
		})

	Size is optional: by default the theme sets width and height for ButtonSize.
	Square = true makes width equal to height (icon buttons, close buttons).
	FullWidth = true fills the parent's width at the theme height.
	Width = number sets the width in pixels and keeps the theme height.
	Color = Color3 overrides the variant fill for one-off buttons.
]]

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Color = require(script.Parent.Parent.Util.Color)
local Tween = require(script.Parent.Parent.Util.Tween)
local Sound = require(script.Parent.Parent.Util.Sound)
local Signal = require(script.Parent.Parent.Util.Signal)
local Maid = require(script.Parent.Parent.Util.Maid)
local Component = require(script.Parent.Parent.Util.Component)
local Badge = require(script.Parent.Badge)

local Button = {}
Button.__index = Button

local VARIANTS = {
	primary = { "primary", "onPrimary" },
	secondary = { "secondary", "onSecondary" },
	buy = { "buy", "onBuy" },
	danger = { "danger", "onDanger" },
}

local GREY = Color3.fromRGB(128, 128, 128)

local function touchOnly(): boolean
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

function Button.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, Button)
	self.Variant = p.Variant or "primary"
	self.ButtonSize = p.ButtonSize or "md"
	self.Square = p.Square == true
	self.FullWidth = p.FullWidth == true
	self.Width = p.Width
	self.Color = p.Color
	self.TextColor = p.TextColor
	self.Enabled = p.Enabled ~= false
	self.Activated = Signal.new()
	self._fixedSize = p.Size ~= nil
	self._hovered = false
	self._pressed = false
	self._depth = 0
	self._maid = Maid.new()

	local root = Create("TextButton", {
		Name = "Button",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Selectable = true,
	})
	self.Instance = root
	self._scale = Create("UIScale", { Parent = root })
	self._shadow = Create("Frame", { Name = "Shadow", ZIndex = 1, BorderSizePixel = 0, Parent = root })
	self._face = Create("Frame", { Name = "Face", ZIndex = 2, BorderSizePixel = 0, Parent = root })

	local content = Create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
		Parent = self._face,
	})
	self._layout = Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = content,
	})
	self._content = content
	self._icon = Create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		LayoutOrder = 1,
		Visible = false,
		Parent = content,
	})
	self._label = Create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
		Text = p.Text or "",
		LayoutOrder = 2,
		Parent = content,
	})

	-- Gamepad selection outline, drawn by the engine when this button is selected.
	self._selection = Create("Frame", {
		Name = "Selection",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(-4, -4),
		Size = UDim2.new(1, 8, 1, 8),
	})
	root.SelectionImageObject = self._selection

	if p.Icon then
		self:SetIcon(p.Icon)
	end
	self:_updateLabelVisibility()

	self._maid:Add(root.MouseEnter:Connect(function()
		if not touchOnly() then
			self._hovered = true
			self:_animate()
		end
	end))
	self._maid:Add(root.MouseLeave:Connect(function()
		self._hovered = false
		self._pressed = false
		self:_animate()
	end))
	self._maid:Add(root.SelectionGained:Connect(function()
		self._hovered = true
		self:_animate()
	end))
	self._maid:Add(root.SelectionLost:Connect(function()
		self._hovered = false
		self:_animate()
	end))
	self._maid:Add(root.MouseButton1Down:Connect(function()
		if self.Enabled then
			self._pressed = true
			self:_animate()
		end
	end))
	self._maid:Add(root.MouseButton1Up:Connect(function()
		self._pressed = false
		self:_animate()
	end))
	self._maid:Add(root.Activated:Connect(function()
		if not self.Enabled then
			return
		end
		Sound.play("click")
		self.Activated:Fire(self)
		if p.OnClick then
			task.spawn(p.OnClick, self)
		end
	end))

	Theme.bind(root, function(theme)
		self:_style(theme)
	end)

	Component.finish(self, p)
	return self
end

function Button:_colors(theme: any): (Color3, Color3)
	local colors = theme.colors
	local base, foreground
	if self.Color then
		base = self.Color
		foreground = self.TextColor or Color.readableOn(self.Color, colors.text, colors.textInverse)
	elseif self.Variant == "ghost" then
		base = colors.surface
		foreground = self.TextColor or colors.text
	else
		local pair = VARIANTS[self.Variant] or VARIANTS.primary
		base = colors[pair[1]]
		foreground = self.TextColor or colors[pair[2]]
	end
	if not self.Enabled then
		base = base:Lerp(GREY, 0.55)
	end
	return base, foreground
end

function Button:_style(theme: any)
	local root = self.Instance
	local face = self._face
	local shadow = self._shadow
	local tokens = theme.buttons
	local ghost = self.Variant == "ghost"
	local base, foreground = self:_colors(theme)

	local height = tokens.heights[self.ButtonSize] or tokens.heights.md
	if self.FullWidth then
		root.Size = UDim2.new(1, 0, 0, height)
	elseif not self._fixedSize then
		local width = self.Width or if self.Square then height else (tokens.widths[self.ButtonSize] or tokens.widths.md)
		root.Size = UDim2.fromOffset(width, height)
	end

	local radius = theme.radius.md
	Style.corner(face, radius)

	local skinned = (not ghost) and Style.skin(face, theme.images.button, base)
	face.BackgroundTransparency = if ghost or skinned then 1 else 0
	Style.fill(face, base, if ghost or skinned then "flat" else tokens.fill, tokens.highlight)

	local strokeThickness = if ghost then math.max(theme.stroke.control, 1) else theme.stroke.control
	Style.stroke(face, if skinned then 0 else strokeThickness, theme.colors.stroke)

	if ghost then
		shadow.Visible = false
		self._depth = 0
	else
		self._depth = Style.shadow(shadow, theme, base, radius, strokeThickness)
	end
	face.Size = UDim2.new(1, 0, 1, -self._depth)
	shadow.Size = UDim2.new(1, 0, 1, -self._depth)
	shadow.Position = UDim2.fromOffset(0, self._depth)
	face.Position = UDim2.fromOffset(0, if self._pressed then self._depth else 0)

	local label = self._label
	label.FontFace = theme.fonts[tokens.font] or theme.fonts.heading
	label.TextSize = tokens.textSizes[self.ButtonSize] or tokens.textSizes.md
	label.TextColor3 = foreground
	label.TextTransparency = if self.Enabled then 0 else 0.3
	Style.textOutline(label, theme, theme.typography.label.outline == true and not ghost)

	local iconSize = math.floor(height * 0.55)
	self._icon.Size = UDim2.fromOffset(iconSize, iconSize)
	self._icon.ImageTransparency = if self.Enabled then 0 else 0.4

	local horizontal = if self.Square then 0 else theme.spacing.md
	Style.padding(self._content, { 0, horizontal, 0, horizontal })

	Style.corner(self._selection, UDim.new(radius.Scale, radius.Offset + 4))
	Style.stroke(self._selection, 2, theme.colors.selection)
end

function Button:_animate()
	local motion = Theme.get().motion
	local target = 1
	if self._pressed then
		target = motion.pressScale
	elseif self._hovered and self.Enabled then
		target = motion.hoverScale
	end
	Tween.play(self._scale, { Scale = target }, "fast")
	Tween.play(self._face, { Position = UDim2.fromOffset(0, if self._pressed then self._depth else 0) }, "fast")
end

function Button:_updateLabelVisibility()
	self._label.Visible = self._label.Text ~= ""
end

function Button:SetText(text: string)
	self._label.Text = text
	self:_updateLabelVisibility()
end

function Button:SetIcon(image: string?)
	self._icon.Image = image or ""
	self._icon.Visible = image ~= nil and image ~= ""
end

function Button:SetVariant(variant: string)
	self.Variant = variant
	self:_style(Theme.get())
end

function Button:SetEnabled(enabled: boolean)
	self.Enabled = enabled
	self.Instance.Active = enabled
	if not enabled then
		self._pressed = false
		self._hovered = false
		self:_animate()
	end
	self:_style(Theme.get())
end

-- Count, true for a dot, or 0/false/nil to hide.
function Button:SetBadge(count: number | boolean | nil)
	if not self._badge then
		self._badge = Badge.new({ Parent = self.Instance })
	end
	self._badge:SetCount(count)
end

function Button:Destroy()
	self._maid:Clean()
	self.Activated:Destroy()
	self._selection:Destroy()
	self.Instance:Destroy()
end

return Button
