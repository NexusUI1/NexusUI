local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local Checkbox = {}
Checkbox.__index = Checkbox
setmetatable(Checkbox, { __index = BaseComponent })

function Checkbox.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Checkbox")
	setmetatable(self, { __index = function(t, k)
		if Checkbox[k] then
			return Checkbox[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Checkbox"
	self.Text = options.Text or options.Name or "Checkbox"
	self.Value = options.Value or false
	self.DefaultValue = self.Value
	self.Callback = options.Callback or function() end

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

function Checkbox:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Checkbox_" .. self.Text
	self.Container.Size = UDim2.new(1, 0, 0, 26)
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

	self.Box = Instance.new("Frame")
	self.Box.Name = "Box"
	self.Box.AnchorPoint = Vector2.new(0, 0.5)
	self.Box.Position = UDim2.new(0, 4, 0.5, 0)
	self.Box.Size = UDim2.new(0, 18, 0, 18)
	self.Box.BackgroundColor3 = self.Value and tokens.Accent or tokens.Background
	self.Box.BorderSizePixel = 0
	self.Box.ZIndex = 8
	self.Box.Parent = self.Hitbox

	UIUtils.Corner(self.Box, tokens.CornerSmall)
	self.BoxStroke = UIUtils.Stroke(self.Box, self.Value and tokens.Accent or tokens.Border, 1.5, 0.3)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		if not self.Value then
			self.Box.BackgroundColor3 = tk.Background
		end
		self.BoxStroke.Color = self.Value and tk.Accent or tk.Border
	end))

	self.Check = Instance.new("ImageLabel")
	self.Check.Name = "Check"
	self.Check.Size = UDim2.new(0, 12, 0, 12)
	self.Check.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.Check.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Check.BackgroundTransparency = 1
	self.Check.Image = "rbxassetid://10709759999"
	self.Check.ImageColor3 = Color3.fromRGB(255, 255, 255)
	self.Check.ScaleType = Enum.ScaleType.Fit
	self.Check.ImageTransparency = self.Value and 0 or 1
	self.Check.Rotation = self.Value and 0 or -45
	self.Check.ZIndex = 9
	self.Check.Parent = self.Box

	self.TextLabel = Instance.new("TextLabel")
	self.TextLabel.Name = "Text"
	self.TextLabel.Position = UDim2.new(0, 30, 0, 0)
	self.TextLabel.Size = UDim2.new(1, -34, 1, 0)
	self.TextLabel.BackgroundTransparency = 1
	self.TextLabel.Font = tokens.Font
	self.TextLabel.Text = self.Text
	self.TextLabel.TextColor3 = tokens.Text
	self.TextLabel.TextSize = tokens.TextSize
	self.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TextLabel.ZIndex = 7
	self.TextLabel.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TextLabel.Font = tk.Font
		self.TextLabel.TextColor3 = tk.Text
		self.TextLabel.TextSize = tk.TextSize
	end))

	self.Hitbox.MouseButton1Click:Connect(function()
		self:SetValue(not self.Value, true)
	end)

	self.Hitbox.MouseEnter:Connect(function()
		Sound.Hover()
	end)
end

function Checkbox:SetValue(value, fireEvent)
	value = value and true or false

	if value == self.Value then
		return self
	end

	self.Value = value
	local tokens = ThemeManager.GetTokens()

	if value then
		Animator.Tween(self.Box, { BackgroundColor3 = tokens.Accent }, 0.15, "Quad")
		Animator.Tween(self.BoxStroke, { Color = tokens.Accent }, 0.15, "Quad")
		Animator.Tween(self.Check, { ImageTransparency = 0, Rotation = 0 }, 0.2, "Back")
	else
		Animator.Tween(self.Box, { BackgroundColor3 = tokens.Background }, 0.15, "Quad")
		Animator.Tween(self.BoxStroke, { Color = tokens.Border }, 0.15, "Quad")
		Animator.Tween(self.Check, { ImageTransparency = 1, Rotation = -45 }, 0.15, "Quad")
	end

	if fireEvent then
		Sound.Toggle()
		self.OnChanged:Fire(value)

		local ok, err = pcall(self.Callback, value)
		if not ok then
			warn("[NexusUI] Checkbox callback error:", err)
		end
	end

	return self
end

function Checkbox:GetValue()
	return self.Value
end

function Checkbox:SetText(text)
	self.Text = text
	self.TextLabel.Text = text
	return self
end

function Checkbox:Reset()
	return self:SetValue(self.DefaultValue, true)
end

function Checkbox:Destroy()
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

return Checkbox
