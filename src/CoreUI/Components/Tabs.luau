--[[
	Tabs: a row of tab buttons with one page per tab.

		local tabs = Tabs.new({
			Tabs = { { Id = "passes", Text = "Passes" }, { Id = "coins", Text = "Coins" } },
			Size = UDim2.fromScale(1, 1),
		})
		Text.new({ Text = "Passes go here", Parent = tabs:GetPage("passes") })
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Signal = require(script.Parent.Parent.Util.Signal)
local Component = require(script.Parent.Parent.Util.Component)
local Button = require(script.Parent.Button)

local Tabs = {}
Tabs.__index = Tabs

function Tabs.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, Tabs)
	self.Changed = Signal.new()
	self.Selected = nil
	self._buttons = {}
	self._pages = {}
	self._onChanged = p.OnChanged

	self.Instance = Create("Frame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	})
	self.Bar = Create("Frame", {
		Name = "Bar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		Parent = self.Instance,
	})
	self._barLayout = Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = self.Bar,
	})
	self.Pages = Create("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		Parent = self.Instance,
	})

	for index, tab in p.Tabs or {} do
		self:AddTab(tab, index)
	end

	Theme.bind(self.Instance, function(theme)
		local barHeight = theme.buttons.heights.sm + theme.shadow.offset
		local gap = theme.spacing.md
		self._barLayout.Padding = UDim.new(0, theme.spacing.sm)
		self.Bar.Size = UDim2.new(1, 0, 0, barHeight)
		self.Pages.Position = UDim2.fromOffset(0, barHeight + gap)
		self.Pages.Size = UDim2.new(1, 0, 1, -(barHeight + gap))
	end)

	Component.finish(self, p)
	local first = p.Selected or (p.Tabs and p.Tabs[1] and p.Tabs[1].Id)
	if first then
		self:Select(first, true)
	end
	return self
end

function Tabs:AddTab(tab: { [string]: any }, order: number?): Frame
	local id = tab.Id
	local button = Button.new({
		Name = "Tab_" .. id,
		Text = tab.Text or id,
		Icon = tab.Icon,
		Variant = "secondary",
		ButtonSize = "sm",
		Width = tab.Width,
		LayoutOrder = order or 0,
		Parent = self.Bar,
		OnClick = function()
			self:Select(id)
		end,
	})
	local page = Create("Frame", {
		Name = "Page_" .. id,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = self.Pages,
	})
	self._buttons[id] = button
	self._pages[id] = page
	return page
end

function Tabs:GetPage(id: string): Frame
	return self._pages[id]
end

function Tabs:GetButton(id: string): any
	return self._buttons[id]
end

function Tabs:Select(id: string, silent: boolean?)
	if not self._pages[id] or self.Selected == id then
		return
	end
	self.Selected = id
	for tabId, page in self._pages do
		local active = tabId == id
		page.Visible = active
		self._buttons[tabId]:SetVariant(if active then "primary" else "secondary")
	end
	if not silent then
		self.Changed:Fire(id)
		if self._onChanged then
			task.spawn(self._onChanged, id)
		end
	end
end

function Tabs:Destroy()
	self.Changed:Destroy()
	for _, button in self._buttons do
		button:Destroy()
	end
	self.Instance:Destroy()
end

return Tabs
