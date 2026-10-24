--[[
	Badge: a notification dot or count pinned to the top-right corner of its parent.

		local badge = Badge.new({ Parent = button.Instance })
		badge:SetCount(3)    -- shows "3"
		badge:SetCount(true) -- shows a dot
		badge:SetCount(0)    -- hides
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Tween = require(script.Parent.Parent.Util.Tween)
local Component = require(script.Parent.Parent.Util.Component)

local Badge = {}
Badge.__index = Badge

function Badge.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, Badge)
	self._count = 0

	self.Instance = Create("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(22, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		ZIndex = 20,
		Visible = false,
	})
	self._scale = Create("UIScale", { Parent = self.Instance })
	self._label = Create("TextLabel", {
		Name = "Count",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "",
		ZIndex = 21,
		Parent = self.Instance,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = self.Instance,
	})

	Theme.bind(self.Instance, function(theme)
		local frame = self.Instance
		frame.BackgroundColor3 = theme.colors.badge
		Style.corner(frame, theme.radius.pill)
		Style.stroke(frame, math.min(theme.stroke.control, 2), theme.colors.stroke)
		Style.padding(frame, { 0, 6, 0, 6 })
		self._label.FontFace = theme.fonts.heading
		self._label.TextSize = 13
		self._label.TextColor3 = theme.colors.onBadge
	end)

	Component.finish(self, p)
	if p.Count ~= nil then
		self:SetCount(p.Count)
	end
	return self
end

function Badge:SetCount(count: number | boolean | nil)
	local frame = self.Instance
	local previous = self._count
	self._count = count
	if count == nil or count == false or count == 0 then
		frame.Visible = false
		return
	end
	frame.Visible = true
	if count == true then
		self._label.Text = ""
		frame.AutomaticSize = Enum.AutomaticSize.None
		frame.Size = UDim2.fromOffset(14, 14)
	else
		self._label.Text = if (count :: number) > 99 then "99+" else tostring(count)
		frame.AutomaticSize = Enum.AutomaticSize.X
		frame.Size = UDim2.fromOffset(22, 22)
	end
	if count ~= previous then
		self._scale.Scale = 1.4
		Tween.pop(self._scale, { Scale = 1 })
	end
end

function Badge:Destroy()
	self.Instance:Destroy()
end

return Badge
