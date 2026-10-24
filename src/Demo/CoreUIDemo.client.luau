--[[
	Core UI demo. Builds every screen with sample data so you can click through the
	kit and switch themes live from Settings > Theme.

	Run it with: rojo serve demo.project.json, then connect from Studio and press Play.
	Nothing here talks to a server: purchases, codes and rewards are faked locally.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoreUI = require(ReplicatedStorage:WaitForChild("CoreUI"))

local Theme = CoreUI.Theme
local Notifications = CoreUI.Notifications

-- Loading screen ------------------------------------------------------------

local loading = CoreUI.LoadingScreen.new({
	Title = "Core UI",
	Tips = {
		"Every screen here restyles itself when the theme changes.",
		"Tap outside a window, or press B on a gamepad, to close it.",
		"Themes are plain tables: copy Clean.luau to make your own.",
	},
})
for step = 1, 10 do
	task.wait(0.12)
	loading:SetProgress(step / 10, if step < 10 then "Loading assets" else "Ready")
end
loading:Finish()

-- State the server would normally own -----------------------------------------

local coins = 1250
local gems = 40
local inventoryItems = {
	{ Id = "p1", Name = "Doggy", Rarity = "common", Count = 3, Description = "Loyal and always hungry." },
	{ Id = "p2", Name = "Kitty", Rarity = "uncommon", Description = "Lands on its feet." },
	{ Id = "p3", Name = "Bunny", Rarity = "rare", Equipped = true, Description = "Hops twice as far." },
	{ Id = "p4", Name = "Dragon", Rarity = "epic", Description = "Breathes small, polite fires." },
	{ Id = "p5", Name = "Phoenix", Rarity = "legendary", Description = "Comes back every time." },
	{ Id = "p6", Name = "Void Cat", Rarity = "mythic", Description = "Nobody knows where it goes." },
	{ Id = "p7", Name = "???", Rarity = "epic", Locked = true },
}

-- Screens ---------------------------------------------------------------------

local hud

CoreUI.Shop.new({
	Categories = {
		{
			Id = "passes",
			Text = "Passes",
			Items = {
				{
					Id = "vip",
					Name = "VIP",
					Description = "2x coins and a gold name tag",
					Price = 299,
					Tag = "Best value",
				},
				{ Id = "speed", Name = "Speed Boots", Description = "Run 50% faster", Price = 149 },
				{ Id = "slots", Name = "+20 Slots", Description = "Hold more pets", Price = 99 },
			},
		},
		{
			Id = "coins",
			Text = "Coins",
			Items = {
				{ Id = "c1", Name = "1K Coins", Description = "A handful", Price = 25 },
				{ Id = "c2", Name = "10K Coins", Description = "A sack full", Price = 199, Tag = "Popular" },
				{ Id = "c3", Name = "100K Coins", Description = "A vault", Price = 999 },
			},
		},
		{
			Id = "gems",
			Text = "Gems",
			Items = {
				{ Id = "g1", Name = "Egg", Description = "Hatch a random pet", Price = 500, Currency = "Coins" },
				{ Id = "g2", Name = "Golden Egg", Description = "Better odds", Price = 25, Currency = "Gems" },
			},
		},
	},
	OnPurchase = function(item, card)
		if item.Currency == "Coins" then
			if coins < item.Price then
				Notifications.error("You need " .. CoreUI.Util.Format.abbreviate(item.Price - coins) .. " more coins.")
				return
			end
			coins -= item.Price
			hud:SetCurrency("coins", coins)
			Notifications.success("Hatched a new pet!", item.Name)
		elseif item.Currency == "Gems" then
			if gems < item.Price then
				Notifications.error("Not enough gems.")
				return
			end
			gems -= item.Price
			hud:SetCurrency("gems", gems)
			Notifications.success("Hatched a shiny pet!", item.Name)
		else
			-- A real game calls MarketplaceService here (leave OnPurchase out and set GamePassId).
			card:SetOwned(true)
			Notifications.info("Pretend purchase complete.", item.Name)
		end
	end,
})

local inventory
inventory = CoreUI.Inventory.new({
	Capacity = 50,
	Items = inventoryItems,
	SortByRarity = true,
	OnEquip = function(item, equip)
		item.Equipped = equip
		inventory:SetItems(inventoryItems)
		Notifications.info((if equip then "Equipped " else "Unequipped ") .. item.Name)
	end,
	OnDelete = function(item)
		local index = table.find(inventoryItems, item)
		if index then
			table.remove(inventoryItems, index)
		end
		inventory:SetItems(inventoryItems)
		Notifications.warning(item.Name .. " was deleted.")
	end,
})

local rewards = {}
for day = 1, 7 do
	table.insert(rewards, { Text = if day == 7 then "Mythic Egg" else tostring(day * 100) .. " Coins" })
end
local daily
daily = CoreUI.DailyRewards.new({
	Rewards = rewards,
	Claimed = 2,
	CanClaim = true,
	OnClaim = function(day)
		task.wait(0.3) -- pretend server round trip
		coins += day * 100
		hud:SetCurrency("coins", coins)
		hud:SetBadge("rewards", 0)
		daily:SetState({ Claimed = day, CanClaim = false, NextIn = 20 * 3600 })
		Notifications.success("+" .. day * 100 .. " coins", "Day " .. day .. " claimed")
	end,
})

CoreUI.Codes.new({
	OnRedeem = function(code)
		task.wait(0.4) -- pretend server round trip
		if string.upper(code) == "CORE" then
			gems += 10
			hud:SetCurrency("gems", gems)
			return true, "+10 gems!"
		end
		return false, "That code doesn't exist or has expired."
	end,
})

local themeNames = Theme.list()
CoreUI.Settings.new({
	Options = {
		{
			Id = "theme",
			Text = "Theme",
			Description = "Switches the whole kit live",
			Type = "choice",
			Choices = themeNames,
			Default = Theme.get().name,
		},
		{ Id = "music", Text = "Music", Type = "toggle", Default = true },
		{ Id = "sfx", Text = "Sound effects", Type = "slider", Min = 0, Max = 100, Step = 5, Default = 80 },
		{
			Id = "lowGraphics",
			Text = "Low graphics",
			Description = "Fewer particles and shadows",
			Type = "toggle",
			Default = false,
		},
		{ Id = "hidePlayers", Text = "Hide other players", Type = "toggle", Default = false },
	},
	OnChanged = function(id, value)
		if id == "theme" then
			Theme.set(value)
			Notifications.info("Theme: " .. value)
		end
	end,
})

-- HUD -------------------------------------------------------------------------

hud = CoreUI.HUD.new({
	Currencies = {
		{ Id = "coins", Amount = coins, Color = "warning", Screen = "Shop" },
		{ Id = "gems", Amount = gems, Color = "info", Screen = "Shop" },
	},
	Buttons = {
		{ Id = "shop", Text = "Shop", Screen = "Shop", Variant = "primary" },
		{ Id = "inventory", Text = "Pets", Screen = "Inventory" },
		{ Id = "rewards", Text = "Rewards", Screen = "DailyRewards" },
		{ Id = "codes", Text = "Codes", Screen = "Codes" },
		{ Id = "settings", Text = "Settings", Screen = "Settings" },
	},
	Objective = "Collect 5,000 coins",
})
hud:SetBadge("rewards", 1)
hud:SetBadge("shop", true)

-- Hotbar along the bottom, built from item slots.
for index = 1, 5 do
	local item = inventoryItems[index]
	CoreUI.ItemSlot.new({
		Item = item,
		Size = UDim2.fromOffset(64, 64),
		LayoutOrder = index,
		Parent = hud.BottomBar,
		OnClick = function()
			Notifications.info("Used " .. item.Name)
		end,
	})
end

local xp = CoreUI.ProgressBar.new({
	Value = 35,
	Max = 100,
	Label = function(value, max)
		return "Level 4  " .. math.floor(value) .. "/" .. max .. " XP"
	end,
	Color = "success",
	Size = UDim2.fromOffset(260, 20),
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 48),
	Parent = hud.Instance,
})

CoreUI.Tooltip.attach(hud:GetButton("codes").Instance, "Follow us for new codes")

-- Main menu over everything at start -------------------------------------------

CoreUI.MainMenu.new({
	Title = "Core UI",
	Subtitle = "A demo of every screen in the kit",
	Buttons = {
		{ Text = "Play", Play = true },
		{ Text = "Settings", Screen = "Settings" },
		{
			Text = "About",
			OnClick = function()
				CoreUI.Dialog.alert({
					Title = "About Core UI",
					Text = "Version "
						.. CoreUI.Version
						.. ". Switch themes in Settings to see the same screens restyle.",
				})
			end,
		},
	},
	OnPlay = function()
		Notifications.success("Welcome back!", "Hi " .. game:GetService("Players").LocalPlayer.DisplayName)
	end,
})

-- Passive income so the counters have something to do.
task.spawn(function()
	while true do
		task.wait(3)
		coins += 25
		hud:SetCurrency("coins", coins)
		xp:SetValue((xp.Value + 7) % 100)
	end
end)
