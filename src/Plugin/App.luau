--[[
	The customizer window: header (theme name, undo, redo, save), live preview,
	tabs, the editor page for the selected tab, and a status line.

	The theme being edited is a full theme table. Every change goes through
	App:set(path, value), which applies it to the plugin's copy of the kit (so the
	preview and the game-view screens restyle at once) and records undo steps.
	Saving stores only the difference from the template it started from.
]]

local SoundService = game:GetService("SoundService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local CoreUI = require(script.Parent.CoreUI)
local Theme = CoreUI.Theme
local Serialize = Theme.Serialize
local Create = CoreUI.Util.Create

local Schema = require(script.Parent.Schema)
local Store = require(script.Parent.Store)
local Studio = require(script.Parent.UI.Studio)
local Controls = require(script.Parent.UI.Controls)
local Overlay = require(script.Parent.UI.Overlay)
local Fields = require(script.Parent.UI.Fields)
local Gallery = require(script.Parent.Preview.Gallery)
local Viewport = require(script.Parent.Preview.Viewport)

local App = {}
App.__index = App

local HEADER = 38
local PREVIEW = 236
local TOOLBAR = 30
local TABS = 62
local STATUS = 24
local UNDO_LIMIT = 60
-- Changes to the same token closer together than this are one undo step (slider drags).
local UNDO_MERGE_SECONDS = 0.6

local TEMPLATE_INFO = {
	Clean = "Flat and modern. A neutral start for any game.",
	Cartoony = "Thick outlines, two-tone buttons, bouncy. Simulator style.",
	Dark = "Muted, hairline borders, quiet motion. Horror and story.",
	Candy = "Pastel pinks, soft outlines, springy. Pets and roleplay.",
	Neon = "Navy glass with cyan glow lines. Sci-fi and racing.",
	Wood = "Parchment, dark wood and gold. Fantasy and RPG.",
	Pixel = "Square corners and an 8-bit font. Retro and arcade.",
}

local function copyTheme(theme: any): any
	return Theme.merge(theme)
end

function App.new(plugin: Plugin, widget: PluginGui, bundled: { [string]: Instance })
	local self = setmetatable({}, App)
	self.plugin = plugin
	self.widget = widget
	self.bundled = bundled
	self.undoStack = {}
	self.redoStack = {}
	self.editors = {}
	self.pages = {}
	self._lastSetPath = nil
	self._lastSetTime = 0

	self.root = Create("Frame", {
		Name = "CoreUICustomizer",
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = widget,
	})
	Studio.bind(self.root, function(c)
		self.root.BackgroundColor3 = c.background
	end)
	self.overlay = Overlay.new(self.root, widget)

	self.ctx = {
		overlay = self.overlay,
		get = function(path)
			return Schema.get(self.theme, path)
		end,
		set = function(path, value, final)
			self:set(path, value, final)
		end,
		theme = function()
			return self.theme
		end,
		recentColors = function()
			return self:_recentColors()
		end,
		addRecentColor = function(color)
			self:_addRecentColor(color)
		end,
		playSound = function(id)
			self:_playSound(id)
		end,
		refresh = function()
			self:_refreshEditors()
		end,
	}

	self.viewport = Viewport.new()
	self:_buildHeader()
	self:_buildPreview()
	self:_buildTabs()
	self:_buildStatus()

	self:_loadInitialTheme()
	self:_selectTab(self:_setting("tab", "themes"))

	self._undoConnections = {
		ChangeHistoryService.OnUndo:Connect(function()
			self:_onPlaceChanged()
		end),
		ChangeHistoryService.OnRedo:Connect(function()
			self:_onPlaceChanged()
		end),
	}
	return self
end

-- Settings remembered between Studio sessions ---------------------------------------

function App:_setting(key: string, default: any): any
	local ok, value = pcall(self.plugin.GetSetting, self.plugin, "CoreUICustomizer_" .. key)
	if ok and value ~= nil then
		return value
	end
	return default
end

function App:_saveSetting(key: string, value: any)
	pcall(self.plugin.SetSetting, self.plugin, "CoreUICustomizer_" .. key, value)
end

function App:_recentColors(): { Color3 }
	local list = {}
	for _, hex in self:_setting("recentColors", {}) do
		local color = CoreUI.Util.Color.fromHex(hex)
		if color then
			table.insert(list, color)
		end
	end
	return list
end

function App:_addRecentColor(color: Color3)
	local hex = CoreUI.Util.Color.toHex(color)
	local list = { hex }
	for _, existing in self:_setting("recentColors", {}) do
		if existing ~= hex and #list < 10 then
			table.insert(list, existing)
		end
	end
	self:_saveSetting("recentColors", list)
end

-- Layout ----------------------------------------------------------------------------

function App:_buildHeader()
	local header = Create("Frame", {
		Name = "Header",
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, HEADER),
		Parent = self.root,
	})
	Studio.bind(header, function(c)
		header.BackgroundColor3 = c.header
	end)
	self._title = Controls.label({
		Text = "",
		Bold = true,
		TextSize = 15,
		RichText = true,
		Size = UDim2.new(1, -170, 1, 0),
		Position = UDim2.fromOffset(10, 0),
		Parent = header,
	})
	local buttons = Create("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(160, 26),
		Parent = header,
	})
	local layout = Controls.list(buttons, 4, true)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	self._undoButton = Controls.button("↶", {
		Width = 28,
		Height = 26,
		TextSize = 16,
		LayoutOrder = 1,
		Parent = buttons,
		OnClick = function()
			self:undo()
		end,
	})
	self._redoButton = Controls.button("↷", {
		Width = 28,
		Height = 26,
		TextSize = 16,
		LayoutOrder = 2,
		Parent = buttons,
		OnClick = function()
			self:redo()
		end,
	})
	self._saveButton = Controls.button("Save", {
		Style = "primary",
		Width = 64,
		Height = 26,
		LayoutOrder = 3,
		Parent = buttons,
		OnClick = function()
			self:save(false)
		end,
	})
end

function App:_buildPreview()
	local area = Create("Frame", {
		Name = "Preview",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, HEADER),
		Size = UDim2.new(1, 0, 0, PREVIEW),
		Parent = self.root,
	})
	local holder = Create("Frame", {
		Name = "Holder",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -TOOLBAR),
		Parent = area,
	})
	self.gallery = Gallery.new(holder)
	self.gallery:SetPage(self:_setting("previewPage", "controls"))

	local toolbar = Create("Frame", {
		Name = "Toolbar",
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -TOOLBAR),
		Size = UDim2.new(1, 0, 0, TOOLBAR),
		Parent = area,
	})
	Studio.bind(toolbar, function(c)
		toolbar.BackgroundColor3 = c.header
	end)
	Controls.padding(toolbar, 3, 6, 3, 6)
	Controls.list(toolbar, 6, true)

	Fields.dropdown(self.ctx, toolbar, Gallery.PAGES, function()
		return self.gallery.Page
	end, function(page)
		self.gallery:SetPage(page)
		self:_saveSetting("previewPage", page)
	end, { Size = UDim2.fromOffset(96, 24), LayoutOrder = 1 })

	Controls.button("▶ Replay", {
		Height = 24,
		LayoutOrder = 2,
		Parent = toolbar,
		OnClick = function()
			self.gallery:Replay()
		end,
	})

	Create("Frame", {
		Name = "Spacer",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(4, 1),
		LayoutOrder = 3,
		Parent = toolbar,
	})

	self._gameViewButton = Controls.button("Game view: off", {
		Height = 24,
		LayoutOrder = 4,
		Parent = toolbar,
		OnClick = function()
			self:_setGameView(not self.viewport.Enabled)
		end,
	})
	self._sceneDropdown = Fields.dropdown(self.ctx, toolbar, Viewport.SCENES, function()
		return self.viewport.Scene
	end, function(scene)
		self:_saveSetting("scene", scene)
		if not self.viewport.Enabled then
			self:_setGameView(true)
		end
		self.viewport:Show(scene)
	end, { Size = UDim2.fromOffset(110, 24), LayoutOrder = 5, MinWidth = 140 })
end

function App:_setGameView(enabled: boolean)
	if enabled then
		self.viewport.Scene = self:_setting("scene", "hud")
	end
	local ok, err = pcall(function()
		self.viewport:SetEnabled(enabled)
	end)
	if not ok then
		self:status("Game view failed: " .. tostring(err), "error")
		return
	end
	self._gameViewButton.Text = if enabled then "Game view: on" else "Game view: off"
	if enabled then
		self:status("Showing the kit over the 3D view. It is never saved into the place.")
	end
end

function App:_buildTabs()
	local bar = Create("Frame", {
		Name = "Tabs",
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, HEADER + PREVIEW),
		Size = UDim2.new(1, 0, 0, TABS),
		Parent = self.root,
	})
	Studio.bind(bar, function(c)
		bar.BackgroundColor3 = c.background
	end)
	Controls.padding(bar, 6, 6, 4, 6)
	Create("UIGridLayout", {
		CellSize = UDim2.new(0.25, -4, 0, 24),
		CellPadding = UDim2.fromOffset(4, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = bar,
	})
	self._tabButtons = {}
	for index, tab in Schema.tabs do
		local button = Controls.button(tab.label, {
			Style = "ghost",
			LayoutOrder = index,
			Parent = bar,
			OnClick = function()
				self:_selectTab(tab.id)
			end,
		})
		self._tabButtons[tab.id] = button
	end

	self.pageHolder = Create("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, HEADER + PREVIEW + TABS),
		Size = UDim2.new(1, 0, 1, -(HEADER + PREVIEW + TABS + STATUS)),
		Parent = self.root,
	})
end

function App:_buildStatus()
	local bar = Create("Frame", {
		Name = "Status",
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -STATUS),
		Size = UDim2.new(1, 0, 0, STATUS),
		Parent = self.root,
	})
	Studio.bind(bar, function(c)
		bar.BackgroundColor3 = c.header
	end)
	self._status = Controls.label({
		Text = "",
		TextSize = 12,
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		Parent = bar,
	})
end

-- kind: "info" | "success" | "warning" | "error"
function App:status(text: string, kind: string?)
	local label = self._status
	label.Text = text
	label.TextColor3 = Studio.colors[if kind == "error"
		then "error"
		elseif kind == "warning" then "warning"
		elseif kind == "success" then "accent"
		else "dim"]
	local token = {}
	self._statusToken = token
	task.delay(8, function()
		if self._statusToken == token and label.Parent then
			label.Text = ""
		end
	end)
end

function App:_newPage(id: string): ScrollingFrame
	local page = Create("ScrollingFrame", {
		Name = "Page_" .. id,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 8,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		Visible = false,
		Parent = self.pageHolder,
	})
	Studio.bind(page, function(c)
		page.ScrollBarImageColor3 = c.scrollBar
	end)
	Controls.list(page, 2)
	return page
end

function App:_selectTab(id: string)
	local tab = nil
	for _, candidate in Schema.tabs do
		if candidate.id == id then
			tab = candidate
		end
	end
	if not tab then
		tab = Schema.tabs[1]
		id = tab.id
	end
	self.currentTab = id
	self:_saveSetting("tab", id)
	self.overlay:closePopover()

	for tabId, button in self._tabButtons do
		button:SetAttribute("Selected", tabId == id)
	end

	if id == "themes" then
		if self.pages.themes then
			self.pages.themes:Destroy()
		end
		self.pages.themes = self:_newPage("themes")
		self:_buildThemesPage(self.pages.themes)
	elseif not self.pages[id] then
		local page = self:_newPage(id)
		self.pages[id] = page
		local editors = {}
		for index, section in tab.sections do
			local _, content = Controls.section(page, section.title, {
				Collapsed = section.collapsed,
				Hint = section.hint,
				LayoutOrder = index,
			})
			for order, field in section.fields do
				table.insert(editors, Fields.build(self.ctx, content, field, order))
			end
		end
		self.editors[id] = editors
	end
	for pageId, page in self.pages do
		page.Visible = pageId == id
	end
end

function App:_refreshEditors()
	for _, list in self.editors do
		for _, editor in list do
			pcall(editor.refresh)
		end
	end
end

function App:_onPlaceChanged()
	if self.currentTab == "themes" then
		self:_selectTab("themes")
	end
end

-- The theme being edited ------------------------------------------------------------

function App:_updateHeader()
	local name = self.name or "?"
	local note
	if self.isTemplate then
		note = '<font transparency="0.4">template (edits make a copy)</font>'
	elseif self.dirty then
		note = '<font color="#FFB000">● unsaved</font>'
	else
		note = '<font transparency="0.4">saved</font>'
	end
	self._title.Text = name .. "  " .. note
	self._undoButton:SetAttribute("Enabled", #self.undoStack > 0)
	self._redoButton:SetAttribute("Enabled", #self.redoStack > 0)
end

function App:_apply()
	if self._applyQueued then
		return
	end
	self._applyQueued = true
	task.defer(function()
		self._applyQueued = false
		self.theme.name = self.name
		local ok, err = pcall(Theme.set, self.theme)
		if not ok then
			self:status("Preview failed: " .. tostring(err), "error")
		end
	end)
end

--[[
	Switch the editor to a theme.
	savedName: the saved theme this came from, if any (saving goes back to it).
]]
function App:_load(name: string, base: string, theme: any, options: { [string]: any }?)
	local o = options or {}
	self.name = name
	self.base = if Theme.isTemplate(base) then base else "Clean"
	self.theme = theme
	self.isTemplate = o.template == true
	self.savedName = o.savedName
	self.dirty = o.dirty == true
	table.clear(self.undoStack)
	table.clear(self.redoStack)
	self._lastSetPath = nil
	self:_apply()
	self:_refreshEditors()
	self:_updateHeader()
	self:_saveSetting("lastTheme", if self.savedName then self.savedName else nil)
end

function App:loadTemplate(name: string)
	self:_load(name, name, copyTheme(Theme.find(name)), { template = true })
	self:status("Previewing the " .. name .. " template. Change anything to start your own copy.")
end

function App:loadSaved(name: string): boolean
	local record, problem = Store.read(name)
	if not record then
		self:status("Could not open " .. name .. ": " .. tostring(problem), "error")
		return false
	end
	local base = if Theme.isTemplate(record.base) then record.base else "Clean"
	self:_load(name, base, Theme.extend(base, record.overrides), { savedName = name })
	return true
end

function App:_loadInitialTheme()
	local active = Store.active()
	if active and Store.exists(active) and self:loadSaved(active) then
		return
	end
	local last = self:_setting("lastTheme", nil)
	if type(last) == "string" and Store.exists(last) and self:loadSaved(last) then
		return
	end
	self:loadTemplate("Clean")
end

function App:_pushUndo()
	table.insert(self.undoStack, copyTheme(self.theme))
	if #self.undoStack > UNDO_LIMIT then
		table.remove(self.undoStack, 1)
	end
	table.clear(self.redoStack)
end

-- Change one token. final = false while a slider or picker is still being dragged.
function App:set(path: string, value: any, _final: boolean?)
	if self.isTemplate then
		-- Templates stay untouched: the first edit starts a copy.
		self.isTemplate = false
		self.name = Store.uniqueName("My " .. self.base)
		self.savedName = nil
		self:status("Started " .. self.name .. " from the " .. self.base .. " template. Press Save to keep it.")
	end
	local now = os.clock()
	if path ~= self._lastSetPath or now - self._lastSetTime > UNDO_MERGE_SECONDS then
		self:_pushUndo()
	end
	self._lastSetPath = path
	self._lastSetTime = now

	Schema.set(self.theme, path, value)
	self.dirty = true
	self:_apply()
	self:_updateHeader()
end

function App:undo()
	local previous = table.remove(self.undoStack)
	if not previous then
		return
	end
	table.insert(self.redoStack, copyTheme(self.theme))
	self.theme = previous
	self.dirty = true
	self._lastSetPath = nil
	self:_apply()
	self:_refreshEditors()
	self:_updateHeader()
end

function App:redo()
	local nextTheme = table.remove(self.redoStack)
	if not nextTheme then
		return
	end
	table.insert(self.undoStack, copyTheme(self.theme))
	self.theme = nextTheme
	self.dirty = true
	self._lastSetPath = nil
	self:_apply()
	self:_refreshEditors()
	self:_updateHeader()
end

function App:_record(): any
	return Store.toRecord(self.name, self.base, self.theme)
end

-- Saving ------------------------------------------------------------------------------

function App:_writeSave(name: string)
	local makeActive = Store.active() == nil
	local record = Store.toRecord(name, self.base, self.theme)
	local ok, err = Store.write(name, record, makeActive)
	if not ok then
		self:status("Save failed: " .. tostring(err), "error")
		return
	end
	self.name = name
	self.savedName = name
	self.isTemplate = false
	self.dirty = false
	self:_updateHeader()
	self:_saveSetting("lastTheme", name)
	local active = Store.active() == name
	self:status(
		"Saved "
			.. name
			.. " to ReplicatedStorage."
			.. Theme.SAVED_FOLDER
			.. (
				if active
					then ". It is the game's active theme."
					else ". Make it active on the Themes tab to use it in game."
			),
		"success"
	)
	if self.currentTab == "themes" then
		self:_selectTab("themes")
	end
	if not Store.kitVersion() then
		self.overlay:confirm(
			"Install the Core UI kit?",
			"Your theme is saved, but this place doesn't have the Core UI kit yet. Install it into ReplicatedStorage now?",
			"Install kit",
			function()
				self:_installKit()
			end
		)
	end
end

function App:save(saveAs: boolean)
	if self.isTemplate and not saveAs then
		-- Saving an untouched template still makes a named copy.
		saveAs = true
	end
	if not saveAs and self.savedName == self.name then
		self:_writeSave(self.name)
		return
	end
	local suggested = if self.isTemplate then Store.uniqueName("My " .. self.base) else self.name
	self.overlay:modal({
		Title = "Save theme",
		Message = "Name this theme. It is saved in this place, under ReplicatedStorage." .. Theme.SAVED_FOLDER .. ".",
		Input = { Text = suggested, Placeholder = "Theme name", SelectAll = true },
		Buttons = {
			{ Text = "Cancel" },
			{
				Text = "Save",
				Style = "primary",
				OnClick = function(text)
					local name = string.match(text or "", "^%s*(.-)%s*$") or ""
					local valid, problem = Store.validName(name)
					if not valid then
						self:status(problem :: string, "warning")
						return true
					end
					if Store.exists(name) and name ~= self.savedName then
						task.defer(function()
							self.overlay:confirm(
								"Replace " .. name .. "?",
								"A saved theme with this name already exists in this place.",
								"Replace",
								function()
									self:_writeSave(name)
								end,
								true
							)
						end)
						return false
					end
					self:_writeSave(name)
					return false
				end,
			},
		},
	})
end

-- Themes tab --------------------------------------------------------------------------

local function swatchStrip(parent: Instance, theme: any, order: number)
	local strip = Create("Frame", {
		Name = "Swatches",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(5 * 16 + 4 * 2, 16),
		LayoutOrder = order,
		Parent = parent,
	})
	Controls.list(strip, 2, true)
	for index, key in { "background", "surface", "primary", "secondary", "buy" } do
		local swatch = Controls.swatch(theme.colors[key], 16, { LayoutOrder = index, Parent = strip })
		swatch.Active = false
	end
	return strip
end

function App:_themeCard(parent: Instance, order: number, title: string, subtitle: string, theme: any?): (Frame, Frame)
	local card = Create("Frame", {
		Name = "Card_" .. title,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = parent,
	})
	Controls.corner(card, 4)
	Controls.stroke(card)
	Controls.padding(card, 8)
	Controls.list(card, 4)
	Studio.bind(card, function(c)
		card.BackgroundColor3 = c.section
	end)
	local top = Create("Frame", {
		Name = "Top",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 1,
		Parent = card,
	})
	Controls.label({
		Text = title,
		Bold = true,
		RichText = true,
		Size = UDim2.new(1, -96, 1, 0),
		Parent = top,
	})
	if theme then
		local strip = swatchStrip(top, theme, 2)
		strip.AnchorPoint = Vector2.new(1, 0)
		strip.Position = UDim2.new(1, 0, 0, 2)
	end
	if subtitle ~= "" then
		Controls.label({
			Text = subtitle,
			Dim = true,
			Wrap = true,
			TextSize = 12,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Parent = card,
		})
	end
	local actions = Create("Frame", {
		Name = "Actions",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 3,
		Parent = card,
	})
	Controls.list(actions, 4, true)
	return card, actions
end

function App:_buildThemesPage(page: ScrollingFrame)
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	-- Saved themes.
	local savedThemes = Store.list()
	local _, saved = Controls.section(page, "Saved in this place", {
		LayoutOrder = nextOrder(),
		Hint = if #savedThemes == 0
			then "Nothing saved yet. Pick a template below, change anything, then press Save."
			else "The active theme is the one your game starts with.",
	})
	for index, entry in savedThemes do
		local record = Store.read(entry.name)
		local preview = if record and Theme.find(record.base) then Theme.extend(record.base, record.overrides) else nil
		local editing = self.savedName == entry.name
		local title = entry.name
			.. (if entry.active then '  <font color="#00A2FF">ACTIVE</font>' else "")
			.. (if editing then '  <font transparency="0.4">(editing)</font>' else "")
		local subtitle = if record then "Based on " .. record.base else "Damaged theme code"
		local _, actions = self:_themeCard(saved, index, title, subtitle, preview)
		local name = entry.name
		Controls.button("Edit", {
			Style = "primary",
			Height = 22,
			LayoutOrder = 1,
			Parent = actions,
			OnClick = function()
				self:_confirmDiscard(function()
					if self:loadSaved(name) then
						self:status("Editing " .. name .. ".")
						self:_selectTab("themes")
					end
				end)
			end,
		})
		if not entry.active then
			Controls.button("Make active", {
				Height = 22,
				LayoutOrder = 2,
				Parent = actions,
				OnClick = function()
					local ok, err = Store.setActive(name)
					self:status(
						if ok then name .. " is now the game's active theme." else tostring(err),
						if ok then "success" else "error"
					)
					self:_selectTab("themes")
				end,
			})
		end
		Controls.button("Rename", {
			Height = 22,
			LayoutOrder = 3,
			Parent = actions,
			OnClick = function()
				self:_renameSaved(name)
			end,
		})
		Controls.button("Copy", {
			Height = 22,
			LayoutOrder = 4,
			Parent = actions,
			OnClick = function()
				local copyRecord = Store.read(name)
				if copyRecord then
					local newName = Store.uniqueName(name .. " copy")
					copyRecord.name = newName
					Store.write(newName, copyRecord, false)
					self:status("Copied to " .. newName .. ".", "success")
					self:_selectTab("themes")
				end
			end,
		})
		Controls.button("Delete", {
			Style = "danger",
			Height = 22,
			LayoutOrder = 5,
			Parent = actions,
			OnClick = function()
				self.overlay:confirm("Delete " .. name .. "?", "Ctrl+Z in Studio brings it back.", "Delete", function()
					Store.delete(name)
					if self.savedName == name then
						self.savedName = nil
						self.dirty = true
						self:_updateHeader()
					end
					self:status("Deleted " .. name .. ".")
					self:_selectTab("themes")
				end, true)
			end,
		})
	end

	-- Templates.
	local _, templates = Controls.section(page, "Templates", {
		LayoutOrder = nextOrder(),
		Hint = "Start from one of these. Templates never change; your edits go into a copy.",
	})
	for index, name in Theme.Templates do
		local current = self.isTemplate and self.name == name
		local title = name .. (if current then '  <font transparency="0.4">(previewing)</font>' else "")
		local _, actions = self:_themeCard(templates, index, title, TEMPLATE_INFO[name] or "", Theme.find(name))
		Controls.button("Use template", {
			Style = if current then "secondary" else "primary",
			Height = 22,
			LayoutOrder = 1,
			Parent = actions,
			OnClick = function()
				self:_confirmDiscard(function()
					self:loadTemplate(name)
					self:_selectTab("themes")
				end)
			end,
		})
	end

	-- Kit and demo.
	local version = Store.kitVersion()
	local bundledVersion = CoreUI.Version
	local kitText
	if not version then
		kitText = "The Core UI kit is not in this place yet. Install it to use your themes in game."
	elseif version ~= bundledVersion then
		kitText = "Installed kit: v" .. version .. ". This plugin has v" .. bundledVersion .. "."
	else
		kitText = "Core UI kit v" .. version .. " is installed in ReplicatedStorage."
	end
	local _, setup = Controls.section(page, "Game setup", { LayoutOrder = nextOrder(), Hint = kitText })
	local setupRow = Create("Frame", {
		Name = "SetupButtons",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 1,
		Parent = setup,
	})
	Controls.list(setupRow, 6, true)
	Controls.button(
		if not version then "Install kit" elseif version ~= bundledVersion then "Update kit" else "Reinstall kit",
		{
			Style = if version == bundledVersion then "secondary" else "primary",
			Height = 24,
			LayoutOrder = 1,
			Parent = setupRow,
			OnClick = function()
				if version then
					self.overlay:confirm(
						"Replace the kit?",
						"ReplicatedStorage.CoreUI will be replaced with v"
							.. bundledVersion
							.. ". Edits you made inside the kit's own scripts are lost (Ctrl+Z undoes this). Saved themes are kept.",
						"Replace",
						function()
							self:_installKit()
						end
					)
				else
					self:_installKit()
				end
			end,
		}
	)
	local demo = self.bundled.demo
	if demo then
		Controls.button(if Store.hasDemo(demo.Name) then "Reinsert demo" else "Insert demo", {
			Height = 24,
			LayoutOrder = 2,
			Parent = setupRow,
			OnClick = function()
				local ok, err = Store.installDemo(demo :: LocalScript)
				if ok then
					self:status("Demo added to StarterPlayerScripts. Press Play to try every screen.", "success")
					if not Store.kitVersion() then
						self:_installKit()
					end
				else
					self:_scriptError(err)
				end
				self:_selectTab("themes")
			end,
		})
	end

	-- Sharing.
	local _, share = Controls.section(page, "Share and export", {
		LayoutOrder = nextOrder(),
		Hint = "Theme code is a line of text you can paste into another place or send to a friend.",
	})
	local shareRow = Create("Frame", {
		Name = "ShareButtons",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = 1,
		Parent = share,
	})
	Controls.list(shareRow, 6, true)
	Controls.button("Copy code", {
		Height = 24,
		LayoutOrder = 1,
		Parent = shareRow,
		OnClick = function()
			self:_showCode()
		end,
	})
	Controls.button("Paste code", {
		Height = 24,
		LayoutOrder = 2,
		Parent = shareRow,
		OnClick = function()
			self:_pasteCode()
		end,
	})
	Controls.button("Export Luau", {
		Height = 24,
		LayoutOrder = 3,
		Parent = shareRow,
		OnClick = function()
			local ok, err = Store.exportModule(self:_record())
			if ok then
				self:status("Exported as a ModuleScript in ReplicatedStorage.", "success")
			else
				self:_scriptError(err)
			end
		end,
	})
end

function App:_scriptError(err: string?)
	self.overlay:alert(
		"Studio blocked the script",
		"Plugins need permission to add scripts. Allow <b>Script Injection</b> for Core UI Customizer when Studio asks, or in Plugins > Manage Plugins, then try again.\n\n"
			.. tostring(err)
	)
end

function App:_installKit()
	local kit = self.bundled.kit
	local ok, err = Store.installKit(kit :: ModuleScript)
	if ok then
		self:status("Core UI kit v" .. CoreUI.Version .. " installed in ReplicatedStorage.", "success")
	else
		self:_scriptError(err)
	end
	if self.currentTab == "themes" then
		self:_selectTab("themes")
	end
end

function App:_confirmDiscard(proceed: () -> ())
	if not self.dirty then
		proceed()
		return
	end
	self.overlay:confirm(
		"Discard unsaved changes?",
		self.name .. " has changes that are not saved.",
		"Discard",
		proceed,
		true
	)
end

function App:_renameSaved(name: string)
	self.overlay:modal({
		Title = "Rename " .. name,
		Input = { Text = name, Placeholder = "New name", SelectAll = true },
		Buttons = {
			{ Text = "Cancel" },
			{
				Text = "Rename",
				Style = "primary",
				OnClick = function(text)
					local newName = string.match(text or "", "^%s*(.-)%s*$") or ""
					if newName == name then
						return false
					end
					local valid, problem = Store.validName(newName)
					if not valid or Store.exists(newName) then
						self:status(problem or (newName .. " already exists."), "warning")
						return true
					end
					local ok, err = Store.rename(name, newName)
					if not ok then
						self:status(tostring(err), "error")
						return false
					end
					if self.savedName == name then
						self.savedName = newName
						self.name = newName
						self:_updateHeader()
					end
					self:_selectTab("themes")
					return false
				end,
			},
		},
	})
end

function App:_showCode()
	local record = self:_record()
	local code = Serialize.toJSON(record)
	self.overlay:modal({
		Title = "Theme code for " .. self.name,
		Message = "Click the box, press Ctrl+A then Ctrl+C to copy.",
		Input = { Text = code, Multiline = true, Mono = true, Height = 140, SelectAll = true },
		Buttons = { { Text = "Done", Style = "primary" } },
	})
end

function App:_pasteCode()
	self.overlay:modal({
		Title = "Paste theme code",
		Message = "Paste code copied from the Core UI Customizer.",
		Input = { Text = "", Multiline = true, Mono = true, Height = 140 },
		Buttons = {
			{ Text = "Cancel" },
			{
				Text = "Import",
				Style = "primary",
				OnClick = function(text)
					local record, problem = Serialize.fromJSON(text or "")
					if not record then
						self:status("Import failed: " .. tostring(problem), "error")
						return true
					end
					if not Theme.isTemplate(record.base) then
						self:status("Import failed: unknown template " .. tostring(record.base), "error")
						return true
					end
					local name = Store.uniqueName(
						if type(record.name) == "string" and Store.validName(record.name)
							then record.name
							else "Imported"
					)
					self:_load(name, record.base, Theme.extend(record.base, record.overrides), { dirty = true })
					self:status("Imported " .. name .. ". Press Save to keep it in this place.", "success")
					return false
				end,
			},
		},
	})
end

-- Sounds --------------------------------------------------------------------------------

function App:_playSound(id: string)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = (self.theme.sounds and self.theme.sounds.volume) or 0.5
	local ok = pcall(SoundService.PlayLocalSound, SoundService, sound)
	if not ok then
		self:status("Could not play " .. id, "warning")
	end
	task.delay(10, function()
		sound:Destroy()
	end)
end

function App:Destroy()
	for _, connection in self._undoConnections do
		connection:Disconnect()
	end
	self.viewport:Destroy()
	self.root:Destroy()
end

return App
