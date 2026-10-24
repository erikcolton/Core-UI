--[[
	Theme manager.

	A theme is a plain table of tokens (colors, fonts, sizes, motion, sounds, images).
	Components never hard-code a look: they call Theme.bind(instance, styler), and the
	styler runs now and again every time Theme.set() switches to another theme.

		Theme.register("MyGame", Theme.extend("Cartoony", {
			colors = { primary = Color3.fromRGB(255, 120, 40) },
		}))
		Theme.set("MyGame")
]]

local Signal = require(script.Parent.Util.Signal)

local Theme = {}

Theme.Changed = Signal.new()

local registry: { [string]: any } = {}
local current: any = nil

-- [Instance] = { styler, ... }. Weak keys so forgotten, unparented instances can be collected.
local bindings = setmetatable({}, { __mode = "k" })

local function isPlainTable(value: any): boolean
	return type(value) == "table" and getmetatable(value) == nil
end

-- Returns a new table: base with overrides layered on top. Nested plain tables merge;
-- everything else (Color3, Font, UDim, arrays you intend to replace) is taken from overrides.
function Theme.merge(base: any, overrides: any?): any
	local result = {}
	for key, value in base do
		result[key] = if isPlainTable(value) then Theme.merge(value) else value
	end
	if overrides then
		for key, value in overrides do
			if isPlainTable(value) and isPlainTable(result[key]) then
				result[key] = Theme.merge(result[key], value)
			elseif isPlainTable(value) then
				result[key] = Theme.merge(value)
			else
				result[key] = value
			end
		end
	end
	return result
end

local function resolve(themeOrName: any): any
	if type(themeOrName) == "string" then
		local found = registry[themeOrName]
		if not found then
			error(string.format("CoreUI: no theme named %q is registered", themeOrName), 3)
		end
		return found
	end
	return themeOrName
end

function Theme.register(name: string, theme: any): any
	theme.name = name
	registry[name] = theme
	return theme
end

-- Build a new theme from a registered theme (or theme table) plus overrides.
function Theme.extend(base: any, overrides: any?): any
	return Theme.merge(resolve(base), overrides)
end

function Theme.list(): { string }
	local names = {}
	for name in registry do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function Theme.find(name: string): any?
	return registry[name]
end

function Theme.get(): any
	if not current then
		current = registry.Clean
	end
	return current
end

local function runStyler(styler: any, theme: any, instance: Instance)
	if type(styler) == "function" then
		styler(theme, instance)
	else
		for property, getter in styler do
			(instance :: any)[property] = getter(theme)
		end
	end
end

local function applyAll(instance: Instance, stylers: { any }, theme: any)
	for _, styler in stylers do
		local ok, err = pcall(runStyler, styler, theme, instance)
		if not ok then
			warn("CoreUI: theme styler failed on " .. instance:GetFullName() .. ": " .. tostring(err))
		end
	end
end

function Theme.set(themeOrName: any)
	current = resolve(themeOrName)
	for instance, stylers in bindings do
		applyAll(instance, stylers, current)
	end
	Theme.Changed:Fire(current)
end

--[[
	Apply a styler now and on every theme change.
	styler is either function(theme, instance) or a table of { Property = function(theme) }.
	Returns a function that removes the binding.
]]
function Theme.bind(instance: Instance, styler: any): () -> ()
	local stylers = bindings[instance]
	if not stylers then
		stylers = {}
		bindings[instance] = stylers
		instance.Destroying:Once(function()
			bindings[instance] = nil
		end)
	end
	table.insert(stylers, styler)
	applyAll(instance, { styler }, Theme.get())

	return function()
		local list = bindings[instance]
		if list then
			local index = table.find(list, styler)
			if index then
				table.remove(list, index)
			end
		end
	end
end

local Themes = script.Themes
local clean = Theme.register("Clean", require(Themes.Clean))
Theme.register("Cartoony", Theme.extend(clean, require(Themes.Cartoony)))
Theme.register("Dark", Theme.extend(clean, require(Themes.Dark)))

return Theme
