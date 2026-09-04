local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)

local Badge = {}
Badge.__index = Badge
setmetatable(Badge, { __index = BaseComponent })

function Badge.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Badge")
	setmetatable(self, { __index = function(t, k)
		if Badge[k] then
			return Badge[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Badge"
	self.Text = options.Text or "New"
	self.Variant = options.Variant or "Accent"
	self.Size = options.Size or UDim2.new(0, 60, 0, 20)

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
	}

	self:_build(parent)

	return self
end

function Badge:_variantColors(variant)
	local tokens = ThemeManager.GetTokens()
	local variants = {
		Accent = { Background = tokens.Accent, Text = Color3.fromRGB(255, 255, 255) },
		Success = { Background = tokens.Success, Text = Color3.fromRGB(255, 255, 255) },
		Error = { Background = tokens.Error, Text = Color3.fromRGB(255, 255, 255) },
		Warning = { Background = tokens.Warning, Text = Color3.fromRGB(40, 30, 10) },
		Info = { Background = tokens.Info, Text = Color3.fromRGB(255, 255, 255) },
		Muted = { Background = tokens.SurfaceLight, Text = tokens.SecondaryText },
		Outline = { Background = tokens.Background, Text = tokens.Accent },
	}
	return variants[variant] or variants.Accent
end

function Badge:_build(parent)
	local tokens = ThemeManager.GetTokens()
	local colors = self:_variantColors(self.Variant)

	self.Container = Instance.new("Frame")
	self.Container.Name = "Badge_" .. self.Text
	self.Container.Size = self.Size
	self.Container.BackgroundColor3 = colors.Background
	self.Container.BackgroundTransparency = self.Variant == "Outline" and 0.8 or 0
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	UIUtils.Corner(self.Container, tokens.CornerSmall)

	if self.Variant == "Outline" then
		UIUtils.Stroke(self.Container, tokens.Accent, 1, 0.3)
	end

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		local vc = self:_variantColors(self.Variant)
		self.Container.BackgroundColor3 = vc.Background
	end))

	self.Label = Instance.new("TextLabel")
	self.Label.Name = "Text"
	self.Label.Size = UDim2.new(1, 0, 1, 0)
	self.Label.BackgroundTransparency = 1
	self.Label.Font = tokens.FontBold
	self.Label.Text = self.Text
	self.Label.TextColor3 = colors.Text
	self.Label.TextSize = 10
	self.Label.ZIndex = 7
	self.Label.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		local vc = self:_variantColors(self.Variant)
		self.Label.Font = tk.FontBold
		self.Label.TextColor3 = vc.Text
	end))
end

function Badge:SetText(text)
	self.Text = text
	self.Label.Text = text
	return self
end

function Badge:SetVariant(variant)
	self.Variant = variant
	local colors = self:_variantColors(variant)

	Animator.Tween(self.Container, { BackgroundColor3 = colors.Background }, 0.2, "Quad")
	Animator.Tween(self.Label, { TextColor3 = colors.Text }, 0.2, "Quad")

	return self
end

function Badge:Pulse()
	Animator.Tween(self.Container, { BackgroundTransparency = 0.4 }, 0.15, "Quad")
	task.delay(0.15, function()
		Animator.Tween(self.Container, { BackgroundTransparency = self.Variant == "Outline" and 0.8 or 0 }, 0.3, "Back")
	end)
	return self
end

function Badge:Destroy()
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

return Badge
