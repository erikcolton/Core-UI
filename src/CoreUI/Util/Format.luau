--[[
	Number and time formatting used by counters, prices and timers.
]]

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

-- 1234 -> "1.2K", 15300000 -> "15.3M". Values under 1000 are shown in full.
function Format.abbreviate(value: number, decimals: number?): string
	local places = decimals or 1
	local sign = if value < 0 then "-" else ""
	local n = math.abs(value)
	if n < 1000 then
		return sign .. tostring(math.floor(n))
	end
	local tier = math.min(math.floor(math.log10(n) / 3), #SUFFIXES - 1)
	local scaled = n / 10 ^ (tier * 3)
	-- log10 can land a hair under a whole number (1e6 -> 5.9999...), so correct the tier.
	if scaled >= 1000 and tier < #SUFFIXES - 1 then
		tier += 1
		scaled /= 1000
	end
	-- Truncate rather than round so 999.96K never shows as "1000.0K".
	local factor = 10 ^ places
	scaled = math.floor(scaled * factor) / factor
	local text = string.format("%." .. places .. "f", scaled)
	if string.find(text, ".", 1, true) then
		text = (string.gsub(text, "0+$", ""))
		text = (string.gsub(text, "%.$", ""))
	end
	return sign .. text .. SUFFIXES[tier + 1]
end

-- 1234567 -> "1,234,567"
function Format.commas(value: number): string
	local sign = if value < 0 then "-" else ""
	local digits = tostring(math.floor(math.abs(value)))
	local result = string.reverse((string.gsub(string.reverse(digits), "(%d%d%d)", "%1,")))
	if string.sub(result, 1, 1) == "," then
		result = string.sub(result, 2)
	end
	return sign .. result
end

-- 75 -> "01:15", 3725 -> "1:02:05"
function Format.duration(seconds: number): string
	local total = math.max(0, math.floor(seconds))
	local hours = total // 3600
	local minutes = (total % 3600) // 60
	local secs = total % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%02d:%02d", minutes, secs)
end

return Format
