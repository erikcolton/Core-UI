--[[
	Logic tests for the Studio plugin: the editor schema covers every theme token
	with the right control, and saving produces records the kit can load back.
]]

local H = require("./harness")

local roblox = H.roblox
local Color3, UDim = roblox.Color3, roblox.UDim

H.reset()
-- The built plugin holds a copy of the kit as a child named CoreUI; mirror that.
local pluginScript = H.script("src/Plugin")
local kitScript = H.script("src/CoreUI")
rawset(kitScript, "Parent", pluginScript)
rawset(pluginScript, "CoreUI", kitScript)

local Theme = H.require(kitScript.Theme)
local Serialize = Theme.Serialize
local Schema = H.require(pluginScript.Schema)

local clean = Theme.find("Clean")

local function leaves(value, path, out)
	for key, child in value do
		local childPath = if path == "" then key else path .. "." .. key
		if type(child) == "table" and getmetatable(child) == nil then
			leaves(child, childPath, out)
		elseif key ~= "name" then
			out[childPath] = child
		end
	end
	return out
end

print("Editor schema")

H.test("every field points at a token of the right type", function()
	local problems = {}
	for _, field in Schema.fields() do
		local value = Schema.get(clean, field.path)
		local allowed = Schema.valueTypes[field.type]
		if field.type == "choice" then
			local matched = false
			for _, option in field.options do
				if Serialize.equals(option[2], value) then
					matched = true
				end
			end
			if not matched then
				table.insert(problems, field.path .. ": Clean value is not one of the options")
			end
		elseif allowed and not table.find(allowed, typeof(value)) then
			table.insert(problems, field.path .. " is " .. typeof(value) .. ", field wants " .. field.type)
		end
	end
	assert(#problems == 0, table.concat(problems, "; "))
end)

H.test("every Clean token has an editor", function()
	local covered = {}
	for _, field in Schema.fields() do
		covered[field.path] = true
	end
	local missing = {}
	for path in leaves(clean, "", {}) do
		if not covered[path] then
			table.insert(missing, path)
		end
	end
	table.sort(missing)
	assert(#missing == 0, "no editor for: " .. table.concat(missing, ", "))
end)

H.test("optional sounds and skins have editors even though Clean leaves them empty", function()
	local covered = {}
	for _, field in Schema.fields() do
		covered[field.path] = true
	end
	for _, path in
		{
			"sounds.click",
			"sounds.open",
			"sounds.close",
			"sounds.notify",
			"images.panel",
			"images.button",
			"images.slot",
		}
	do
		assert(covered[path], path)
	end
end)

H.test("every template value fits its choice field", function()
	local problems = {}
	for _, name in Theme.Templates do
		local theme = Theme.find(name)
		for _, field in Schema.fields() do
			if field.type == "choice" then
				local value = Schema.get(theme, field.path)
				local matched = false
				for _, option in field.options do
					if Serialize.equals(option[2], value) then
						matched = true
					end
				end
				if not matched then
					table.insert(problems, name .. " " .. field.path .. " = " .. tostring(value))
				end
			end
		end
	end
	assert(#problems == 0, table.concat(problems, "; "))
end)

H.test("number fields keep template values inside their range", function()
	local problems = {}
	for _, name in Theme.Templates do
		local theme = Theme.find(name)
		for _, field in Schema.fields() do
			if field.type == "number" or field.type == "udim" then
				local value = Schema.get(theme, field.path)
				local n = if typeof(value) == "UDim" then value.Offset else value
				if type(n) ~= "number" or n < field.min or n > field.max then
					table.insert(problems, name .. " " .. field.path .. " = " .. tostring(n))
				end
			end
		end
	end
	assert(#problems == 0, table.concat(problems, "; "))
end)

H.test("field paths are unique", function()
	local seen = {}
	for _, field in Schema.fields() do
		assert(not seen[field.path], "duplicate " .. field.path)
		seen[field.path] = true
	end
end)

H.test("Schema.set creates parents and Schema.get reads them back", function()
	local theme = Theme.merge(clean)
	Schema.set(theme, "images.panel", { Image = "rbxassetid://1" })
	assert(Schema.get(theme, "images.panel").Image == "rbxassetid://1")
	Schema.set(theme, "brand.new.token", 5)
	assert(Schema.get(theme, "brand.new.token") == 5)
	assert(Schema.get(theme, "missing.path.here") == nil)
end)

print("\nSaving")

H.test("an edited template saves as a small diff and loads back identical", function()
	local working = Theme.merge(Theme.find("Cartoony"))
	Schema.set(working, "colors.primary", Color3.fromRGB(255, 0, 128))
	Schema.set(working, "radius.md", UDim.new(0, 22))
	Schema.set(working, "motion.openStyle", "slide")
	Schema.set(working, "sounds.click", "rbxassetid://123")
	local diff = Serialize.diff(Theme.find("Cartoony"), working)
	local record = { format = 1, name = "Test", base = "Cartoony", overrides = diff }
	local json = Serialize.toJSON(record)
	assert(#json < 800, "diff should be small, got " .. #json .. " chars")
	local back = assert(Serialize.fromJSON(json))
	local loaded = Theme.extend(back.base, back.overrides)
	loaded.name = nil
	working.name = nil
	assert(Serialize.equals(loaded, working))
end)

return H.finish()
