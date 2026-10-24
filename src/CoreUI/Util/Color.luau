--[[
	Color helpers for deriving shades from theme colors.
]]

local Color = {}

local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

function Color.darken(color: Color3, amount: number): Color3
	return color:Lerp(BLACK, amount)
end

function Color.lighten(color: Color3, amount: number): Color3
	return color:Lerp(WHITE, amount)
end

-- Relative luminance, used to pick readable text on an arbitrary fill.
function Color.luminance(color: Color3): number
	local function channel(c: number): number
		return if c <= 0.03928 then c / 12.92 else ((c + 0.055) / 1.055) ^ 2.4
	end
	return 0.2126 * channel(color.R) + 0.7152 * channel(color.G) + 0.0722 * channel(color.B)
end

function Color.readableOn(color: Color3, dark: Color3?, light: Color3?): Color3
	if Color.luminance(color) > 0.45 then
		return dark or BLACK
	end
	return light or WHITE
end

-- Two-tone sequence with a hard stop in the middle, the classic cartoony button fill.
function Color.twoTone(color: Color3, highlight: number): ColorSequence
	local top = Color.lighten(color, highlight)
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, top),
		ColorSequenceKeypoint.new(0.5, top),
		ColorSequenceKeypoint.new(0.501, color),
		ColorSequenceKeypoint.new(1, color),
	})
end

return Color
