--[[
	Collects things to clean up (connections, instances, functions, objects with Destroy)
	and releases them all at once.
]]

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Add(item)
	table.insert(self._tasks, item)
	return item
end

local function release(item)
	local kind = typeof(item)
	if kind == "function" then
		item()
	elseif kind == "RBXScriptConnection" then
		item:Disconnect()
	elseif kind == "Instance" then
		item:Destroy()
	elseif kind == "thread" then
		pcall(task.cancel, item)
	elseif kind == "table" then
		if type(item.Destroy) == "function" then
			item:Destroy()
		elseif type(item.Disconnect) == "function" then
			item:Disconnect()
		end
	end
end

function Maid:Clean()
	local tasks = self._tasks
	for index = #tasks, 1, -1 do
		local item = tasks[index]
		tasks[index] = nil
		release(item)
	end
end

Maid.Destroy = Maid.Clean

return Maid
