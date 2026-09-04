local Easing = {}

Easing.Linear = function(t)
	return t
end

Easing.Sine = function(t)
	return -(math.cos(math.pi * t) - 1) / 2
end

Easing.Quad = function(t)
	if t < 0.5 then
		return 2 * t * t
	end
	return 1 - math.pow(-2 * t + 2, 2) / 2
end

Easing.Cubic = function(t)
	if t < 0.5 then
		return 4 * t * t * t
	end
	return 1 - math.pow(-2 * t + 2, 3) / 2
end

Easing.Quart = function(t)
	if t < 0.5 then
		return 8 * t * t * t * t
	end
	return 1 - math.pow(-2 * t + 2, 4) / 2
end

Easing.Quint = function(t)
	if t < 0.5 then
		return 16 * t * t * t * t * t
	end
	return 1 - math.pow(-2 * t + 2, 5) / 2
end

Easing.Expo = function(t)
	if t == 0 then
		return 0
	end
	if t == 1 then
		return 1
	end
	if t < 0.5 then
		return math.pow(2, 20 * t - 10) / 2
	end
	return (2 - math.pow(2, -20 * t + 10)) / 2
end

Easing.Circ = function(t)
	if t < 0.5 then
		return (1 - math.sqrt(1 - math.pow(2 * t, 2))) / 2
	end
	return (math.sqrt(1 - math.pow(-2 * t + 2, 2)) + 1) / 2
end

Easing.Back = function(t)
	local c1 = 1.70158
	local c2 = c1 * 1.525
	if t < 0.5 then
		return (math.pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
	end
	return (math.pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
end

Easing.Elastic = function(t)
	local c4 = (2 * math.pi) / 3
	if t == 0 then
		return 0
	end
	if t == 1 then
		return 1
	end
	if t < 0.5 then
		return -(math.pow(2, 20 * t - 10) * math.sin((20 * t - 11.125) * c4)) / 2
	end
	return (math.pow(2, -20 * t + 10) * math.sin((20 * t - 11.125) * c4)) / 2 + 1
end

Easing.Bounce = function(t)
	local n1 = 7.5625
	local d1 = 2.75
	if t < 1 / d1 then
		return n1 * t * t
	elseif t < 2 / d1 then
		t = t - 1.5 / d1
		return n1 * t * t + 0.75
	elseif t < 2.5 / d1 then
		t = t - 2.25 / d1
		return n1 * t * t + 0.9375
	else
		t = t - 2.625 / d1
		return n1 * t * t + 0.984375
	end
end

Easing.Spring = function(t)
	local damping = 26
	local mass = 1
	local stiffness = 170
	local initial = 0
	local target = 1

	local omega = math.sqrt(stiffness / mass)
	local zeta = damping / (2 * math.sqrt(stiffness * mass))
	local x = t - 1

	if zeta < 1 then
		local omegaD = omega * math.sqrt(1 - zeta * zeta)
		return 1 - math.exp(-zeta * omega * t) * (math.cos(omegaD * t) + (zeta * omega / omegaD) * math.sin(omegaD * t))
	else
		return 1 - (1 + omega * t) * math.exp(-omega * t)
	end
end

Easing.SmoothStep = function(t)
	return t * t * (3 - 2 * t)
end

Easing.SmootherStep = function(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

Easing.InOut = function(t, fn)
	return fn(t)
end

Easing.In = function(t, fn)
	return fn(t * t)
end

Easing.Out = function(t, fn)
	return 1 - fn(1 - t)
end

Easing.Resolve = function(name)
	if type(name) == "function" then
		return name
	end
	return Easing[name] or Easing.Quad
end

Easing.Names = {
	"Linear", "Sine", "Quad", "Cubic", "Quart", "Quint",
	"Expo", "Circ", "Back", "Elastic", "Bounce", "Spring",
	"SmoothStep", "SmootherStep",
}

return Easing
