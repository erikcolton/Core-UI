# Components and screens

Every component is created with `.new(props)` and returns an object with:

- `Instance`: the root GuiObject.
- `Content` (containers only): where children go. Passing a container as `Parent` puts the child in its `Content`.
- `Destroy()`.

Common props on every component: `Parent`, `Name`, `Position`, `AnchorPoint`, `Size`, `LayoutOrder`, `Visible`, `ZIndex`.

Colors in props are theme color names (`"primary"`, `"textMuted"`, `"rarity.epic"`) or a `Color3`. Names stay correct when the theme changes; a `Color3` does not.

## Components

| Component | Props | Methods and signals |
| --- | --- | --- |
| `Text` | `Text`, `Role` (display, title, heading, label, body, caption), `Color`, `Outline`, `AlignX`, `AlignY`, `Wrap`, `Truncate`, `RichText` | `SetText`, `SetColor`, `SetRole` |
| `Button` | `Text`, `Icon`, `Variant` (primary, secondary, buy, danger, ghost), `ButtonSize` (sm, md, lg), `Square`, `FullWidth`, `Width`, `Color`, `TextColor`, `Enabled`, `OnClick` | `SetText`, `SetIcon`, `SetVariant`, `SetEnabled`, `SetBadge`, `Activated` |
| `Panel` | `Variant` (surface, inset), `Padding`, `Color`, `Clip` | `Surface`, `Content` |
| `Window` | `Title`, `Size`, `Closable` | `Open`, `Close`, `Toggle`, `SetTitle`, `Body`, `Opened`, `Closed` |
| `ProgressBar` | `Value`, `Max`, `Color`, `Label` (true, string, or function(value, max)) | `SetValue(value, max?, animate?)`, `SetColor` |
| `Toggle` | `Value`, `OnChanged` | `SetValue(value, silent?)`, `Changed` |
| `Slider` | `Min`, `Max`, `Step`, `Value`, `OnChanged` | `SetValue(value, silent?)`, `Changed` |
| `Tabs` | `Tabs` ({ Id, Text, Icon, Width }), `Selected`, `OnChanged` | `GetPage(id)`, `GetButton(id)`, `Select(id)`, `AddTab`, `Changed` |
| `ScrollList` | `Layout` (list, grid), `CellSize`, `Gap`, `AlignX` | `Add(child)`, `Clear()` |
| `ItemSlot` | `Item` ({ Image, Name, Rarity, Count, Equipped, Locked }), `Selected`, `OnClick` | `SetItem`, `SetSelected`, `Activated` |
| `ShopCard` | `Item` ({ Id, Name, Description, Price, Currency, PriceText, Image, Tag }), `OnBuy` | `SetOwned` |
| `CurrencyCounter` | `Icon` or `Color`, `Amount`, `Abbreviate`, `OnAdd` | `SetAmount(amount, animate?)` |
| `Badge` | `Count` | `SetCount(number or true or 0)` |
| `TextInput` | `Placeholder`, `Text`, `OnSubmit` | `GetText`, `SetText`, `Focus`, `Submit`, `Submitted` |
| `Tooltip` | (module) | `Tooltip.attach(guiObject, text or function) -> detach`, `Tooltip.hide()` |

## Screens

Screens that are windows register with the Manager under `Id` (defaults shown), so HUD buttons and menus can open them by name.

| Screen | Default Id | Props | Methods |
| --- | --- | --- | --- |
| `HUD` | none | `Currencies` ({ Id, Icon, Color, Amount, Screen or OnClick }), `Buttons` ({ Id, Text, Icon, Variant, Screen or OnClick }), `Objective` | `SetCurrency`, `GetCurrency`, `SetBadge`, `GetButton`, `SetObjective`, `SetVisible`, `AddCurrency`, `AddButton`, `BottomBar` frame |
| `Shop` | `Shop` | `Categories` ({ Id, Text, Items }), `OnPurchase(item, card)`, `CardSize` | `SetOwned(itemId, owned)`, `Open`, `Close` |
| `Inventory` | `Inventory` | `Items`, `Capacity`, `SortByRarity`, `OnEquip(item, equip)`, `OnDelete(item)`, `EmptyText` | `SetItems`, `Select`, `Open`, `Close` |
| `Settings` | `Settings` | `Options` ({ Id, Text, Description, Type = toggle, slider or choice, Default, Min, Max, Step, Choices }), `OnChanged(id, value)` | `Get`, `Set(id, value, silent?)`, `Changed` |
| `DailyRewards` | `DailyRewards` | `Rewards` ({ Text, Image }), `Claimed`, `CanClaim`, `NextIn`, `OnClaim(day)` | `SetState({ Claimed, CanClaim, NextIn })` |
| `Codes` | `Codes` | `OnRedeem(code) -> ok, message`, `Description`, `Placeholder` | `Redeem`, `SetStatus` |
| `Dialog` | (module) | | `Dialog.confirm(options) -> boolean`, `Dialog.alert(options)`; both yield. `Dialog.dismissAll()` cancels open dialogs |
| `Notifications` | (module) | | `push({ Title, Text, Kind, Duration })`, `info`, `success`, `warning`, `error` |
| `LoadingScreen` | none | `Title`, `Tips`, `TipInterval`, `Background`, `Status` | `SetProgress(ratio, status?)`, `Finish()` |
| `MainMenu` | none | `Title`, `Subtitle`, `Background`, `Buttons` ({ Text, Variant, Play or Screen or OnClick }), `OnPlay` | `Show`, `Hide`, `Play`, `Played` |

## Manager

```lua
CoreUI.Manager.open("Shop")
CoreUI.Manager.toggle("Inventory")
CoreUI.Manager.close()          -- whatever is open
CoreUI.Manager.register("Quests", myWindowOrScreen)
CoreUI.Manager.Opened:Connect(function(id) end)
```

Only one window is open at a time. Set `screen.CloseOnBackdrop = false` to stop backdrop taps from closing a screen.

## Layers

Each layer is its own ScreenGui, created on first use:

| Layer | Display order | Safe area | Used by |
| --- | --- | --- | --- |
| HUD | 10 | yes | HUD |
| Menu | 15 | no | MainMenu |
| Backdrop | 19 | no | window backdrop |
| Windows | 20 | yes | every Window |
| Dialogs | 30 | no | Dialog |
| Toasts | 40 | yes | Notifications |
| Overlay | 50 | no | LoadingScreen, Tooltip |

`Layers.configure({ Parent = instance, Prefix = "Name_" })` sends layers somewhere other than the player's PlayerGui (the Studio plugin uses CoreGui to preview screens in Edit mode), and `Layers.setEnabled(on)` shows or hides them all.
