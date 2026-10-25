--[[
	Dialog: modal questions that sit above windows.

		if Dialog.confirm({ Title = "Delete pet?", Text = "This can't be undone.", ConfirmText = "Delete", Danger = true }) then
			-- deleted
		end
		Dialog.alert({ Title = "Welcome!", Text = "Thanks for playing." })

	Both yield until the player answers. Tapping outside or pressing B cancels.
]]

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Tween = require(script.Parent.Parent.Util.Tween)
local Sound = require(script.Parent.Parent.Util.Sound)
local Layers = require(script.Parent.Parent.Util.Layers)
local Panel = require(script.Parent.Parent.Components.Panel)
local Text = require(script.Parent.Parent.Components.Text)
local Button = require(script.Parent.Parent.Components.Button)

local Dialog = {}

-- Answer functions of the dialogs on screen, so dismissAll can close them.
local open: { [any]: boolean } = {}

local function show(options: { [string]: any }, withCancel: boolean): boolean
	local layer = Layers.get("Dialogs")
	local result = Instance.new("BindableEvent")
	local answered = false

	local root = Create("Frame", {
		Name = "Dialog",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = layer,
	})
	local backdrop = Create("TextButton", {
		Name = "Backdrop",
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = root,
	})
	local panel = Panel.new({
		Name = "Box",
		Size = UDim2.fromOffset(420, 230),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Padding = "lg",
		ZIndex = 2,
		Parent = root,
	})
	local popScale = Create("UIScale", { Parent = panel.Instance })

	local content = panel.Content
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = content,
	})
	Text.new({
		Text = options.Title or "",
		Role = "heading",
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = 1,
		Parent = content,
	})
	Text.new({
		Text = options.Text or "",
		Role = "body",
		Color = "textMuted",
		Wrap = true,
		AlignY = Enum.TextYAlignment.Top,
		Size = UDim2.new(1, 0, 1, -110),
		LayoutOrder = 2,
		Parent = content,
	})
	local row = Create("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 64),
		LayoutOrder = 3,
		Parent = content,
	})
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = row,
	})

	local function answer(value: boolean)
		if answered then
			return
		end
		answered = true
		open[answer] = nil
		result:Fire(value)
	end
	open[answer] = true

	local confirm = Button.new({
		Text = options.ConfirmText or "OK",
		Variant = if options.Danger then "danger" else "primary",
		LayoutOrder = 2,
		Parent = row,
		OnClick = function()
			answer(true)
		end,
	})
	if withCancel then
		Button.new({
			Text = options.CancelText or "Cancel",
			Variant = "secondary",
			LayoutOrder = 1,
			Parent = row,
			OnClick = function()
				answer(false)
			end,
		})
	end

	backdrop.Activated:Connect(function()
		answer(false)
	end)
	local inputConnection = UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.ButtonB then
			answer(false)
		end
	end)

	local theme = Theme.get()
	backdrop.BackgroundColor3 = theme.colors.overlay
	Tween.play(backdrop, { BackgroundTransparency = theme.transparency.overlay }, "normal")
	local home = panel.Instance.Position
	Tween.reveal(panel.Instance, popScale, home, true)
	Sound.play("open")

	local previousSelection = GuiService.SelectedObject
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = confirm.Instance
	end

	local value = result.Event:Wait()
	inputConnection:Disconnect()
	result:Destroy()
	Sound.play("close")
	if UserInputService.GamepadEnabled and previousSelection and previousSelection.Parent then
		GuiService.SelectedObject = previousSelection
	end

	Tween.play(backdrop, { BackgroundTransparency = 1 }, "fast")
	local closing = Tween.reveal(panel.Instance, popScale, home, false)
	if closing then
		closing.Completed:Once(function()
			root:Destroy()
		end)
	else
		root:Destroy()
	end
	return value
end

function Dialog.confirm(options: { [string]: any }): boolean
	return show(options, true)
end

function Dialog.alert(options: { [string]: any })
	show(options, false)
end

-- Cancel every open dialog (confirm returns false).
function Dialog.dismissAll()
	for answer in table.clone(open) do
		answer(false)
	end
end

return Dialog
