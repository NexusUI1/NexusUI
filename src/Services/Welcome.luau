local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)
local Icons = require(script.Parent.Parent.Core.Icons)

local Welcome = {}
Welcome.__index = Welcome

Welcome.Shown = false

local function getRoot()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	if not ok or parent == nil then
		parent = PlayerGui
	end

	local existing = parent:FindFirstChild("NexusUI_Welcome")
	if existing then
		return existing
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NexusUI_Welcome"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 800
	screenGui.Parent = parent

	return screenGui
end

function Welcome.new(options)
	options = options or {}

	local self = setmetatable({}, Welcome)
	self.Title = options.Title or "NexusUI"
	self.SubTitle = options.SubTitle or "Premium Interface Framework"
	self.Version = options.Version or "1.0.0"
	self.Duration = options.Duration or 3
	self.OnFinished = Signal.new()

	self._maid = Maid.new()

	self:Show()

	return self
end

function Welcome:Show()
	if Welcome.Shown then
		return self
	end

	Welcome.Shown = true
	local tokens = ThemeManager.GetTokens()

	local root = getRoot()

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = tokens.Background
	backdrop.BackgroundTransparency = 0
	backdrop.BorderSizePixel = 0
	backdrop.ZIndex = 800
	backdrop.Parent = root

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		backdrop.BackgroundColor3 = tk.Background
	end))

	local bgImage = Instance.new("ImageLabel")
	bgImage.Name = "BackgroundImage"
	bgImage.Size = UDim2.new(1, 0, 1, 0)
	bgImage.BackgroundTransparency = 1
	bgImage.Image = Icons.Assets.Background
	bgImage.ImageColor3 = tokens.Accent
	bgImage.ImageTransparency = 0.93
	bgImage.ScaleType = Enum.ScaleType.Crop
	bgImage.ZIndex = 801
	bgImage.Parent = backdrop

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		bgImage.ImageColor3 = tk.Accent
	end))

	local logoFrame = Instance.new("Frame")
	logoFrame.Name = "Logo"
	logoFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	logoFrame.Position = UDim2.new(0.5, 0, 0.5, -20)
	logoFrame.Size = UDim2.new(0, 72, 0, 72)
	logoFrame.BackgroundColor3 = tokens.Accent
	logoFrame.BackgroundTransparency = 0.85
	logoFrame.BorderSizePixel = 0
	logoFrame.ZIndex = 802
	logoFrame.Parent = backdrop

	UIUtils.Corner(logoFrame, tokens.CornerLarge)
	UIUtils.Stroke(logoFrame, tokens.Accent, 1.5, 0.3)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		logoFrame.BackgroundColor3 = tk.Accent
	end))

	local logo = Instance.new("ImageLabel")
	logo.Name = "Icon"
	logo.Size = UDim2.new(0, 40, 0, 40)
	logo.Position = UDim2.new(0.5, 0, 0.5, 0)
	logo.AnchorPoint = Vector2.new(0.5, 0.5)
	logo.BackgroundTransparency = 1
	logo.Image = Icons.Assets.Background
	logo.ImageColor3 = tokens.Accent
	logo.ZIndex = 803
	logo.Parent = logoFrame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		logo.ImageColor3 = tk.Accent
	end))

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.AnchorPoint = Vector2.new(0.5, 0)
	titleLabel.Position = UDim2.new(0.5, 0, 0.5, 30)
	titleLabel.Size = UDim2.new(1, 0, 0, 32)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = tokens.FontBold
	titleLabel.Text = self.Title
	titleLabel.TextColor3 = tokens.Text
	titleLabel.TextSize = 28
	titleLabel.TextTransparency = 1
	titleLabel.ZIndex = 802
	titleLabel.Parent = backdrop

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		titleLabel.Font = tk.FontBold
		titleLabel.TextColor3 = tk.Text
	end))

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubTitle"
	subtitleLabel.AnchorPoint = Vector2.new(0.5, 0)
	subtitleLabel.Position = UDim2.new(0.5, 0, 0.5, 66)
	subtitleLabel.Size = UDim2.new(1, 0, 0, 18)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font = tokens.Font
	subtitleLabel.Text = self.SubTitle .. "  |  v" .. self.Version
	subtitleLabel.TextColor3 = tokens.SecondaryText
	subtitleLabel.TextSize = 14
	subtitleLabel.TextTransparency = 1
	subtitleLabel.ZIndex = 802
	subtitleLabel.Parent = backdrop

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		subtitleLabel.Font = tk.Font
		subtitleLabel.TextColor3 = tk.SecondaryText
	end))

	local scale = UIUtils.Scale(logoFrame, 0.5)

	Animator.Tween(scale, { Scale = 1 }, 0.5, "Back")
	Animator.Tween(logoFrame, { BackgroundTransparency = 0.85 }, 0.5, "Quart")

	task.delay(0.25, function()
		Animator.Tween(titleLabel, { TextTransparency = 0 }, 0.4, "Quart")
		Animator.Tween(subtitleLabel, { TextTransparency = 0 }, 0.4, "Quart")
	end)

	task.delay(self.Duration, function()
		Animator.Tween(titleLabel, { TextTransparency = 1 }, 0.3, "Quad")
		Animator.Tween(subtitleLabel, { TextTransparency = 1 }, 0.3, "Quad")
		Animator.Tween(logoFrame, { BackgroundTransparency = 1 }, 0.3, "Quad")
		Animator.Tween(bgImage, { ImageTransparency = 1 }, 0.3, "Quad")

		task.delay(0.35, function()
			backdrop:Destroy()
			Welcome.Shown = false
			self.OnFinished:Fire()
			self._maid:Destroy()
		end)
	end)

	return self
end

function Welcome:Destroy()
	if self._maid then
		self._maid:Destroy()
	end
	Welcome.Shown = false
end

return Welcome
