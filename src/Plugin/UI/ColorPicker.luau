--[[
	Color picker popover: saturation/value square, hue bar, hex and RGB boxes,
	the theme's own palette and recently used colors.

		ColorPicker.open(overlay, anchor, {
			Color = current,
			Palette = { Color3, ... },
			Recent = { Color3, ... },
			OnChange = function(color, final) end, -- final = true when a drag or edit ends
		})
]]

local Controls = require(script.Parent.Controls)
local Create = require(script.Parent.Parent.CoreUI.Util.Create)
local Color = require(script.Parent.Parent.CoreUI.Util.Color)

local ColorPicker = {}

local WIDTH = 248
local SQUARE = 150
local HUE_HEIGHT = 14

local function quantize(color: Color3): Color3
	return Color3.fromRGB(math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
end

local function rainbow(): ColorSequence
	local keys = {}
	for index = 0, 6 do
		table.insert(keys, ColorSequenceKeypoint.new(index / 6, Color3.fromHSV((index / 6) % 1, 1, 1)))
	end
	return ColorSequence.new(keys)
end

local function paletteRow(parent: Instance, title: string, colors: { Color3 }, order: number, pick: (Color3) -> ())
	if #colors == 0 then
		return 0
	end
	Controls.label({
		Text = title,
		Dim = true,
		TextSize = 12,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = order,
		Parent = parent,
	})
	local row = Create("Frame", {
		Name = title,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = order + 1,
		Parent = parent,
	})
	Controls.list(row, 4, true)
	for index, color in colors do
		if index > 10 then
			break
		end
		local swatch = Controls.swatch(color, 18, { LayoutOrder = index, Parent = row })
		swatch.Activated:Connect(function()
			pick(color)
		end)
	end
	return 36
end

function ColorPicker.open(overlay: any, anchor: GuiObject, options: { [string]: any })
	local h, s, v = (options.Color :: Color3):ToHSV()
	local current = options.Color

	local paletteHeight = (if #(options.Palette or {}) > 0 then 40 else 0)
		+ (if #(options.Recent or {}) > 0 then 40 else 0)
	local height = 12 + SQUARE + 8 + HUE_HEIGHT + 10 + 26 + 6 + paletteHeight + 8

	overlay:popover(anchor, WIDTH, height, function(frame: Frame)
		Controls.padding(frame, 8)
		Controls.list(frame, 6)

		-- Saturation (left to right) and value (top to bottom) over the hue color.
		local square = Create("TextButton", {
			Name = "SV",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			Text = "",
			Size = UDim2.new(1, 0, 0, SQUARE),
			LayoutOrder = 1,
			Parent = frame,
		})
		Controls.corner(square, 3)
		local white = Create("Frame", {
			Name = "White",
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.fromScale(1, 1),
			Parent = square,
		})
		Controls.corner(white, 3)
		Create("UIGradient", {
			Transparency = NumberSequence.new(0, 1),
			Parent = white,
		})
		local black = Create("Frame", {
			Name = "Black",
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.new(0, 0, 0),
			Size = UDim2.fromScale(1, 1),
			Parent = square,
		})
		Controls.corner(black, 3)
		Create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new(1, 0),
			Parent = black,
		})
		local cursor = Create("Frame", {
			Name = "Cursor",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(10, 10),
			ZIndex = 3,
			Parent = square,
		})
		Controls.corner(cursor, 5)
		Create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Parent = cursor })

		local hue = Create("TextButton", {
			Name = "Hue",
			AutoButtonColor = false,
			BorderSizePixel = 0,
			Text = "",
			BackgroundColor3 = Color3.new(1, 1, 1),
			Size = UDim2.new(1, 0, 0, HUE_HEIGHT),
			LayoutOrder = 2,
			Parent = frame,
		})
		Controls.corner(hue, 3)
		Create("UIGradient", { Color = rainbow(), Parent = hue })
		local hueCursor = Create("Frame", {
			Name = "Cursor",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 4, 1, 4),
			Position = UDim2.fromScale(0, 0.5),
			Parent = hue,
		})
		Controls.corner(hueCursor, 2)
		Create("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.4, Parent = hueCursor })

		local inputs = Create("Frame", {
			Name = "Inputs",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 26),
			LayoutOrder = 3,
			Parent = frame,
		})
		Controls.list(inputs, 4, true)
		local preview = Controls.swatch(current, 24, { LayoutOrder = 0, Parent = inputs })
		preview.Active = false

		local hexBox, rgbBoxes
		local function render(skipBoxes: boolean?)
			square.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			cursor.Position = UDim2.fromScale(s, 1 - v)
			hueCursor.Position = UDim2.fromScale(h, 0.5)
			preview.BackgroundColor3 = current
			if not skipBoxes then
				hexBox.Text = Color.toHex(current)
				rgbBoxes[1].Text = tostring(math.round(current.R * 255))
				rgbBoxes[2].Text = tostring(math.round(current.G * 255))
				rgbBoxes[3].Text = tostring(math.round(current.B * 255))
			end
		end

		local function emit(final: boolean)
			options.OnChange(current, final)
		end

		local function setColor(color: Color3, final: boolean)
			current = quantize(color)
			local nh, ns, nv = current:ToHSV()
			-- Keep the hue when the color is grey, so the square does not jump to red.
			if ns > 0 and nv > 0 then
				h = nh
			end
			s, v = ns, nv
			render()
			emit(final)
		end

		local function setFromHSV(final: boolean)
			current = quantize(Color3.fromHSV(h, s, v))
			render()
			emit(final)
		end

		hexBox = Controls.textBox({
			Mono = true,
			Size = UDim2.fromOffset(76, 24),
			LayoutOrder = 1,
			Parent = inputs,
			OnCommit = function(text)
				local parsed = Color.fromHex(text)
				if parsed then
					setColor(parsed, true)
				else
					render()
				end
			end,
		})
		rgbBoxes = {}
		for index = 1, 3 do
			rgbBoxes[index] = Controls.textBox({
				Mono = true,
				Size = UDim2.fromOffset(40, 24),
				LayoutOrder = 1 + index,
				Parent = inputs,
				OnCommit = function()
					local r = tonumber(rgbBoxes[1].Text)
					local g = tonumber(rgbBoxes[2].Text)
					local b = tonumber(rgbBoxes[3].Text)
					if r and g and b then
						setColor(
							Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255)),
							true
						)
					else
						render()
					end
				end,
			})
		end

		local order = 10
		order += paletteRow(frame, "Theme colors", options.Palette or {}, order, function(color)
			setColor(color, true)
		end)
		paletteRow(frame, "Recent", options.Recent or {}, order + 2, function(color)
			setColor(color, true)
		end)

		square.MouseButton1Down:Connect(function()
			overlay:drag(function(mouse: Vector2)
				local origin = square.AbsolutePosition
				local size = square.AbsoluteSize
				s = math.clamp((mouse.X - origin.X) / size.X, 0, 1)
				v = 1 - math.clamp((mouse.Y - origin.Y) / size.Y, 0, 1)
				setFromHSV(false)
			end, function()
				emit(true)
			end)
		end)
		hue.MouseButton1Down:Connect(function()
			overlay:drag(function(mouse: Vector2)
				local origin = hue.AbsolutePosition
				h = math.clamp((mouse.X - origin.X) / hue.AbsoluteSize.X, 0, 0.999)
				setFromHSV(false)
			end, function()
				emit(true)
			end)
		end)

		render()
	end, options.OnClose)
end

return ColorPicker
