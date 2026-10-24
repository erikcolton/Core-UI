--[[
	Manager: opens and closes registered windows so only one is open at a time.

		Manager.register("Shop", shop)  -- any object with a Window field, or a Window
		Manager.open("Shop")
		Manager.toggle("Inventory")
		Manager.close()                 -- closes whatever is open

	While a window is open, a backdrop dims the game. Tapping the backdrop or pressing
	B on a gamepad closes the window. Opening a window moves gamepad selection into it.
]]

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local Create = require(script.Parent.Util.Create)
local Tween = require(script.Parent.Util.Tween)
local Signal = require(script.Parent.Util.Signal)
local Layers = require(script.Parent.Util.Layers)

local Manager = {}

Manager.Opened = Signal.new()
Manager.Closed = Signal.new()

local screens: { [string]: any } = {}
local openId: string? = nil
local backdrop: TextButton? = nil
local inputConnection: RBXScriptConnection? = nil

local function windowOf(screen: any): any
	return screen.Window or screen
end

local function ensureBackdrop(): TextButton
	if backdrop and backdrop.Parent then
		return backdrop
	end
	local button = Create("TextButton", {
		Name = "Backdrop",
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Selectable = false,
		Visible = false,
		Parent = Layers.get("Backdrop"),
	})
	Theme.bind(button, function(theme)
		button.BackgroundColor3 = theme.colors.overlay
		if button.Visible then
			button.BackgroundTransparency = theme.transparency.overlay
		end
	end)
	button.Activated:Connect(function()
		local screen = openId and screens[openId]
		if screen and screen.CloseOnBackdrop ~= false then
			Manager.close(openId)
		end
	end)
	backdrop = button
	return button
end

local function showBackdrop()
	local button = ensureBackdrop()
	if not button.Visible then
		button.Visible = true
		button.BackgroundTransparency = 1
	end
	Tween.play(button, { BackgroundTransparency = Theme.get().transparency.overlay }, "normal")
end

local function hideBackdrop()
	local button = ensureBackdrop()
	local tween = Tween.play(button, { BackgroundTransparency = 1 }, "fast")
	tween.Completed:Once(function()
		if openId == nil then
			button.Visible = false
		end
	end)
end

local function firstSelectable(root: Instance): GuiObject?
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("GuiButton") and descendant.Selectable and descendant.Visible then
			return descendant
		end
	end
	return nil
end

local function listenForInput()
	if inputConnection then
		return
	end
	inputConnection = UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.ButtonB and openId then
			Manager.close(openId)
		end
	end)
end

function Manager.register(id: string, screen: any): any
	screens[id] = screen
	local window = windowOf(screen)
	window.OnCloseRequest = function()
		Manager.close(id)
	end
	listenForInput()
	return screen
end

function Manager.unregister(id: string)
	if openId == id then
		Manager.close(id)
	end
	screens[id] = nil
end

function Manager.get(id: string): any
	return screens[id]
end

function Manager.isOpen(id: string): boolean
	return openId == id
end

function Manager.current(): string?
	return openId
end

function Manager.open(id: string)
	local screen = screens[id]
	if not screen then
		warn("CoreUI: no screen registered as " .. tostring(id))
		return
	end
	if openId == id then
		return
	end
	if openId then
		Manager.close(openId, true)
	end
	openId = id
	showBackdrop()
	local window = windowOf(screen)
	window:Open()
	if type(screen.OnOpen) == "function" then
		task.spawn(screen.OnOpen, screen)
	end
	if UserInputService.GamepadEnabled then
		local target = firstSelectable(window.Instance)
		if target then
			GuiService.SelectedObject = target
		end
	end
	Manager.Opened:Fire(id)
end

-- Close the open window (or the one named). switching = true keeps the backdrop up.
function Manager.close(id: string?, switching: boolean?)
	local target = id or openId
	if not target or target ~= openId then
		return
	end
	local screen = screens[target]
	openId = nil
	if screen then
		windowOf(screen):Close()
		if type(screen.OnClose) == "function" then
			task.spawn(screen.OnClose, screen)
		end
	end
	if not switching then
		hideBackdrop()
		GuiService.SelectedObject = nil
	end
	Manager.Closed:Fire(target)
end

function Manager.toggle(id: string)
	if openId == id then
		Manager.close(id)
	else
		Manager.open(id)
	end
end

return Manager
