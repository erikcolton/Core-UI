--[[
	Settings: a window of option rows built from a config table.

		local settings = Settings.new({
			Options = {
				{ Id = "music", Text = "Music", Type = "toggle", Default = true },
				{ Id = "volume", Text = "Sound effects", Type = "slider", Min = 0, Max = 1, Default = 0.8 },
				{ Id = "graphics", Text = "Graphics", Type = "choice", Choices = { "Low", "High" }, Default = "High" },
			},
			OnChanged = function(id, value) end,
		})
		settings:Get("music") --> true

	Saving is up to the game (for example a RemoteEvent to a DataStore); call
	settings:Set(id, value, true) on join to load saved values without firing OnChanged.
	Registers itself with the Manager as props.Id (default "Settings").
]]

local Theme = require(script.Parent.Parent.Theme)
local Manager = require(script.Parent.Parent.Manager)
local Create = require(script.Parent.Parent.Util.Create)
local Signal = require(script.Parent.Parent.Util.Signal)
local Window = require(script.Parent.Parent.Components.Window)
local ScrollList = require(script.Parent.Parent.Components.ScrollList)
local Text = require(script.Parent.Parent.Components.Text)
local Toggle = require(script.Parent.Parent.Components.Toggle)
local Slider = require(script.Parent.Parent.Components.Slider)
local Button = require(script.Parent.Parent.Components.Button)

local Settings = {}
Settings.__index = Settings

local ROW_HEIGHT = 58

function Settings.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, Settings)
	self.Id = p.Id or "Settings"
	self.Values = {}
	self.Changed = Signal.new()
	self._controls = {}
	self._options = {}
	self._onChanged = p.OnChanged

	self.Window = Window.new({
		Name = self.Id,
		Title = p.Title or "Settings",
		Size = p.Size or UDim2.fromOffset(540, 420),
	})
	self.Instance = self.Window.Instance
	self.List = ScrollList.new({ Layout = "list", Size = UDim2.fromScale(1, 1), Parent = self.Window })

	for index, option in p.Options or {} do
		self:_addRow(option, index)
	end

	Manager.register(self.Id, self)
	return self
end

function Settings:_addRow(option: { [string]: any }, order: number)
	local id = option.Id
	self._options[id] = option
	self.Values[id] = option.Default

	local row = Create("Frame", {
		Name = "Row_" .. id,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		LayoutOrder = order,
		Parent = self.List.Instance,
	})
	local divider = Create("Frame", {
		Name = "Divider",
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		Parent = row,
	})
	Theme.bind(divider, {
		BackgroundColor3 = function(theme)
			return theme.colors.stroke
		end,
		BackgroundTransparency = function(theme)
			return if theme.stroke.panel > 2 then 0.7 else 0.2
		end,
	})

	local labels = Create("Frame", {
		Name = "Labels",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(0.55, 0, 1, 0),
		Parent = row,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = labels,
	})
	Text.new({ Text = option.Text or id, Role = "body", LayoutOrder = 1, Parent = labels })
	if option.Description then
		Text.new({ Text = option.Description, Role = "caption", Color = "textMuted", LayoutOrder = 2, Parent = labels })
	end

	local anchor = Vector2.new(1, 0.5)
	local position = UDim2.new(1, -4, 0.5, 0)
	local kind = option.Type or "toggle"
	local control
	if kind == "toggle" then
		control = Toggle.new({
			Value = option.Default == true,
			AnchorPoint = anchor,
			Position = position,
			Parent = row,
			OnChanged = function(value)
				self:_changed(id, value)
			end,
		})
	elseif kind == "slider" then
		control = Slider.new({
			Min = option.Min or 0,
			Max = option.Max or 1,
			Step = option.Step,
			Value = option.Default or option.Min or 0,
			AnchorPoint = anchor,
			Position = position,
			Size = UDim2.fromOffset(180, 28),
			Parent = row,
			OnChanged = function(value)
				self:_changed(id, value)
			end,
		})
	elseif kind == "choice" then
		local choices = option.Choices or {}
		control = Button.new({
			Text = tostring(option.Default or choices[1] or ""),
			Variant = "secondary",
			ButtonSize = "sm",
			Width = option.Width or 130,
			AnchorPoint = anchor,
			Position = position,
			Parent = row,
			OnClick = function()
				local current = table.find(choices, self.Values[id]) or 0
				local nextValue = choices[current % #choices + 1]
				self:Set(id, nextValue)
			end,
		})
		if self.Values[id] == nil then
			self.Values[id] = choices[1]
		end
	else
		warn("CoreUI Settings: unknown option type " .. tostring(kind))
	end
	self._controls[id] = control
end

function Settings:_changed(id: string, value: any)
	self.Values[id] = value
	self.Changed:Fire(id, value)
	if self._onChanged then
		task.spawn(self._onChanged, id, value)
	end
end

function Settings:Get(id: string): any
	return self.Values[id]
end

function Settings:Set(id: string, value: any, silent: boolean?)
	local option = self._options[id]
	local control = self._controls[id]
	if not option or not control then
		return
	end
	local kind = option.Type or "toggle"
	if kind == "choice" then
		self.Values[id] = value
		control:SetText(tostring(value))
		if not silent then
			self:_changed(id, value)
		end
	else
		-- Toggle and Slider fire OnChanged themselves unless silent.
		self.Values[id] = value
		control:SetValue(value, silent)
	end
end

function Settings:Open()
	Manager.open(self.Id)
end

function Settings:Close()
	Manager.close(self.Id)
end

function Settings:Destroy()
	Manager.unregister(self.Id)
	for _, control in self._controls do
		control:Destroy()
	end
	self.Changed:Destroy()
	self.Window:Destroy()
end

return Settings
