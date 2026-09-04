local Signal = require(script.Parent.Signal)
local Maid = require(script.Parent.Maid)

local Component = {}
Component.__index = Component

Component.Registry = {}

local nextId = 0
local function generateId(class)
	nextId = nextId + 1
	return ("%s_%d_%d"):format(class, os.clock() * 1000 % 1e6, nextId)
end

function Component.new(class, options)
	options = options or {}

	local self = setmetatable({}, Component)
	self.Class = class
	self.Id = generateId(class)
	self.Name = options.Name or class
	self.Visible = true
	self.Enabled = true
	self.Selected = false
	self.Loading = false
	self.Destroyed = false

	self._maid = Maid.new()
	self._signals = {
		StateChanged = Signal.new(),
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		EnabledChanged = Signal.new(),
	}
	self._stateBindings = {}

	Component.Registry[self] = true

	return self
end

function Component:On(eventName)
	return self._signals[eventName]
end

function Component:BindSignal(name)
	local signal = self._signals[name]
	if not signal then
		signal = Signal.new()
		self._signals[name] = signal
		self._maid:GiveTask(signal)
	end
	return signal
end

function Component:BindState(state, applyFn)
	if not state or type(applyFn) ~= "function" then
		return self
	end

	local connection = state:Subscribe(function(value)
		applyFn(self, value)
	end)

	self._maid:GiveTask(connection)
	table.insert(self._stateBindings, state)

	if not self._maid:GetTask("StateDestroyHook_" .. tostring(state)) then
		local originalDestroy = state.Destroy
		self._maid:GiveTask("StateDestroyHook_" .. tostring(state), function()
			originalDestroy(state)
		end)
	end

	return self
end

function Component:SetState(stateName, value)
	self[stateName] = value
	self._signals.StateChanged:Fire(stateName, value)
	return self
end

function Component:SetVisible(visible)
	visible = visible and true or false
	if self.Visible == visible then
		return self
	end

	self.Visible = visible
	self._signals.VisibleChanged:Fire(visible)
	return self
end

function Component:Show()
	return self:SetVisible(true)
end

function Component:Hide()
	return self:SetVisible(false)
end

function Component:SetEnabled(enabled)
	enabled = enabled and true or false
	if self.Enabled == enabled then
		return self
	end

	self.Enabled = enabled
	self._signals.EnabledChanged:Fire(enabled)
	return self
end

function Component:SetLoading(loading)
	self.Loading = loading and true or false
	self._signals.StateChanged:Fire("Loading", self.Loading)
	return self
end

function Component:SetSelected(selected)
	self.Selected = selected and true or false
	self._signals.StateChanged:Fire("Selected", self.Selected)
	return self
end

function Component:Destroy()
	if self.Destroyed then
		return
	end

	self.Destroyed = true

	for _, signal in pairs(self._signals) do
		signal:Destroy()
	end
	self._signals = {}

	for _, state in ipairs(self._stateBindings) do
		pcall(function() state:Destroy() end)
	end
	self._stateBindings = {}

	self._maid:Destroy()
	Component.Registry[self] = nil
	self._signals.Destroyed:Fire()
end

function Component.Count()
	local n = 0
	for _ in pairs(Component.Registry) do
		n = n + 1
	end
	return n
end

return Component
