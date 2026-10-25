--[[
	Loads kit and plugin modules outside Roblox with Lune, for logic tests.

	Real Roblox datatypes (Color3, Font, Enum, ...) come from @lune/roblox. Services
	and `script` are small fakes: a fake `script` maps to files under src/, so
	`require(script.Parent.Util.Signal)` loads src/CoreUI/Util/Signal.luau.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local task = require("@lune/task")

local Harness = {}

-- Fake services ---------------------------------------------------------------

local function fakeFolder(name: string, children: { any }?, attributes: { [string]: any }?)
	local folder = { Name = name, ClassName = "Folder", _children = children or {}, _attributes = attributes or {} }
	function folder:GetChildren()
		return self._children
	end
	function folder:FindFirstChild(childName: string)
		for _, child in self._children do
			if child.Name == childName then
				return child
			end
		end
		return nil
	end
	function folder:WaitForChild(childName: string)
		return self:FindFirstChild(childName)
	end
	function folder:GetAttribute(key: string)
		return self._attributes[key]
	end
	function folder:SetAttribute(key: string, value: any)
		self._attributes[key] = value
	end
	function folder:IsA(className: string)
		return className == self.ClassName
	end
	return folder
end
Harness.fakeFolder = fakeFolder

function Harness.fakeStringValue(name: string, value: string)
	local object = fakeFolder(name)
	object.ClassName = "StringValue"
	object.Value = value
	return object
end

Harness.ReplicatedStorage = fakeFolder("ReplicatedStorage")

local services = {
	ReplicatedStorage = Harness.ReplicatedStorage,
	HttpService = {
		JSONEncode = function(_, value)
			return serde.encode("json", value)
		end,
		JSONDecode = function(_, text)
			return serde.decode("json", text)
		end,
	},
	RunService = {
		IsRunning = function()
			return false
		end,
		IsClient = function()
			return false
		end,
		IsStudio = function()
			return true
		end,
	},
}

local game = {
	GetService = function(_, name: string)
		return services[name] or fakeFolder(name)
	end,
}

-- Fake scripts ----------------------------------------------------------------

local cache: { [string]: any } = {}
local env: { [string]: any }

local function isDir(path: string): boolean
	return fs.isDir(path)
end

local function sourceFile(path: string): string?
	if isDir(path) then
		for _, init in { "/init.luau", "/init.server.luau", "/init.client.luau" } do
			if fs.isFile(path .. init) then
				return path .. init
			end
		end
		return nil
	end
	return if fs.isFile(path) then path else nil
end

-- Builds the whole tree up front: fs calls yield, so they cannot run inside __index.
local function makeScript(path: string, parent: any?): any
	local name = string.match(path, "([^/]+)$") :: string
	name = string.gsub(string.gsub(name, "%.server%.luau$", ""), "%.client%.luau$", "")
	name = string.gsub(name, "%.luau$", "")
	local object = { Name = name, _path = path, Parent = parent }
	if isDir(path) then
		for _, entry in fs.readDir(path) do
			local child = path .. "/" .. entry
			if isDir(child) or string.match(entry, "%.luau$") then
				local childScript = makeScript(child, object)
				if childScript.Name ~= "init" then
					object[childScript.Name] = childScript
				end
			end
		end
	end
	return setmetatable(object, {
		__index = function(_, key)
			error("fake script " .. path .. " has no child " .. tostring(key), 2)
		end,
	})
end

local function fakeRequire(target: any): any
	if type(target) == "string" then
		return require(target)
	end
	local path = target._path
	if cache[path] ~= nil then
		return cache[path]
	end
	local file = sourceFile(path)
	assert(file, "nothing to require at " .. path)
	local source = fs.readFile(file)
	-- Lune copies the environment's own keys, so flatten the globals into it.
	local moduleEnv = table.clone(env)
	moduleEnv.script = target
	local chunk = luau.load(source, { debugName = file, environment = moduleEnv })
	local result = chunk()
	cache[path] = result
	return result
end

env = {
	game = game,
	script = nil,
	require = fakeRequire,
	task = task,
	typeof = typeof,
	Color3 = roblox.Color3,
	ColorSequence = roblox.ColorSequence,
	ColorSequenceKeypoint = roblox.ColorSequenceKeypoint,
	UDim = roblox.UDim,
	UDim2 = roblox.UDim2,
	Vector2 = roblox.Vector2,
	Rect = roblox.Rect,
	Font = roblox.Font,
	Enum = roblox.Enum,
	warn = function(...)
		Harness.warnings = Harness.warnings or {}
		table.insert(Harness.warnings, table.concat({ ... }, " "))
	end,
}

-- Swap in a fake service or global for the modules loaded after this call.
function Harness.setService(name: string, service: any)
	services[name] = service
end

function Harness.setGlobal(name: string, value: any)
	env[name] = value
end

function Harness.script(path: string): any
	return makeScript(path, nil)
end

-- Require a fake script, e.g. Harness.require(Harness.script("src/CoreUI").Theme).
function Harness.require(target: any): any
	return fakeRequire(target)
end

-- Fresh module cache, e.g. to reload the theme manager with a different saved folder.
function Harness.reset()
	table.clear(cache)
	Harness.warnings = {}
end

function Harness.compile(source: string, name: string): (boolean, string?)
	local ok, err = pcall(luau.compile, source, { debugName = name })
	return ok, if ok then nil else tostring(err)
end

Harness.roblox = roblox

-- Tiny test runner -------------------------------------------------------------

local results = { passed = 0, failed = 0 }

function Harness.test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		results.passed += 1
		print("  ok    " .. name)
	else
		results.failed += 1
		print("  FAIL  " .. name .. "\n        " .. tostring(err))
	end
end

-- Prints the totals for this file and starts counting again for the next one.
function Harness.finish(): number
	print(string.format("\n%d passed, %d failed", results.passed, results.failed))
	local failed = results.failed
	results.passed, results.failed = 0, 0
	return failed
end

return Harness
