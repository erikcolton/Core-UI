--[[
	Text: a label with a typography role.

		Text.new({ Text = "Daily Rewards", Role = "title", Color = "text", Parent = frame })

	Role: display | title | heading | label | body | caption (default body)
	Color: a theme color name or a Color3 (default "text")
	Outline: true/false to override the role's default outline
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Component = require(script.Parent.Parent.Util.Component)

local Text = {}
Text.__index = Text

function Text.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, Text)
	self.Role = p.Role or "body"
	self.Color = p.Color or "text"
	self.Outline = p.Outline

	self.Instance = Create("TextLabel", {
		Name = "Text",
		BackgroundTransparency = 1,
		Text = p.Text or "",
		RichText = p.RichText ~= false,
		TextWrapped = p.Wrap == true,
		TextTruncate = if p.Truncate then Enum.TextTruncate.AtEnd else Enum.TextTruncate.None,
		TextXAlignment = p.AlignX or Enum.TextXAlignment.Left,
		TextYAlignment = p.AlignY or Enum.TextYAlignment.Center,
		Size = p.Size or UDim2.new(),
		AutomaticSize = if p.Size then Enum.AutomaticSize.None else Enum.AutomaticSize.XY,
	})

	Theme.bind(self.Instance, function(theme)
		self:_style(theme)
	end)
	return Component.finish(self, p)
end

function Text:_style(theme: any)
	local label = self.Instance
	Style.text(label, theme, self.Role, self.Outline)
	label.TextColor3 = Style.color(theme, self.Color, "text")
end

function Text:SetText(text: string)
	self.Instance.Text = text
end

function Text:SetColor(color: string | Color3)
	self.Color = color
	self:_style(Theme.get())
end

function Text:SetRole(role: string)
	self.Role = role
	self:_style(Theme.get())
end

function Text:Destroy()
	self.Instance:Destroy()
end

return Text
