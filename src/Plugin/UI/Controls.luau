--[[
	Studio-styled building blocks for the plugin's own interface: labels, buttons,
	text boxes, rows and collapsible sections. They follow the Studio theme, never the
	Core UI theme being edited.
]]

local Studio = require(script.Parent.Studio)
local Create = require(script.Parent.Parent.CoreUI.Util.Create)

local Controls = {}

Controls.ROW = 28
Controls.LABEL_WIDTH = 0.42

function Controls.corner(instance: Instance, radius: number?)
	Create("UICorner", { CornerRadius = UDim.new(0, radius or 4), Parent = instance })
end

function Controls.stroke(instance: Instance, colorName: string?)
	local stroke = Create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
		Parent = instance,
	})
	Studio.bind(stroke, function(c)
		stroke.Color = c[colorName or "border"]
	end)
	return stroke
end

function Controls.padding(instance: Instance, top: number, right: number?, bottom: number?, left: number?)
	Create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right or top),
		PaddingBottom = UDim.new(0, bottom or top),
		PaddingLeft = UDim.new(0, left or right or top),
		Parent = instance,
	})
end

function Controls.list(instance: Instance, gap: number?, horizontal: boolean?): UIListLayout
	return Create("UIListLayout", {
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = if horizontal then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, gap or 0),
		Parent = instance,
	})
end

-- props: Text, Dim, Bold, Mono, Size, Wrap, AlignX, plus any TextLabel property.
function Controls.label(props: { [string]: any }): TextLabel
	local dim = props.Dim
	local label = Create("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = if props.Bold then Studio.fontBold elseif props.Mono then Studio.fontMono else Studio.font,
		TextSize = props.TextSize or Studio.textSize,
		TextXAlignment = props.AlignX or Enum.TextXAlignment.Left,
		TextWrapped = props.Wrap == true,
		TextTruncate = if props.Wrap then Enum.TextTruncate.None else Enum.TextTruncate.AtEnd,
		Text = props.Text or "",
		Size = props.Size or UDim2.new(1, 0, 0, Controls.ROW),
		AutomaticSize = props.AutomaticSize,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder or 0,
		RichText = props.RichText == true,
		Name = props.Name or "Label",
		Parent = props.Parent,
	})
	Studio.bind(label, function(c)
		label.TextColor3 = if props.Color then c[props.Color] else if dim then c.dim else c.text
	end)
	return label
end

local STYLES = {
	primary = { "accent", "accentHover", "accentText" },
	secondary = { "button", "buttonHover", "buttonText" },
	danger = { "danger", "dangerHover", "accentText" },
	ghost = { "background", "hover", "text" },
}

-- opts: Style (primary | secondary | danger | ghost), Width, Height, OnClick, Tooltip text in Hint.
function Controls.button(text: string, opts: { [string]: any }?): TextButton
	local o = opts or {}
	local style = STYLES[o.Style or "secondary"]
	local button = Create("TextButton", {
		Name = o.Name or text,
		AutoButtonColor = false,
		BorderSizePixel = 0,
		FontFace = Studio.fontBold,
		TextSize = o.TextSize or 13,
		Text = text,
		Size = o.Size or UDim2.fromOffset(o.Width or 0, o.Height or 24),
		AutomaticSize = if o.Width or o.Size then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
		LayoutOrder = o.LayoutOrder or 0,
		Position = o.Position,
		AnchorPoint = o.AnchorPoint,
		Parent = o.Parent,
	})
	Controls.corner(button, 4)
	if not (o.Width or o.Size) then
		Controls.padding(button, 0, 10, 0, 10)
	end
	if o.Style ~= "primary" and o.Style ~= "danger" then
		Controls.stroke(button)
	end
	local hovered = false
	local enabled = true
	local function paint(c)
		local colors = c or Studio.colors
		if button:GetAttribute("Selected") then
			-- Selected tabs keep the accent color whatever the hover state.
			button.BackgroundColor3 = colors.accent
			button.TextColor3 = colors.accentText
		else
			button.BackgroundColor3 = colors[if hovered and enabled then style[2] else style[1]]
			button.TextColor3 = colors[style[3]]
		end
		button.TextTransparency = if enabled then 0 else 0.5
		button.BackgroundTransparency = if enabled then 0 else 0.4
	end
	Studio.bind(button, paint)
	button.MouseEnter:Connect(function()
		hovered = true
		paint()
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		paint()
	end)
	if o.OnClick then
		button.Activated:Connect(function()
			if enabled then
				o.OnClick(button)
			end
		end)
	end
	button:GetAttributeChangedSignal("Selected"):Connect(function()
		paint()
	end)
	-- Lets callers grey a button out: button:SetAttribute("Enabled", false).
	button:SetAttribute("Enabled", true)
	button:GetAttributeChangedSignal("Enabled"):Connect(function()
		enabled = button:GetAttribute("Enabled") ~= false
		button.Active = enabled
		paint()
	end)
	return button
end

-- opts: Text, Placeholder, Mono, Multiline, OnCommit(text, enterPressed), Size, ClearOnFocus
function Controls.textBox(opts: { [string]: any }): TextBox
	local box = Create("TextBox", {
		Name = opts.Name or "Input",
		BorderSizePixel = 0,
		ClearTextOnFocus = opts.ClearOnFocus == true,
		FontFace = if opts.Mono then Studio.fontMono else Studio.font,
		TextSize = opts.TextSize or 13,
		Text = opts.Text or "",
		PlaceholderText = opts.Placeholder or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = if opts.Multiline then Enum.TextYAlignment.Top else Enum.TextYAlignment.Center,
		MultiLine = opts.Multiline == true,
		TextWrapped = opts.Multiline == true,
		TextTruncate = if opts.Multiline then Enum.TextTruncate.None else Enum.TextTruncate.AtEnd,
		ClipsDescendants = true,
		Size = opts.Size or UDim2.new(1, 0, 0, 24),
		Position = opts.Position,
		AnchorPoint = opts.AnchorPoint,
		LayoutOrder = opts.LayoutOrder or 0,
		Parent = opts.Parent,
	})
	Controls.corner(box, 3)
	Controls.padding(box, if opts.Multiline then 6 else 0, 6, if opts.Multiline then 6 else 0, 6)
	local stroke = Controls.stroke(box, "inputBorder")
	Studio.bind(box, function(c)
		box.BackgroundColor3 = c.input
		box.TextColor3 = c.text
		box.PlaceholderColor3 = c.dim
	end)
	box.Focused:Connect(function()
		stroke.Color = Studio.colors.accent
	end)
	box.FocusLost:Connect(function(enterPressed)
		stroke.Color = Studio.colors.inputBorder
		if opts.OnCommit then
			opts.OnCommit(box.Text, enterPressed)
		end
	end)
	return box
end

-- A labelled row: label on the left, returns the frame for the control on the right.
function Controls.row(parent: Instance, labelText: string, height: number?, order: number?): (Frame, Frame)
	local row = Create("Frame", {
		Name = "Row_" .. labelText,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height or Controls.ROW),
		LayoutOrder = order or 0,
		Parent = parent,
	})
	Controls.label({
		Text = labelText,
		Size = UDim2.new(Controls.LABEL_WIDTH, -6, 0, Controls.ROW),
		Parent = row,
	})
	local control = Create("Frame", {
		Name = "Control",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(Controls.LABEL_WIDTH, 0),
		Size = UDim2.new(1 - Controls.LABEL_WIDTH, 0, 1, 0),
		Parent = row,
	})
	return row, control
end

-- A collapsible section with a header bar. Returns the section frame and its content frame.
function Controls.section(parent: Instance, title: string, opts: { [string]: any }?): (Frame, Frame)
	local o = opts or {}
	local collapsed = o.Collapsed == true
	local section = Create("Frame", {
		Name = "Section_" .. title,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = o.LayoutOrder or 0,
		Parent = parent,
	})
	Controls.list(section)
	local header = Create("TextButton", {
		Name = "Header",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Text = "",
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 0,
		Parent = section,
	})
	Studio.bind(header, function(c)
		header.BackgroundColor3 = c.section
	end)
	local arrow = Controls.label({
		Text = "",
		Size = UDim2.fromOffset(18, 26),
		Position = UDim2.fromOffset(6, 0),
		Dim = true,
		Parent = header,
	})
	Controls.label({
		Text = title,
		Bold = true,
		Size = UDim2.new(1, -28, 0, 26),
		Position = UDim2.fromOffset(24, 0),
		Parent = header,
	})
	local content = Create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Parent = section,
	})
	Controls.list(content, 4)
	Controls.padding(content, 6, 10, 10, 10)
	if o.Hint then
		Controls.label({
			Text = o.Hint,
			Dim = true,
			Wrap = true,
			TextSize = 12,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = -1,
			Parent = content,
		})
	end
	local function render()
		content.Visible = not collapsed
		arrow.Text = if collapsed then "▸" else "▾"
	end
	header.Activated:Connect(function()
		collapsed = not collapsed
		render()
	end)
	render()
	return section, content
end

-- A small color square, used by color fields and palettes.
function Controls.swatch(color: Color3, size: number, props: { [string]: any }?): TextButton
	local p = props or {}
	local swatch = Create("TextButton", {
		Name = p.Name or "Swatch",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		Text = "",
		BackgroundColor3 = color,
		Size = UDim2.fromOffset(size, size),
		LayoutOrder = p.LayoutOrder or 0,
		Position = p.Position,
		Parent = p.Parent,
	})
	Controls.corner(swatch, 3)
	Controls.stroke(swatch, "inputBorder")
	return swatch
end

return Controls
