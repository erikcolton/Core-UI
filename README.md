# Core UI

A themeable UI kit for Roblox games. One set of components and screens, restyled per game by swapping a theme table.

- **Theme system**: every color, font, size, radius, stroke, shadow, motion timing, sound and 9-slice image comes from a theme. `Theme.set()` restyles everything on screen live.
- **Studio plugin**: the Core UI Customizer edits themes inside Studio with a live preview and saves them into the place. See [docs/PLUGIN.md](docs/PLUGIN.md).
- **Seven templates**: `Clean`, `Cartoony`, `Dark`, `Candy`, `Neon`, `Wood` and `Pixel`.
- **15 components**: Button, Panel, Window, Text, ProgressBar, Toggle, Slider, Tabs, ScrollList, ItemSlot, ShopCard, CurrencyCounter, Badge, TextInput, Tooltip.
- **10 ready screens**: HUD, Shop, Inventory, Settings, DailyRewards, Codes, Dialog, Notifications, LoadingScreen, MainMenu.
- **Built for every device**: phone-first sizing with one UIScale per layer, safe-area insets, nothing under the mobile thumbstick or jump button, gamepad selection and B-to-close.

No dependencies: plain Luau and Roblox instances.

## Install

The quickest way is the Studio plugin: install it (see [docs/PLUGIN.md](docs/PLUGIN.md)), open **Customizer**, and press **Install kit** on the Themes tab.

With [Rojo](https://rojo.space):

```sh
rojo build default.project.json -o CoreUI.rbxm                    # the kit as a model for any place
rojo build plugin.project.json --plugin CoreUICustomizer.rbxm     # the Studio plugin, into your plugins folder
rojo build demo.project.json -o CoreUIDemo.rbxl                   # a demo place
rojo serve demo.project.json                                      # or live-sync the demo place
```

Put the `CoreUI` module in `ReplicatedStorage` and require it from a LocalScript.

## Quick start

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreUI = require(ReplicatedStorage.CoreUI)

-- Themes saved with the Studio plugin load by themselves. Or pick one in code:
CoreUI.Theme.set("Cartoony")

-- Screens register with the Manager under an Id, so buttons can open them by name.
CoreUI.Shop.new({
	Categories = {
		{ Id = "passes", Text = "Passes", Items = {
			{ Id = "vip", Name = "VIP", Description = "2x coins", Price = 299, GamePassId = 123456 }, -- your game pass id
		} },
	},
})
CoreUI.Settings.new({
	Options = {
		{ Id = "music", Text = "Music", Type = "toggle", Default = true },
	},
})

local hud = CoreUI.HUD.new({
	Currencies = { { Id = "coins", Amount = 0, Screen = "Shop" } },
	Buttons = {
		{ Id = "shop", Text = "Shop", Screen = "Shop", Variant = "primary" },
		{ Id = "settings", Text = "Settings", Screen = "Settings" },
	},
})

hud:SetCurrency("coins", 1500)
CoreUI.Notifications.success("Welcome!")
```

The demo in [`src/Demo/CoreUIDemo.client.luau`](src/Demo/CoreUIDemo.client.luau) builds every screen with sample data and lets you switch themes from Settings.

## Layout of the repo

```
src/CoreUI/
  init.luau            entry point: CoreUI.Button, CoreUI.Shop, CoreUI.Theme, ...
  Theme/               theme manager, saved-theme code (Serialize) and the seven templates
  Components/          single controls
  Screens/             whole frames built from components
  Manager.luau         opens one window at a time, backdrop, gamepad
  Util/                Signal, Maid, Create, Style, Tween, Sound, Format, Color, Layers
src/Demo/              demo LocalScript
src/Plugin/            the Core UI Customizer Studio plugin
tests/                 Lune tests (logic, plugin schema, and a smoke run of the plugin and demo)
docs/
  UI_INVENTORY.md      what typical Roblox games include, and what this kit covers
  THEMING.md           theme tokens and how to make a theme for a game
  COMPONENTS.md        API reference
  PLUGIN.md            installing, using and publishing the Studio plugin
```

## Development

Tools are pinned in `rokit.toml` (Rojo, StyLua, Selene, Lune). With [Rokit](https://github.com/rojo-rbx/rokit) installed, run `rokit install`, then:

```sh
stylua --check src tests     # formatting
lune run tests/run           # tests
```

The tests run the kit and the plugin outside Studio against small fakes of Roblox services. They catch logic errors and crashes, not visual problems, so check changes in Studio too (docs/PLUGIN.md has a checklist).

## Server side

The kit is client-only and never grants anything. Purchases go through `MarketplaceService` prompts and must be granted in `ProcessReceipt` on the server; codes, daily rewards, inventory changes and settings saves should go through your own RemoteEvents or RemoteFunctions, with the server checking every request.
