local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Spring = require(script.Parent.Parent.Animation.Spring)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local Toggle = {}
Toggle.__index = Toggle
setmetatable(Toggle, { __index = BaseComponent })

function Toggle.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Toggle")
	setmetatable(self, { __index = function(t, k)
		if Toggle[k] then
			return Toggle[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Toggle"
	self.Text = options.Text or options.Name or "Toggle"
	self.Description = options.Description or ""
	self.Value = options.Value or false
	self.Callback = options.Callback or function() end
	self.DefaultValue = self.Value

	self.OnChanged = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
	}

	self:_build(parent)

	return self
end

function Toggle:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Toggle_" .. self.Text
	self.Container.Size = UDim2.new(1, 0, 0, 32)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Hitbox = Instance.new("TextButton")
	self.Hitbox.Name = "Hitbox"
	self.Hitbox.Size = UDim2.new(1, 0, 1, 0)
	self.Hitbox.BackgroundTransparency = 1
	self.Hitbox.BorderSizePixel = 0
	self.Hitbox.AutoButtonColor = false
	self.Hitbox.Text = ""
	self.Hitbox.ZIndex = 7
	self.Hitbox.Parent = self.Container

	self.Switch = Instance.new("Frame")
	self.Switch.Name = "Switch"
	self.Switch.AnchorPoint = Vector2.new(1, 0.5)
	self.Switch.Position = UDim2.new(1, -4, 0.5, 0)
	self.Switch.Size = UDim2.new(0, 40, 0, 22)
	self.Switch.BackgroundColor3 = tokens.SurfaceLight
	self.Switch.BorderSizePixel = 0
	self.Switch.ZIndex = 8
	self.Switch.Parent = self.Hitbox

	UIUtils.Corner(self.Switch, tokens.CornerCircle)
	UIUtils.Stroke(self.Switch, tokens.Border, 1, 0.6)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		if not self.Value then
			self.Switch.BackgroundColor3 = tk.SurfaceLight
		end
	end))

	self.Knob = Instance.new("Frame")
	self.Knob.Name = "Knob"
	self.Knob.AnchorPoint = Vector2.new(0, 0.5)
	self.Knob.Position = UDim2.new(0, 3, 0.5, 0)
	self.Knob.Size = UDim2.new(0, 16, 0, 16)
	self.Knob.BackgroundColor3 = tokens.SecondaryText
	self.Knob.BorderSizePixel = 0
	self.Knob.ZIndex = 9
	self.Knob.Parent = self.Switch

	UIUtils.Corner(self.Knob, tokens.CornerCircle)

	self._knobSpring = Spring.new(0, { Stiffness = 260, Damping = 22 })
	self._knobSpring:OnUpdate(function(value)
		self.Knob.Position = UDim2.new(0, 3 + value * 18, 0.5, 0)
	end)

	self.TextLabel = Instance.new("TextLabel")
	self.TextLabel.Name = "Text"
	self.TextLabel.BackgroundTransparency = 1
	self.TextLabel.Position = UDim2.new(0, 4, 0, 0)
	self.TextLabel.Size = UDim2.new(1, -56, 1, 0)
	self.TextLabel.Font = tokens.Font
	self.TextLabel.Text = self.Text
	self.TextLabel.TextColor3 = tokens.Text
	self.TextLabel.TextSize = tokens.TextSize
	self.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TextLabel.TextTruncate = Enum.TextTruncate.AtEnd
	self.TextLabel.ZIndex = 7
	self.TextLabel.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TextLabel.Font = tk.Font
		self.TextLabel.TextColor3 = tk.Text
		self.TextLabel.TextSize = tk.TextSize
	end))

	self.Hitbox.MouseEnter:Connect(function()
		Sound.Hover()
	end)

	self.Hitbox.MouseButton1Click:Connect(function()
		self:SetValue(not self.Value, true)
	end)

	self:_updateVisual(true)
end

function Toggle:_updateVisual(instant)
	local tokens = ThemeManager.GetTokens()
	local targetKnobPos = self.Value and 1 or 0

	if instant then
		self._knobSpring:SetValue(targetKnobPos)
	else
		self._knobSpring:SetTarget(targetKnobPos)
	end

	if self.Value then
		Animator.Tween(self.Switch, { BackgroundColor3 = tokens.Accent }, 0.2, "Quad")
		Animator.Tween(self.Knob, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, 0.15, "Quad")
	else
		Animator.Tween(self.Switch, { BackgroundColor3 = tokens.SurfaceLight }, 0.2, "Quad")
		Animator.Tween(self.Knob, { BackgroundColor3 = tokens.SecondaryText }, 0.15, "Quad")
	end
end

function Toggle:SetValue(value, fireEvent)
	value = value and true or false

	if value == self.Value then
		return self
	end

	self.Value = value
	self:_updateVisual(false)

	if fireEvent then
		Sound.Toggle()
		self.OnChanged:Fire(value)

		local ok, err = pcall(self.Callback, value)
		if not ok then
			warn("[NexusUI] Toggle callback error:", err)
		end
	end

	return self
end

function Toggle:GetValue()
	return self.Value
end

function Toggle:SetText(text)
	self.Text = text
	self.TextLabel.Text = text
	return self
end

function Toggle:Reset()
	return self:SetValue(self.DefaultValue, true)
end

function Toggle:Destroy()
	if self.Destroyed then
		return
	end

	if self._knobSpring then
		self._knobSpring:Destroy()
	end

	if self.Container then
		self.Container:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return Toggle
