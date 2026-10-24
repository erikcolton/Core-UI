--[[
	DailyRewards: a login-streak calendar with a claim button.

		local daily = DailyRewards.new({
			Rewards = {
				{ Text = "100 Coins", Image = "rbxassetid://..." },
				{ Text = "250 Coins" },
				-- one entry per day
			},
			OnClaim = function(day) end, -- ask the server, then call daily:SetState(...)
		})
		daily:SetState({ Claimed = 2, CanClaim = true })               -- day 3 is ready
		daily:SetState({ Claimed = 3, CanClaim = false, NextIn = 3600 }) -- countdown to the next

	The server owns the streak; this screen only shows it.
	Registers itself with the Manager as props.Id (default "DailyRewards").
]]

local Theme = require(script.Parent.Parent.Theme)
local Manager = require(script.Parent.Parent.Manager)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Format = require(script.Parent.Parent.Util.Format)
local Tween = require(script.Parent.Parent.Util.Tween)
local Window = require(script.Parent.Parent.Components.Window)
local ScrollList = require(script.Parent.Parent.Components.ScrollList)
local Panel = require(script.Parent.Parent.Components.Panel)
local Text = require(script.Parent.Parent.Components.Text)
local Button = require(script.Parent.Parent.Components.Button)

local DailyRewards = {}
DailyRewards.__index = DailyRewards

local FOOTER_HEIGHT = 64

function DailyRewards.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, DailyRewards)
	self.Id = p.Id or "DailyRewards"
	self.Rewards = p.Rewards or {}
	self.Claimed = 0
	self.CanClaim = false
	self.NextIn = nil
	self._cards = {}
	self._onClaim = p.OnClaim

	self.Window = Window.new({
		Name = self.Id,
		Title = p.Title or "Daily Rewards",
		Size = p.Size or UDim2.fromOffset(560, 450),
	})
	self.Instance = self.Window.Instance

	self.Grid = ScrollList.new({
		Layout = "grid",
		CellSize = UDim2.fromOffset(116, 132),
		AlignX = Enum.HorizontalAlignment.Center,
		Size = UDim2.new(1, 0, 1, -FOOTER_HEIGHT),
		Parent = self.Window,
	})
	for day, reward in self.Rewards do
		self:_addCard(day, reward)
	end

	local footer = Create("Frame", {
		Name = "Footer",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, FOOTER_HEIGHT),
		Parent = self.Window.Body,
	})
	self._status = Text.new({
		Role = "body",
		Color = "textMuted",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Parent = footer,
	})
	self.ClaimButton = Button.new({
		Text = "Claim",
		Variant = "buy",
		ButtonSize = "lg",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Parent = footer,
		OnClick = function()
			if self.CanClaim and self._onClaim then
				self.ClaimButton:SetEnabled(false)
				self._onClaim(self.Claimed + 1)
			end
		end,
	})

	self._timer = task.spawn(function()
		while true do
			task.wait(1)
			if self.NextIn then
				self.NextIn = math.max(0, self.NextIn - 1)
				self:_renderStatus()
			end
		end
	end)

	-- Panels restyle themselves on a theme change; reapply the claimed and ready highlights after.
	self._themeConnection = Theme.Changed:Connect(function()
		self:_renderCards(false)
	end)

	self:SetState({ Claimed = p.Claimed or 0, CanClaim = p.CanClaim == true, NextIn = p.NextIn })
	Manager.register(self.Id, self)
	return self
end

function DailyRewards:_addCard(day: number, reward: { [string]: any })
	local panel =
		Panel.new({ Name = "Day" .. day, Variant = "inset", Padding = "sm", LayoutOrder = day, Parent = self.Grid })
	local content = panel.Content
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = content,
	})
	Text.new({ Text = "Day " .. day, Role = "caption", Color = "textMuted", LayoutOrder = 1, Parent = content })
	Create("ImageLabel", {
		Name = "Image",
		BackgroundTransparency = 1,
		Image = reward.Image or "",
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(52, 52),
		Visible = reward.Image ~= nil,
		LayoutOrder = 2,
		Parent = content,
	})
	local label = Text.new({
		Text = reward.Text or "",
		Role = "label",
		AlignX = Enum.TextXAlignment.Center,
		Wrap = true,
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 3,
		Parent = content,
	})
	local scale = Create("UIScale", { Parent = panel.Instance })
	self._cards[day] = { panel = panel, label = label, scale = scale }
end

function DailyRewards:_renderStatus()
	if self.CanClaim then
		self._status:SetText("Your day " .. (self.Claimed + 1) .. " reward is ready!")
	elseif self.Claimed >= #self.Rewards then
		self._status:SetText("All rewards claimed. Come back for a new streak!")
	elseif self.NextIn then
		self._status:SetText("Next reward in " .. Format.duration(self.NextIn))
	else
		self._status:SetText("Come back tomorrow for your next reward.")
	end
end

--[[
	state.Claimed: how many days are claimed (0 = none)
	state.CanClaim: whether the next day can be claimed now
	state.NextIn: optional seconds until the next day unlocks
]]
function DailyRewards:SetState(state: { [string]: any })
	self.Claimed = state.Claimed or self.Claimed
	self.CanClaim = state.CanClaim == true
	self.NextIn = state.NextIn
	self:_renderCards(true)
	self.ClaimButton:SetEnabled(self.CanClaim)
	self:_renderStatus()
end

function DailyRewards:_renderCards(animate: boolean)
	local theme = Theme.get()
	for day, card in self._cards do
		local surface = card.panel.Surface
		local claimed = day <= self.Claimed
		local ready = self.CanClaim and day == self.Claimed + 1
		surface.BackgroundTransparency = if claimed then 0.5 else theme.transparency.surfaceAlt or 0
		Style.stroke(
			surface,
			if ready then math.max(theme.stroke.control, 3) else theme.stroke.control,
			if ready then theme.colors.buy else theme.colors.stroke
		)
		card.label:SetColor(if claimed then "textMuted" else "text")
		if claimed then
			card.label:SetText("Claimed")
		else
			card.label:SetText(self.Rewards[day].Text or "")
		end
		if ready and animate then
			card.scale.Scale = 1.08
			Tween.pop(card.scale, { Scale = 1 }, "slow")
		end
	end
end

function DailyRewards:Open()
	Manager.open(self.Id)
end

function DailyRewards:Close()
	Manager.close(self.Id)
end

function DailyRewards:Destroy()
	Manager.unregister(self.Id)
	task.cancel(self._timer)
	self._themeConnection:Disconnect()
	self.Window:Destroy()
end

return DailyRewards
