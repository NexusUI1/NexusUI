local Signal = {}
Signal.__index = Signal

Signal.GlobalConnections = 0

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn, once)
	local self = setmetatable({}, Connection)
	self.Connected = true
	self._signal = signal
	self._fn = fn
	self._once = once and true or false
	return self
end

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false

	local handlers = self._signal._handlers
	local index = table.find(handlers, self)
	if index then
		table.remove(handlers, index)
	end

	Signal.GlobalConnections = Signal.GlobalConnections - 1
	self._signal.Count = math.max(0, self._signal.Count - 1)
end

function Signal.new()
	local self = setmetatable({}, Signal)
	self._handlers = {}
	self._waiters = {}
	self.Count = 0
	self.Destroyed = false
	return self
end

function Signal:Connect(fn)
	assert(type(fn) == "function", "Signal:Connect expects a function")
	if self.Destroyed then
		warn("[NexusUI] Connect called on a destroyed Signal")
		return { Disconnect = function() end, Connected = false }
	end

	local connection = Connection.new(self, fn, false)
	table.insert(self._handlers, connection)
	self.Count = self.Count + 1
	Signal.GlobalConnections = Signal.GlobalConnections + 1
	return connection
end

function Signal:Once(fn)
	assert(type(fn) == "function", "Signal:Once expects a function")
	if self.Destroyed then
		return { Disconnect = function() end, Connected = false }
	end

	local connection = Connection.new(self, fn, true)
	table.insert(self._handlers, connection)
	self.Count = self.Count + 1
	Signal.GlobalConnections = Signal.GlobalConnections + 1
	return connection
end

function Signal:Fire(...)
	if self.Destroyed then
		return
	end

	local snapshot = table.create(#self._handlers)
	for i = 1, #self._handlers do
		snapshot[i] = self._handlers[i]
	end

	local args = table.pack(...)

	for i = 1, #snapshot do
		local connection = snapshot[i]
		if connection.Connected then
			if connection._once then
				connection:Disconnect()
			end
			task.spawn(connection._fn, table.unpack(args, 1, args.n))
		end
	end

	if #self._waiters > 0 then
		local waiters = self._waiters
		self._waiters = {}
		for i = 1, #waiters do
			task.spawn(waiters[i], table.unpack(args, 1, args.n))
		end
	end
end

function Signal:Wait()
	if self.Destroyed then
		return nil
	end
	local thread = coroutine.running()
	table.insert(self._waiters, thread)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	local handlers = self._handlers
	for i = #handlers, 1, -1 do
		handlers[i]:Disconnect()
	end
	self._handlers = {}

	local waiters = self._waiters
	for i = 1, #waiters do
		pcall(task.cancel, waiters[i])
	end
	self._waiters = {}
	self.Count = 0
end

function Signal:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	self:DisconnectAll()
end

return Signal
