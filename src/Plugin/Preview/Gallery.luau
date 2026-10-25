--[[
	Live preview inside the plugin window, built from the real kit components so it
	restyles exactly like a game would. It is laid out at a fixed design size and
	scaled to fit the space it gets.

	Pages: "controls" (buttons, text, bars, toggles, slots) and "cards" (shop cards,
	tabs, input, currency).
]]

local CoreUI = require(script.Parent.Parent.CoreUI)
local Create = CoreUI.Util.Create
local Theme = CoreUI.Theme

local Gallery = {}
Gallery.__index = Gallery

local DESIGN = Vector2.new(600, 400)

Gallery.PAGES = {
	{ "Controls", "controls" },
	{ "Shop cards", "cards" },
}

local function row(parent: Instance, order: number, height: number, gap: number?): Frame
	local frame = Create("Frame", {
		Name = "Row" .. order,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height),
		LayoutOrder = order,
		Parent = parent,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap or 10),
		Parent = frame,
	})
	return frame
end

local function buildControls(window: any)
	local body = window.Body
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = body,
	})

	local buttons = row(body, 1, 60)
	CoreUI.Button.new({ Text = "Play", Variant = "primary", ButtonSize = "sm", LayoutOrder = 1, Parent = buttons })
	CoreUI.Button.new({ Text = "Options", Variant = "secondary", ButtonSize = "sm", LayoutOrder = 2, Parent = buttons })
	CoreUI.Button.new({ Text = "R$ 99", Variant = "buy", ButtonSize = "sm", LayoutOrder = 3, Parent = buttons })
	CoreUI.Button.new({ Text = "Delete", Variant = "danger", ButtonSize = "sm", LayoutOrder = 4, Parent = buttons })
	local gift = CoreUI.Button.new({
		Text = "Gifts",
		Variant = "ghost",
		ButtonSize = "sm",
		Width = 80,
		LayoutOrder = 5,
		Parent = buttons,
	})
	gift:SetBadge(3)

	local middle = row(body, 2, 92, 18)
	local texts = Create("Frame", {
		Name = "Texts",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(250, 92),
		LayoutOrder = 1,
		Parent = middle,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = texts,
	})
	CoreUI.Text.new({ Text = "Daily Rewards", Role = "title", LayoutOrder = 1, Parent = texts })
	CoreUI.Text.new({ Text = "Heading text", Role = "heading", LayoutOrder = 2, Parent = texts })
	CoreUI.Text.new({ Text = "Body text reads like this.", Role = "body", LayoutOrder = 3, Parent = texts })
	CoreUI.Text.new({ Text = "Caption text", Role = "caption", Color = "textMuted", LayoutOrder = 4, Parent = texts })

	local counters = Create("Frame", {
		Name = "Counters",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(250, 92),
		LayoutOrder = 2,
		Parent = middle,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = counters,
	})
	CoreUI.CurrencyCounter.new({
		Amount = 12500,
		Color = "warning",
		OnAdd = function() end,
		LayoutOrder = 1,
		Parent = counters,
	})
	CoreUI.CurrencyCounter.new({ Amount = 840, Color = "info", LayoutOrder = 2, Parent = counters })

	local bars = row(body, 3, 34, 16)
	CoreUI.ProgressBar.new({
		Value = 65,
		Max = 100,
		Label = true,
		Color = "success",
		Size = UDim2.fromOffset(220, 22),
		LayoutOrder = 1,
		Parent = bars,
	})
	CoreUI.Toggle.new({ Value = true, LayoutOrder = 2, Parent = bars })
	CoreUI.Toggle.new({ Value = false, LayoutOrder = 3, Parent = bars })
	CoreUI.Slider.new({ Value = 0.6, Size = UDim2.fromOffset(150, 28), LayoutOrder = 4, Parent = bars })

	local slots = row(body, 4, 70, 8)
	local rarities = { "common", "uncommon", "rare", "epic", "legendary", "mythic" }
	local names = { "Dog", "Cat", "Bunny", "Dragon", "Phoenix", "Void" }
	for index, rarity in rarities do
		CoreUI.ItemSlot.new({
			Item = {
				Name = names[index],
				Rarity = rarity,
				Count = if index == 1 then 3 else nil,
				Equipped = index == 3,
				Locked = index == 6,
			},
			Selected = index == 4,
			Size = UDim2.fromOffset(62, 62),
			LayoutOrder = index,
			Parent = slots,
		})
	end
end

local function buildCards(window: any)
	local body = window.Body
	local tabs = CoreUI.Tabs.new({
		Tabs = { { Id = "passes", Text = "Passes" }, { Id = "coins", Text = "Coins" } },
		Size = UDim2.fromScale(1, 1),
		Parent = body,
	})
	local function cards(page: Instance, items: { any })
		local holder = Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = page,
		})
		Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
			Parent = holder,
		})
		for index, item in items do
			local card = CoreUI.ShopCard.new({
				Item = item,
				Size = UDim2.fromOffset(170, 248),
				LayoutOrder = index,
				Parent = holder,
			})
			if item.Owned then
				card:SetOwned(true)
			end
		end
	end
	cards(tabs:GetPage("passes"), {
		{ Id = "vip", Name = "VIP", Description = "2x coins and a gold tag", Price = 299, Tag = "Best value" },
		{ Id = "speed", Name = "Speed Boots", Description = "Run 50% faster", Price = 149 },
		{ Id = "pets", Name = "+20 Slots", Description = "Hold more pets", Price = 99, Owned = true },
	})
	cards(tabs:GetPage("coins"), {
		{ Id = "c1", Name = "1K Coins", Description = "A handful", Price = 25 },
		{ Id = "c2", Name = "Egg", Description = "Hatch a pet", Price = 500, Currency = "Coins", Tag = "New" },
	})
end

function Gallery.new(parent: GuiObject)
	local self = setmetatable({}, Gallery)
	self.Page = "controls"

	-- Fills the preview area with the theme background.
	self.Instance = Create("Frame", {
		Name = "Gallery",
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	Theme.bind(self.Instance, function(theme)
		self.Instance.BackgroundColor3 = theme.colors.background
	end)

	self._stage = Create("Frame", {
		Name = "Stage",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(DESIGN.X, DESIGN.Y),
		Parent = self.Instance,
	})
	self._scale = Create("UIScale", { Parent = self._stage })
	self.Instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_fit()
	end)
	self:_fit()
	self:SetPage(self.Page)
	return self
end

function Gallery:_fit()
	local size = self.Instance.AbsoluteSize
	if size.X > 0 and size.Y > 0 then
		self._scale.Scale = math.min(size.X / DESIGN.X, size.Y / DESIGN.Y)
	end
end

function Gallery:SetPage(page: string)
	self.Page = page
	if self._window then
		self._window:Destroy()
	end
	local window = CoreUI.Window.new({
		Title = if page == "cards" then "Shop" else "Core UI preview",
		Size = UDim2.fromOffset(DESIGN.X - 20, DESIGN.Y - 20),
		Parent = self._stage,
	})
	self._window = window
	-- The close button replays the animation instead of hiding the preview.
	window.OnCloseRequest = function()
		self:Replay()
	end
	if page == "cards" then
		buildCards(window)
	else
		buildControls(window)
	end
	window:Open()
end

-- Plays the window close and open animations again, to try motion settings.
function Gallery:Replay()
	local window = self._window
	if not window then
		return
	end
	window:Close()
	task.delay(Theme.get().motion.fast + 0.15, function()
		if self._window == window then
			window:Open()
		end
	end)
end

function Gallery:Destroy()
	self.Instance:Destroy()
end

return Gallery
