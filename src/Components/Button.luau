local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local Button = {}
Button.__index = Button
setmetatable(Button, { __index = BaseComponent })

function Button.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Button")
	setmetatable(self, { __index = function(t, k)
		if Button[k] then
			return Button[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Button"
	self.Text = options.Text or options.Name or "Button"
	self.Description = options.Description or ""
	self.Callback = options.Callback or function() end
	self.Variant = options.Variant or "Primary"
	self.FullWidth = options.FullWidth ~= false
	self.Icon = options.Icon

	self.ClickCount = 0

	self.OnClick = Signal.new()
	self.OnPressed = Signal.new()
	self.OnReleased = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Click = self.OnClick,
		Pressed = self.OnPressed,
		Released = self.OnReleased,
	}

	self:_build(parent)

	return self
end

function Button:_variantColors(variant)
	local tokens = ThemeManager.GetTokens()

	local variants = {
		Primary = {
			Background = tokens.Accent,
			Text = Color3.fromRGB(255, 255, 255),
			Stroke = tokens.AccentDark,
			StrokeTransparency = 0.4,
			BackgroundTransparency = 0,
		},
		Secondary = {
			Background = tokens.SurfaceLight,
			Text = tokens.Text,
			Stroke = tokens.Border,
			StrokeTransparency = 0.5,
			BackgroundTransparency = 0.1,
		},
		Outline = {
			Background = tokens.Background,
			Text = tokens.Text,
			Stroke = tokens.Accent,
			StrokeTransparency = 0.35,
			BackgroundTransparency = 0.85,
		},
		Ghost = {
			Background = tokens.Surface,
			Text = tokens.SecondaryText,
			Stroke = tokens.Surface,
			StrokeTransparency = 1,
			BackgroundTransparency = 1,
		},
		Danger = {
			Background = tokens.Error,
			Text = Color3.fromRGB(255, 255, 255),
			Stroke = tokens.Error,
			StrokeTransparency = 0.4,
			BackgroundTransparency = 0,
		},
		Success = {
			Background = tokens.Success,
			Text = Color3.fromRGB(255, 255, 255),
			Stroke = tokens.Success,
			StrokeTransparency = 0.4,
			BackgroundTransparency = 0,
		},
	}

	return variants[variant] or variants.Primary
end

function Button:_build(parent)
	local tokens = ThemeManager.GetTokens()
	local colors = self:_variantColors(self.Variant)

	self.Container = Instance.new("Frame")
	self.Container.Name = "Button_" .. self.Text
	self.Container.Size = self.FullWidth and UDim2.new(1, 0, 0, 36) or UDim2.new(0, 120, 0, 36)
	self.Container.AutomaticSize = self.FullWidth and Enum.AutomaticSize.None or Enum.AutomaticSize.None
	self.Container.BackgroundColor3 = colors.Background
	self.Container.BackgroundTransparency = colors.BackgroundTransparency
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	UIUtils.Corner(self.Container, tokens.CornerSmall)

	self.Stroke = UIUtils.Stroke(self.Container, colors.Stroke, 1, colors.StrokeTransparency)

	self.Button = Instance.new("TextButton")
	self.Button.Name = "ClickTarget"
	self.Button.Size = UDim2.new(1, 0, 1, 0)
	self.Button.BackgroundTransparency = 1
	self.Button.BorderSizePixel = 0
	self.Button.AutoButtonColor = false
	self.Button.Font = tokens.FontBold
	self.Button.Text = self.Text
	self.Button.TextColor3 = colors.Text
	self.Button.TextSize = tokens.TextSize
	self.Button.TextXAlignment = Enum.TextXAlignment.Center
	self.Button.ZIndex = 7
	self.Button.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		local vc = self:_variantColors(self.Variant)
		self.Container.BackgroundColor3 = vc.Background
		self.Container.BackgroundTransparency = vc.BackgroundTransparency
		self.Stroke.Color = vc.Stroke
		self.Stroke.Transparency = vc.StrokeTransparency
		self.Button.Font = tk.FontBold
		self.Button.TextColor3 = vc.Text
		self.Button.TextSize = tk.TextSize
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = self.Container

	if self.Icon then
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.Image = self.Icon
		icon.Size = UDim2.new(0, 16, 0, 16)
		icon.ImageColor3 = colors.Text
		icon.ScaleType = Enum.ScaleType.Fit
		icon.LayoutOrder = 1
		icon.ZIndex = 8
		icon.Parent = self.Container

		self._icon = icon

		local iconCorner = UDim.new(0, 8)
		local holderLayout = Instance.new("UIListLayout")
		holderLayout.FillDirection = Enum.FillDirection.Horizontal
		holderLayout.Padding = UDim.new(0, 6)
		holderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		holderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
		holderLayout.Parent = self.Container

		self.Button.TextXAlignment = Enum.TextXAlignment.Center
	end

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = self.Container
	self._scale = scale

	local pressed = false

	self.Button.MouseEnter:Connect(function()
		if not self.Enabled then
			return
		end
		Animator.Tween(scale, { Scale = 1.02 }, 0.15, "Quad")
		Animator.Tween(self.Container, { BackgroundTransparency = math.max(0, colors.BackgroundTransparency - 0.05) }, 0.15, "Quad")
		Sound.Hover()
	end)

	self.Button.MouseLeave:Connect(function()
		Animator.Tween(scale, { Scale = 1 }, 0.2, "Quad")
		Animator.Tween(self.Container, { BackgroundTransparency = colors.BackgroundTransparency }, 0.2, "Quad")
		pressed = false
	end)

	self.Button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			pressed = true
			Animator.Tween(scale, { Scale = 0.96 }, 0.08, "Quad")
			self.OnPressed:Fire()
		end
	end)

	self.Button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if pressed then
				pressed = false
				Animator.Tween(scale, { Scale = 1 }, 0.2, "Back")
				self.OnReleased:Fire()
			end
		end
	end)

	self.Button.MouseButton1Click:Connect(function()
		if not self.Enabled then
			return
		end

		self.ClickCount = self.ClickCount + 1
		Sound.Click()
		self.OnClick:Fire(self.ClickCount)

		local ok, err = pcall(self.Callback, self.ClickCount)
		if not ok then
			warn("[NexusUI] Button callback error:", err)
		end
	end)
end

function Button:SetText(text)
	self.Text = text
	self.Button.Text = text
	self.Container.Name = "Button_" .. text
	return self
end

function Button:SetIcon(icon)
	self.Icon = icon

	if icon then
		if not self._icon then
			self._icon = Instance.new("ImageLabel")
			self._icon.Name = "Icon"
			self._icon.BackgroundTransparency = 1
			self._icon.Size = UDim2.new(0, 16, 0, 16)
			self._icon.ScaleType = Enum.ScaleType.Fit
			self._icon.LayoutOrder = 1
			self._icon.ZIndex = 8
			self._icon.Parent = self.Container
		end
		self._icon.Image = icon
	elseif self._icon then
		self._icon:Destroy()
		self._icon = nil
	end

	return self
end

function Button:SetVariant(variant)
	self.Variant = variant
	local tokens = ThemeManager.GetTokens()
	local colors = self:_variantColors(variant)

	Animator.Tween(self.Container, { BackgroundColor3 = colors.Background }, 0.2, "Quad")
	Animator.Tween(self.Button, { TextColor3 = colors.Text }, 0.2, "Quad")
	Animator.Tween(self.Stroke, { Color = colors.Stroke, Transparency = colors.StrokeTransparency }, 0.2, "Quad")

	if self._icon then
		self._icon.ImageColor3 = colors.Text
	end

	return self
end

function Button:SetFullWidth(fullWidth)
	self.FullWidth = fullWidth
	if fullWidth then
		self.Container.Size = UDim2.new(1, 0, 0, 36)
	else
		self.Container.Size = UDim2.new(0, 120, 0, 36)
	end
	return self
end

function Button:OnEnabledChanged(enabled)
	local tokens = ThemeManager.GetTokens()

	if enabled then
		local vc = self:_variantColors(self.Variant)
		Animator.Tween(self.Container, { BackgroundTransparency = vc.BackgroundTransparency }, 0.2, "Quad")
		Animator.Tween(self.Button, { TextTransparency = 0 }, 0.2, "Quad")
	else
		Animator.Tween(self.Container, { BackgroundTransparency = 0.6 }, 0.2, "Quad")
		Animator.Tween(self.Button, { TextTransparency = 0.5 }, 0.2, "Quad")
	end
end

function Button:PlayClickAnimation()
	local scale = self._scale
	if scale then
		Animator.Tween(scale, { Scale = 0.94 }, 0.07, "Quad")
		task.delay(0.07, function()
			Animator.Tween(scale, { Scale = 1 }, 0.25, "Back")
		end)
	end
	return self
end

function Button:Destroy()
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

return Button
