--[[
	Core UI: a themeable UI kit for Roblox games.

		local CoreUI = require(ReplicatedStorage.CoreUI)

		CoreUI.Theme.set("Cartoony")
		local shop = CoreUI.Shop.new({ Categories = { ... } })
		local hud = CoreUI.HUD.new({ Buttons = { { Id = "shop", Text = "Shop", Screen = "Shop" } } })

	Components build single controls; Screens build whole frames out of components and
	register with the Manager. Everything reads its look from the active theme and
	restyles itself when CoreUI.Theme.set() switches themes. See docs/ for details.
]]

local Components = script.Components
local Screens = script.Screens
local Util = script.Util

local CoreUI = {
	Version = "0.2.0",

	Theme = require(script.Theme),
	Manager = require(script.Manager),
	Layers = require(Util.Layers),

	Util = {
		Color = require(Util.Color),
		Create = require(Util.Create),
		Format = require(Util.Format),
		Maid = require(Util.Maid),
		Signal = require(Util.Signal),
		Sound = require(Util.Sound),
		Style = require(Util.Style),
		Tween = require(Util.Tween),
	},

	-- Components
	Badge = require(Components.Badge),
	Button = require(Components.Button),
	CurrencyCounter = require(Components.CurrencyCounter),
	ItemSlot = require(Components.ItemSlot),
	Panel = require(Components.Panel),
	ProgressBar = require(Components.ProgressBar),
	ScrollList = require(Components.ScrollList),
	ShopCard = require(Components.ShopCard),
	Slider = require(Components.Slider),
	Tabs = require(Components.Tabs),
	Text = require(Components.Text),
	TextInput = require(Components.TextInput),
	Toggle = require(Components.Toggle),
	Tooltip = require(Components.Tooltip),
	Window = require(Components.Window),

	-- Screens
	Codes = require(Screens.Codes),
	DailyRewards = require(Screens.DailyRewards),
	Dialog = require(Screens.Dialog),
	HUD = require(Screens.HUD),
	Inventory = require(Screens.Inventory),
	LoadingScreen = require(Screens.LoadingScreen),
	MainMenu = require(Screens.MainMenu),
	Notifications = require(Screens.Notifications),
	Settings = require(Screens.Settings),
	Shop = require(Screens.Shop),
}

return CoreUI
