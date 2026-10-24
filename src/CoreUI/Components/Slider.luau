--[[
	Slider: drag to pick a value between Min and Max. Works with mouse, touch,
	and gamepad (left/right on the D-pad while the knob is selected).

		Slider.new({ Min = 0, Max = 100, Step = 5, Value = 50, OnChanged = function(value) end })
]]

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Signal = require(script.Parent.Parent.Util.Signal)
local Maid = require(script.Parent.Parent.Util.Maid)
local Component = require(script.Parent.Parent.Util.Component)

local Slider = {}
Slider.__index = Slider

local TRACK_HEIGHT = 8
local KNOB_SIZE = 24

local function isPointer(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

function Slider.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, Slider)
	self.Min = p.Min or 0
	self.Max = p.Max or 1
	self.Step = p.Step
	self.Value = math.clamp(p.Value or self.Min, self.Min, self.Max)
	self.Changed = Signal.new()
	self._onChanged = p.OnChanged
	self._maid = Maid.new()
	self._dragging = false

	self.Instance = Create("Frame", {
		Name = "Slider",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(220, 28),
	})
	self._track = Create("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, TRACK_HEIGHT),
		BorderSizePixel = 0,
		Parent = self.Instance,
	})
	self._fill = Create("Frame", {
		Name = "Fill",
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		Parent = self._track,
	})
	self._knob = Create("TextButton", {
		Name = "Knob",
		Text = "",
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(KNOB_SIZE, KNOB_SIZE),
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = self.Instance,
	})
	-- Keep D-pad left/right on the knob so they adjust the value instead of moving selection.
	self._knob.NextSelectionLeft = self._knob
	self._knob.NextSelectionRight = self._knob

	Theme.bind(self.Instance, function(theme)
		Style.corner(self._track, theme.radius.pill)
		self._track.BackgroundColor3 = theme.colors.track
		Style.stroke(self._track, math.min(theme.stroke.control, 2), theme.colors.stroke)
		Style.corner(self._fill, theme.radius.pill)
		self._fill.BackgroundColor3 = theme.colors.primary
		Style.corner(self._knob, theme.radius.pill)
		self._knob.BackgroundColor3 = theme.colors.surface
		Style.stroke(self._knob, math.max(theme.stroke.control, 1), theme.colors.stroke)
	end)

	local function beginDrag(input: InputObject)
		if isPointer(input) then
			self._dragging = true
			self:_setFromX(input.Position.X)
		end
	end
	self._maid:Add(self.Instance.InputBegan:Connect(beginDrag))
	self._maid:Add(self._knob.InputBegan:Connect(beginDrag))
	self._maid:Add(UserInputService.InputChanged:Connect(function(input)
		if
			self._dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			self:_setFromX(input.Position.X)
		end
	end))
	self._maid:Add(UserInputService.InputEnded:Connect(function(input)
		if isPointer(input) then
			self._dragging = false
		end
	end))
	self._maid:Add(UserInputService.InputBegan:Connect(function(input)
		if GuiService.SelectedObject ~= self._knob then
			return
		end
		local step = self.Step or (self.Max - self.Min) / 20
		if input.KeyCode == Enum.KeyCode.DPadRight then
			self:SetValue(self.Value + step)
		elseif input.KeyCode == Enum.KeyCode.DPadLeft then
			self:SetValue(self.Value - step)
		end
	end))

	Component.finish(self, p)
	self:_render()
	return self
end

function Slider:_setFromX(x: number)
	local track = self._track
	local width = track.AbsoluteSize.X
	if width <= 0 then
		return
	end
	local ratio = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
	self:SetValue(self.Min + ratio * (self.Max - self.Min))
end

function Slider:_render()
	local range = self.Max - self.Min
	local ratio = if range > 0 then (self.Value - self.Min) / range else 0
	self._fill.Size = UDim2.fromScale(ratio, 1)
	self._knob.Position = UDim2.fromScale(ratio, 0.5)
end

function Slider:SetValue(value: number, silent: boolean?)
	local v = math.clamp(value, self.Min, self.Max)
	if self.Step then
		v = self.Min + math.floor((v - self.Min) / self.Step + 0.5) * self.Step
		v = math.clamp(v, self.Min, self.Max)
	end
	if v == self.Value then
		return
	end
	self.Value = v
	self:_render()
	if not silent then
		self.Changed:Fire(v)
		if self._onChanged then
			task.spawn(self._onChanged, v)
		end
	end
end

function Slider:Destroy()
	self._maid:Clean()
	self.Changed:Destroy()
	self.Instance:Destroy()
end

return Slider
