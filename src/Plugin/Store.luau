--[[
	Everything the plugin changes in the open place, each step undoable with Ctrl+Z:

	- saved themes: StringValues of theme code in ReplicatedStorage.CoreUIThemes,
	  with the folder's "Active" attribute naming the theme the game starts with
	- the Core UI kit itself (ReplicatedStorage.CoreUI), installed or updated from the
	  copy bundled in the plugin
	- the optional demo LocalScript and exported theme ModuleScripts
]]

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local StarterPlayer = game:GetService("StarterPlayer")

local Theme = require(script.Parent.CoreUI.Theme)
local Serialize = Theme.Serialize

local Store = {}

Store.KIT_NAME = "CoreUI"

-- Runs fn as one undo step. Returns ok, error.
function Store.record(name: string, fn: () -> ()): (boolean, string?)
	local recording = nil
	pcall(function()
		recording = ChangeHistoryService:TryBeginRecording(name)
	end)
	local ok, err = pcall(fn)
	if recording then
		ChangeHistoryService:FinishRecording(
			recording,
			if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		)
	else
		ChangeHistoryService:SetWaypoint(name)
	end
	return ok, if ok then nil else tostring(err)
end

-- Saved themes -----------------------------------------------------------------------

function Store.folder(create: boolean?): Folder?
	local folder = ReplicatedStorage:FindFirstChild(Theme.SAVED_FOLDER)
	if folder or not create then
		return folder :: Folder?
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = Theme.SAVED_FOLDER
	newFolder.Parent = ReplicatedStorage
	return newFolder
end

-- { { name, active } } sorted by name.
function Store.list(): { { name: string, active: boolean } }
	local folder = Store.folder()
	local result = {}
	if not folder then
		return result
	end
	local active = folder:GetAttribute("Active")
	for _, child in folder:GetChildren() do
		if child:IsA("StringValue") then
			table.insert(result, { name = child.Name, active = child.Name == active })
		end
	end
	table.sort(result, function(a, b)
		return string.lower(a.name) < string.lower(b.name)
	end)
	return result
end

function Store.active(): string?
	local folder = Store.folder()
	local active = folder and folder:GetAttribute("Active")
	return if type(active) == "string" then active else nil
end

function Store.exists(name: string): boolean
	local folder = Store.folder()
	local child = folder and folder:FindFirstChild(name)
	return child ~= nil and child:IsA("StringValue")
end

-- The saved record, or nil and a reason.
function Store.read(name: string): (any?, string?)
	local folder = Store.folder()
	local child = folder and folder:FindFirstChild(name)
	if not child or not child:IsA("StringValue") then
		return nil, "no saved theme named " .. name
	end
	return Serialize.fromJSON(child.Value)
end

-- Turns a full theme into the record that gets saved.
function Store.toRecord(name: string, base: string, theme: any): any
	local baseTheme = Theme.find(base) or Theme.find("Clean")
	return {
		format = Serialize.FORMAT,
		name = name,
		base = base,
		overrides = Serialize.diff(baseTheme, theme) or {},
	}
end

function Store.write(name: string, record: any, makeActive: boolean?): (boolean, string?)
	return Store.record("Save Core UI theme " .. name, function()
		local folder = Store.folder(true) :: Folder
		local child = folder:FindFirstChild(name)
		if child and not child:IsA("StringValue") then
			child:Destroy()
			child = nil
		end
		if not child then
			child = Instance.new("StringValue")
			child.Name = name
			child.Parent = folder
		end
		(child :: StringValue).Value = Serialize.toJSON(record)
		if makeActive then
			folder:SetAttribute("Active", name)
		end
	end)
end

function Store.setActive(name: string?): (boolean, string?)
	return Store.record("Set active Core UI theme", function()
		local folder = Store.folder(true) :: Folder
		folder:SetAttribute("Active", name)
	end)
end

function Store.delete(name: string): (boolean, string?)
	return Store.record("Delete Core UI theme " .. name, function()
		local folder = Store.folder()
		if not folder then
			return
		end
		local child = folder:FindFirstChild(name)
		if child then
			child:Destroy()
		end
		if folder:GetAttribute("Active") == name then
			folder:SetAttribute("Active", nil)
		end
	end)
end

function Store.rename(oldName: string, newName: string): (boolean, string?)
	return Store.record("Rename Core UI theme", function()
		local folder = Store.folder() :: Folder
		local child = folder:FindFirstChild(oldName) :: StringValue
		local record = assert(Serialize.fromJSON(child.Value))
		record.name = newName
		child.Value = Serialize.toJSON(record)
		child.Name = newName
		if folder:GetAttribute("Active") == oldName then
			folder:SetAttribute("Active", newName)
		end
	end)
end

-- Theme names may not clash with the starter templates.
function Store.validName(name: string?): (boolean, string?)
	local trimmed = string.match(name or "", "^%s*(.-)%s*$") or ""
	if trimmed == "" then
		return false, "Give the theme a name."
	elseif #trimmed > 40 then
		return false, "Keep the name under 40 characters."
	elseif Theme.isTemplate(trimmed) then
		return false, trimmed .. " is a built-in template name. Pick another."
	end
	return true, nil
end

function Store.uniqueName(wanted: string): string
	if not Store.exists(wanted) and not Theme.isTemplate(wanted) then
		return wanted
	end
	local index = 2
	while Store.exists(wanted .. " " .. index) do
		index += 1
	end
	return wanted .. " " .. index
end

-- The kit ------------------------------------------------------------------------------

-- Version of the kit inside the place, read from its source without running it.
function Store.kitVersion(): string?
	local kit = ReplicatedStorage:FindFirstChild(Store.KIT_NAME)
	if not kit or not kit:IsA("ModuleScript") then
		return nil
	end
	local ok, source = pcall(function()
		return (kit :: ModuleScript).Source
	end)
	if not ok then
		return "unknown"
	end
	return string.match(source, 'Version%s*=%s*"([^"]+)"') or "unknown"
end

-- Copies the bundled kit into ReplicatedStorage, replacing an older copy.
function Store.installKit(bundled: ModuleScript): (boolean, string?)
	return Store.record("Install Core UI kit", function()
		local existing = ReplicatedStorage:FindFirstChild(Store.KIT_NAME)
		local copy = bundled:Clone()
		copy.Name = Store.KIT_NAME
		if existing then
			existing:Destroy()
		end
		copy.Parent = ReplicatedStorage
		Selection:Set({ copy })
	end)
end

-- Adds the demo LocalScript, which builds every screen so you can try the theme in Play.
function Store.installDemo(bundled: LocalScript): (boolean, string?)
	return Store.record("Insert Core UI demo", function()
		local scripts = StarterPlayer:FindFirstChildOfClass("StarterPlayerScripts")
		assert(scripts, "StarterPlayerScripts is missing")
		local existing = scripts:FindFirstChild(bundled.Name)
		if existing then
			existing:Destroy()
		end
		local copy = bundled:Clone()
		-- Shipped disabled so it never runs inside the plugin itself.
		copy.Enabled = true
		copy.Parent = scripts
		Selection:Set({ copy })
	end)
end

function Store.hasDemo(name: string): boolean
	local scripts = StarterPlayer:FindFirstChildOfClass("StarterPlayerScripts")
	return scripts ~= nil and scripts:FindFirstChild(name) ~= nil
end

-- Writes the theme as a ModuleScript in ReplicatedStorage and selects it.
function Store.exportModule(record: any): (boolean, string?)
	return Store.record("Export Core UI theme", function()
		local name = string.gsub(record.name, "[^%w_]", "") .. "Theme"
		local module = ReplicatedStorage:FindFirstChild(name)
		if not module or not module:IsA("ModuleScript") then
			module = Instance.new("ModuleScript")
			module.Name = name
		end
		(module :: ModuleScript).Source = Serialize.toLuau(record)
		module.Parent = ReplicatedStorage
		Selection:Set({ module })
	end)
end

return Store
