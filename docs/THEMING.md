# Theming

The easiest way to make a theme is the **Core UI Customizer** Studio plugin (see [PLUGIN.md](PLUGIN.md)): pick a template, edit it with a live preview, and save it into the place. The kit loads the saved theme by itself. Everything below is for doing the same in code.

A theme is a plain Luau table. Components never hard-code colors or sizes: they read the active theme, and they restyle themselves whenever `Theme.set()` switches to another one.

## Making a theme for a game

Start from the starter theme closest to the look you want and override only what changes:

```lua
local CoreUI = require(ReplicatedStorage.CoreUI)
local Theme = CoreUI.Theme

Theme.register("Lava", Theme.extend("Cartoony", {
	colors = {
		background = Color3.fromRGB(40, 12, 8),
		primary = Color3.fromRGB(255, 120, 30),
		secondary = Color3.fromRGB(120, 40, 30),
	},
	fonts = {
		display = Font.new("rbxasset://fonts/families/Bangers.json"),
	},
	sounds = {
		click = "rbxassetid://YOUR_CLICK_SOUND",
	},
}))

Theme.set("Lava")
```

`Theme.extend` deep-merges tables, so `colors = { primary = ... }` keeps every other color from the base. Values that are not plain tables (Color3, Font, UDim, Vector2) are replaced whole. To remove a token the base sets (for example a click sound), set it to `Theme.None`.

## Templates

Seven starter themes ship with the kit, in `src/CoreUI/Theme/Themes/`:

| Template | Look |
| --- | --- |
| `Clean` | Flat and modern; the base every other theme extends |
| `Cartoony` | Thick outlines, two-tone buttons, outlined text, bouncy motion |
| `Dark` | Muted colors, hairline borders, quiet motion |
| `Candy` | Pastel pink and lilac, soft outlines, smooth gradients, springy |
| `Neon` | Navy glass, cyan and magenta glow lines, techy fonts, slide-in windows |
| `Wood` | Parchment panels, dark wood outlines, gold buttons, serif titles |
| `Pixel` | Square corners, chunky borders, 8-bit font, no easing |

## Saved themes

The plugin saves each theme as a `StringValue` of theme code in `ReplicatedStorage.CoreUIThemes`; the folder's `Active` attribute names the theme the game starts with. When the kit loads it registers every saved theme under its name and switches to the active one, unless your code already called `Theme.set`. So with a saved theme you can leave `Theme.set` out entirely, or switch between saved themes by name:

```lua
CoreUI.Theme.set("Lava") -- a theme saved from the plugin
```

Saved theme code only stores what differs from its template, so themes keep working when the kit adds new tokens. `Theme.loadSaved()` reloads the folder, and `Theme.Serialize` has the helpers the plugin uses (`toJSON`, `fromJSON`, `diff`, `toLuau`).

For a theme you will reuse, copy `src/CoreUI/Theme/Themes/Clean.luau` to a ModuleScript in your game, edit it, and register it with `Theme.register("MyTheme", require(path.MyTheme))`.

## Tokens

All tokens live in `Clean.luau`, with a comment on each group. In short:

| Group | What it controls |
| --- | --- |
| `colors` | Surfaces, text, strokes, action colors (`primary`, `secondary`, `buy`, `danger`, each with an `on…` text color), states (`success`, `warning`, `error`, `info`), `badge`, `overlay`, `track`, `selection`, and `rarity` (common to mythic). |
| `transparency` | Surface transparency, backdrop dimming, disabled state. |
| `fonts` | `display`, `heading`, `body`, `mono` as `Font` values. |
| `typography` | Text roles (`display`, `title`, `heading`, `label`, `body`, `caption`): which font, size in reference pixels, and whether the role is outlined. |
| `radius` | Corner radii `sm`, `md`, `lg`, `pill`. |
| `stroke` | Border thickness for panels and controls, and the text outline thickness (0 turns outlines off). |
| `shadow` | `soft` (faint offset), `lip` (solid darker base under buttons and panels) or `none`, plus offset and transparency. |
| `buttons` | Heights, widths and text sizes per button size; `fill` is `flat`, `twoTone` (hard stop) or `gradient` (smooth), with `highlight` setting how much lighter the top is. |
| `effects` | `panelGradient`: 0 for flat panels, up to about 0.4 for a sheen that lightens the top of each panel. |
| `spacing` | `xs` to `xl` gaps and padding. |
| `motion` | Durations, easing styles, hover and press scale; `openStyle` (`pop`, `slide` or `none`) and `openFrom` set how windows and dialogs appear. |
| `layout` | Reference resolution and min/max UI scale. |
| `sounds` | Asset ids for click, open, close, notify; `nil` is silent. |
| `images` | Optional 9-slice skins for panels, buttons and item slots: `{ Image = "rbxassetid://...", SliceCenter = Rect.new(...), SliceScale = 1 }`. A skin replaces the flat fill and border, which is how you get ornate, pixel or hand-drawn styles. |

## Sizing

Components are sized in reference pixels at `layout.referenceSize` (1100 x 620 by default, a landscape phone scaled up). Each ScreenGui layer has one UIScale set to `min(screen / reference)`, clamped to `minScale` and `maxScale`, so the whole UI grows and shrinks together and text stays readable on phones without ballooning on TVs.

## Using theme values in your own UI

```lua
local Theme = CoreUI.Theme
local Style = CoreUI.Util.Style

local frame = Instance.new("Frame")
Theme.bind(frame, function(theme)
	frame.BackgroundColor3 = theme.colors.surface
	Style.corner(frame, theme.radius.md)
	Style.stroke(frame, theme.stroke.panel, theme.colors.stroke)
end)
```

The function runs now and again on every theme change. It is released when the frame is destroyed.
