--[[
	ShopCard: one product in a shop grid.

		ShopCard.new({
			Item = {
				Id = "vip",
				Name = "VIP",
				Description = "2x coins forever",
				Price = 299,
				Currency = "Robux",  -- or the name of an in-game currency, e.g. "Coins"
				Image = "rbxassetid://...",
				Tag = "Best value",  -- optional ribbon
			},
			OnBuy = function(item) end,
		})
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Format = require(script.Parent.Parent.Util.Format)
local Component = require(script.Parent.Parent.Util.Component)
local Panel = require(script.Parent.Panel)
local Text = require(script.Parent.Text)
local Button = require(script.Parent.Button)

local ShopCard = {}
ShopCard.__index = ShopCard

function ShopCard.priceText(item: { [string]: any }): string
	if item.PriceText then
		return item.PriceText
	end
	local price = item.Price or 0
	if price <= 0 then
		return "Free"
	end
	local currency = item.Currency or "Robux"
	if currency == "Robux" then
		return "R$ " .. Format.commas(price)
	end
	return Format.abbreviate(price) .. " " .. currency
end

function ShopCard.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, ShopCard)
	local item = p.Item or {}
	self.Item = item
	self.Owned = false

	self.Panel = Panel.new({
		Name = "ShopCard_" .. tostring(item.Id or ""),
		Size = UDim2.fromOffset(196, 252),
		Padding = "md",
	})
	self.Instance = self.Panel.Instance
	local content = self.Panel.Content

	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = content,
	})
	Create("ImageLabel", {
		Name = "Image",
		BackgroundTransparency = 1,
		Image = item.Image or "",
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(84, 84),
		LayoutOrder = 1,
		Parent = content,
	})
	Text.new({
		Name = "Name",
		Text = item.Name or "",
		Role = "heading",
		AlignX = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 28),
		Truncate = true,
		LayoutOrder = 2,
		Parent = content,
	})
	Text.new({
		Name = "Description",
		Text = item.Description or "",
		Role = "caption",
		Color = "textMuted",
		AlignX = Enum.TextXAlignment.Center,
		AlignY = Enum.TextYAlignment.Top,
		Wrap = true,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 3,
		Parent = content,
	})
	self.BuyButton = Button.new({
		Name = "Buy",
		Text = ShopCard.priceText(item),
		Variant = "buy",
		ButtonSize = "md",
		FullWidth = true,
		LayoutOrder = 4,
		Parent = content,
		OnClick = function()
			if not self.Owned and p.OnBuy then
				p.OnBuy(item, self)
			end
		end,
	})

	if item.Tag then
		self._tag = Create("TextLabel", {
			Name = "Tag",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0, 4),
			AutomaticSize = Enum.AutomaticSize.XY,
			Text = string.upper(item.Tag),
			ZIndex = 10,
			Parent = self.Instance,
		})
		Theme.bind(self._tag, function(theme)
			local tag = self._tag
			tag.BackgroundColor3 = theme.colors.warning
			tag.TextColor3 = theme.colors.textInverse
			tag.FontFace = theme.fonts.heading
			tag.TextSize = 13
			Style.corner(tag, theme.radius.pill)
			Style.stroke(tag, math.min(theme.stroke.control, 2), theme.colors.stroke)
			Style.padding(tag, { 3, 8, 3, 8 })
			Style.textOutline(tag, theme, true)
		end)
	end

	return Component.finish(self, p)
end

function ShopCard:SetOwned(owned: boolean)
	self.Owned = owned
	if owned then
		self.BuyButton:SetText("Owned")
		self.BuyButton:SetVariant("secondary")
		self.BuyButton:SetEnabled(false)
	else
		self.BuyButton:SetText(ShopCard.priceText(self.Item))
		self.BuyButton:SetVariant("buy")
		self.BuyButton:SetEnabled(true)
	end
end

function ShopCard:Destroy()
	self.BuyButton:Destroy()
	self.Instance:Destroy()
end

return ShopCard
