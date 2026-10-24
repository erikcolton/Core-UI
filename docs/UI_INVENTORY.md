# UI inventory for Roblox games

What players expect to find in a typical Roblox game, grouped by where it lives on screen, and how Core UI covers each piece. This list was put together from popular simulator, roleplay, obby, horror and shooter games, from the screens that commercial Roblox UI packs ship with, and from Roblox's own design guidance (sources at the bottom).

Status key:

- **Built**: ships in this first cut as a component or screen.
- **Compose**: no dedicated module yet, but it is a few lines on top of built components (examples are given).
- **Planned**: needs its own module; listed in rough priority order.

## 1. Always on screen (HUD)

| Element | Seen in | Status | Notes |
| --- | --- | --- | --- |
| Currency counters (coins, gems, tickets) | Almost every simulator and tycoon | Built: `CurrencyCounter`, `HUD` | Top right, anchored at (1, 0). Abbreviates 1.2K / 3.4M, animates count-up, pulses on change, optional "+" that opens the shop. |
| Side menu buttons (Shop, Inventory, Rewards, Codes, Settings) | Simulators, roleplay | Built: `HUD` side buttons | Left middle, clear of the mobile joystick. Each can show a notification badge. |
| Notification badges | Everywhere | Built: `Badge` | Red count or dot on any button. Clash Royale's rule: badges instead of popups. |
| Objective / quest tracker line | Story, obby, horror | Built: `HUD:SetObjective` | Top center, below the Roblox top bar. |
| Hotbar / ability bar | Shooters, fighting, RPG | Compose: `HUD` bottom bar + `ItemSlot` | Bottom center, between joystick and jump button. |
| Health / stamina / XP bars | Fighting, RPG, horror | Built: `ProgressBar` | Segment-free bar with label. |
| Round timer and team score | Round-based games | Compose: `Text` in `HUD` top center | |
| Active boosts with timers (2x coins 04:59) | Simulators | Planned: `BoostList` | Icon + countdown, tooltip on hover. |
| World-space prompts ("E  Open door") | Horror, roleplay | Planned: `WorldPrompt` | BillboardGui wrapper and custom ProximityPrompt style. |

## 2. Menus and windows

| Element | Seen in | Status | Notes |
| --- | --- | --- | --- |
| Window frame with title and close button | Everywhere | Built: `Window` | Pop-in animation, backdrop, closes on backdrop tap. |
| Shop (game passes, developer products, currency packs) | Everywhere that monetizes | Built: `Shop`, `ShopCard` | Tabs per category, "Best value" tag, Owned state, calls `MarketplaceService` for Robux items. |
| Inventory / pets / backpack | Simulators, RPG | Built: `Inventory`, `ItemSlot` | Grid with rarity borders, detail pane, Equip and Delete actions, capacity counter. |
| Settings (music, SFX, low graphics, hide others) | Everywhere | Built: `Settings` | Rows built from a config table: toggle, slider, choice. |
| Daily rewards / login streak | Simulators, roleplay | Built: `DailyRewards` | 7-day grid, claimed / available / locked states. |
| Codes / redeem | Simulators | Built: `Codes` | Text input, redeem button, success or error line. |
| Main menu / title screen | Story, horror, competitive | Built: `MainMenu` | Title, subtitle, stacked buttons. |
| Loading screen | Larger games | Built: `LoadingScreen` | Progress bar, rotating tips, fade out. |
| Confirm dialog ("Delete this pet?") | Everywhere | Built: `Dialog.confirm` | Yields and returns true or false. |
| Toast notifications | Everywhere | Built: `Notifications` | Info, success, warning, error; auto-dismiss; stacked. |
| Tooltips | Inventory, shop | Built: `Tooltip` | Follows the pointer; skipped on touch. |
| Rebirth / prestige | Simulators | Compose: `Window` + `ProgressBar` + `Button` | Requirement bar, reward text, Rebirth button. |
| Upgrades list | Simulators, tycoons | Compose: `Window` + `ScrollList` + rows of `Text` and `Button` | |
| Index / collection book | Pet and RNG games | Compose: `Inventory` with locked slots | `ItemSlot` already has a locked state. |
| Playtime and offline rewards | Simulators | Compose: `DailyRewards` with timer text | |
| Group reward / like reward | Simulators | Compose: `Dialog` or `Window` | |
| Egg / crate / roll opening | Pet and RNG games | Planned: `RevealSequence` | Full-screen overlay, shake, rarity flash. |
| Quests / tasks list | Simulators, RPG | Planned: `QuestList` | Rows with progress bars and claim buttons. |
| Trading | Pet games | Planned: `Trade` | Two inventories, offer grids, accept countdown. |
| Gifting a pass to a friend | Monetized games | Planned: `PlayerPicker` | Player list with search. |
| Custom leaderboard / scoreboard | Competitive | Planned: `Scoreboard` | |
| World / teleport select | Simulators, obbies | Planned: `WorldSelect` | Cards with lock requirements. |
| NPC dialogue box | Story, RPG | Planned: `DialogueBox` | Typewriter text, choice buttons. |
| Death / respawn and spectate | Round-based | Planned: `RespawnScreen` | |
| Tutorial pointer and highlight | Onboarding | Planned: `TutorialPointer` | |

## 3. Base components

These are what everything above is built from. Every one of them reads its look from the active theme and restyles itself live when the theme changes.

| Component | What it is |
| --- | --- |
| `Text` | Label with a type role: display, title, heading, label, body, caption. |
| `Button` | Variants primary, secondary, buy, danger, ghost; sizes sm, md, lg; optional icon; hover and press animation; click sound; disabled state; badge. |
| `Panel` | Themed surface with corner radius, stroke, shadow (soft, lip or none) and an optional 9-slice skin image. |
| `Window` | Panel with a header, title and close button, and a body frame. |
| `ProgressBar` | Track and fill with label, animated changes. |
| `Toggle` | On/off switch. |
| `Slider` | Draggable value from min to max, mouse and touch. |
| `Tabs` | Row of tab buttons with one page each. |
| `ScrollList` | Scrolling list or grid that sizes its canvas automatically. |
| `ItemSlot` | Square slot with icon, rarity border, count, equipped mark, locked overlay. |
| `ShopCard` | Product card with image, name, description, price, tag and buy button. |
| `CurrencyCounter` | Icon and abbreviated amount with count-up animation. |
| `Badge` | Notification dot or count. |
| `TextInput` | Themed text box with submit. |
| `Tooltip` | Pointer-following hint attached to any GUI object. |

## 4. Rules every screen follows

These come from the research and are built into the kit rather than left to each game:

- **Phone first.** Layouts are designed at phone size and scaled up with one `UIScale` per layer, clamped so text stays readable on phones and does not balloon on TVs.
- **Safe area.** HUD and window layers use `ScreenInsets.CoreUISafeInsets` so nothing sits under the top bar, notch or Dynamic Island; only the backdrop and loading screen cover the full screen.
- **Mobile controls.** Nothing is placed bottom-left (joystick) or bottom-right (jump).
- **One level deep.** Opening a window closes the previous one; the backdrop or gamepad B closes it.
- **Consistent color meaning.** Primary for the main action, buy for spending, danger for destructive actions, and the warning and error colors only for alerts.
- **Gamepad.** Opening a window moves gamepad selection into it, and every button has a themed selection outline.

## Sources

- Clash Royale UX breakdown, The Rookies: https://www.therookies.co/blog/education/game-design-ux-best-practices-detailed-breakdown-of-clash-royale
- Designing UI: tips and best practices, DevForum: https://devforum.roblox.com/t/3074034
- Adaptive design guidelines, Roblox docs: https://create.roblox.com/docs/production/publishing/adaptive-design
- Cross-platform development, Roblox docs: https://create.roblox.com/docs/projects/cross-platform
- Aesthetically pleasing UI?, DevForum: https://devforum.roblox.com/t/aesthetically-pleasing-ui/549103
- General UI Kit (tag-based framework), DevForum: https://devforum.roblox.com/t/general-ui-kit-complete-roblox-ui-framework-for-roblox-games-tag-based-no-script-editing/4533783
- Roblox UI Starter Bundle (loading screen, main menu), DevForum: https://devforum.roblox.com/t/roblox-ui-starter-bundle-loading-screen-main-menu/4727511
- RNG Roll Game UI Pack screen list, BuiltByBit: https://builtbybit.com/resources/rng-roll-game-ui-pack.109589/
- Clean Stud UI System 3 screen list, BuiltByBit: https://builtbybit.com/resources/clean-stud-ui-system-3-for-roblox.105203/
- What to steal from Destiny's UI, Game Developer: https://www.gamedeveloper.com/design/what-to-steal-from-destiny-s-ui
- Game UI Field Guide (earlier research for this project): https://claude.ai/artifact/1zH8vN3xUBAXinYNRJyFGq
