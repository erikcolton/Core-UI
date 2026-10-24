--[[
	TextInput: a themed text box.

		local input = TextInput.new({ Placeholder = "Enter code", OnSubmit = function(text) end })
		input.Submitted:Connect(function(text) end)
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Signal = require(script.Parent.Parent.Util.Signal)
local Component = require(script.Parent.Parent.Util.Component)

local TextInput = {}
TextInput.__index = TextInput

function TextInput.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, TextInput)
	self.Submitted = Signal.new()
	self._focused = false

	self.Instance = Create("Frame", {
		Name = "TextInput",
		Size = UDim2.fromOffset(240, 46),
		BorderSizePixel = 0,
	})
	self.Box = Create("TextBox", {
		Name = "Box",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = p.Text or "",
		PlaceholderText = p.Placeholder or "",
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = self.Instance,
	})

	local function style(theme: any)
		local frame = self.Instance
		frame.BackgroundColor3 = theme.colors.surfaceAlt
		frame.BackgroundTransparency = theme.transparency.surfaceAlt or 0
		Style.corner(frame, theme.radius.md)
		Style.stroke(
			frame,
			math.max(theme.stroke.control, if self._focused then 2 else 1),
			if self._focused then theme.colors.primary else theme.colors.stroke
		)
		Style.padding(frame, { 0, theme.spacing.md, 0, theme.spacing.md })
		Style.text(self.Box, theme, "body", false)
		self.Box.TextColor3 = theme.colors.text
		self.Box.PlaceholderColor3 = theme.colors.textMuted
	end
	Theme.bind(self.Instance, style)

	self.Box.Focused:Connect(function()
		self._focused = true
		style(Theme.get())
	end)
	self.Box.FocusLost:Connect(function(enterPressed)
		self._focused = false
		style(Theme.get())
		if enterPressed then
			self:Submit()
		end
	end)
	if p.OnSubmit then
		self.Submitted:Connect(p.OnSubmit)
	end

	return Component.finish(self, p)
end

function TextInput:GetText(): string
	return self.Box.Text
end

function TextInput:SetText(text: string)
	self.Box.Text = text
end

function TextInput:Focus()
	self.Box:CaptureFocus()
end

function TextInput:Submit()
	self.Submitted:Fire(self.Box.Text)
end

function TextInput:Destroy()
	self.Submitted:Destroy()
	self.Instance:Destroy()
end

return TextInput
