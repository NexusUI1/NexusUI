local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)

local ProgressBar = {}
ProgressBar.__index = ProgressBar
setmetatable(ProgressBar, { __index = BaseComponent })

function ProgressBar.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("ProgressBar")
	setmetatable(self, { __index = function(t, k)
		if ProgressBar[k] then
			return ProgressBar[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "ProgressBar"
	self.Text = options.Text or ""
	self.Min = options.Min or 0
	self.Max = options.Max or 100
	self.Value = options.Value or 0
	self.ShowPercentage = options.ShowPercentage ~= false
	self.Animated = options.Animated ~= false

	self.OnCompleted = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Completed = self.OnCompleted,
	}

	self:_build(parent)
	self:_updateFill(true)

	return self
end

function ProgressBar:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "ProgressBar_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, self.Text ~= "" and 40 or 14)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	if self.Text ~= "" then
		self.Label = Instance.new("TextLabel")
		self.Label.Name = "Label"
		self.Label.Size = UDim2.new(1, 0, 0, 16)
		self.Label.BackgroundTransparency = 1
		self.Label.Font = tokens.Font
		self.Label.Text = self.Text
		self.Label.TextColor3 = tokens.Text
		self.Label.TextSize = tokens.TextSize
		self.Label.TextXAlignment = Enum.TextXAlignment.Left
		self.Label.ZIndex = 7
		self.Label.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.Label.Font = tk.Font
			self.Label.TextColor3 = tk.Text
		end))
	end

	self.Track = Instance.new("Frame")
	self.Track.Name = "Track"
	self.Track.Position = self.Text ~= "" and UDim2.new(0, 0, 0, 20) or UDim2.new(0, 0, 0, 0)
	self.Track.Size = UDim2.new(1, 0, 0, 8)
	self.Track.BackgroundColor3 = tokens.SurfaceLight
	self.Track.BackgroundTransparency = 0.2
	self.Track.BorderSizePixel = 0
	self.Track.ZIndex = 7
	self.Track.Parent = self.Container

	UIUtils.Corner(self.Track, tokens.CornerCircle)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Track.BackgroundColor3 = tk.SurfaceLight
	end))

	self.Fill = Instance.new("Frame")
	self.Fill.Name = "Fill"
	self.Fill.Size = UDim2.new(0, 0, 1, 0)
	self.Fill.BackgroundColor3 = tokens.Accent
	self.Fill.BorderSizePixel = 0
	self.Fill.ZIndex = 8
	self.Fill.Parent = self.Track

	UIUtils.Corner(self.Fill, tokens.CornerCircle)

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	gradient.Parent = self.Fill

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Fill.BackgroundColor3 = tk.Accent
	end))

	if self.ShowPercentage then
		self.PercentageLabel = Instance.new("TextLabel")
		self.PercentageLabel.Name = "Percentage"
		self.PercentageLabel.AnchorPoint = Vector2.new(1, 0)
		self.PercentageLabel.Position = UDim2.new(1, 0, self.Text ~= "" and 0 or 0, self.Text ~= "" and 0 or -2)
		self.PercentageLabel.Size = UDim2.new(0, 50, 0, 12)
		self.PercentageLabel.BackgroundTransparency = 1
		self.PercentageLabel.Font = tokens.FontBold
		self.PercentageLabel.Text = "0%"
		self.PercentageLabel.TextColor3 = tokens.SecondaryText
		self.PercentageLabel.TextSize = 10
		self.PercentageLabel.TextXAlignment = Enum.TextXAlignment.Right
		self.PercentageLabel.ZIndex = 8
		self.PercentageLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.PercentageLabel.Font = tk.FontBold
			self.PercentageLabel.TextColor3 = tk.SecondaryText
		end))
	end
end

function ProgressBar:_updateFill(instant)
	local alpha = math.clamp((self.Value - self.Min) / math.max(0.0001, self.Max - self.Min), 0, 1)
	local targetSize = UDim2.new(alpha, 0, 1, 0)

	if instant or not self.Animated then
		self.Fill.Size = targetSize
	else
		Animator.Tween(self.Fill, { Size = targetSize }, 0.3, "Quart")
	end

	if self.PercentageLabel then
		self.PercentageLabel.Text = math.floor(alpha * 100 + 0.5) .. "%"
	end

	if alpha >= 1 then
		self.OnCompleted:Fire()
	end
end

function ProgressBar:SetValue(value, instant)
	self.Value = math.clamp(value, self.Min, self.Max)
	self:_updateFill(instant == true)
	return self
end

function ProgressBar:GetValue()
	return self.Value
end

function ProgressBar:SetText(text)
	self.Text = text
	if self.Label then
		self.Label.Text = text
	end
	return self
end

function ProgressBar:SetRange(min, max)
	self.Min = min
	self.Max = max
	self:_updateFill()
	return self
end

function ProgressBar:Increment(amount)
	return self:SetValue(self.Value + (amount or 1))
end

function ProgressBar:Reset()
	return self:SetValue(self.Min, true)
end

function ProgressBar:Complete()
	return self:SetValue(self.Max)
end

function ProgressBar:Destroy()
	if self.Destroyed then
		return
	end

	if self.Container then
		self.Container:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return ProgressBar
