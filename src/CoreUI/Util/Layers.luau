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

	local player = Players.LocalPlayer
	assert(player, "CoreUI: layers can only be created on the client")
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Create("ScreenGui", {
		Name = "CoreUI_" .. name,
		DisplayOrder = spec.order,
		ResetOnSpawn = false,
		IgnoreGuiInset = not spec.safe,
		ScreenInsets = if spec.safe then Enum.ScreenInsets.CoreUISafeInsets else Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local uiScale = Create("UIScale", { Name = "Scale", Parent = gui })
	gui.Parent = playerGui
	track(gui, uiScale)
	guis[name] = gui
	return gui
end

-- Current scale of a layer, for converting screen pixels into reference pixels.
function Layers.scale(name: string): number
	local gui = Layers.get(name)
	local uiScale = gui:FindFirstChild("Scale") :: UIScale?
	return if uiScale then uiScale.Scale else 1
end

return Layers
