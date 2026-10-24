--[[
	Inventory: a grid of item slots with a detail pane for the selected item.

		local inventory = Inventory.new({
			Capacity = 50,
			Items = {
				{ Id = "dog1", Name = "Dog", Rarity = "rare", Image = "rbxassetid://...", Description = "A good boy" },
			},
			OnEquip = function(item, equip) end,  -- equip is true to equip, false to unequip
			OnDelete = function(item) end,        -- asked to confirm first
		})
		inventory:SetItems(newItems)

	Items keep the order you pass unless SortByRarity = true.
	Registers itself with the Manager as props.Id (default "Inventory").
]]

local Manager = require(script.Parent.Parent.Manager)
local Create = require(script.Parent.Parent.Util.Create)
local Window = require(script.Parent.Parent.Components.Window)
local Panel = require(script.Parent.Parent.Components.Panel)
local ScrollList = require(script.Parent.Parent.Components.ScrollList)
local ItemSlot = require(script.Parent.Parent.Components.ItemSlot)
local Text = require(script.Parent.Parent.Components.Text)
local Button = require(script.Parent.Parent.Components.Button)
local Dialog = require(script.Parent.Dialog)

local Inventory = {}
Inventory.__index = Inventory

local DETAIL_WIDTH = 224

Inventory.RarityOrder = { "mythic", "legendary", "epic", "rare", "uncommon", "common" }

local function rarityRank(item: { [string]: any }): number
	return table.find(Inventory.RarityOrder, string.lower(item.Rarity or "common")) or #Inventory.RarityOrder + 1
end

local function titleCase(text: string): string
	return (string.gsub(text, "^%l", string.upper))
end

function Inventory.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, Inventory)
	self.Id = p.Id or "Inventory"
	self.Title = p.Title or "Inventory"
	self.Capacity = p.Capacity
	self.SortByRarity = p.SortByRarity == true
	self.Items = {}
	self.Selected = nil
	self._slots = {}
	self._onEquip = p.OnEquip
	self._onDelete = p.OnDelete

	self.Window = Window.new({
		Name = self.Id,
		Title = self.Title,
		Size = p.Size or UDim2.fromOffset(720, 450),
	})
	self.Instance = self.Window.Instance

	self.Grid = ScrollList.new({
		Layout = "grid",
		CellSize = UDim2.fromOffset(84, 84),
		Size = UDim2.new(1, -(DETAIL_WIDTH + 12), 1, 0),
		Parent = self.Window,
	})

	self.Details = Panel.new({
		Name = "Details",
		Variant = "inset",
		Padding = "md",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, DETAIL_WIDTH, 1, 0),
		Parent = self.Window,
	})
	local details = self.Details.Content
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = details,
	})
	self._preview = ItemSlot.new({ Size = UDim2.fromOffset(96, 96), LayoutOrder = 1, Parent = details })
	self._preview.Instance.Active = false
	self._preview.Instance.Selectable = false
	self._name = Text.new({
		Role = "heading",
		AlignX = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 28),
		Truncate = true,
		LayoutOrder = 2,
		Parent = details,
	})
	self._rarity = Text.new({
		Role = "caption",
		AlignX = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 3,
		Parent = details,
	})
	self._description = Text.new({
		Role = "caption",
		Color = "textMuted",
		Wrap = true,
		AlignX = Enum.TextXAlignment.Center,
		AlignY = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, 0, 0, 54),
		LayoutOrder = 4,
		Parent = details,
	})
	self._equipButton = Button.new({
		Text = "Equip",
		Variant = "primary",
		FullWidth = true,
		LayoutOrder = 5,
		Parent = details,
		OnClick = function()
			self:_equipSelected()
		end,
	})
	self._deleteButton = Button.new({
		Text = "Delete",
		Variant = "danger",
		ButtonSize = "sm",
		FullWidth = true,
		LayoutOrder = 6,
		Visible = p.OnDelete ~= nil,
		Parent = details,
		OnClick = function()
			self:_deleteSelected()
		end,
	})
	self._empty = Text.new({
		Text = p.EmptyText or "Nothing here yet.",
		Role = "body",
		Color = "textMuted",
		AlignX = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, -(DETAIL_WIDTH + 12) / 2, 0.5, 0),
		Parent = self.Window,
	})

	self:SetItems(p.Items or {})
	Manager.register(self.Id, self)
	return self
end

function Inventory:_updateTitle()
	if self.Capacity then
		self.Window:SetTitle(string.format("%s  %d/%d", self.Title, #self.Items, self.Capacity))
	else
		self.Window:SetTitle(self.Title)
	end
end

function Inventory:SetItems(items: { { [string]: any } })
	local list = table.clone(items)
	if self.SortByRarity then
		table.sort(list, function(a, b)
			local ra, rb = rarityRank(a), rarityRank(b)
			if ra ~= rb then
				return ra < rb
			end
			return (a.Name or "") < (b.Name or "")
		end)
	end
	self.Items = list

	for _, slot in self._slots do
		slot:Destroy()
	end
	self._slots = {}
	for index, item in list do
		local slot = ItemSlot.new({
			Name = "Slot_" .. tostring(item.Id or index),
			Item = item,
			LayoutOrder = index,
			Parent = self.Grid,
			OnClick = function()
				self:Select(item.Id)
			end,
		})
		self._slots[item.Id or index] = slot
	end

	self._empty.Instance.Visible = #list == 0
	self:_updateTitle()

	local keep = self.Selected and self:_find(self.Selected)
	self.Selected = nil
	if keep then
		self:Select(keep.Id)
	elseif list[1] then
		self:Select(list[1].Id)
	else
		self:_showDetails(nil)
	end
end

function Inventory:_find(id: any): { [string]: any }?
	for _, item in self.Items do
		if item.Id == id then
			return item
		end
	end
	return nil
end

function Inventory:Select(id: any)
	if self.Selected ~= nil and self._slots[self.Selected] then
		self._slots[self.Selected]:SetSelected(false)
	end
	self.Selected = id
	local slot = self._slots[id]
	if slot then
		slot:SetSelected(true)
	end
	self:_showDetails(self:_find(id))
end

function Inventory:_showDetails(item: { [string]: any }?)
	self.Details.Instance.Visible = item ~= nil
	if not item then
		return
	end
	self._preview:SetItem(item)
	self._name:SetText(item.Name or "")
	local rarity = string.lower(item.Rarity or "common")
	self._rarity:SetText(titleCase(rarity))
	self._rarity:SetColor("rarity." .. rarity)
	self._description:SetText(item.Description or "")
	self._equipButton:SetText(if item.Equipped then "Unequip" else "Equip")
	self._equipButton:SetVariant(if item.Equipped then "secondary" else "primary")
	self._equipButton.Instance.Visible = self._onEquip ~= nil and not item.Locked
	self._deleteButton.Instance.Visible = self._onDelete ~= nil and not item.Locked
end

function Inventory:_equipSelected()
	local item = self.Selected ~= nil and self:_find(self.Selected)
	if item and self._onEquip then
		self._onEquip(item, not item.Equipped)
	end
end

function Inventory:_deleteSelected()
	local item = self.Selected ~= nil and self:_find(self.Selected)
	if not item or not self._onDelete then
		return
	end
	local confirmed = Dialog.confirm({
		Title = "Delete " .. (item.Name or "item") .. "?",
		Text = "This can't be undone.",
		ConfirmText = "Delete",
		Danger = true,
	})
	if confirmed then
		self._onDelete(item)
	end
end

function Inventory:Open()
	Manager.open(self.Id)
end

function Inventory:Close()
	Manager.close(self.Id)
end

function Inventory:Destroy()
	Manager.unregister(self.Id)
	self.Window:Destroy()
end

return Inventory
