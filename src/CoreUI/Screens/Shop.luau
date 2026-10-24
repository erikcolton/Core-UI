--[[
	Shop: a window with one tab per category and a grid of product cards.

		local shop = Shop.new({
			Categories = {
				{ Id = "passes", Text = "Passes", Items = {
					{ Id = "vip", Name = "VIP", Description = "2x coins", Price = 299, GamePassId = 123456 },
				} },
				{ Id = "coins", Text = "Coins", Items = {
					{ Id = "coins_1k", Name = "1,000 Coins", Price = 49, ProductId = 987654, Tag = "Popular" },
				} },
			},
		})
		shop:SetOwned("vip", true)

	Buying: items with GamePassId or ProductId prompt the Roblox purchase dialog.
	Pass OnPurchase(item, card) to handle buying yourself (for in-game currency items).
	Grant purchases on the server with MarketplaceService.ProcessReceipt; this UI only prompts.

	Registers itself with the Manager as props.Id (default "Shop").
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Manager = require(script.Parent.Parent.Manager)
local Window = require(script.Parent.Parent.Components.Window)
local Tabs = require(script.Parent.Parent.Components.Tabs)
local ScrollList = require(script.Parent.Parent.Components.ScrollList)
local ShopCard = require(script.Parent.Parent.Components.ShopCard)

local Shop = {}
Shop.__index = Shop

function Shop.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, Shop)
	self.Id = p.Id or "Shop"
	self.Cards = {}
	self._onPurchase = p.OnPurchase

	self.Window = Window.new({
		Name = self.Id,
		Title = p.Title or "Shop",
		Size = p.Size or UDim2.fromOffset(720, 450),
	})
	self.Instance = self.Window.Instance

	local tabSpecs = {}
	for _, category in p.Categories or {} do
		table.insert(tabSpecs, { Id = category.Id, Text = category.Text, Icon = category.Icon, Width = category.Width })
	end
	self.Tabs = Tabs.new({ Tabs = tabSpecs, Size = UDim2.fromScale(1, 1), Parent = self.Window })

	for _, category in p.Categories or {} do
		local grid = ScrollList.new({
			Layout = "grid",
			CellSize = p.CardSize or UDim2.fromOffset(196, 252),
			Size = UDim2.fromScale(1, 1),
			Parent = self.Tabs:GetPage(category.Id),
		})
		for index, item in category.Items or {} do
			local card = ShopCard.new({
				Item = item,
				LayoutOrder = index,
				Parent = grid,
				OnBuy = function(boughtItem, boughtCard)
					self:_buy(boughtItem, boughtCard)
				end,
			})
			self.Cards[item.Id] = card
		end
	end

	Manager.register(self.Id, self)
	return self
end

function Shop:_buy(item: { [string]: any }, card: any)
	if self._onPurchase then
		self._onPurchase(item, card)
		return
	end
	local player = Players.LocalPlayer
	if item.GamePassId then
		MarketplaceService:PromptGamePassPurchase(player, item.GamePassId)
	elseif item.ProductId then
		MarketplaceService:PromptProductPurchase(player, item.ProductId)
	else
		warn("CoreUI Shop: item " .. tostring(item.Id) .. " has no GamePassId, ProductId or OnPurchase handler")
	end
end

function Shop:SetOwned(itemId: string, owned: boolean)
	local card = self.Cards[itemId]
	if card then
		card:SetOwned(owned)
	end
end

function Shop:Open()
	Manager.open(self.Id)
end

function Shop:Close()
	Manager.close(self.Id)
end

function Shop:Destroy()
	Manager.unregister(self.Id)
	self.Tabs:Destroy()
	self.Window:Destroy()
end

return Shop
