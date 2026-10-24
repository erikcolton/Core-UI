--[[
	CurrencyCounter: icon plus amount, with a count-up animation and a pulse on change.

		local coins = CurrencyCounter.new({
			Icon = "rbxassetid://...",           -- or Color = Color3 for a plain coin dot
			Amount = 0,
			OnAdd = function() Manager.open("Shop") end, -- shows a "+" button
		})
		coins:SetAmount(1500)
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Format = require(script.Parent.Parent.Util.Format)
local Tween = require(script.Parent.Parent.Util.Tween)
local Component = require(script.Parent.Parent.Util.Component)
local Button = require(script.Parent.Button)

local CurrencyCounter = {}
CurrencyCounter.__index = CurrencyCounter

local HEIGHT = 40

function CurrencyCounter.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, CurrencyCounter)
	self.Amount = p.Amount or 0
	self.Abbreviate = p.Abbreviate ~= false
	self.Color = p.Color or "warning"

	self.Instance = Create("Frame", {
		Name = p.Name or "CurrencyCounter",
		Size = UDim2.fromOffset(0, HEIGHT),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
	})
	self._scale = Create("UIScale", { Parent = self.Instance })
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = self.Instance,
	})

	if p.Icon then
		self._icon = Create("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Image = p.Icon,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(HEIGHT - 8, HEIGHT - 8),
			LayoutOrder = 1,
			Parent = self.Instance,
		})
	else
		self._icon = Create("Frame", {
			Name = "Icon",
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(HEIGHT - 12, HEIGHT - 12),
			LayoutOrder = 1,
			Parent = self.Instance,
		})
	end

	self._value = Instance.new("NumberValue")
	self._value.Value = self.Amount
	self._label = Create("TextLabel", {
		Name = "Amount",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, HEIGHT),
		LayoutOrder = 2,
		Parent = self.Instance,
	})
	self._value.Changed:Connect(function(value)
		self._label.Text = self:_format(value)
	end)
	self._label.Text = self:_format(self.Amount)

	if p.OnAdd then
		self.AddButton = Button.new({
			Name = "Add",
			Text = "+",
			Variant = "buy",
			ButtonSize = "sm",
			Square = true,
			Size = UDim2.fromOffset(HEIGHT - 10, HEIGHT - 10),
			LayoutOrder = 3,
			Parent = self.Instance,
			OnClick = p.OnAdd,
		})
	end

	Theme.bind(self.Instance, function(theme)
		local frame = self.Instance
		frame.BackgroundColor3 = theme.colors.surface
		frame.BackgroundTransparency = theme.transparency.surface or 0
		Style.corner(frame, theme.radius.pill)
		Style.stroke(frame, math.max(theme.stroke.control, 1), theme.colors.stroke)
		Style.padding(frame, { 0, if p.OnAdd then 5 else 14, 0, 5 })
		Style.text(self._label, theme, "label", true)
		self._label.TextColor3 = if theme.stroke.text > 0 then theme.colors.textInverse else theme.colors.text
		if self._icon:IsA("Frame") then
			self._icon.BackgroundColor3 = Style.color(theme, self.Color, "warning")
			Style.corner(self._icon, theme.radius.pill)
			Style.stroke(self._icon, math.min(theme.stroke.control, 2), theme.colors.stroke)
		end
	end)

	return Component.finish(self, p)
end

function CurrencyCounter:_format(value: number): string
	if self.Abbreviate then
		return Format.abbreviate(value)
	end
	return Format.commas(value)
end

function CurrencyCounter:SetAmount(amount: number, animate: boolean?)
	local previous = self.Amount
	self.Amount = amount
	if animate == false or amount == previous then
		self._value.Value = amount
		return
	end
	Tween.play(self._value, { Value = amount }, "slow")
	self._scale.Scale = if amount > previous then 1.15 else 0.9
	Tween.pop(self._scale, { Scale = 1 }, "normal")
end

function CurrencyCounter:Destroy()
	self._value:Destroy()
	if self.AddButton then
		self.AddButton:Destroy()
	end
	self.Instance:Destroy()
end

return CurrencyCounter
