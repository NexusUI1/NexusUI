local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local Slider = {}
Slider.__index = Slider
setmetatable(Slider, { __index = BaseComponent })

function Slider.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Slider")
	setmetatable(self, { __index = function(t, k)
		if Slider[k] then
			return Slider[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Slider"
	self.Text = options.Text or options.Name or "Slider"
	self.Min = options.Min or 0
	self.Max = options.Max or 100
	self.Step = options.Step or 1
	self.DefaultValue = options.Value or options.Default or self.Min
	self.Value = math.clamp(self.DefaultValue, self.Min, self.Max)
	self.Suffix = options.Suffix or ""
	self.Prefix = options.Prefix or ""
	self.Callback = options.Callback or function() end
	self.OnInputEnded = options.OnInputEnded

	self.OnChanged = Signal.new()
	self.OnDragging = Signal.new()
	self.OnReleased = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
		Dragging = self.OnDragging,
		Released = self.OnReleased,
	}

	self:_build(parent)
	self:_setValue(self.Value, false, true)

	return self
end

function Slider:_roundToStep(value)
	local stepped = math.floor((value - self.Min) / self.Step + 0.5) * self.Step + self.Min
	return math.clamp(stepped, self.Min, self.Max)
end

function Slider:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Slider_" .. self.Text
	self.Container.Size = UDim2.new(1, 0, 0, 48)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Header = Instance.new("Frame")
	self.Header.Name = "Header"
	self.Header.Size = UDim2.new(1, 0, 0, 18)
	self.Header.BackgroundTransparency = 1
	self.Header.ZIndex = 7
	self.Header.Parent = self.Container

	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Name = "Title"
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.Size = UDim2.new(0.6, 0, 1, 0)
	self.TitleLabel.Font = tokens.Font
	self.TitleLabel.Text = self.Text
	self.TitleLabel.TextColor3 = tokens.Text
	self.TitleLabel.TextSize = tokens.TextSize
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.ZIndex = 7
	self.TitleLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TitleLabel.Font = tk.Font
		self.TitleLabel.TextColor3 = tk.Text
		self.TitleLabel.TextSize = tk.TextSize
	end))

	self.ValueLabel = Instance.new("TextLabel")
	self.ValueLabel.Name = "Value"
	self.ValueLabel.AnchorPoint = Vector2.new(1, 0)
	self.ValueLabel.Position = UDim2.new(1, 0, 0, 0)
	self.ValueLabel.Size = UDim2.new(0.4, 0, 1, 0)
	self.ValueLabel.Font = tokens.FontBold
	self.ValueLabel.Text = self:_formatValue(self.Value)
	self.ValueLabel.TextColor3 = tokens.Accent
	self.ValueLabel.TextSize = 12
	self.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.ValueLabel.ZIndex = 7
	self.ValueLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.ValueLabel.Font = tk.FontBold
		self.ValueLabel.TextColor3 = tk.Accent
	end))

	self.Track = Instance.new("TextButton")
	self.Track.Name = "Track"
	self.Track.Position = UDim2.new(0, 0, 0, 24)
	self.Track.Size = UDim2.new(1, 0, 0, 18)
	self.Track.BackgroundColor3 = tokens.SurfaceLight
	self.Track.BackgroundTransparency = 0.3
	self.Track.BorderSizePixel = 0
	self.Track.AutoButtonColor = false
	self.Track.Text = ""
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

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Fill.BackgroundColor3 = tk.Accent
	end))

	self.Thumb = Instance.new("Frame")
	self.Thumb.Name = "Thumb"
	self.Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Thumb.Position = UDim2.new(0, 0, 0.5, 0)
	self.Thumb.Size = UDim2.new(0, 14, 0, 14)
	self.Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.Thumb.BorderSizePixel = 0
	self.Thumb.ZIndex = 9
	self.Thumb.Parent = self.Track

	UIUtils.Corner(self.Thumb, tokens.CornerCircle)
	UIUtils.Stroke(self.Thumb, tokens.Accent, 1.5, 0.15)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Thumb.Stroke.Color = tk.Accent
	end))

	self:_bindDrag()
end

function Slider:_formatValue(value)
	local decimals = 0
	local step = self.Step
	while step < 1 and decimals < 4 do
		step = step * 10
		decimals = decimals + 1
	end

	local formatted = string.format("%." .. decimals .. "f", value)
	return self.Prefix .. formatted .. self.Suffix
end

function Slider:_getAlpha()
	return (self.Value - self.Min) / math.max(0.0001, self.Max - self.Min)
end

function Slider:_applyAlpha(alpha, fireEvent)
	alpha = math.clamp(alpha, 0, 1)
	local rawValue = self.Min + alpha * (self.Max - self.Min)
	self:_setValue(rawValue, fireEvent, false)
end

function Slider:_setValue(value, fireEvent, instant)
	value = self:_roundToStep(value)

	local changed = value ~= self.Value
	self.Value = value

	local alpha = self:_getAlpha()
	self.Fill.Size = UDim2.new(alpha, 0, 1, 0)
	self.Thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
	self.ValueLabel.Text = self:_formatValue(value)

	if fireEvent and changed then
		Sound.Pop()
		self.OnChanged:Fire(value)

		local ok, err = pcall(self.Callback, value)
		if not ok then
			warn("[NexusUI] Slider callback error:", err)
		end
	end
end

function Slider:_bindDrag()
	local dragging = false

	self.Track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true

			local alpha = (input.Position.X - self.Track.AbsolutePosition.X) / self.Track.AbsoluteSize.X
			self:_applyAlpha(alpha, true)
			self.OnDragging:Fire(self.Value)

			Animator.Tween(self.Thumb, { Size = UDim2.new(0, 17, 0, 17) }, 0.1, "Quad")
		end
	end)

	local uis = game:GetService("UserInputService")

	local moveConnection = uis.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local alpha = (input.Position.X - self.Track.AbsolutePosition.X) / self.Track.AbsoluteSize.X
			self:_applyAlpha(alpha, true)
		end
	end)

	local endConnection = uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				Animator.Tween(self.Thumb, { Size = UDim2.new(0, 14, 0, 14) }, 0.15, "Back")
				self.OnReleased:Fire(self.Value)

				if self.OnInputEnded then
					pcall(self.OnInputEnded, self.Value)
				end
			end
		end
	end)

	self._maid:GiveTask(moveConnection)
	self._maid:GiveTask(endConnection)
end

function Slider:SetValue(value, fireEvent)
	self:_setValue(value, fireEvent ~= false, false)
	return self
end

function Slider:GetValue()
	return self.Value
end

function Slider:SetRange(min, max)
	self.Min = min
	self.Max = max
	self:_setValue(math.clamp(self.Value, min, max), false, false)
	return self
end

function Slider:SetStep(step)
	self.Step = step or 1
	self:_setValue(self.Value, false, false)
	return self
end

function Slider:SetText(text)
	self.Text = text
	self.TitleLabel.Text = text
	return self
end

function Slider:SetSuffix(suffix)
	self.Suffix = suffix or ""
	self.ValueLabel.Text = self:_formatValue(self.Value)
	return self
end

function Slider:Reset()
	return self:SetValue(self.DefaultValue)
end

function Slider:Destroy()
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

return Slider
