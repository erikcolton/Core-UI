--[[
	Turns themes into plain data and back, so they can be saved in a place, shared
	as text, or exported as Luau.

	A saved theme is a record:

		{ format = 1, name = "Lava", base = "Cartoony", overrides = { colors = { ... } } }

	overrides holds only what differs from the base theme, so a saved theme picks up
	tokens added to the kit later. Roblox values (Color3, Font, UDim, Vector2, Rect,
	EnumItem) are stored as small tables tagged with "$type".
]]

local HttpService = game:GetService("HttpService")

local Serialize = {}

Serialize.FORMAT = 1

-- Stands for "no value" in overrides, e.g. a theme that removes its base's click sound.
-- Theme.merge drops keys set to None.
Serialize.None = setmetatable({}, {
	__tostring = function()
		return "None"
	end,
})
table.freeze(Serialize.None)

local function isPlainTable(value: any): boolean
	return type(value) == "table" and getmetatable(value) == nil
end

local function byte(channel: number): number
	return math.clamp(math.round(channel * 255), 0, 255)
end

-- Roblox value or token table -> JSON-safe value.
function Serialize.encode(value: any): any
	local kind = typeof(value)
	if kind == "Color3" then
		return { ["$type"] = "Color3", v = { byte(value.R), byte(value.G), byte(value.B) } }
	elseif kind == "Font" then
		return {
			["$type"] = "Font",
			family = value.Family,
			weight = value.Weight.Name,
			style = value.Style.Name,
		}
	elseif kind == "UDim" then
		return { ["$type"] = "UDim", v = { value.Scale, value.Offset } }
	elseif kind == "Vector2" then
		return { ["$type"] = "Vector2", v = { value.X, value.Y } }
	elseif kind == "Rect" then
		return { ["$type"] = "Rect", v = { value.Min.X, value.Min.Y, value.Max.X, value.Max.Y } }
	elseif kind == "EnumItem" then
		-- tostring(Enum.X) is "X" in Roblox and "Enum.X" in some tools.
		local enumName = string.gsub(tostring(value.EnumType), "^Enum%.", "")
		return { ["$type"] = "Enum", enum = enumName, name = value.Name }
	elseif value == Serialize.None then
		return { ["$type"] = "None" }
	elseif kind == "table" then
		local result = {}
		for key, child in value do
			if type(key) == "string" then
				result[key] = Serialize.encode(child)
			end
		end
		return result
	elseif kind == "number" or kind == "string" or kind == "boolean" then
		return value
	end
	return nil
end

local function enumItem(enumName: string, itemName: string): EnumItem?
	local ok, item = pcall(function()
		return (Enum :: any)[enumName][itemName]
	end)
	return if ok then item else nil
end

local function numbers(list: any, count: number): boolean
	if type(list) ~= "table" then
		return false
	end
	for index = 1, count do
		if type(list[index]) ~= "number" then
			return false
		end
	end
	return true
end

-- JSON-safe value -> Roblox value or token table. Unknown or broken entries become nil.
function Serialize.decode(data: any): any
	if type(data) ~= "table" then
		return data
	end
	local tag = data["$type"]
	if tag == nil then
		local result = {}
		for key, child in data do
			result[key] = Serialize.decode(child)
		end
		return result
	end
	local v = data.v
	if tag == "Color3" and numbers(v, 3) then
		return Color3.fromRGB(v[1], v[2], v[3])
	elseif tag == "Font" and type(data.family) == "string" then
		local weight = enumItem("FontWeight", data.weight or "Regular") or Enum.FontWeight.Regular
		local style = enumItem("FontStyle", data.style or "Normal") or Enum.FontStyle.Normal
		return Font.new(data.family, weight :: any, style :: any)
	elseif tag == "UDim" and numbers(v, 2) then
		return UDim.new(v[1], v[2])
	elseif tag == "Vector2" and numbers(v, 2) then
		return Vector2.new(v[1], v[2])
	elseif tag == "Rect" and numbers(v, 4) then
		return Rect.new(v[1], v[2], v[3], v[4])
	elseif tag == "Enum" and type(data.enum) == "string" and type(data.name) == "string" then
		return enumItem(data.enum, data.name)
	elseif tag == "None" then
		return Serialize.None
	end
	return nil
end

-- Value equality that understands Fonts and nested token tables.
function Serialize.equals(a: any, b: any): boolean
	if a == b then
		return true
	end
	local kind = typeof(a)
	if kind ~= typeof(b) then
		return false
	elseif kind == "Font" then
		return a.Family == b.Family and a.Weight == b.Weight and a.Style == b.Style
	elseif isPlainTable(a) and isPlainTable(b) then
		for key, value in a do
			if not Serialize.equals(value, b[key]) then
				return false
			end
		end
		for key in b do
			if a[key] == nil then
				return false
			end
		end
		return true
	end
	return false
end

-- What full changes relative to base, as an overrides table (nil when nothing differs).
-- A key that base has and full lacks becomes None.
function Serialize.diff(base: any, full: any): any?
	local result = {}
	local changed = false
	for key, value in full do
		if key == "name" then
			continue
		end
		local baseValue = base[key]
		if isPlainTable(value) and isPlainTable(baseValue) then
			local child = Serialize.diff(baseValue, value)
			if child then
				result[key] = child
				changed = true
			end
		elseif not Serialize.equals(value, baseValue) then
			result[key] = value
			changed = true
		end
	end
	for key in base do
		if key ~= "name" and full[key] == nil then
			result[key] = Serialize.None
			changed = true
		end
	end
	return if changed then result else nil
end

function Serialize.toJSON(record: any): string
	return HttpService:JSONEncode(Serialize.encode(record))
end

-- Returns the record, or nil and a reason.
function Serialize.fromJSON(text: string): (any?, string?)
	local ok, data = pcall(HttpService.JSONDecode, HttpService, text)
	if not ok or type(data) ~= "table" then
		return nil, "not valid theme code"
	end
	local record = Serialize.decode(data)
	if type(record.base) ~= "string" then
		return nil, "theme code has no base theme"
	end
	if type(record.overrides) ~= "table" then
		record.overrides = {}
	end
	return record, nil
end

-- Luau source ------------------------------------------------------------------

local IDENTIFIER = "^[%a_][%w_]*$"

local function number(n: number): string
	if n == math.floor(n) and math.abs(n) < 1e15 then
		return string.format("%d", n)
	end
	return (string.gsub(string.format("%.4f", n), "0+$", ""))
end

local function literal(value: any, indent: string): string
	local kind = typeof(value)
	if kind == "Color3" then
		return string.format("Color3.fromRGB(%d, %d, %d)", byte(value.R), byte(value.G), byte(value.B))
	elseif kind == "Font" then
		return string.format(
			"Font.new(%q, Enum.FontWeight.%s, Enum.FontStyle.%s)",
			value.Family,
			value.Weight.Name,
			value.Style.Name
		)
	elseif kind == "UDim" then
		return string.format("UDim.new(%s, %s)", number(value.Scale), number(value.Offset))
	elseif kind == "Vector2" then
		return string.format("Vector2.new(%s, %s)", number(value.X), number(value.Y))
	elseif kind == "Rect" then
		return string.format(
			"Rect.new(%s, %s, %s, %s)",
			number(value.Min.X),
			number(value.Min.Y),
			number(value.Max.X),
			number(value.Max.Y)
		)
	elseif kind == "EnumItem" then
		return tostring(value)
	elseif value == Serialize.None then
		return "Theme.None"
	elseif kind == "number" then
		return number(value)
	elseif kind == "string" then
		return string.format("%q", value)
	elseif kind == "boolean" then
		return tostring(value)
	elseif kind == "table" then
		local keys = {}
		for key in value do
			if type(key) == "string" then
				table.insert(keys, key)
			end
		end
		table.sort(keys)
		if #keys == 0 then
			return "{}"
		end
		local inner = indent .. "\t"
		local lines = { "{" }
		for _, key in keys do
			local name = if string.match(key, IDENTIFIER) then key else string.format("[%q]", key)
			table.insert(lines, inner .. name .. " = " .. literal(value[key], inner) .. ",")
		end
		table.insert(lines, indent .. "}")
		return table.concat(lines, "\n")
	end
	return "nil"
end

-- A ModuleScript source that registers the theme when required.
function Serialize.toLuau(record: any): string
	return table.concat({
		"--[[",
		"\t" .. record.name .. ": a Core UI theme exported from the Core UI Customizer.",
		"",
		"\t\trequire(path.To.ThisModule)",
		"\t\tCoreUI.Theme.set(" .. string.format("%q", record.name) .. ")",
		"]]",
		"",
		'local ReplicatedStorage = game:GetService("ReplicatedStorage")',
		'local Theme = require(ReplicatedStorage:WaitForChild("CoreUI")).Theme',
		"",
		"return Theme.register(" .. string.format("%q", record.name) .. ", Theme.extend(" .. string.format(
			"%q",
			record.base
		) .. ", " .. literal(record.overrides or {}, "") .. "))",
		"",
	}, "\n")
end

return Serialize
