--[[
	A small stand-in for Roblox instances, signals and services, good enough to run
	the kit's components and the plugin's UI code end to end outside Studio.
	It records nothing about rendering; it only lets code run so crashes, nil
	indexing and wrong method calls show up.
]]

local roblox = require("@lune/roblox")
local task = require("@lune/task")

local Fakes = {}

local Vector2, UDim2 = roblox.Vector2, roblox.UDim2

-- Signals -------------------------------------------------------------------------

local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ handlers = {} }, Signal)
end

function Signal:Connect(fn)
	local connection = { Connected = true }
	local handlers = self.handlers
	function connection.Disconnect()
		connection.Connected = false
		local index = table.find(handlers, connection)
		if index then
			table.remove(handlers, index)
		end
	end
	connection.fn = fn
	table.insert(handlers, connection)
	return connection
end

function Signal:Once(fn)
	local connection
	connection = self:Connect(function(...)
		connection.Disconnect()
		fn(...)
	end)
	return connection
end

function Signal:Wait()
	local thread = coroutine.running()
	self:Once(function(...)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:Fire(...)
	for _, connection in table.clone(self.handlers) do
		if connection.Connected then
			connection.fn(...)
		end
	end
end

Fakes.Signal = Signal

-- Instances -----------------------------------------------------------------------

local SIGNALS = {
	Activated = true,
	MouseEnter = true,
	MouseLeave = true,
	MouseButton1Down = true,
	MouseButton1Up = true,
	MouseButton1Click = true,
	InputBegan = true,
	InputChanged = true,
	InputEnded = true,
	Focused = true,
	FocusLost = true,
	SelectionGained = true,
	SelectionLost = true,
	Changed = true,
	Destroying = true,
	Event = true,
	ChildAdded = true,
	ChildRemoved = true,
	Click = true,
	Unloading = true,
	ThemeChanged = true,
}

local DEFAULTS = {
	Visible = true,
	Enabled = true,
	Active = true,
	Text = "",
	Value = 0,
	GroupTransparency = 0,
	BackgroundTransparency = 0,
	Scale = 1,
	Position = UDim2.new(),
	Size = UDim2.new(),
	AnchorPoint = Vector2.new(),
	AbsoluteSize = Vector2.new(400, 300),
	AbsolutePosition = Vector2.new(0, 0),
	CanvasPosition = Vector2.new(0, 0),
	TextSize = 14,
	Source = "",
	LayoutOrder = 0,
	ZIndex = 1,
}

local Instance = {}
Fakes.created = 0

local instanceMeta = {}

function instanceMeta.__index(self, key)
	local data = rawget(self, "_data")
	if data.props[key] ~= nil then
		return data.props[key]
	end
	if Instance[key] then
		return Instance[key]
	end
	if SIGNALS[key] then
		local signal = data.signals[key]
		if not signal then
			signal = Signal.new()
			data.signals[key] = signal
		end
		return signal
	end
	for _, child in data.children do
		if child.Name == key then
			return child
		end
	end
	if DEFAULTS[key] ~= nil then
		return DEFAULTS[key]
	end
	return nil
end

function instanceMeta.__newindex(self, key, value)
	local data = rawget(self, "_data")
	if data.destroyed and key ~= "Parent" then
		-- Roblox allows this too; nothing to do.
	end
	if key == "Parent" then
		local old = data.props.Parent
		if old == value then
			return
		end
		if old then
			local siblings = rawget(old, "_data").children
			local index = table.find(siblings, self)
			if index then
				table.remove(siblings, index)
			end
		end
		data.props.Parent = value
		if value then
			table.insert(rawget(value, "_data").children, self)
			value.ChildAdded:Fire(self)
		end
	else
		data.props[key] = value
	end
	local changed = data.propSignals[key]
	if changed then
		changed:Fire()
	end
end

instanceMeta.__tostring = function(self)
	return self.Name
end

function Fakes.new(className: string, props: { [string]: any }?): any
	Fakes.created += 1
	local self = setmetatable({
		_data = {
			props = { ClassName = className, Name = className },
			children = {},
			signals = {},
			propSignals = {},
			attributes = {},
			attributeSignals = {},
		},
	}, instanceMeta)
	for key, value in props or {} do
		self[key] = value
	end
	return self
end

function Instance.IsA(self, className)
	local own = self.ClassName
	if own == className or className == "Instance" then
		return true
	end
	local families = {
		GuiObject = {
			"Frame",
			"TextLabel",
			"TextButton",
			"TextBox",
			"ImageLabel",
			"ImageButton",
			"ScrollingFrame",
			"CanvasGroup",
		},
		GuiButton = { "TextButton", "ImageButton" },
		LuaSourceContainer = { "Script", "LocalScript", "ModuleScript" },
		ValueBase = { "StringValue", "NumberValue" },
	}
	return families[className] ~= nil and table.find(families[className], own) ~= nil
end

function Instance.GetChildren(self)
	return table.clone(rawget(self, "_data").children)
end

function Instance.GetDescendants(self)
	local out = {}
	local function walk(node)
		for _, child in rawget(node, "_data").children do
			table.insert(out, child)
			walk(child)
		end
	end
	walk(self)
	return out
end

function Instance.FindFirstChild(self, name)
	for _, child in rawget(self, "_data").children do
		if child.Name == name then
			return child
		end
	end
	return nil
end

function Instance.FindFirstChildOfClass(self, className)
	for _, child in rawget(self, "_data").children do
		if child.ClassName == className then
			return child
		end
	end
	return nil
end

function Instance.WaitForChild(self, name)
	return self:FindFirstChild(name)
end

function Instance.Destroy(self)
	local data = rawget(self, "_data")
	if data.destroyed then
		return
	end
	data.destroyed = true
	self.Destroying:Fire()
	for _, child in table.clone(data.children) do
		child:Destroy()
	end
	self.Parent = nil
end

function Instance.ClearAllChildren(self)
	for _, child in self:GetChildren() do
		child:Destroy()
	end
end

function Instance.Clone(self)
	local data = rawget(self, "_data")
	local copy = Fakes.new(data.props.ClassName)
	for key, value in data.props do
		if key ~= "Parent" then
			copy[key] = value
		end
	end
	for key, value in data.attributes do
		copy:SetAttribute(key, value)
	end
	for _, child in data.children do
		child:Clone().Parent = copy
	end
	return copy
end

function Instance.GetFullName(self)
	local parent = self.Parent
	return if parent then parent:GetFullName() .. "." .. self.Name else self.Name
end

function Instance.GetPropertyChangedSignal(self, key)
	local data = rawget(self, "_data")
	local signal = data.propSignals[key]
	if not signal then
		signal = Signal.new()
		data.propSignals[key] = signal
	end
	return signal
end

function Instance.GetAttribute(self, key)
	return rawget(self, "_data").attributes[key]
end

function Instance.SetAttribute(self, key, value)
	local data = rawget(self, "_data")
	data.attributes[key] = value
	local signal = data.attributeSignals[key]
	if signal then
		signal:Fire()
	end
end

function Instance.GetAttributeChangedSignal(self, key)
	local data = rawget(self, "_data")
	local signal = data.attributeSignals[key]
	if not signal then
		signal = Signal.new()
		data.attributeSignals[key] = signal
	end
	return signal
end

-- BindableEvent
function Instance.Fire(self, ...)
	self.Event:Fire(...)
end

function Instance.CaptureFocus() end
function Instance.ReleaseFocus() end

-- Plugin widget extras.
function Instance.GetRelativeMousePosition()
	return Vector2.new(120, 40)
end

-- Plugin toolbar extras.
function Instance.CreateButton(self)
	return Fakes.new("PluginToolbarButton")
end
function Instance.SetActive() end

Fakes.Instance = {
	new = function(className: string, parent: any?)
		local object = Fakes.new(className)
		if parent then
			object.Parent = parent
		end
		return object
	end,
}

function Fakes.isInstance(value)
	return type(value) == "table" and getmetatable(value) == instanceMeta
end

-- Services --------------------------------------------------------------------------

function Fakes.services()
	local tweenService = Fakes.new("TweenService")
	function tweenService.Create(_, instance, _info, goals)
		local tween = Fakes.new("Tween")
		function tween.Play()
			for key, value in goals do
				instance[key] = value
			end
			task.defer(function()
				tween.Completed:Fire()
			end)
		end
		tween.Completed = Signal.new()
		return tween
	end

	local userInput = Fakes.new("UserInputService", {
		TouchEnabled = false,
		MouseEnabled = true,
		GamepadEnabled = false,
	})
	function userInput.GetMouseLocation()
		return Vector2.new(10, 10)
	end

	local guiService = Fakes.new("GuiService", { ReducedMotionEnabled = false })
	local soundService = Fakes.new("SoundService")
	function soundService.PlayLocalSound() end

	local history = Fakes.new("ChangeHistoryService")
	history.OnUndo = Signal.new()
	history.OnRedo = Signal.new()
	history.recordings = {}
	function history.TryBeginRecording(_, name)
		table.insert(history.recordings, name)
		return name
	end
	function history.FinishRecording() end
	function history.SetWaypoint() end

	local selection = Fakes.new("Selection")
	function selection.Set(_, list)
		selection.selected = list
	end

	local starterPlayer = Fakes.new("StarterPlayer")
	Fakes.new("StarterPlayerScripts").Parent = starterPlayer

	local runService = Fakes.new("RunService")
	runService.RenderStepped = Signal.new()
	runService.Heartbeat = Signal.new()
	function runService.IsRunning()
		return false
	end
	function runService.IsClient()
		return true
	end
	function runService.IsStudio()
		return true
	end

	return {
		TweenService = tweenService,
		UserInputService = userInput,
		GuiService = guiService,
		SoundService = soundService,
		ChangeHistoryService = history,
		Selection = selection,
		StarterPlayer = starterPlayer,
		RunService = runService,
		ReplicatedStorage = Fakes.new("ReplicatedStorage"),
		CoreGui = Fakes.new("CoreGui"),
		Players = Fakes.new("Players"),
		MarketplaceService = Fakes.new("MarketplaceService"),
	}
end

function Fakes.plugin()
	local plugin = Fakes.new("Plugin")
	local settings = {}
	function plugin.GetSetting(_, key)
		return settings[key]
	end
	function plugin.SetSetting(_, key, value)
		settings[key] = value
	end
	function plugin.CreateToolbar()
		return Fakes.new("PluginToolbar")
	end
	function plugin.CreateDockWidgetPluginGuiAsync()
		local widget = Fakes.new("DockWidgetPluginGui", { Enabled = false, AbsoluteSize = Vector2.new(400, 760) })
		plugin.widget = widget
		return widget
	end
	return plugin
end

function Fakes.settings()
	local themeChanged = Signal.new()
	local studio = {
		ThemeChanged = themeChanged,
		Theme = {
			GetColor = function()
				return roblox.Color3.fromRGB(50, 50, 50)
			end,
		},
	}
	return function()
		return { Studio = studio }
	end
end

return Fakes
