--[[
	Tooltip: a hint that follows the pointer while it is over a GUI object.
	Mouse only; touch devices skip it.

		local detach = Tooltip.attach(button.Instance, "Doubles your coins")
		Tooltip.attach(slot.Instance, function() return slot.Item.Name end)
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)
local Create = require(script.Parent.Parent.Util.Create)
local Style = require(script.Parent.Parent.Util.Style)
local Layers = require(script.Parent.Parent.Util.Layers)

local Tooltip = {}

local frame: Frame? = nil
local label: TextLabel? = nil
local owner: GuiObject? = nil
local followConnection: RBXScriptConnection? = nil

local OFFSET = Vector2.new(16, 18)

local function ensure(): (Frame, TextLabel)
	if frame and frame.Parent and label then
		return frame, label
	end
	local newFrame = Create("Frame", {
		Name = "Tooltip",
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 100,
		Parent = Layers.get("Overlay"),
	})
	local newLabel = Create("TextLabel", {
		Name = "Text",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
		TextWrapped = false,
		RichText = true,
		ZIndex = 101,
		Parent = newFrame,
	})
	Create("UISizeConstraint", { MaxSize = Vector2.new(280, math.huge), Parent = newFrame })
	Theme.bind(newFrame, function(theme)
		newFrame.BackgroundColor3 = theme.colors.text
		newFrame.BackgroundTransparency = 0.05
		Style.corner(newFrame, theme.radius.sm)
		Style.padding(newFrame, { 6, 10, 6, 10 })
		Style.text(newLabel, theme, "caption", false)
		newLabel.TextColor3 = theme.colors.surface
	end)
	frame, label = newFrame, newLabel
	return newFrame, newLabel
end

local function hide(target: GuiObject?)
	if target ~= nil and owner ~= target then
		return
	end
	owner = nil
	if followConnection then
		followConnection:Disconnect()
		followConnection = nil
	end
	if frame then
		frame.Visible = false
	end
end

local function show(target: GuiObject, text: string)
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return
	end
	local tip, textLabel = ensure()
	owner = target
	textLabel.Text = text
	tip.Visible = text ~= ""
	if followConnection then
		followConnection:Disconnect()
	end
	followConnection = RunService.RenderStepped:Connect(function()
		if not target.Parent or not target.Visible then
			hide(target)
			return
		end
		local scale = Layers.scale("Overlay")
		local position = (UserInputService:GetMouseLocation() + OFFSET) / scale
		tip.Position = UDim2.fromOffset(position.X, position.Y)
	end)
end

function Tooltip.attach(target: GuiObject, text: string | () -> string): () -> ()
	local enter = target.MouseEnter:Connect(function()
		show(target, if type(text) == "function" then text() else text)
	end)
	local leave = target.MouseLeave:Connect(function()
		hide(target)
	end)
	return function()
		enter:Disconnect()
		leave:Disconnect()
		hide(target)
	end
end

function Tooltip.hide()
	hide(nil)
end

return Tooltip
