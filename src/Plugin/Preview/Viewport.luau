--[[
	"Show in game view": puts the kit's real screens over the Studio viewport at true
	size, with sample data, so a theme can be judged in place without pressing Play.
	The screens live in CoreGui, are never saved into the place, and are clickable.
]]

local CoreGui = game:GetService("CoreGui")

local CoreUI = require(script.Parent.Parent.CoreUI)
local Manager = CoreUI.Manager
local Layers = CoreUI.Layers

local Viewport = {}
Viewport.__index = Viewport

Viewport.PREFIX = "CoreUICustomizer_"

Viewport.SCENES = {
	{ "HUD", "hud" },
	{ "Shop", "Shop" },
	{ "Inventory", "Inventory" },
	{ "Settings", "Settings" },
	{ "Daily rewards", "DailyRewards" },
	{ "Codes", "Codes" },
	{ "Dialog", "dialog" },
	{ "Notifications", "toasts" },
	{ "Main menu", "menu" },
	{ "Loading screen", "loading" },
}

-- Call once, before anything creates a layer.
function Viewport.configure()
	Layers.configure({ Parent = CoreGui, Prefix = Viewport.PREFIX })
end

function Viewport.new()
	local self = setmetatable({}, Viewport)
	self.Enabled = false
	self.Scene = "hud"
	self._built = false
	return self
end

local PETS = {
	{ Id = "p1", Name = "Doggy", Rarity = "common", Count = 3, Description = "Loyal and always hungry." },
	{ Id = "p2", Name = "Kitty", Rarity = "uncommon", Description = "Lands on its feet." },
	{ Id = "p3", Name = "Bunny", Rarity = "rare", Equipped = true, Description = "Hops twice as far." },
	{ Id = "p4", Name = "Dragon", Rarity = "epic", Description = "Breathes small, polite fires." },
	{ Id = "p5", Name = "Phoenix", Rarity = "legendary", Description = "Comes back every time." },
	{ Id = "p6", Name = "Void Cat", Rarity = "mythic", Description = "Nobody knows where it goes." },
	{ Id = "p7", Name = "???", Rarity = "epic", Locked = true },
}

function Viewport:_build()
	if self._built then
		return
	end
	self._built = true

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
					{ Id = "c3", Name = "Egg", Description = "Hatch a random pet", Price = 500, Currency = "Coins" },
				},
			},
		},
		OnPurchase = function(_, card)
			card:SetOwned(true)
		end,
	})

	local inventory
	inventory = CoreUI.Inventory.new({
		Capacity = 50,
		Items = PETS,
		SortByRarity = true,
		OnEquip = function(item, equip)
			item.Equipped = equip
			inventory:SetItems(PETS)
		end,
		OnDelete = function() end,
	})

	CoreUI.Settings.new({
		Options = {
			{ Id = "music", Text = "Music", Type = "toggle", Default = true },
			{ Id = "sfx", Text = "Sound effects", Type = "slider", Min = 0, Max = 100, Step = 5, Default = 80 },
			{
				Id = "quality",
				Text = "Graphics",
				Type = "choice",
				Choices = { "Low", "Medium", "High" },
				Default = "High",
			},
			{
				Id = "lowGraphics",
				Text = "Hide particles",
				Description = "Fewer effects on slow devices",
				Type = "toggle",
				Default = false,
			},
		},
	})

	local rewards = {}
	for day = 1, 7 do
		table.insert(rewards, { Text = if day == 7 then "Mythic Egg" else tostring(day * 100) .. " Coins" })
	end
	CoreUI.DailyRewards.new({ Rewards = rewards, Claimed = 2, CanClaim = true, OnClaim = function() end })

	CoreUI.Codes.new({
		OnRedeem = function(code)
			if string.upper(code) == "CORE" then
				return true, "+10 gems!"
			end
			return false, "Try CORE in the preview."
		end,
	})

	self._hud = CoreUI.HUD.new({
		Currencies = {
			{ Id = "coins", Amount = 12500, Color = "warning", Screen = "Shop" },
			{ Id = "gems", Amount = 40, Color = "info", Screen = "Shop" },
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
	self._hud:SetBadge("rewards", 1)
	self._hud:SetBadge("shop", true)
	for index = 1, 5 do
		CoreUI.ItemSlot.new({
			Item = PETS[index],
			Size = UDim2.fromOffset(64, 64),
			LayoutOrder = index,
			Parent = self._hud.BottomBar,
		})
	end
	CoreUI.ProgressBar.new({
		Value = 35,
		Max = 100,
		Label = function(value, max)
			return "Level 4  " .. math.floor(value) .. "/" .. max .. " XP"
		end,
		Color = "success",
		Size = UDim2.fromOffset(260, 20),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 48),
		Parent = self._hud.Instance,
	})

	self._menu = CoreUI.MainMenu.new({
		Title = "My Game",
		Subtitle = "Season 1",
		Buttons = {
			{ Text = "Play", Play = true },
			{ Text = "Shop", Screen = "Shop" },
			{ Text = "Settings", Screen = "Settings" },
		},
	})
	self:_hideMenu()
end

function Viewport:_hideMenu()
	if self._menu then
		self._menu.Instance.Visible = false
		self._menu.Instance.GroupTransparency = 1
	end
end

function Viewport:_clear()
	Manager.close()
	CoreUI.Dialog.dismissAll()
	self:_hideMenu()
	if self._loading then
		self._loading:Destroy()
		self._loading = nil
	end
end

function Viewport:Show(scene: string)
	self.Scene = scene
	if not self.Enabled then
		return
	end
	self:_clear()
	if scene == "dialog" then
		task.spawn(CoreUI.Dialog.confirm, {
			Title = "Unlock the Forest World?",
			Text = "This costs 5,000 coins. You can't undo it.",
			ConfirmText = "Unlock",
		})
	elseif scene == "toasts" then
		CoreUI.Notifications.success("+500 coins", "Code redeemed")
		CoreUI.Notifications.info("Your pet is hungry.")
		CoreUI.Notifications.warning("Inventory almost full")
		CoreUI.Notifications.error("Not enough gems")
	elseif scene == "menu" then
		self._menu.Instance.Visible = true
		self._menu.Instance.GroupTransparency = 0
	elseif scene == "loading" then
		self._loading = CoreUI.LoadingScreen.new({
			Title = "My Game",
			Tips = { "Tip: rare pets hatch more often at night.", "Tip: invite friends for a coin bonus." },
		})
		self._loading:SetProgress(0.62, "Loading map")
	elseif scene ~= "hud" then
		Manager.open(scene)
	end
end

function Viewport:SetEnabled(enabled: boolean)
	self.Enabled = enabled
	if enabled then
		self:_build()
		Layers.setEnabled(true)
		self:Show(self.Scene)
	elseif self._built then
		self:_clear()
		Layers.setEnabled(false)
	end
end

-- Removes every preview ScreenGui from CoreGui.
function Viewport:Destroy()
	self.Enabled = false
	pcall(function()
		self:_clear()
	end)
	for _, child in CoreGui:GetChildren() do
		if string.sub(child.Name, 1, #Viewport.PREFIX) == Viewport.PREFIX then
			child:Destroy()
		end
	end
end

return Viewport
