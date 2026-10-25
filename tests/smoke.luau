--[[
	Smoke test: starts the plugin against fake Studio services and clicks through it.
	Every kit screen gets built (game view), every editor tab gets built, and the
	save, load, rename, delete, share and install paths all run. This cannot show how
	anything looks; it catches crashes and wrong calls before Studio does.
]]

local H = require("./harness")
local Fakes = require("./fakes")
local roblox = H.roblox
local task = require("@lune/task")

H.reset()

local services = Fakes.services()
for name, service in services do
	H.setService(name, service)
end
local plugin = Fakes.plugin()
H.setGlobal("Instance", Fakes.Instance)
H.setGlobal("settings", Fakes.settings())
H.setGlobal("plugin", plugin)
H.setGlobal("DockWidgetPluginGuiInfo", {
	new = function()
		return {}
	end,
})
H.setGlobal("TweenInfo", {
	new = function()
		return {}
	end,
})
H.setGlobal("NumberSequence", roblox.NumberSequence)

local errors = {}
H.setGlobal("warn", function(...)
	table.insert(errors, table.concat({ ... }, " "))
end)

local pluginScript = H.script("src/Plugin")
local kitScript = H.script("src/CoreUI")
local demoScript = H.script("src/Demo/CoreUIDemo.client.luau")
rawset(kitScript, "Parent", pluginScript)
rawset(pluginScript, "CoreUI", kitScript)
rawset(pluginScript, "CoreUIDemo", demoScript)
rawset(demoScript, "Parent", pluginScript)
rawset(pluginScript, "FindFirstChild", function(self, name)
	return rawget(self, name)
end)
rawset(kitScript, "Clone", function()
	return Fakes.new("ModuleScript", { Name = "CoreUI", Source = 'Version = "0.2.0",' })
end)
rawset(demoScript, "Clone", function()
	return Fakes.new("LocalScript", { Name = "CoreUIDemo", Enabled = false })
end)
rawset(demoScript, "Name", "CoreUIDemo")

local function settle()
	for _ = 1, 3 do
		task.wait()
	end
end

print("Plugin smoke test")

-- Start the plugin and open its window.
H.require(pluginScript)
local widget = plugin.widget
assert(widget, "dock widget not created")

local App = H.require(pluginScript.App)
local app

H.test("plugin opens its window without errors", function()
	widget.Enabled = true
	settle()
	local root = widget:FindFirstChild("CoreUICustomizer")
	assert(root, "editor root missing; warnings: " .. table.concat(errors, " | "))
	assert(#errors == 0, table.concat(errors, " | "))
end)

-- Reach the App instance: open() created it; make another for direct calls.
app = App.new(plugin, Fakes.new("DockWidgetPluginGui", { AbsoluteSize = roblox.Vector2.new(400, 760) }), {
	kit = kitScript,
	demo = demoScript,
})
settle()

local Theme = H.require(kitScript.Theme)
local Store = H.require(pluginScript.Store)
local Schema = H.require(pluginScript.Schema)
local ReplicatedStorage = services.ReplicatedStorage

H.test("every tab builds its editors", function()
	for _, tab in Schema.tabs do
		app:_selectTab(tab.id)
	end
	settle()
	local count = 0
	for _, list in app.editors do
		count += #list
	end
	assert(count == #Schema.fields(), "built " .. count .. " of " .. #Schema.fields() .. " editors")
	assert(#errors == 0, table.concat(errors, " | "))
end)

H.test("every template loads and restyles the preview", function()
	for _, name in Theme.Templates do
		app:loadTemplate(name)
		settle()
		assert(Theme.get().colors.primary == Theme.find(name).colors.primary, name .. " not applied")
	end
	assert(#errors == 0, table.concat(errors, " | "))
end)

H.test("editing a template forks a copy and undo/redo work", function()
	app:loadTemplate("Neon")
	local before = app.theme.colors.primary
	app:set("colors.primary", roblox.Color3.fromRGB(1, 2, 3), true)
	settle()
	assert(app.name == "My Neon", "fork name " .. tostring(app.name))
	assert(not app.isTemplate and app.dirty)
	assert(Theme.find("Neon").colors.primary == before, "template was changed")
	assert(Theme.get().colors.primary == roblox.Color3.fromRGB(1, 2, 3), "preview not updated")
	app:undo()
	assert(app.theme.colors.primary == before, "undo")
	app:redo()
	assert(app.theme.colors.primary == roblox.Color3.fromRGB(1, 2, 3), "redo")
end)

H.test("each field type accepts a value", function()
	local samples = {
		{ "radius.md", roblox.UDim.new(0, 30) },
		{ "radius.pill", roblox.UDim.new(0, 0) },
		{ "stroke.panel", 6 },
		{ "typography.title.outline", false },
		{ "typography.title.font", "body" },
		{ "fonts.display", roblox.Font.new("rbxasset://fonts/families/Bangers.json") },
		{ "motion.easing", roblox.Enum.EasingStyle.Bounce },
		{ "motion.openStyle", "slide" },
		{ "buttons.fill", "gradient" },
		{ "effects.panelGradient", 0.3 },
		{ "shadow.style", "soft" },
		{ "layout.referenceSize", roblox.Vector2.new(1280, 720) },
		{ "sounds.click", "rbxassetid://12345" },
		{ "images.panel", { Image = "rbxassetid://1", SliceCenter = roblox.Rect.new(8, 8, 56, 56), SliceScale = 1 } },
		{ "images.button", { Image = "rbxassetid://2", SliceScale = 0.5 } },
	}
	for _, sample in samples do
		app:set(sample[1], sample[2], true)
		settle()
	end
	app.ctx.refresh()
	assert(#errors == 0, table.concat(errors, " | "))
end)

H.test("game view builds every kit screen and scene", function()
	app:_setGameView(true)
	settle()
	local Viewport = H.require(pluginScript.Preview.Viewport)
	for _, scene in Viewport.SCENES do
		app.viewport:Show(scene[2])
		settle()
	end
	app:_setGameView(false)
	settle()
	local guis = 0
	for _, child in services.CoreGui:GetChildren() do
		if string.find(child.Name, "CoreUICustomizer_", 1, true) then
			guis += 1
		end
	end
	assert(guis >= 5, "expected layer ScreenGuis in CoreGui, found " .. guis)
	assert(#errors == 0, table.concat(errors, " | "))
end)

H.test("preview pages and replay work", function()
	app.gallery:SetPage("cards")
	app.gallery:Replay()
	app.gallery:SetPage("controls")
	task.wait(0.5)
	assert(#errors == 0, table.concat(errors, " | "))
end)

H.test("saving writes theme code the kit can load, and marks it active", function()
	app:_writeSave("Lava")
	local folder = ReplicatedStorage:FindFirstChild(Theme.SAVED_FOLDER)
	assert(folder, "folder not created")
	local value = folder:FindFirstChild("Lava")
	assert(value and value.ClassName == "StringValue", "StringValue missing")
	assert(folder:GetAttribute("Active") == "Lava", "first save should become active")
	assert(not app.dirty and app.savedName == "Lava")
	local loaded = Theme.loadSaved(folder, false)
	assert(table.find(loaded, "Lava"), "kit could not load the saved theme")
	assert(Theme.find("Lava").radius.md.Offset == 30)
	assert(Theme.find("Lava").images.panel.SliceCenter == roblox.Rect.new(8, 8, 56, 56))
end)

H.test("saved themes list, copy, rename, activate and delete", function()
	app:_selectTab("themes")
	assert(Store.exists("Lava"))
	Store.write("Ice", Store.toRecord("Ice", "Clean", Theme.merge(Theme.find("Clean"))), false)
	assert(#Store.list() == 2)
	assert(Store.setActive("Ice"))
	assert(Store.active() == "Ice")
	assert(Store.rename("Ice", "Frost"))
	assert(Store.active() == "Frost", "rename keeps active")
	assert(app:loadSaved("Frost"))
	assert(Store.delete("Frost"))
	assert(Store.active() == nil)
	app:_selectTab("themes")
	assert(#errors == 0, table.concat(errors, " | "))
end)

H.test("template names are refused and duplicates get numbered", function()
	assert(not Store.validName("Cartoony"))
	assert(not Store.validName("   "))
	assert(Store.validName("Lava 2"))
	assert(Store.uniqueName("Lava") == "Lava 2")
end)

H.test("install kit, demo and export module", function()
	app:_installKit()
	local kit = ReplicatedStorage:FindFirstChild("CoreUI")
	assert(kit, "kit not installed")
	assert(Store.kitVersion() == "0.2.0", "version " .. tostring(Store.kitVersion()))
	assert(Store.installDemo(demoScript))
	local scripts = services.StarterPlayer:FindFirstChildOfClass("StarterPlayerScripts")
	local demo = scripts:FindFirstChild("CoreUIDemo")
	assert(demo and demo.Enabled == true, "demo not enabled after insert")
	assert(Store.exportModule(Store.toRecord("Lava", "Cartoony", app.theme)))
	local module = ReplicatedStorage:FindFirstChild("LavaTheme")
	assert(module and string.find(module.Source, "Theme.register", 1, true), "export missing")
	local ok, err = H.compile(module.Source, "LavaTheme")
	assert(ok, err)
end)

H.test("share code round-trips through paste", function()
	app:_showCode()
	app:_pasteCode()
	app.overlay:closeModal()
	assert(#errors == 0, table.concat(errors, " | "))
end)

H.test("dropdowns and the color picker open", function()
	app:_selectTab("colors")
	local root = app.root
	local opened = 0
	for _, descendant in root:GetDescendants() do
		if descendant.Name == "Swatch" and opened == 0 then
			descendant.Activated:Fire()
			opened += 1
		end
	end
	settle()
	assert(app.overlay._popover, "color picker did not open")
	app.overlay:closePopover()
	app:_selectTab("text")
	for _, descendant in root:GetDescendants() do
		if descendant.Name == "Dropdown" and descendant.Parent and descendant.Parent.Parent then
			descendant.Activated:Fire()
			break
		end
	end
	settle()
	assert(app.overlay._popover, "dropdown did not open")
	app.overlay:closePopover()
	assert(#errors == 0, table.concat(errors, " | "))
end)

H.test("slider drag goes through the overlay", function()
	app:_selectTab("shapes")
	local hit
	for _, descendant in app.root:GetDescendants() do
		if descendant.Name == "Hit" then
			hit = descendant
			break
		end
	end
	assert(hit, "no slider")
	hit.MouseButton1Down:Fire()
	local catcher = app.overlay.layer:FindFirstChild("Catcher")
	assert(catcher, "drag catcher missing")
	catcher.MouseButton1Up:Fire()
	settle()
	assert(#errors == 0, table.concat(errors, " | "))
end)

H.test("plugin unloads cleanly", function()
	plugin.Unloading:Fire()
	app:Destroy()
	settle()
	assert(#errors == 0, table.concat(errors, " | "))
end)

H.test("the demo place script runs every screen as a player would", function()
	H.reset()
	table.clear(errors)
	local player = Fakes.new("Player", { DisplayName = "Tester" })
	Fakes.new("PlayerGui").Parent = player
	services.Players.LocalPlayer = player
	ReplicatedStorage:ClearAllChildren()
	local kit = H.script("src/CoreUI")
	table.insert(rawget(ReplicatedStorage, "_data").children, kit)
	H.require(H.script("src/Demo/CoreUIDemo.client.luau"))
	task.wait(2)
	local Manager = H.require(kit.Manager)
	for _, id in { "Shop", "Inventory", "DailyRewards", "Codes", "Settings" } do
		Manager.open(id)
		settle()
		assert(Manager.isOpen(id), id .. " did not open")
	end
	Manager.close()
	local Theme = H.require(kit.Theme)
	for _, name in Theme.Templates do
		Theme.set(name)
		settle()
	end
	local guis = player.PlayerGui:GetChildren()
	assert(#guis >= 5, "expected layer ScreenGuis in PlayerGui, found " .. #guis)
	assert(#errors == 0, table.concat(errors, " | "))
end)

return H.finish()
