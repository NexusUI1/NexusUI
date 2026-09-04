local Signal = require(script.Parent.Signal)

local State = {}
State.__index = State

State.Registry = {}
State.TotalCreated = 0

function State.new(initialValue, options)
	options = options or {}

	local self = setmetatable({}, State)
	self._value = initialValue
	self._signal = Signal.new()
	self._validators = {}
	self._transformIn = options.TransformIn
	self._transformOut = options.TransformOut
	self.Name = options.Name or ("State_" .. tostring(State.TotalCreated))
	self.ReadOnly = options.ReadOnly or false

	State.TotalCreated = State.TotalCreated + 1
	State.Registry[self] = true

	return self
end

function State:Get()
	local transform = self._transformOut
	if transform then
		return transform(self._value)
	end
	return self._value
end

function State:RawGet()
	return self._value
end

function State:Set(newValue)
	if self.ReadOnly then
		warn("[NexusUI] Attempt to Set a read-only State:", self.Name)
		return self._value
	end

	local transform = self._transformIn
	if transform then
		newValue = transform(newValue)
	end

	for i = 1, #self._validators do
		local validator = self._validators[i]
		local ok, result = pcall(validator, newValue)
		if not ok or result == false then
			warn("[NexusUI] State validator rejected value:", tostring(newValue))
			return self._value
		end
	end

	local old = self._value
	if old == newValue then
		return newValue
	end

	self._value = newValue
	self._signal:Fire(newValue, old)
	return newValue
end

function State:Toggle(forceValue)
	if forceValue ~= nil then
		return self:Set(forceValue)
	end
	return self:Set(not self._value)
end

function State:AddValidator(fn)
	if type(fn) == "function" then
		table.insert(self._validators, fn)
	end
	return self
end

function State:Subscribe(fn)
	return self._signal:Connect(fn)
end

function State:Bind(instance, applyFn)
	if typeof(instance) == "Instance" and type(applyFn) == "function" then
		self._signal:Connect(function(value)
			applyFn(instance, value)
		end)
		applyFn(instance, self._value)
	end
	return self
end

function State:Map(mapperFn)
	local derived = State.new(mapperFn(self._value))
	self._signal:Connect(function(value)
		derived:Set(mapperFn(value))
	end)
	return derived
end

function State:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._signal:Destroy()
	State.Registry[self] = nil
end

State.False = function() return State.new(false) end
State.True = function() return State.new(true) end
State.Zero = function() return State.new(0) end
State.Empty = function() return State.new("") end

return State
