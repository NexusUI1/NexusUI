local Easing = require(script.Parent.Easing)

local Spring = {}
Spring.__index = Spring

Spring.Active = {}
Spring.ActiveCount = 0
Spring.ManagerRunning = false

local RunService = game:GetService("RunService")

function Spring.new(initialValue, config)
	config = config or {}

	local self = setmetatable({}, Spring)
	self.Value = initialValue
	self.Target = initialValue
	self.Velocity = 0
	self.Damping = config.Damping or 24
	self.Stiffness = config.Stiffness or 180
	self.Precision = config.Precision or 0.001
	self.Speed = config.Speed or 1

	self._onUpdate = nil
	self._destroyed = false
	self._sleeping = true

	return self
end

function Spring:SetTarget(target)
	self.Target = target
	self._sleeping = false
	Spring._addToManager(self)
	return self
end

function Spring:SetValue(value)
	self.Value = value
	self.Target = value
	self.Velocity = 0
	self._sleeping = true
	self:_emit()
	return self
end

function Spring:Impulse(velocity)
	self.Velocity = self.Velocity + velocity
	self._sleeping = false
	Spring._addToManager(self)
	return self
end

function Spring:OnUpdate(fn)
	self._onUpdate = fn
	if self._sleeping then
		fn(self.Value)
	end
	return self
end

function Spring:_emit()
	if self._onUpdate then
		self._onUpdate(self.Value)
	end
end

function Spring:Step(dt)
	if self._destroyed or self._sleeping then
		return true
	end

	dt = math.min(dt, 1 / 30) * self.Speed

	local displacement = self.Value - self.Target
	local springForce = -self.Stiffness * displacement
	local dampingForce = -self.Damping * self.Velocity
	local acceleration = springForce + dampingForce

	self.Velocity = self.Velocity + acceleration * dt
	self.Value = self.Value + self.Velocity * dt

	if
		math.abs(self.Value - self.Target) < self.Precision
		and math.abs(self.Velocity) < self.Precision * 10
	then
		self.Value = self.Target
		self.Velocity = 0
		self._sleeping = true
		self:_emit()
		return true
	end

	self:_emit()
	return false
end

function Spring:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	Spring._removeFromManager(self)
	self._onUpdate = nil
end

function Spring.IsSleeping(spring)
	return spring._sleeping
end

function Spring._addToManager(spring)
	if Spring.Active[spring] then
		return
	end
	Spring.Active[spring] = true
	Spring.ActiveCount = Spring.ActiveCount + 1
	Spring._startManager()
end

function Spring._removeFromManager(spring)
	if not Spring.Active[spring] then
		return
	end
	Spring.Active[spring] = nil
	Spring.ActiveCount = Spring.ActiveCount - 1
end

function Spring._startManager()
	if Spring.ManagerRunning then
		return
	end
	Spring.ManagerRunning = true

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		local finished = {}

		for spring in pairs(Spring.Active) do
			local done = spring:Step(dt)
			if done then
				table.insert(finished, spring)
			end
		end

		for i = 1, #finished do
			Spring._removeFromManager(finished[i])
		end

		if Spring.ActiveCount == 0 then
			connection:Disconnect()
			Spring.ManagerRunning = false
		end
	end)
end

function Spring.Stats()
	return {
		Active = Spring.ActiveCount,
		Running = Spring.ManagerRunning,
	}
end

Spring.Easing = Easing

return Spring
