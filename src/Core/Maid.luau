local Maid = {}
Maid.__index = Maid

Maid.TotalTasks = 0

local function isConnection(value)
	return type(value) == "table" and typeof == nil
end

local function cleanupTask(task)
	local taskType = typeof(task)

	if taskType == "RBXScriptConnection" then
		if task.Connected then
			task:Disconnect()
		end
	elseif taskType == "Instance" then
		task:Destroy()
	elseif taskType == "function" then
		task()
	elseif taskType == "table" then
		if type(task.Destroy) == "function" then
			task:Destroy()
		elseif type(task.Disconnect) == "function" then
			task:Disconnect()
		elseif type(task.Clean) == "function" then
			task:Clean()
		end
	end
end

function Maid.new()
	local self = setmetatable({}, Maid)
	self._tasks = {}
	self._count = 0
	self.Destroyed = false
	return self
end

function Maid:GiveTask(a, b)
	if type(a) == "string" and b ~= nil then
		self:RemoveTask(a)
		self._tasks[a] = b
		Maid.TotalTasks = Maid.TotalTasks + 1
		return b
	end

	if a == nil then
		return nil
	end

	table.insert(self._tasks, a)
	Maid.TotalTasks = Maid.TotalTasks + 1
	return a
end

function Maid:SetTask(key, task)
	return self:GiveTask(key, task)
end

function Maid:GetTask(key)
	return self._tasks[key]
end

function Maid:RemoveTask(key)
	local task = self._tasks[key]
	if task ~= nil then
		self._tasks[key] = nil
		pcall(cleanupTask, task)
		return true
	end
	return false
end

function Maid:GiveCleanup(fn)
	assert(type(fn) == "function", "Maid:GiveCleanup expects a function")
	return self:GiveTask(fn)
end

function Maid:Clean()
	if self.Destroyed then
		return
	end

	local tasks = self._tasks
	for _, task in pairs(tasks) do
		pcall(cleanupTask, task)
	end
	self._tasks = {}
	self._count = 0
end

function Maid:TaskCount()
	local n = 0
	for _ in pairs(self._tasks) do
		n = n + 1
	end
	return n
end

function Maid:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	self:Clean()
end

return Maid
