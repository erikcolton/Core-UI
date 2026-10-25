--[[
	ScreenGui layers, created on first use under the local player's PlayerGui.

	Each layer has one UIScale that tracks the screen size against the theme's
	layout.referenceSize, so components are sized in reference pixels and grow or
	shrink together. "Safe" layers keep clear of the Roblox top bar and device cutouts.
]]

local Players = game:GetService("Players")

local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Parent.Theme)

local Layers = {}

local SPECS = {
	HUD = { order = 10, safe = true },
	Menu = { order = 15, safe = false },
	Backdrop = { order = 19, safe = false },
	Windows = { order = 20, safe = true },
	Dialogs = { order = 30, safe = false },
	Toasts = { order = 40, safe = true },
	Overlay = { order = 50, safe = false },
}

local guis: { [string]: ScreenGui } = {}

-- Where layers go. nil = the local player's PlayerGui. Tools such as the Studio
-- plugin point this somewhere else (CoreGui) to show the kit outside a play session.
local customParent: Instance? = nil
local namePrefix = "CoreUI_"

local function computeScale(size: Vector2): number
	local layout = Theme.get().layout
	local ref = layout.referenceSize
	if size.X <= 0 or size.Y <= 0 then
		return 1
	end
	local scale = math.min(size.X / ref.X, size.Y / ref.Y)
	return math.clamp(scale, layout.minScale, layout.maxScale)
end

local function track(gui: ScreenGui, uiScale: UIScale)
	local function update()
		uiScale.Scale = computeScale(gui.AbsoluteSize)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	Theme.Changed:Connect(update)
	update()
end

function Layers.get(name: string): ScreenGui
	local existing = guis[name]
	if existing and existing.Parent then
		return existing
	end
	local spec = SPECS[name]
	assert(spec, "CoreUI: unknown layer " .. tostring(name))

	local parent = customParent
	if not parent then
		local player = Players.LocalPlayer
		assert(player, "CoreUI: layers can only be created on the client")
		parent = player:WaitForChild("PlayerGui")
	end

	local gui = Create("ScreenGui", {
		Name = namePrefix .. name,
		DisplayOrder = spec.order,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	-- IgnoreGuiInset and ScreenInsets are linked, so set them in this order.
	gui.IgnoreGuiInset = not spec.safe
	gui.ScreenInsets = if spec.safe then Enum.ScreenInsets.CoreUISafeInsets else Enum.ScreenInsets.None
	local uiScale = Create("UIScale", { Name = "Scale", Parent = gui })
	gui.Parent = parent
	track(gui, uiScale)
	guis[name] = gui
	return gui
end

--[[
	Send layers somewhere other than PlayerGui. Call before anything is created.

		Layers.configure({ Parent = game:GetService("CoreGui"), Prefix = "MyTool_" })
]]
function Layers.configure(options: { Parent: Instance?, Prefix: string? })
	customParent = options.Parent
	namePrefix = options.Prefix or namePrefix
end

-- Show or hide every layer at once.
function Layers.setEnabled(enabled: boolean)
	for _, gui in guis do
		gui.Enabled = enabled
	end
end

-- Current scale of a layer, for converting screen pixels into reference pixels.
function Layers.scale(name: string): number
	local gui = Layers.get(name)
	local uiScale = gui:FindFirstChild("Scale") :: UIScale?
	return if uiScale then uiScale.Scale else 1
end

return Layers
