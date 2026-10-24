--[[
	HUD: the always-on layer.

		local hud = HUD.new({
			Currencies = {
				{ Id = "coins", Icon = "rbxassetid://...", Amount = 0, Screen = "Shop" },
				{ Id = "gems", Color = Color3.fromRGB(80, 200, 255) },
			},
			Buttons = {
				{ Id = "shop", Text = "Shop", Icon = "rbxassetid://...", Screen = "Shop" },
				{ Id = "settings", Text = "Settings", Screen = "Settings" },
			},
		})
		hud:SetCurrency("coins", 1500)
		hud:SetBadge("shop", 2)
		hud:SetObjective("Find the key")

	Placement follows mobile conventions: currencies top right, menu buttons left middle
	(above the thumbstick), objective top center, and an empty BottomBar frame at bottom
	center for hotbars, between the thumbstick and jump button.
	A button or currency with Screen opens that registered screen through the Manager;
	use OnClick instead for custom behavior.
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Layers = require(script.Parent.Parent.Util.Layers)
local Manager = require(script.Parent.Parent.Manager)
local Text = require(script.Parent.Parent.Components.Text)
local Button = require(script.Parent.Parent.Components.Button)
local CurrencyCounter = require(script.Parent.Parent.Components.CurrencyCounter)

local HUD = {}
HUD.__index = HUD

local EDGE = 12

local function clickHandler(spec: { [string]: any }): (() -> ())?
	if spec.OnClick then
		return spec.OnClick
	elseif spec.Screen then
		return function()
			Manager.toggle(spec.Screen)
		end
	end
	return nil
end

function HUD.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, HUD)
	self.Currencies = {}
	self.Buttons = {}

	self.Instance = Create("Frame", {
		Name = "HUD",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = p.Parent or Layers.get("HUD"),
	})

	self.CurrencyStack = Create("Frame", {
		Name = "Currencies",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -EDGE, 0, EDGE),
		AutomaticSize = Enum.AutomaticSize.XY,
		Parent = self.Instance,
	})
	self._currencyLayout = Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.CurrencyStack,
	})

	self.SideButtons = Create("Frame", {
		Name = "SideButtons",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, EDGE, 0.5, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Parent = self.Instance,
	})
	self._buttonLayout = Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.SideButtons,
	})

	self.Objective = Text.new({
		Name = "Objective",
		Role = "label",
		Outline = true,
		AlignX = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, EDGE),
		Visible = false,
		Parent = self.Instance,
	})

	self.BottomBar = Create("Frame", {
		Name = "BottomBar",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -EDGE),
		AutomaticSize = Enum.AutomaticSize.XY,
		Parent = self.Instance,
	})
	self._bottomLayout = Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = self.BottomBar,
	})

	Theme.bind(self.Instance, function(theme)
		local gap = UDim.new(0, theme.spacing.sm)
		self._currencyLayout.Padding = gap
		self._buttonLayout.Padding = gap
		self._bottomLayout.Padding = gap
	end)

	for index, spec in p.Currencies or {} do
		self:AddCurrency(spec, index)
	end
	for index, spec in p.Buttons or {} do
		self:AddButton(spec, index)
	end
	if p.Objective then
		self:SetObjective(p.Objective)
	end
	return self
end

function HUD:AddCurrency(spec: { [string]: any }, order: number?): any
	local counter = CurrencyCounter.new({
		Name = "Currency_" .. spec.Id,
		Icon = spec.Icon,
		Color = spec.Color,
		Amount = spec.Amount or 0,
		Abbreviate = spec.Abbreviate,
		OnAdd = clickHandler(spec),
		LayoutOrder = order or 0,
		Parent = self.CurrencyStack,
	})
	self.Currencies[spec.Id] = counter
	return counter
end

function HUD:AddButton(spec: { [string]: any }, order: number?): any
	local button = Button.new({
		Name = "Button_" .. spec.Id,
		Text = spec.Text or "",
		Icon = spec.Icon,
		Variant = spec.Variant or "secondary",
		ButtonSize = spec.ButtonSize or "md",
		Width = spec.Width,
		Square = spec.Text == nil,
		LayoutOrder = order or 0,
		Parent = self.SideButtons,
		OnClick = clickHandler(spec),
	})
	self.Buttons[spec.Id] = button
	return button
end

function HUD:SetCurrency(id: string, amount: number, animate: boolean?)
	local counter = self.Currencies[id]
	if counter then
		counter:SetAmount(amount, animate)
	end
end

function HUD:GetCurrency(id: string): any
	return self.Currencies[id]
end

function HUD:GetButton(id: string): any
	return self.Buttons[id]
end

function HUD:SetBadge(id: string, count: number | boolean | nil)
	local button = self.Buttons[id]
	if button then
		button:SetBadge(count)
	end
end

function HUD:SetObjective(text: string?)
	self.Objective.Instance.Visible = text ~= nil and text ~= ""
	self.Objective:SetText(text or "")
end

function HUD:SetVisible(visible: boolean)
	self.Instance.Visible = visible
end

function HUD:Destroy()
	for _, button in self.Buttons do
		button:Destroy()
	end
	for _, counter in self.Currencies do
		counter:Destroy()
	end
	self.Instance:Destroy()
end

return HUD
