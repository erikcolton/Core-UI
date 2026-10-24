--[[
	MainMenu: a title screen with stacked buttons, shown over the game.

		local menu = MainMenu.new({
			Title = "My Game",
			Subtitle = "Season 1",
			Buttons = {
				{ Text = "Play", Variant = "primary", Play = true }, -- hides the menu
				{ Text = "Settings", Screen = "Settings" },          -- opens a registered screen
				{ Text = "Credits", OnClick = function() end },
			},
			OnPlay = function() end,
		})

	Windows opened from the menu appear above it.
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Tween = require(script.Parent.Parent.Util.Tween)
local Signal = require(script.Parent.Parent.Util.Signal)
local Layers = require(script.Parent.Parent.Util.Layers)
local Manager = require(script.Parent.Parent.Manager)
local Text = require(script.Parent.Parent.Components.Text)
local Button = require(script.Parent.Parent.Components.Button)

local MainMenu = {}
MainMenu.__index = MainMenu

function MainMenu.new(props: { [string]: any }?)
	local p = props or {}
	local self = setmetatable({}, MainMenu)
	self.Played = Signal.new()
	self._onPlay = p.OnPlay
	self.Buttons = {}

	self.Instance = Create("CanvasGroup", {
		Name = "MainMenu",
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = Layers.get("Menu"),
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
	local backgroundTransparency = if p.Background then 1 else (p.BackgroundTransparency or 0.15)
	Theme.bind(self.Instance, {
		BackgroundColor3 = function(theme)
			return theme.colors.background
		end,
		BackgroundTransparency = function()
			return backgroundTransparency
		end,
	})

	local column = Create("Frame", {
		Name = "Column",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.08, 0, 0.5, 0),
		Size = UDim2.fromOffset(360, 420),
		Parent = self.Instance,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 12),
		Parent = column,
	})
	Text.new({ Text = p.Title or "", Role = "display", LayoutOrder = 1, Parent = column })
	if p.Subtitle then
		Text.new({ Text = p.Subtitle, Role = "body", Color = "textMuted", LayoutOrder = 2, Parent = column })
	end
	Create("Frame", {
		Name = "Spacer",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(1, 12),
		LayoutOrder = 3,
		Parent = column,
	})

	for index, spec in p.Buttons or {} do
		local button = Button.new({
			Text = spec.Text,
			Icon = spec.Icon,
			Variant = spec.Variant or (if index == 1 then "primary" else "secondary"),
			ButtonSize = "lg",
			Width = 260,
			LayoutOrder = 10 + index,
			Parent = column,
			OnClick = function()
				if spec.Play then
					self:Play()
				elseif spec.Screen then
					Manager.open(spec.Screen)
				elseif spec.OnClick then
					spec.OnClick(self)
				end
			end,
		})
		table.insert(self.Buttons, button)
	end
	return self
end

function MainMenu:Show()
	self.Instance.Visible = true
	Tween.play(self.Instance, { GroupTransparency = 0 }, "normal")
end

function MainMenu:Hide()
	local tween = Tween.play(self.Instance, { GroupTransparency = 1 }, "normal")
	tween.Completed:Once(function()
		if self.Instance.GroupTransparency >= 1 then
			self.Instance.Visible = false
		end
	end)
end

function MainMenu:Play()
	self:Hide()
	self.Played:Fire()
	if self._onPlay then
		task.spawn(self._onPlay)
	end
end

function MainMenu:Destroy()
	for _, button in self.Buttons do
		button:Destroy()
	end
	self.Played:Destroy()
	self.Instance:Destroy()
end

return MainMenu
