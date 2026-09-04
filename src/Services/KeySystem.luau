local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)
local Icons = require(script.Parent.Parent.Core.Icons)

local KeySystem = {}
KeySystem.__index = KeySystem

KeySystem.Shown = false

local function getRoot()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	if not ok or parent == nil then
		parent = PlayerGui
	end

	local existing = parent:FindFirstChild("NexusUI_KeySystem")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NexusUI_KeySystem"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 700
	screenGui.Parent = parent

	return screenGui
end

function KeySystem.new(options)
	options = options or {}

	local self = setmetatable({}, KeySystem)
	self.Title = options.Title or "Key Verification"
	self.SubTitle = options.SubTitle or "Enter your access key to continue"
	self.Icon = options.Icon or Icons.Assets.Settings
	self.Validate = options.Validate or function(key)
		return key == options.Key
	end
	self.OnValidated = options.OnValidated or function() end
	self.OnFailed = options.OnFailed or function() end
	self.MaxAttempts = options.MaxAttempts or 3
	self.SaveKey = options.SaveKey

	self.Attempts = 0
	self.OnAttempt = Signal.new()

	self._maid = Maid.new()

	self:Show()

	return self
end

function KeySystem:Show()
	local tokens = ThemeManager.GetTokens()

	local root = getRoot()

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = tokens.Background
	backdrop.BackgroundTransparency = 0
	backdrop.BorderSizePixel = 0
	backdrop.ZIndex = 700
	backdrop.Parent = root

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		backdrop.BackgroundColor3 = tk.Background
	end))

	local bgImage = Instance.new("ImageLabel")
	bgImage.Name = "BG"
	bgImage.Size = UDim2.new(1, 0, 1, 0)
	bgImage.BackgroundTransparency = 1
	bgImage.Image = Icons.Assets.Background
	bgImage.ImageColor3 = tokens.Accent
	bgImage.ImageTransparency = 0.92
	bgImage.ScaleType = Enum.ScaleType.Crop
	bgImage.ZIndex = 701
	bgImage.Parent = backdrop

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		bgImage.ImageColor3 = tk.Accent
	end))

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.Size = UDim2.new(0, 380, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = tokens.Surface
	card.BackgroundTransparency = 0.04
	card.BorderSizePixel = 0
	card.ZIndex = 702
	card.Parent = backdrop

	UIUtils.Corner(card, tokens.CornerLarge)
	UIUtils.Stroke(card, tokens.BorderLight, 1, 0.45)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		card.BackgroundColor3 = tk.Surface
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 22)
	padding.PaddingRight = UDim.new(0, 22)
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 20)
	padding.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 12)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = card

	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "IconFrame"
	iconFrame.Size = UDim2.new(0, 56, 0, 56)
	iconFrame.BackgroundColor3 = tokens.Accent
	iconFrame.BackgroundTransparency = 0.85
	iconFrame.BorderSizePixel = 0
	iconFrame.LayoutOrder = 1
	iconFrame.ZIndex = 703
	iconFrame.Parent = card

	UIUtils.Corner(iconFrame, tokens.CornerLarge)

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 30, 0, 30)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = self.Icon
	icon.ImageColor3 = tokens.Accent
	icon.ZIndex = 704
	icon.Parent = iconFrame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		icon.ImageColor3 = tk.Accent
	end))

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 22)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = tokens.FontBold
	titleLabel.Text = self.Title
	titleLabel.TextColor3 = tokens.Text
	titleLabel.TextSize = 18
	titleLabel.LayoutOrder = 2
	titleLabel.ZIndex = 703
	titleLabel.Parent = card

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		titleLabel.Font = tk.FontBold
		titleLabel.TextColor3 = tk.Text
	end))

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubTitle"
	subtitleLabel.Size = UDim2.new(1, 0, 0, 16)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font = tokens.Font
	subtitleLabel.Text = self.SubTitle
	subtitleLabel.TextColor3 = tokens.SecondaryText
	subtitleLabel.TextSize = 12
	subtitleLabel.LayoutOrder = 3
	subtitleLabel.ZIndex = 703
	subtitleLabel.Parent = card

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		subtitleLabel.Font = tk.Font
		subtitleLabel.TextColor3 = tk.SecondaryText
	end))

	local inputFrame = Instance.new("Frame")
	inputFrame.Name = "InputFrame"
	inputFrame.Size = UDim2.new(1, 0, 0, 40)
	inputFrame.BackgroundColor3 = tokens.Background
	inputFrame.BackgroundTransparency = 0.2
	inputFrame.BorderSizePixel = 0
	inputFrame.LayoutOrder = 4
	inputFrame.ZIndex = 703
	inputFrame.Parent = card

	UIUtils.Corner(inputFrame, tokens.CornerSmall)
	self.InputStroke = UIUtils.Stroke(inputFrame, tokens.Border, 1, 0.6)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		inputFrame.BackgroundColor3 = tk.Background
	end))

	self.Input = Instance.new("TextBox")
	self.Input.Name = "KeyInput"
	self.Input.Size = UDim2.new(1, -20, 1, 0)
	self.Input.Position = UDim2.new(0, 10, 0, 0)
	self.Input.BackgroundTransparency = 1
	self.Input.Font = tokens.Font
	self.Input.Text = ""
	self.Input.PlaceholderText = "Enter key..."
	self.Input.PlaceholderColor3 = tokens.MutedText
	self.Input.TextColor3 = tokens.Text
	self.Input.TextSize = 14
	self.Input.ClearTextOnFocus = false
	self.Input.ZIndex = 704
	self.Input.Parent = inputFrame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Input.Font = tk.Font
		self.Input.TextColor3 = tk.Text
		self.Input.PlaceholderColor3 = tk.MutedText
	end))

	self.SubmitButton = Instance.new("TextButton")
	self.SubmitButton.Name = "Submit"
	self.SubmitButton.Size = UDim2.new(1, 0, 0, 38)
	self.SubmitButton.BackgroundColor3 = tokens.Accent
	self.SubmitButton.BackgroundTransparency = 0
	self.SubmitButton.BorderSizePixel = 0
	self.SubmitButton.AutoButtonColor = false
	self.SubmitButton.Font = tokens.FontBold
	self.SubmitButton.Text = "Verify"
	self.SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	self.SubmitButton.TextSize = 14
	self.SubmitButton.LayoutOrder = 5
	self.SubmitButton.ZIndex = 703
	self.SubmitButton.Parent = card

	UIUtils.Corner(self.SubmitButton, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.SubmitButton.BackgroundColor3 = tk.Accent
		self.SubmitButton.Font = tk.FontBold
	end))

	self.StatusLabel = Instance.new("TextLabel")
	self.StatusLabel.Name = "Status"
	self.StatusLabel.Size = UDim2.new(1, 0, 0, 16)
	self.StatusLabel.BackgroundTransparency = 1
	self.StatusLabel.Font = tokens.Font
	self.StatusLabel.Text = ""
	self.StatusLabel.TextColor3 = tokens.Error
	self.StatusLabel.TextSize = 12
	self.StatusLabel.LayoutOrder = 6
	self.StatusLabel.ZIndex = 703
	self.StatusLabel.Parent = card

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.StatusLabel.Font = tk.Font
	end))

	local scale = UIUtils.Scale(card, 0.9)
	Animator.Tween(scale, { Scale = 1 }, 0.4, "Back")
	Animator.Tween(card, { BackgroundTransparency = 0.04 }, 0.3, "Quart")

	self.SubmitButton.MouseEnter:Connect(function()
		Animator.Tween(self.SubmitButton, { BackgroundTransparency = 0.15 }, 0.15, "Quad")
	end)

	self.SubmitButton.MouseLeave:Connect(function()
		Animator.Tween(self.SubmitButton, { BackgroundTransparency = 0 }, 0.15, "Quad")
	end)

	local selfRef = self

	self.SubmitButton.MouseButton1Click:Connect(function()
		selfRef:_submit()
	end)

	self.Input.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			selfRef:_submit()
		end
	end)

	self.Input.Focused:Connect(function()
		Animator.Tween(self.InputStroke, { Color = ThemeManager.GetTokens().Accent, Transparency = 0.1 }, 0.18, "Quad")
	end)

	self.Card = card
	self.Backdrop = backdrop
	self.RootGui = root

	return self
end

function KeySystem:_submit()
	local key = self.Input.Text

	if key == "" then
		self.StatusLabel.Text = "Please enter a key"
		self.StatusLabel.TextColor3 = ThemeManager.GetTokens().Warning
		Sound.Error()
		return
	end

	self.Attempts = self.Attempts + 1
	self.OnAttempt:Fire(self.Attempts, self.MaxAttempts)

	local tokens = ThemeManager.GetTokens()
	self.SubmitButton.Text = "Verifying..."
	self.SubmitButton.BackgroundTransparency = 0.3

	task.wait(0.4)

	local success, result = pcall(self.Validate, key)

	self.SubmitButton.Text = "Verify"
	self.SubmitButton.BackgroundTransparency = 0

	if success and result then
		self.StatusLabel.Text = "Key verified!"
		self.StatusLabel.TextColor3 = tokens.Success
		Sound.Success()

		Animator.Tween(self.Card, { BackgroundTransparency = 0.6 }, 0.3, "Quad")
		task.delay(0.4, function()
			self:_close()
			pcall(self.OnValidated)
		end)
	else
		local remaining = self.MaxAttempts - self.Attempts
		self.StatusLabel.Text = remaining > 0 and ("Invalid key. Attempts remaining: " .. remaining) or "Too many attempts"
		self.StatusLabel.TextColor3 = tokens.Error
		Sound.Error()

		Animator.Tween(self.Card, { Position = self.Card.Position + UDim2.new(0, 8, 0, 0) }, 0.05, "Quad")
		task.delay(0.05, function()
			Animator.Tween(self.Card, { Position = self.Card.Position - UDim2.new(0, 16, 0, 0) }, 0.05, "Quad")
			task.delay(0.05, function()
				Animator.Tween(self.Card, { Position = self.Card.Position + UDim2.new(0, 8, 0, 0) }, 0.15, "Quad")
			end)
		end)

		if remaining <= 0 then
			task.delay(0.6, function()
				self:_close()
				pcall(self.OnFailed)
			end)
		end
	end
end

function KeySystem:_close()
	if self.Backdrop then
		Animator.Tween(self.Card, { BackgroundTransparency = 1 }, 0.25, "Quad")
		task.delay(0.3, function()
			if self.RootGui then
				self.RootGui:Destroy()
			end
			self._maid:Destroy()
			KeySystem.Shown = false
		end)
	end
end

function KeySystem:Destroy()
	if self.RootGui then
		self.RootGui:Destroy()
	end
	if self._maid then
		self._maid:Destroy()
	end
	KeySystem.Shown = false
end

return KeySystem
