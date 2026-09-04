local TweenService = game:GetService("TweenService")

local Easing = require(script.Parent.Easing)

local Animator = {}
Animator.__index = Animator

local activeTweens = {}

local function tweenInfo(duration, easingStyle, easingDirection)
	return TweenInfo.new(
		duration or 0.3,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out
	)
end

local function mapEasing(name, direction)
	if type(name) == "table" and name.Style then
		return tweenInfo(name.Duration or 0.3, name.Style, name.Direction or Enum.EasingDirection.Out)
	end

	local styleMap = {
		Linear = Enum.EasingStyle.Linear,
		Sine = Enum.EasingStyle.Sine,
		Quad = Enum.EasingStyle.Quad,
		Cubic = Enum.EasingStyle.Cubic,
		Quart = Enum.EasingStyle.Quart,
		Quint = Enum.EasingStyle.Quint,
		Expo = Enum.EasingStyle.Exponential,
		Circ = Enum.EasingStyle.Circular,
		Back = Enum.EasingStyle.Back,
		Elastic = Enum.EasingStyle.Elastic,
		Bounce = Enum.EasingStyle.Bounce,
	}

	local style = styleMap[name] or Enum.EasingStyle.Quad
	local dir = direction == "In" and Enum.EasingDirection.In
		or direction == "InOut" and Enum.EasingDirection.InOut
		or Enum.EasingDirection.Out

	return tweenInfo(0.3, style, dir)
end

function Animator.Tween(instance, props, duration, easingName, direction)
	if typeof(instance) ~= "Instance" then
		return nil
	end

	local info
	if type(duration) == "table" then
		info = TweenInfo.new(
			duration.Duration or 0.3,
			duration.Style or Enum.EasingStyle.Quad,
			duration.Direction or Enum.EasingDirection.Out
		)
	else
		info = mapEasing(easingName, direction)
		info = TweenInfo.new(duration or 0.3, info.EasingStyle, info.EasingDirection)
	end

	local old = activeTweens[instance]
	if old then
		pcall(function() old:Cancel() end)
	end

	local tween = TweenService:Create(instance, info, props)
	activeTweens[instance] = tween
	tween:Play()

	tween.Completed:Once(function()
		if activeTweens[instance] == tween then
			activeTweens[instance] = nil
		end
	end)

	return tween
end

function Animator.Cancel(instance)
	local tween = activeTweens[instance]
	if tween then
		tween:Cancel()
		activeTweens[instance] = nil
	end
end

function Animator.IsActive(instance)
	return activeTweens[instance] ~= nil
end

function Animator.ActiveCount()
	local n = 0
	for _ in pairs(activeTweens) do
		n = n + 1
	end
	return n
end

function Animator.FadeIn(instance, duration, easingName)
	if typeof(instance) ~= "Instance" then return end
	local startTransparency = 1
	if instance:IsA("GuiObject") then
		instance.BackgroundTransparency = startTransparency
	end
	for _, child in ipairs(instance:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child.TextTransparency = startTransparency
			child.TextStrokeTransparency = startTransparency
		elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
			child.ImageTransparency = startTransparency
		end
	end
	return Animator.Tween(instance, { BackgroundTransparency = 0 }, duration or 0.35, easingName or "Quad")
end

function Animator.FadeOut(instance, duration, easingName)
	if typeof(instance) ~= "Instance" then return end
	return Animator.Tween(instance, { BackgroundTransparency = 1 }, duration or 0.3, easingName or "Quad")
end

function Animator.Scale(instance, from, to, duration, easingName)
	if typeof(instance) ~= "Instance" then return end

	local scale = instance:FindFirstChild("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = instance
	end

	scale.Scale = from or 0.85
	return Animator.Tween(scale, { Scale = to or 1 }, duration or 0.35, easingName or "Back")
end

function Animator.Slide(instance, direction, distance, duration, easingName)
	if typeof(instance) ~= "Instance" then return end

	local original = instance.Position
	local offset
	if direction == "Up" then
		offset = UDim2.new(original.X.Scale, original.X.Offset, original.Y.Scale, original.Y.Offset + (distance or 20))
	elseif direction == "Down" then
		offset = UDim2.new(original.X.Scale, original.X.Offset, original.Y.Scale, original.Y.Offset - (distance or 20))
	elseif direction == "Left" then
		offset = UDim2.new(original.X.Scale, original.X.Offset + (distance or 30), original.Y.Scale, original.Y.Offset)
	else
		offset = UDim2.new(original.X.Scale, original.X.Offset - (distance or 30), original.Y.Scale, original.Y.Offset)
	end

	instance.Position = offset
	return Animator.Tween(instance, { Position = original }, duration or 0.4, easingName or "Quart")
end

function Animator.Stagger(instances, applyFn, staggerDelay, startDelay)
	if type(instances) ~= "table" or type(applyFn) ~= "function" then
		return
	end

	staggerDelay = staggerDelay or 0.04
	startDelay = startDelay or 0

	task.spawn(function()
		for i, instance in ipairs(instances) do
			task.delay(startDelay + (i - 1) * staggerDelay, function()
				applyFn(instance, i)
			end)
		end
	end)
end

function Animator.Sequence(steps)
	task.spawn(function()
		for _, step in ipairs(steps) do
			if type(step) == "function" then
				step()
			elseif type(step) == "table" and step.Run then
				step.Run()
			end
		end
	end)
end

Animator.Easing = Easing

return Animator
