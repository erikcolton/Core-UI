--[[
	ProgressBar: track and fill with an optional centered label.

		local bar = ProgressBar.new({ Value = 30, Max = 100, Color = "success", Size = UDim2.fromOffset(240, 22) })
		bar:SetValue(75)

	Label: true shows "value / max"; a function(value, max) returns custom text; false hides.
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Format = require(script.Parent.Parent.Util.Format)
local Tween = require(script.Parent.Parent.Util.Tween)
local Component = require(script.Parent.Parent.Util.Component)

local ProgressBar = {}
ProgressBar.__index = ProgressBar

function ProgressBar.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, ProgressBar)
	self.Value = p.Value or 0
	self.Max = p.Max or 1
	self.Color = p.Color or "primary"
	self.Label = if p.Label == nil then false else p.Label

	self.Instance = Create("Frame", {
		Name = "ProgressBar",
		Size = UDim2.fromOffset(240, 22),
		BorderSizePixel = 0,
	})
	self._fill = Create("Frame", {
		Name = "Fill",
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		ZIndex = 2,
		Parent = self.Instance,
	})
	self._label = Create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 3,
		Parent = self.Instance,
	})

	Theme.bind(self.Instance, function(theme)
		local track = self.Instance
		track.BackgroundColor3 = theme.colors.track
		Style.corner(track, theme.radius.pill)
		Style.stroke(track, theme.stroke.control, theme.colors.stroke)
		Style.corner(self._fill, theme.radius.pill)
		Style.fill(
			self._fill,
			Style.color(theme, self.Color, "primary"),
			theme.buttons.gradient,
			theme.buttons.highlight
		)
		Style.text(self._label, theme, "caption", true)
		-- Outlined themes read best with light text; without an outline, use body text color.
		self._label.TextColor3 = if theme.stroke.text > 0 then theme.colors.textInverse else theme.colors.text
	end)

	Component.finish(self, p)
	self:SetValue(self.Value, self.Max, false)
	return self
end

function ProgressBar:_labelText(): string
	if self.Label == true then
		return Format.abbreviate(self.Value) .. " / " .. Format.abbreviate(self.Max)
	elseif type(self.Label) == "function" then
		return self.Label(self.Value, self.Max)
	elseif type(self.Label) == "string" then
		return self.Label
	end
	return ""
end

function ProgressBar:SetValue(value: number, max: number?, animate: boolean?)
	self.Value = value
	if max then
		self.Max = max
	end
	local ratio = if self.Max > 0 then math.clamp(self.Value / self.Max, 0, 1) else 0
	local goal = UDim2.fromScale(ratio, 1)
	self._fill.Visible = ratio > 0
	if animate == false then
		self._fill.Size = goal
	else
		Tween.play(self._fill, { Size = goal }, "normal")
	end
	self._label.Text = self:_labelText()
end

function ProgressBar:SetColor(color: string | Color3)
	self.Color = color
	local theme = Theme.get()
	Style.fill(self._fill, Style.color(theme, color, "primary"), theme.buttons.gradient, theme.buttons.highlight)
end

function ProgressBar:Destroy()
	self.Instance:Destroy()
end

return ProgressBar
