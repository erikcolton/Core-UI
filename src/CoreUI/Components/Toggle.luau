--[[
	Toggle: an on/off switch.

		local toggle = Toggle.new({ Value = true, OnChanged = function(on) end })
		toggle.Changed:Connect(function(on) end)
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Tween = require(script.Parent.Parent.Util.Tween)
local Sound = require(script.Parent.Parent.Util.Sound)
local Signal = require(script.Parent.Parent.Util.Signal)
local Component = require(script.Parent.Parent.Util.Component)

local Toggle = {}
Toggle.__index = Toggle

local KNOB_GAP = 3

function Toggle.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, Toggle)
	self.Value = p.Value == true
	self.Changed = Signal.new()
	self._onChanged = p.OnChanged

	self.Instance = Create("TextButton", {
		Name = "Toggle",
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(56, 30),
	})
	self._knob = Create("Frame", {
		Name = "Knob",
		BorderSizePixel = 0,
		Size = UDim2.new(1, -KNOB_GAP * 2, 1, -KNOB_GAP * 2),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Parent = self.Instance,
	})

	Theme.bind(self.Instance, function(theme)
		self:_style(theme, false)
	end)

	self.Instance.Activated:Connect(function()
		Sound.play("click")
		self:SetValue(not self.Value)
	end)

	return Component.finish(self, p)
end

function Toggle:_style(theme: any, animate: boolean)
	local track = self.Instance
	local knob = self._knob
	Style.corner(track, theme.radius.pill)
	Style.stroke(track, theme.stroke.control, theme.colors.stroke)
	Style.corner(knob, theme.radius.pill)
	Style.stroke(knob, math.min(theme.stroke.control, 2), theme.colors.stroke)
	knob.BackgroundColor3 = theme.colors.surface

	local goals = {
		AnchorPoint = if self.Value then Vector2.new(1, 0.5) else Vector2.new(0, 0.5),
		Position = if self.Value then UDim2.new(1, -KNOB_GAP, 0.5, 0) else UDim2.new(0, KNOB_GAP, 0.5, 0),
	}
	local trackColor = if self.Value then theme.colors.success else theme.colors.track
	if animate then
		Tween.play(knob, goals, "fast")
		Tween.play(track, { BackgroundColor3 = trackColor }, "fast")
	else
		knob.AnchorPoint = goals.AnchorPoint
		knob.Position = goals.Position
		track.BackgroundColor3 = trackColor
	end
end

function Toggle:SetValue(value: boolean, silent: boolean?)
	if value == self.Value then
		return
	end
	self.Value = value
	self:_style(Theme.get(), true)
	if not silent then
		self.Changed:Fire(value)
		if self._onChanged then
			task.spawn(self._onChanged, value)
		end
	end
end

function Toggle:Destroy()
	self.Changed:Destroy()
	self.Instance:Destroy()
end

return Toggle
