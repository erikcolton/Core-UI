--[[
	ScrollList: a scrolling list or grid whose canvas grows with its children.

		local grid = ScrollList.new({ Layout = "grid", CellSize = UDim2.fromOffset(88, 88), Size = UDim2.fromScale(1, 1) })
		ItemSlot.new({ Parent = grid })

	Layout: list (vertical stack, default) | grid
	Gap: spacing token or pixels between children (default "sm")
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Component = require(script.Parent.Parent.Util.Component)

local ScrollList = {}
ScrollList.__index = ScrollList

function ScrollList.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, ScrollList)
	self.Layout = p.Layout or "list"
	self.Gap = p.Gap

	self.Instance = Create("ScrollingFrame", {
		Name = "ScrollList",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		Selectable = false,
	})
	self.Content = self.Instance

	if self.Layout == "grid" then
		self._layout = Create("UIGridLayout", {
			CellSize = p.CellSize or UDim2.fromOffset(88, 88),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = p.AlignX or Enum.HorizontalAlignment.Left,
			Parent = self.Instance,
		})
	else
		self._layout = Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = p.AlignX or Enum.HorizontalAlignment.Left,
			Parent = self.Instance,
		})
	end

	Theme.bind(self.Instance, function(theme)
		local gap = Style.space(theme, self.Gap, "sm")
		if self.Layout == "grid" then
			self._layout.CellPadding = UDim2.fromOffset(gap, gap)
		else
			self._layout.Padding = UDim.new(0, gap)
		end
		self.Instance.ScrollBarImageColor3 = theme.colors.textMuted
		-- Room for strokes, lips and hover scaling so they are not clipped at the edges.
		Style.padding(self.Instance, { 6, 10, 10, 6 })
	end)

	return Component.finish(self, p)
end

-- Parent a component or instance into the list. Order follows LayoutOrder, then insertion.
function ScrollList:Add(child: any): any
	local instance = Component.instance(child)
	if instance then
		instance.Parent = self.Instance
	end
	return child
end

-- Destroy every child except the layout and padding.
function ScrollList:Clear()
	for _, child in self.Instance:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	self.Instance.CanvasPosition = Vector2.zero
end

function ScrollList:Destroy()
	self.Instance:Destroy()
end

return ScrollList
