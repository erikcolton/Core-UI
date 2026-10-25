--[[
	Core UI Customizer: a Studio plugin for designing Core UI themes.

	Toolbar button "Customizer" opens a dock window where you pick a template, edit
	colors, shapes, fonts, effects, motion, sounds and 9-slice skins with a live
	preview, then save the theme into the place. The Core UI kit loads the saved,
	active theme by itself when the game runs.
]]

local RunService = game:GetService("RunService")

-- Plugins also run inside Play sessions; the editor only belongs in Edit mode.
if RunService:IsRunning() then
	return
end

local Viewport = require(script.Preview.Viewport)
-- Kit screens shown over the 3D view must go to CoreGui, not a PlayerGui.
Viewport.configure()

local App = require(script.App)

local WIDGET_ID = "CoreUICustomizer"

local toolbar = plugin:CreateToolbar("Core UI")
local button = toolbar:CreateButton("CoreUICustomizer", "Design and switch Core UI themes", "", "Customizer")
button.ClickableWhenViewportHidden = true

local info = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 400, 760, 340, 520)
local widget: DockWidgetPluginGui
local ok = pcall(function()
	widget = plugin:CreateDockWidgetPluginGuiAsync(WIDGET_ID, info)
end)
if not ok or not widget then
	-- Older Studio builds only have the synchronous version.
	widget = (plugin :: any):CreateDockWidgetPluginGui(WIDGET_ID, info)
end
widget.Name = WIDGET_ID
widget.Title = "Core UI Customizer"
widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local app = nil

local function open()
	if app then
		return
	end
	local created, result = pcall(App.new, plugin, widget, {
		kit = script.CoreUI,
		demo = script:FindFirstChild("CoreUIDemo"),
	})
	if created then
		app = result
	else
		warn("Core UI Customizer failed to start: " .. tostring(result))
	end
end

local function sync()
	button:SetActive(widget.Enabled)
	if widget.Enabled then
		open()
	elseif app then
		-- Hide the game-view screens with the window; keep the editor state.
		app:_setGameView(false)
	end
end

button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)
widget:GetPropertyChangedSignal("Enabled"):Connect(sync)
sync()

plugin.Unloading:Connect(function()
	if app then
		app:Destroy()
		app = nil
	end
end)
