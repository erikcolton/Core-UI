--[[
	Window: a panel with a header (title and close button) and a body.
	Starts hidden. Open and Close animate it; the Manager calls these for you when
	the window is registered as a screen.

		local window = Window.new({ Title = "Shop", Size = UDim2.fromOffset(720, 440) })
		Text.new({ Text = "Hello", Parent = window }) -- goes into window.Body
		window:Open()

	With no Parent, the window goes into the Windows layer, centered.
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Tween = require(script.Parent.Parent.Util.Tween)
local Sound = require(script.Parent.Parent.Util.Sound)
local Signal = require(script.Parent.Parent.Util.Signal)
local Layers = require(script.Parent.Parent.Util.Layers)
local Component = require(script.Parent.Parent.Util.Component)
local Panel = require(script.Parent.Panel)
local Text = require(script.Parent.Text)
local Button = require(script.Parent.Button)

local Window = {}
Window.__index = Window

local HEADER_HEIGHT = 52

function Window.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, Window)
	self.IsOpen = false
	self.Opened = Signal.new()
	self.Closed = Signal.new()
	self.OnCloseRequest = nil -- set by the Manager
	self._closeToken = 0

	self.Panel = Panel.new({
		Name = p.Name or "Window",
		Size = p.Size or UDim2.fromOffset(560, 380),
		AnchorPoint = p.AnchorPoint or Vector2.new(0.5, 0.5),
		Position = p.Position or UDim2.fromScale(0.5, 0.5),
		Padding = false,
	})
	self.Instance = self.Panel.Instance
	self.Instance.Visible = false
	self._popScale = Create("UIScale", { Name = "PopScale", Parent = self.Instance })

	local surface = self.Panel.Surface
	self.Header = Create("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		Parent = surface,
	})
	self.Title = Text.new({
		Text = p.Title or "",
		Role = "heading",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Parent = self.Header,
	})
	if p.Closable ~= false then
		self.CloseButton = Button.new({
			Name = "Close",
			Text = "X",
			Variant = "danger",
			ButtonSize = "sm",
			Square = true,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Parent = self.Header,
			OnClick = function()
				self:RequestClose()
			end,
		})
	end

	self.Body = Create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, HEADER_HEIGHT),
		Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT),
		Parent = surface,
	})
	self.Content = self.Body

	Theme.bind(self.Header, function(theme)
		Style.padding(self.Header, { 0, theme.spacing.md, 0, theme.spacing.lg })
		Style.padding(self.Body, { 0, theme.spacing.lg, theme.spacing.lg, theme.spacing.lg })
	end)

	-- Layout props were consumed by the panel above; only parent here.
	local parent = Component.container(p.Parent) or Layers.get("Windows")
	self.Instance.Parent = parent
	return self
end

function Window:SetTitle(title: string)
	self.Title:SetText(title)
end

function Window:RequestClose()
	if self.OnCloseRequest then
		self.OnCloseRequest()
	else
		self:Close()
	end
end

function Window:Open()
	if self.IsOpen then
		return
	end
	self.IsOpen = true
	self._closeToken += 1
	local motion = Theme.get().motion
	self.Instance.Visible = true
	self._popScale.Scale = motion.openFrom
	Tween.pop(self._popScale, { Scale = 1 })
	Sound.play("open")
	self.Opened:Fire()
end

function Window:Close()
	if not self.IsOpen then
		return
	end
	self.IsOpen = false
	self._closeToken += 1
	local token = self._closeToken
	local motion = Theme.get().motion
	local tween = Tween.play(self._popScale, { Scale = motion.openFrom }, "fast", nil, Enum.EasingDirection.In)
	tween.Completed:Once(function()
		if self._closeToken == token then
			self.Instance.Visible = false
		end
	end)
	Sound.play("close")
	self.Closed:Fire()
end

function Window:Toggle()
	if self.IsOpen then
		self:RequestClose()
	else
		self:Open()
	end
end

function Window:Destroy()
	self.Opened:Destroy()
	self.Closed:Destroy()
	self.Instance:Destroy()
end

return Window
