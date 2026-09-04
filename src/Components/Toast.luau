local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local Toast = {}
Toast.__index = Toast
setmetatable(Toast, { __index = BaseComponent })

local function getRoot()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	if not ok or parent == nil then
		parent = PlayerGui
	end

	local existing = parent:FindFirstChild("NexusUI_Toasts")
	if existing then
		return existing
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NexusUI_Toasts"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 250
	screenGui.Parent = parent

	return screenGui
end

local ToastContainer = nil

local function getContainer(position)
	local root = getRoot()

	local containerName = "Container_" .. position
	local existing = root:FindFirstChild(containerName)
	if existing then
		return existing
	end

	local container = Instance.new("Frame")
	container.Name = containerName
	container.BackgroundTransparency = 1
	container.ZIndex = 100

	if position == "BottomCenter" then
		container.AnchorPoint = Vector2.new(0.5, 1)
		container.Position = UDim2.new(0.5, 0, 1, -40)
	elseif position == "TopCenter" then
		container.AnchorPoint = Vector2.new(0.5, 0)
		container.Position = UDim2.new(0.5, 0, 0, 40)
	elseif position == "BottomLeft" then
		container.AnchorPoint = Vector2.new(0, 1)
		container.Position = UDim2.new(0, 20, 1, -40)
	else
		container.AnchorPoint = Vector2.new(0.5, 1)
		container.Position = UDim2.new(0.5, 0, 1, -80)
	end

	container.Size = UDim2.new(0, 360, 0, 300)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = position == "TopCenter" and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	container.Parent = root
	return container
end

function Toast.new(options)
	options = options or {}

	local self = BaseComponent.new("Toast")
	setmetatable(self, { __index = function(t, k)
		if Toast[k] then
			return Toast[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Toast"
	self.Text = options.Text or "Done!"
	self.Position = options.Position or "BottomCenter"
	self.Duration = options.Duration or 2
	self.Variant = options.Variant or "Dark"

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
	}

	self:Show()

	return self
end

function Toast:_variantColors(variant)
	local tokens = ThemeManager.GetTokens()
	local variants = {
		Dark = { Background = tokens.Elevated, Text = tokens.Text },
		Accent = { Background = tokens.Accent, Text = Color3.fromRGB(255, 255, 255) },
		Success = { Background = tokens.Success, Text = Color3.fromRGB(255, 255, 255) },
		Error = { Background = tokens.Error, Text = Color3.fromRGB(255, 255, 255) },
	}
	return variants[variant] or variants.Dark
end

function Toast:Show()
	local tokens = ThemeManager.GetTokens()
	local colors = self:_variantColors(self.Variant)

	local container = getContainer(self.Position)

	self.Frame = Instance.new("Frame")
	self.Frame.Name = "Toast"
	self.Frame.Size = UDim2.new(0, 0, 0, 0)
	self.Frame.AutomaticSize = Enum.AutomaticSize.XY
	self.Frame.BackgroundColor3 = colors.Background
	self.Frame.BackgroundTransparency = self.Variant == "Dark" and 0.06 or 0
	self.Frame.BorderSizePixel = 0
	self.Frame.ZIndex = 101
	self.Frame.Parent = container

	UIUtils.Corner(self.Frame, tokens.Corner)

	if self.Variant == "Dark" then
		UIUtils.Stroke(self.Frame, tokens.BorderLight, 1, 0.5)
	end

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.PaddingTop = UDim.new(0, 9)
	padding.PaddingBottom = UDim.new(0, 9)
	padding.Parent = self.Frame

	self.Label = Instance.new("TextLabel")
	self.Label.Name = "Text"
	self.Label.Size = UDim2.new(0, 0, 0, 0)
	self.Label.AutomaticSize = Enum.AutomaticSize.XY
	self.Label.BackgroundTransparency = 1
	self.Label.Font = tokens.FontBold
	self.Label.Text = self.Text
	self.Label.TextColor3 = colors.Text
	self.Label.TextSize = 13
	self.Label.ZIndex = 102
	self.Label.Parent = self.Frame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		local vc = self:_variantColors(self.Variant)
		self.Frame.BackgroundColor3 = vc.Background
		self.Label.Font = tk.FontBold
		self.Label.TextColor3 = vc.Text
	end))

	self.Frame.BackgroundTransparency = 1
	if self.Label then
		self.Label.TextTransparency = 1
	end

	Animator.Tween(self.Frame, { BackgroundTransparency = self.Variant == "Dark" and 0.06 or 0 }, 0.25, "Quart")
	Animator.Tween(self.Label, { TextTransparency = 0 }, 0.25, "Quart")

	Sound.Pop()

	task.delay(self.Duration, function()
		self:Hide()
	end)

	return self
end

function Toast:Hide()
	if self.Hidden then
		return self
	end
	self.Hidden = true

	if self.Frame and self.Frame.Parent then
		Animator.Tween(self.Frame, { BackgroundTransparency = 1 }, 0.2, "Quad")
		if self.Label then
			Animator.Tween(self.Label, { TextTransparency = 1 }, 0.2, "Quad")
		end

		task.delay(0.22, function()
			if self.Frame then
				self.Frame:Destroy()
			end
			self._maid:Destroy()
		end)
	end

	return self
end

function Toast:SetText(text)
	self.Text = text
	if self.Label then
		self.Label.Text = text
	end
	return self
end

function Toast:Destroy()
	self:Hide()
	self.Destroyed = true
end

return Toast
