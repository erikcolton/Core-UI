--[[
	LoadingScreen: a full-screen cover with a progress bar and rotating tips.
	It shows as soon as it is created.

		local loading = LoadingScreen.new({ Title = "My Game", Tips = { "Tip one", "Tip two" } })
		loading:SetProgress(0.5, "Loading map")
		loading:Finish() -- fades out and destroys

	To cover the screen before anything else loads, require CoreUI from a
	LocalScript in ReplicatedFirst after waiting for it to replicate, and call
	ReplicatedFirst:RemoveDefaultLoadingScreen().
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Tween = require(script.Parent.Parent.Util.Tween)
local Layers = require(script.Parent.Parent.Util.Layers)
local Text = require(script.Parent.Parent.Components.Text)
local ProgressBar = require(script.Parent.Parent.Components.ProgressBar)

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

function LoadingScreen.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, LoadingScreen)
	self.Tips = p.Tips or {}
	self._tipIndex = 0

	-- CanvasGroup so the whole screen fades as one.
	self.Instance = Create("CanvasGroup", {
		Name = "LoadingScreen",
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = Layers.get("Overlay"),
	})
	if p.Background then
		Create("ImageLabel", {
			Name = "Background",
			BackgroundTransparency = 1,
			Image = p.Background,
			ScaleType = Enum.ScaleType.Crop,
			Size = UDim2.fromScale(1, 1),
			Parent = self.Instance,
		})
	end
	Theme.bind(self.Instance, {
		BackgroundColor3 = function(theme)
			return theme.colors.background
		end,
	})

	local column = Create("Frame", {
		Name = "Column",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromOffset(420, 200),
		Parent = self.Instance,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 14),
		Parent = column,
	})
	Text.new({
		Text = p.Title or "",
		Role = "display",
		AlignX = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		Parent = column,
	})
	self.Bar = ProgressBar.new({
		Value = 0,
		Max = 1,
		Size = UDim2.fromOffset(360, 18),
		LayoutOrder = 2,
		Parent = column,
	})
	self._status = Text.new({
		Text = p.Status or "Loading…",
		Role = "caption",
		Color = "textMuted",
		AlignX = Enum.TextXAlignment.Center,
		LayoutOrder = 3,
		Parent = column,
	})
	self._tip = Text.new({
		Role = "body",
		AlignX = Enum.TextXAlignment.Center,
		Wrap = true,
		Size = UDim2.fromOffset(420, 48),
		LayoutOrder = 4,
		Parent = column,
	})

	if #self.Tips > 0 then
		self:_nextTip()
		self._tipThread = task.spawn(function()
			while true do
				task.wait(p.TipInterval or 4)
				self:_nextTip()
			end
		end)
	end
	return self
end

function LoadingScreen:_nextTip()
	self._tipIndex = self._tipIndex % #self.Tips + 1
	self._tip:SetText(self.Tips[self._tipIndex])
end

function LoadingScreen:SetProgress(ratio: number, status: string?)
	self.Bar:SetValue(math.clamp(ratio, 0, 1))
	if status then
		self._status:SetText(status)
	end
end

function LoadingScreen:Finish()
	if self._finished then
		return
	end
	self._finished = true
	self.Bar:SetValue(1)
	local tween = Tween.play(self.Instance, { GroupTransparency = 1 }, "slow")
	tween.Completed:Once(function()
		self:Destroy()
	end)
end

function LoadingScreen:Destroy()
	if self._tipThread then
		task.cancel(self._tipThread)
		self._tipThread = nil
	end
	self.Instance:Destroy()
end

return LoadingScreen
