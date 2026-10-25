# Core UI Customizer (Studio plugin)

A Studio plugin for designing Core UI themes without writing code. Pick a template, change colors, shapes, fonts, effects, motion, sounds and 9-slice skins with a live preview, then save the theme into your place. When the game runs, the Core UI kit loads the saved theme by itself.

## Install

**From a build file.** Get `CoreUICustomizer.rbxm` (from a GitHub Actions run of this repo, or build it yourself below). In Studio, open the **Plugins** tab, click **Plugins Folder**, and drop the file in. Studio picks it up right away; if not, restart Studio.

**With Rojo**, straight into your plugins folder:

```sh
rojo build plugin.project.json --plugin CoreUICustomizer.rbxm
```

A **Core UI** section with a **Customizer** button appears in the Plugins tab. Click it to open the window; it docks on the right and you can drag it anywhere.

The first time you install the kit, insert the demo or export a theme as a ModuleScript, Studio asks whether the plugin may add scripts (**Script Injection**). Allow it; you can change this later in **Plugins > Manage Plugins**.

## Using it

The window has four parts: the theme name with **undo**, **redo** and **Save** at the top, a live preview, the tabs, and the editor for the selected tab.

1. **Themes tab.** Pick a template with **Use template**. Templates never change: your first edit starts a copy called "My (template)". This tab also lists the themes saved in this place, sets which one is **active** (the one the game starts with), and has the setup and sharing buttons.
2. **Colors.** Click a swatch to open the picker (drag the square and hue bar, type hex or RGB, or reuse the theme's own colors and your recent ones), or type a hex code straight into the box.
3. **Shapes.** Corner radii, pill shape, border and text-outline thickness, button sizes, spacing, and how the UI scales across screen sizes.
4. **Fonts.** The four font families (any built-in Roblox font, or **Custom** for a Creator Store font id), with weight and italic, and per-role size, font and outline for titles, headings, labels, body and captions.
5. **Effects.** Shadow style (none, soft drop shadow, solid 3D lip), depth and transparency; button fill (flat, two-tone, smooth gradient) and highlight; panel sheen; surface transparency.
6. **Motion.** Window open animation (pop, slide up, none), hover and press scale, speeds and easing. **▶ Replay** in the preview bar plays the window animation again; the preview's close button does too.
7. **Sounds & Skins.** Click, open, close and notification sounds (asset ids, with a ▶ test button) and volume; optional 9-slice images for panels, buttons and item slots.

Press **Save** (or Ctrl+Z in Studio to undo a save). The first theme you save becomes the active one.

### Previews

- The **preview** in the window is made of the kit's real components. Switch between **Controls** and **Shop cards** with the dropdown under it.
- **Game view** puts the kit's real screens over the 3D view at true size: HUD, Shop, Inventory, Settings, Daily rewards, Codes, Dialog, Notifications, Main menu and Loading screen. They are clickable and restyle as you edit. They live in CoreGui, so they are never saved into your place, and they hide when you close the window.

### Game setup

On the Themes tab:

- **Install kit** copies the Core UI kit bundled in the plugin to `ReplicatedStorage.CoreUI`. When the plugin carries a newer kit than the place, the button says **Update kit**. Saved themes are kept.
- **Insert demo** adds a LocalScript to StarterPlayerScripts that builds every screen with sample data. Press Play to try your theme in a real session, then delete the script.

To use the kit in your own game, require it from a LocalScript; see the README. If you saved a theme with the plugin you do not need to call `Theme.set` at all.

### Sharing and export

- **Copy code** shows the theme as one line of text. Paste it into **Paste code** in another place (or send it to someone) to get the same theme.
- **Export Luau** writes the theme as a ModuleScript in ReplicatedStorage, for people who prefer themes in code. Requiring it registers the theme.

## Where things are saved

| What | Where |
| --- | --- |
| Saved themes | `ReplicatedStorage.CoreUIThemes`, one StringValue per theme; the folder's `Active` attribute names the active one |
| The kit | `ReplicatedStorage.CoreUI` |
| Demo script | `StarterPlayer.StarterPlayerScripts.CoreUIDemo` |
| Exported theme | `ReplicatedStorage.<Name>Theme` |
| Plugin preferences (last tab, recent colors) | Studio plugin settings, not the place |

Every change the plugin makes to the place is a single undo step.

## Studio test checklist

Run through this after installing a new build:

1. Open a new Baseplate. Click **Customizer**: the window opens with the Clean template and a preview.
2. Themes tab: click **Use template** on each of the seven templates; the preview restyles each time.
3. Change a color with the picker (drag the square), then a corner radius slider, then a font. The header shows "My (template) ● unsaved"; undo and redo step back and forth.
4. Turn on **Game view**, then pick each scene from the dropdown. Click HUD buttons to open windows. Edits restyle the screens live.
5. Press **Save**, name the theme, then **Install kit** when asked. Check `ReplicatedStorage` has `CoreUI` and `CoreUIThemes`.
6. **Insert demo** and press Play: every screen uses your theme. In the demo's Settings, the Theme choice lists your saved theme.
7. Back in Edit mode: rename, copy, make active and delete saved themes; Ctrl+Z brings a deleted one back.
8. **Copy code**, open another place, **Paste code**: the theme matches.
9. Switch Studio between light and dark (File > Studio Settings > Theme): the plugin window follows.

## Publishing on the Creator Store

1. Build the plugin and insert it into an empty place (drag `CoreUICustomizer.rbxm` into the Explorer under ServerStorage).
2. Right-click the `CoreUICustomizer` script and choose **Publish as Plugin...**. Give it a name, description and icon.
3. Finish the listing on the Creator Hub: thumbnails (screenshots of the window and of Game view work well), description, and price. Check Roblox's current seller requirements for paid plugins first; they change from time to time.
4. To ship an update, publish the same way and choose to overwrite the existing plugin.

The toolbar button has no icon yet. Upload a 32 x 32 image, then put its `rbxassetid://` id in the `toolbar:CreateButton` call in `src/Plugin/init.server.luau`.

## How the plugin is built

```
src/Plugin/
  init.server.luau   toolbar button, dock window, start and stop
  App.luau           the window: header, preview, tabs, Themes tab, saving
  Schema.luau        every editable token: tab, section, label, control type
  Store.luau         reading and writing the place (themes, kit, demo, export)
  UI/                Studio-styled controls, color picker, field editors, popovers
  Preview/           Gallery (in-window preview) and Viewport (game view)
```

The plugin bundles its own copy of the kit (`plugin.project.json` mounts `src/CoreUI` inside it), so the preview always matches the kit it installs. To expose a new theme token in the editor, add one line to `Schema.luau`; the tests fail if a token in `Clean.luau` has no editor.
