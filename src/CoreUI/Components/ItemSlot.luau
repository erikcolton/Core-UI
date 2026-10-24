--[[
	ItemSlot: a square slot for inventories, hotbars and collection books.

		ItemSlot.new({
			Item = { Image = "rbxassetid://...", Rarity = "epic", Count = 3, Equipped = true },
			OnClick = function(slot) end,
		})

	Rarity names match theme.colors.rarity: common, uncommon, rare, epic, legendary, mythic.
	Item.Locked shows a "?" cover, for undiscovered entries in an index.
]]

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Format = require(script.Parent.Parent.Util.Format)
local Tween = require(script.Parent.Parent.Util.Tween)
local Sound = require(script.Parent.Parent.Util.Sound)
local Signal = require(script.Parent.Parent.Util.Signal)
local Maid = require(script.Parent.Parent.Util.Maid)
local Component = require(script.Parent.Parent.Util.Component)

local ItemSlot = {}
ItemSlot.__index = ItemSlot

function ItemSlot.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, ItemSlot)
	self.Item = p.Item or {}
	self.Selected = p.Selected == true
	self.Activated = Signal.new()
	self._maid = Maid.new()

	local root = Create("TextButton", {
		Name = "ItemSlot",
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(88, 88),
	})
	self.Instance = root
	self._scale = Create("UIScale", { Parent = root })
	self._face = Create("Frame", {
		Name = "Face",
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = root,
	})
	self._icon = Create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.72, 0.72),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 2,
		Parent = self._face,
	})
	-- Shown when an item has no image: the first letter of its name.
	self._initial = Create("TextLabel", {
		Name = "Initial",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
		Parent = self._face,
	})
	self._count = Create("TextLabel", {
		Name = "Count",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -4, 1, -2),
		AutomaticSize = Enum.AutomaticSize.XY,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 4,
		Parent = self._face,
	})
	self._equipped = Create("TextLabel", {
		Name = "Equipped",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(20, 20),
		Text = "E",
		TextXAlignment = Enum.TextXAlignment.Center,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = self._face,
	})
	self._lock = Create("TextLabel", {
		Name = "Locked",
		Size = UDim2.fromScale(1, 1),
		Text = "?",
		TextXAlignment = Enum.TextXAlignment.Center,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = self._face,
	})
	self._ring = Create("Frame", {
		Name = "SelectedRing",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 8, 1, 8),
		ZIndex = 6,
		Parent = root,
	})
	self._selection = Create("Frame", {
		Name = "Selection",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(-4, -4),
		Size = UDim2.new(1, 8, 1, 8),
	})
	root.SelectionImageObject = self._selection

	local function setHover(on: boolean)
		local motion = Theme.get().motion
		Tween.play(self._scale, { Scale = if on then motion.hoverScale else 1 }, "fast")
	end
	self._maid:Add(root.MouseEnter:Connect(function()
		if not (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) then
			setHover(true)
		end
	end))
	self._maid:Add(root.MouseLeave:Connect(function()
		setHover(false)
	end))
	self._maid:Add(root.SelectionGained:Connect(function()
		setHover(true)
	end))
	self._maid:Add(root.SelectionLost:Connect(function()
		setHover(false)
	end))
	self._maid:Add(root.Activated:Connect(function()
		Sound.play("click")
		self.Activated:Fire(self)
		if p.OnClick then
			task.spawn(p.OnClick, self)
		end
	end))

	Theme.bind(root, function(theme)
		self:_style(theme)
	end)
	Component.finish(self, p)
	self:_render()
	return self
end

function ItemSlot:_rarityColor(theme: any): Color3
	local rarity = string.lower(self.Item.Rarity or "common")
	return theme.colors.rarity[rarity] or theme.colors.rarity.common
end

function ItemSlot:_style(theme: any)
	local face = self._face
	local rarityColor = self:_rarityColor(theme)
	local radius = theme.radius.md
	local skinned = Style.skin(face, theme.images.slot, rarityColor)
	face.BackgroundColor3 = theme.colors.surfaceAlt:Lerp(rarityColor, 0.2)
	face.BackgroundTransparency = if skinned then 1 else theme.transparency.surfaceAlt or 0
	Style.corner(face, radius)
	Style.stroke(face, if skinned then 0 else math.max(theme.stroke.control, 2), rarityColor)

	self._initial.FontFace = theme.fonts.display
	self._initial.TextSize = 34
	self._initial.TextColor3 = rarityColor
	Style.textOutline(self._initial, theme, true)

	Style.text(self._count, theme, "caption", true)
	self._count.TextColor3 = if theme.stroke.text > 0 then theme.colors.textInverse else theme.colors.text

	local equipped = self._equipped
	equipped.BackgroundColor3 = theme.colors.success
	equipped.TextColor3 = theme.colors.onBuy
	equipped.FontFace = theme.fonts.heading
	equipped.TextSize = 13
	Style.corner(equipped, theme.radius.pill)

	local lock = self._lock
	lock.BackgroundColor3 = theme.colors.overlay
	lock.BackgroundTransparency = 0.35
	lock.TextColor3 = theme.colors.textInverse
	lock.FontFace = theme.fonts.display
	lock.TextSize = 36
	Style.corner(lock, radius)

	Style.corner(self._ring, UDim.new(radius.Scale, radius.Offset + 4))
	Style.stroke(self._ring, 3, theme.colors.selection)
	Style.corner(self._selection, UDim.new(radius.Scale, radius.Offset + 4))
	Style.stroke(self._selection, 2, theme.colors.selection)
end

function ItemSlot:_render()
	local item = self.Item
	self._icon.Image = item.Image or ""
	self._initial.Text = if item.Image or item.Locked then "" else string.upper(string.sub(item.Name or "", 1, 1))
	local count = item.Count
	self._count.Text = if count and count > 1 then "x" .. Format.abbreviate(count) else ""
	self._equipped.Visible = item.Equipped == true
	self._lock.Visible = item.Locked == true
	self._ring.Visible = self.Selected
end

function ItemSlot:SetItem(item: { [string]: any })
	self.Item = item
	self:_style(Theme.get())
	self:_render()
end

function ItemSlot:SetSelected(selected: boolean)
	self.Selected = selected
	self:_render()
end

function ItemSlot:Destroy()
	self._maid:Clean()
	self.Activated:Destroy()
	self._selection:Destroy()
	self.Instance:Destroy()
end

return ItemSlot
