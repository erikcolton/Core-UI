--[[
	Logic tests for the theme system: templates, serialization and saved themes.
]]

local fs = require("@lune/fs")
local H = require("./harness")

local roblox = H.roblox
local Color3, Font, Enum = roblox.Color3, roblox.Font, roblox.Enum

local function loadTheme()
	H.reset()
	return H.require(H.script("src/CoreUI").Theme)
end

local Theme = loadTheme()
local Serialize = Theme.Serialize

local function isPlain(value)
	return type(value) == "table" and getmetatable(value) == nil
end

-- Every key a template sets must exist in Clean, with the same kind of value.
local function checkShape(base, overrides, path, problems)
	for key, value in overrides do
		local where = path .. "." .. tostring(key)
		local baseValue = base[key]
		if baseValue == nil then
			-- Clean leaves sounds and images nil on purpose.
			if not (string.find(where, "%.sounds%.") or string.find(where, "%.images%.")) then
				table.insert(problems, where .. " is not a Clean token")
			end
		elseif isPlain(value) and isPlain(baseValue) then
			checkShape(baseValue, value, where, problems)
		elseif typeof(value) ~= typeof(baseValue) then
			table.insert(problems, where .. " is a " .. typeof(value) .. ", Clean has " .. typeof(baseValue))
		end
	end
end

local knownFamilies = {}
for _, item in Enum.Font:GetEnumItems() do
	local ok, font = pcall(Font.fromEnum, item)
	if ok then
		knownFamilies[font.Family] = true
	end
end

-- Newer than Lune's copy of the Roblox API: Enum.Font.BuilderSans (2023).
knownFamilies["rbxasset://fonts/families/BuilderSans.json"] = true

local function fontsIn(value, found)
	if typeof(value) == "Font" then
		table.insert(found, value.Family)
	elseif isPlain(value) then
		for _, child in value do
			fontsIn(child, found)
		end
	end
	return found
end

print("Theme templates")

H.test("every template is registered and listed", function()
	for _, name in Theme.Templates do
		assert(Theme.find(name), name .. " missing")
		assert(Theme.isTemplate(name))
	end
	assert(#Theme.list() == #Theme.Templates, "unexpected extra themes")
end)

local clean = Theme.find("Clean")
local themesDir = H.script("src/CoreUI").Theme.Themes

for _, name in Theme.Templates do
	H.test(name .. " only overrides real Clean tokens", function()
		local raw = H.require(themesDir[name])
		local problems = {}
		if name ~= "Clean" then
			checkShape(clean, raw, name, problems)
		end
		assert(#problems == 0, table.concat(problems, "; "))
	end)
	H.test(name .. " uses built-in font families", function()
		for _, family in fontsIn(Theme.find(name), {}) do
			assert(knownFamilies[family], family .. " is not a built-in font family")
		end
	end)
	H.test(name .. " has valid enum tokens", function()
		local theme = Theme.find(name)
		assert(table.find({ "flat", "twoTone", "gradient" }, theme.buttons.fill), "buttons.fill")
		assert(table.find({ "soft", "lip", "none" }, theme.shadow.style), "shadow.style")
		assert(table.find({ "pop", "slide", "none" }, theme.motion.openStyle), "motion.openStyle")
		for role, spec in theme.typography do
			assert(theme.fonts[spec.font], "typography." .. role .. " uses missing font " .. tostring(spec.font))
		end
	end)
end

print("\nSerialize")

for _, name in Theme.Templates do
	H.test(name .. " survives a JSON round trip", function()
		local theme = Theme.find(name)
		local record = { format = 1, name = name, base = "Clean", overrides = Serialize.diff(clean, theme) or {} }
		local back = assert(Serialize.fromJSON(Serialize.toJSON(record)))
		local rebuilt = Theme.extend("Clean", back.overrides)
		rebuilt.name = name
		assert(Serialize.equals(rebuilt, theme), "rebuilt theme differs")
	end)
end

H.test("diff of a theme against itself is empty", function()
	assert(Serialize.diff(clean, Theme.merge(clean)) == nil)
end)

H.test("diff only holds what changed", function()
	local edited = Theme.merge(clean)
	edited.colors.primary = Color3.fromRGB(1, 2, 3)
	edited.radius.md = roblox.UDim.new(0, 20)
	local diff = Serialize.diff(clean, edited)
	assert(diff.colors.primary == Color3.fromRGB(1, 2, 3))
	assert(diff.radius.md.Offset == 20)
	local count = 0
	for _ in diff do
		count += 1
	end
	assert(count == 2, "expected colors and radius only")
end)

H.test("removing a token round-trips as None", function()
	local base = Theme.extend("Clean", { sounds = { click = "rbxassetid://1" } })
	local edited = Theme.merge(base)
	edited.sounds.click = nil
	local diff = Serialize.diff(base, edited)
	assert(diff.sounds.click == Theme.None)
	local json = Serialize.toJSON({ name = "x", base = "Clean", overrides = diff })
	local back = assert(Serialize.fromJSON(json))
	assert(back.overrides.sounds.click == Theme.None)
	assert(Theme.merge(base, back.overrides).sounds.click == nil)
end)

H.test("9-slice images and enums round-trip", function()
	local value = {
		images = {
			panel = { Image = "rbxassetid://5", SliceCenter = roblox.Rect.new(10, 10, 90, 90), SliceScale = 0.5 },
		},
		motion = { easing = Enum.EasingStyle.Bounce },
		fonts = { body = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Italic) },
	}
	local back = Serialize.decode(Serialize.encode(value))
	assert(Serialize.equals(back, value))
end)

H.test("broken theme code is rejected, not thrown", function()
	assert(Serialize.fromJSON("not json") == nil)
	assert(Serialize.fromJSON('{"overrides":{}}') == nil)
	local record =
		assert(Serialize.fromJSON('{"base":"Clean","overrides":{"colors":{"primary":{"$type":"Color3","v":"oops"}}}}'))
	assert(record.overrides.colors.primary == nil)
end)

H.test("exported Luau compiles", function()
	for _, name in Theme.Templates do
		local source = Serialize.toLuau({
			name = "My " .. name,
			base = "Clean",
			overrides = Serialize.diff(clean, Theme.find(name)),
		})
		local ok, err = H.compile(source, name)
		assert(ok, err)
	end
end)

print("\nSaved themes")

H.test("loadSaved registers saved themes and activates the marked one", function()
	local record = {
		format = 1,
		name = "Lava",
		base = "Cartoony",
		overrides = { colors = { primary = Color3.fromRGB(255, 80, 0) } },
	}
	local folder = H.fakeFolder("CoreUIThemes", {
		H.fakeStringValue("Lava", Serialize.toJSON(record)),
		H.fakeStringValue("Broken", "{"),
		H.fakeStringValue("Clean", Serialize.toJSON({ base = "Dark", overrides = {} })),
	}, { Active = "Lava" })
	H.ReplicatedStorage._children = { folder }
	local fresh = loadTheme()
	H.ReplicatedStorage._children = {}
	local lava = fresh.find("Lava")
	assert(lava, "Lava not registered")
	assert(lava.colors.primary == Color3.fromRGB(255, 80, 0))
	assert(lava.stroke.panel == fresh.find("Cartoony").stroke.panel, "base tokens kept")
	assert(fresh.get() == lava, "active theme not applied")
	assert(fresh.find("Clean").colors.background == clean.colors.background, "template overwritten")
	assert(#H.warnings == 1, "expected one warning for the broken entry, got " .. #H.warnings)
end)

H.test("Theme.set by code wins over the saved active theme", function()
	local fresh = loadTheme()
	fresh.set("Dark")
	assert(fresh.get().name == "Dark")
end)

return H.finish()
