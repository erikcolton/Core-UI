--[[
	Things that float above the editor inside the plugin window: popovers (dropdowns,
	the color picker), modal dialogs, and a full-window catcher that keeps a slider
	drag going while the mouse leaves the control.
]]

local Studio = require(script.Parent.Studio)
local Controls = require(script.Parent.Controls)
local Create = require(script.Parent.Parent.CoreUI.Util.Create)

local Overlay = {}
Overlay.__index = Overlay

function Overlay.new(root: GuiObject, widget: PluginGui)
	local self = setmetatable({}, Overlay)
	self.root = root
	self.widget = widget
	self.layer = Create("Frame", {
		Name = "Overlay",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
		Parent = root,
	})
	self._popover = nil
	self._modal = nil
	return self
end

-- Mouse position inside the plugin window, in the same space as AbsolutePosition.
function Overlay:mouse(): Vector2
	return self.widget:GetRelativeMousePosition()
end

function Overlay:_catcher(zIndex: number, transparency: number?): TextButton
	local catcher = Create("TextButton", {
		Name = "Catcher",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Text = "",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = transparency or 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = zIndex,
		Parent = self.layer,
	})
	return catcher
end

function Overlay:closePopover()
	if self._popover then
		local popover = self._popover
		self._popover = nil
		popover.catcher:Destroy()
		popover.frame:Destroy()
		if popover.onClose then
			popover.onClose()
		end
	end
end

--[[
	Opens a panel under anchor (or above it when there is no room). build(frame, close)
	fills it. Clicking outside closes it.
]]
function Overlay:popover(
	anchor: GuiObject,
	width: number,
	height: number,
	build: (Frame, () -> ()) -> (),
	onClose: (() -> ())?
)
	self:closePopover()
	local catcher = self:_catcher(60)
	local rootSize = self.root.AbsoluteSize
	local rootPos = self.root.AbsolutePosition
	local anchorPos = anchor.AbsolutePosition - rootPos
	local x = math.clamp(anchorPos.X + anchor.AbsoluteSize.X - width, 4, math.max(4, rootSize.X - width - 4))
	local below = anchorPos.Y + anchor.AbsoluteSize.Y + 2
	local y = if below + height <= rootSize.Y - 4 then below else math.max(4, anchorPos.Y - height - 2)
	height = math.min(height, rootSize.Y - 8)

	local frame = Create("Frame", {
		Name = "Popover",
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(width, height),
		ZIndex = 61,
		Parent = self.layer,
	})
	Controls.corner(frame, 4)
	Controls.stroke(frame)
	Studio.bind(frame, function(c)
		frame.BackgroundColor3 = c.background
	end)
	local popover = { catcher = catcher, frame = frame, onClose = onClose }
	self._popover = popover
	catcher.MouseButton1Down:Connect(function()
		if self._popover == popover then
			self:closePopover()
		end
	end)
	build(frame, function()
		if self._popover == popover then
			self:closePopover()
		end
	end)
end

--[[
	Modal dialog.
		overlay:modal({
			Title = "Rename theme",
			Message = "Optional text",
			Input = { Text = "My theme", Placeholder = "Name", Multiline = false, Mono = false, Height = 24 },
			Buttons = { { Text = "Save", Style = "primary", OnClick = function(text) return keepOpen end }, ... },
		})
]]
function Overlay:modal(options: { [string]: any })
	self:closeModal()
	self:closePopover()
	local catcher = self:_catcher(70, 0.45)
	local width = math.min(380, self.root.AbsoluteSize.X - 24)
	local box = Create("Frame", {
		Name = "Modal",
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 71,
		Parent = self.layer,
	})
	Controls.corner(box, 6)
	Controls.stroke(box)
	Controls.padding(box, 14)
	Controls.list(box, 10)
	Studio.bind(box, function(c)
		box.BackgroundColor3 = c.background
	end)
	Controls.label({ Text = options.Title or "", Bold = true, TextSize = 16, LayoutOrder = 1, Parent = box })
	if options.Message then
		Controls.label({
			Text = options.Message,
			Wrap = true,
			RichText = true,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2,
			Parent = box,
		})
	end
	local input: TextBox? = nil
	if options.Input then
		local spec = options.Input
		input = Controls.textBox({
			Text = spec.Text,
			Placeholder = spec.Placeholder,
			Multiline = spec.Multiline,
			Mono = spec.Mono,
			Size = UDim2.new(1, 0, 0, spec.Height or 26),
			LayoutOrder = 3,
			Parent = box,
		})
	end
	local row = Create("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 4,
		Parent = box,
	})
	local layout = Controls.list(row, 8, true)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	local buttons = options.Buttons or { { Text = "OK", Style = "primary" } }
	for index, spec in buttons do
		Controls.button(spec.Text, {
			Style = spec.Style,
			Height = 26,
			LayoutOrder = index,
			Parent = row,
			OnClick = function()
				local keepOpen = false
				if spec.OnClick then
					keepOpen = spec.OnClick(if input then input.Text else nil) == true
				end
				if not keepOpen then
					self:closeModal()
				end
			end,
		})
	end
	self._modal = { catcher = catcher, box = box }
	if input and options.Input.Focus ~= false then
		task.defer(function()
			if input.Parent then
				input:CaptureFocus()
				if options.Input.SelectAll then
					input.SelectionStart = 1
					input.CursorPosition = #input.Text + 1
				end
			end
		end)
	end
	return input
end

function Overlay:closeModal()
	if self._modal then
		self._modal.catcher:Destroy()
		self._modal.box:Destroy()
		self._modal = nil
	end
end

-- Simple message with one OK button.
function Overlay:alert(title: string, message: string)
	self:modal({ Title = title, Message = message })
end

-- Yes/no question; onYes runs when confirmed.
function Overlay:confirm(title: string, message: string, yesText: string, onYes: () -> (), danger: boolean?)
	self:modal({
		Title = title,
		Message = message,
		Buttons = {
			{ Text = "Cancel" },
			{ Text = yesText, Style = if danger then "danger" else "primary", OnClick = onYes },
		},
	})
end

--[[
	Keeps reporting the mouse position until the button is released, even when the
	mouse moves off the control that started the drag.
]]
function Overlay:drag(onMove: (Vector2) -> (), onEnd: (() -> ())?)
	local catcher = self:_catcher(90)
	local finished = false
	local function finish()
		if finished then
			return
		end
		finished = true
		catcher:Destroy()
		if onEnd then
			onEnd()
		end
	end
	catcher.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			onMove(self:mouse())
		end
	end)
	catcher.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			finish()
		end
	end)
	catcher.MouseButton1Up:Connect(finish)
	catcher.MouseLeave:Connect(finish)
	-- If a release was ever missed, the next click clears the catcher instead of
	-- leaving the window blocked.
	catcher.MouseButton1Down:Connect(finish)
	onMove(self:mouse())
end

return Overlay
