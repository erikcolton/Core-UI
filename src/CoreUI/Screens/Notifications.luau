--[[
	Notifications: toast messages stacked at the top center of the screen.

		Notifications.push({ Title = "Code redeemed", Text = "+500 coins", Kind = "success" })
		Notifications.success("Saved!")
		Notifications.error("Not enough coins")

	Kind: info | success | warning | error. Duration in seconds (default 4).
	At most MAX_VISIBLE toasts show at once; the oldest is dismissed first. Tap a toast to dismiss it.
]]

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Tween = require(script.Parent.Parent.Util.Tween)
local Sound = require(script.Parent.Parent.Util.Sound)
local Layers = require(script.Parent.Parent.Util.Layers)

local Notifications = {}

local MAX_VISIBLE = 4
local WIDTH = 360

local container: Frame? = nil
local active: { any } = {}
local order = 0

local function ensureContainer(): Frame
	if container and container.Parent then
		return container
	end
	local frame = Create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.new(0, WIDTH, 1, -24),
		Parent = Layers.get("Toasts"),
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = frame,
	})
	container = frame
	return frame
end

local function dismiss(toast: any)
	if toast.dismissed then
		return
	end
	toast.dismissed = true
	local index = table.find(active, toast)
	if index then
		table.remove(active, index)
	end
	local tween = Tween.play(toast.scale, { Scale = 0 }, "fast", nil, Enum.EasingDirection.In)
	tween.Completed:Once(function()
		toast.frame:Destroy()
	end)
end

function Notifications.push(options: { [string]: any })
	local parent = ensureContainer()
	local kind = options.Kind or "info"
	order += 1

	local frame = Create("TextButton", {
		Name = "Toast",
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		LayoutOrder = order,
	})
	local scale = Create("UIScale", { Scale = 0.6, Parent = frame })
	-- A dot rather than a full-height bar: AutomaticSize cannot size a child by scale.
	local accent = Create("Frame", {
		Name = "Accent",
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 5),
		Size = UDim2.fromOffset(10, 10),
		Parent = frame,
	})
	local body = Create("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.new(1, -18, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = frame,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = body,
	})
	local title = if options.Title
		then Create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = options.Title,
			LayoutOrder = 1,
			Parent = body,
		})
		else nil
	local text = Create("TextLabel", {
		Name = "Text",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		RichText = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = options.Text or "",
		LayoutOrder = 2,
		Parent = body,
	})

	Theme.bind(frame, function(theme)
		frame.BackgroundColor3 = theme.colors.surface
		frame.BackgroundTransparency = theme.transparency.surface or 0
		Style.corner(frame, theme.radius.md)
		local kindColor = theme.colors[kind] or theme.colors.info
		Style.stroke(frame, math.max(theme.stroke.control, 2), kindColor)
		Style.padding(frame, { 10, 12, 10, 12 })
		accent.BackgroundColor3 = kindColor
		Style.corner(accent, theme.radius.pill)
		if title then
			Style.text(title, theme, "heading", false)
			title.TextSize = math.min(title.TextSize, 18)
			title.TextColor3 = theme.colors.text
		end
		Style.text(text, theme, "body", false)
		text.TextColor3 = if title then theme.colors.textMuted else theme.colors.text
	end)

	frame.Parent = parent
	Tween.pop(scale, { Scale = 1 }, "normal")
	Sound.play("notify")

	local toast = { frame = frame, scale = scale, dismissed = false }
	table.insert(active, toast)
	while #active > MAX_VISIBLE do
		dismiss(active[1])
	end

	frame.Activated:Connect(function()
		dismiss(toast)
	end)
	task.delay(options.Duration or 4, function()
		dismiss(toast)
	end)
	return toast
end

function Notifications.info(text: string, title: string?)
	return Notifications.push({ Text = text, Title = title, Kind = "info" })
end

function Notifications.success(text: string, title: string?)
	return Notifications.push({ Text = text, Title = title, Kind = "success" })
end

function Notifications.warning(text: string, title: string?)
	return Notifications.push({ Text = text, Title = title, Kind = "warning" })
end

function Notifications.error(text: string, title: string?)
	return Notifications.push({ Text = text, Title = title, Kind = "error" })
end

return Notifications
