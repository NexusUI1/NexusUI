local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local Card = {}
Card.__index = Card
setmetatable(Card, { __index = BaseComponent })

function Card.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Card")
	setmetatable(self, { __index = function(t, k)
		if Card[k] then
			return Card[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Card"
	self.Title = options.Title or ""
	self.Description = options.Description or ""
	self.Image = options.Image
	self.Clickable = options.Clickable or false
	self.Callback = options.Callback or function() end
	self.Layout = options.Layout or "Vertical"

	self.OnClick = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Click = self.OnClick,
	}

	self:_build(parent)

	return self
end

function Card:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Card_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, 0)
	self.Container.AutomaticSize = Enum.AutomaticSize.Y
	self.Container.BackgroundColor3 = tokens.Surface
	self.Container.BackgroundTransparency = 0.2
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	UIUtils.Corner(self.Container, tokens.Corner)
	UIUtils.Stroke(self.Container, tokens.Border, 1, 0.7)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Container.BackgroundColor3 = tk.Surface
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = self.Container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Container

	if self.Image then
		local imageHolder = Instance.new("Frame")
		imageHolder.Name = "ImageHolder"
		imageHolder.Size = UDim2.new(1, 0, 0, 100)
		imageHolder.BackgroundColor3 = tokens.Background
		imageHolder.BackgroundTransparency = 0.4
		imageHolder.BorderSizePixel = 0
		imageHolder.ClipsDescendants = true
		imageHolder.LayoutOrder = 1
		imageHolder.ZIndex = 7
		imageHolder.Parent = self.Container

		UIUtils.Corner(imageHolder, tokens.CornerSmall)

		local image = Instance.new("ImageLabel")
		image.Name = "Image"
		image.Size = UDim2.new(1, 0, 1, 0)
		image.BackgroundTransparency = 1
		image.Image = self.Image
		image.ScaleType = Enum.ScaleType.Crop
		image.ZIndex = 8
		image.Parent = imageHolder

		self._image = image
	end

	if self.Title ~= "" then
		self.TitleLabel = Instance.new("TextLabel")
		self.TitleLabel.Name = "Title"
		self.TitleLabel.Size = UDim2.new(1, 0, 0, 18)
		self.TitleLabel.BackgroundTransparency = 1
		self.TitleLabel.Font = tokens.FontBold
		self.TitleLabel.Text = self.Title
		self.TitleLabel.TextColor3 = tokens.Text
		self.TitleLabel.TextSize = 14
		self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.TitleLabel.LayoutOrder = 2
		self.TitleLabel.ZIndex = 7
		self.TitleLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.TitleLabel.Font = tk.FontBold
			self.TitleLabel.TextColor3 = tk.Text
		end))
	end

	if self.Description ~= "" then
		self.DescLabel = Instance.new("TextLabel")
		self.DescLabel.Name = "Description"
		self.DescLabel.Size = UDim2.new(1, 0, 0, 0)
		self.DescLabel.AutomaticSize = Enum.AutomaticSize.Y
		self.DescLabel.BackgroundTransparency = 1
		self.DescLabel.Font = tokens.Font
		self.DescLabel.Text = self.Description
		self.DescLabel.TextColor3 = tokens.SecondaryText
		self.DescLabel.TextSize = 12
		self.DescLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.DescLabel.TextWrapped = true
		self.DescLabel.LayoutOrder = 3
		self.DescLabel.ZIndex = 7
		self.DescLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.DescLabel.Font = tk.Font
			self.DescLabel.TextColor3 = tk.SecondaryText
		end))
	end

	if self.Clickable then
		local clickButton = Instance.new("TextButton")
		clickButton.Name = "ClickTarget"
		clickButton.Size = UDim2.new(1, 0, 1, 0)
		clickButton.BackgroundTransparency = 1
		clickButton.Text = ""
		clickButton.ZIndex = 10
		clickButton.Parent = self.Container

		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = self.Container

		clickButton.MouseEnter:Connect(function()
			Animator.Tween(scale, { Scale = 1.015 }, 0.18, "Quad")
			Animator.Tween(self.Container, { BackgroundTransparency = 0.05 }, 0.18, "Quad")
			Sound.Hover()
		end)

		clickButton.MouseLeave:Connect(function()
			Animator.Tween(scale, { Scale = 1 }, 0.22, "Quad")
			Animator.Tween(self.Container, { BackgroundTransparency = 0.2 }, 0.22, "Quad")
		end)

		clickButton.MouseButton1Click:Connect(function()
			Animator.Tween(scale, { Scale = 0.985 }, 0.08, "Quad")
			task.delay(0.08, function()
				Animator.Tween(scale, { Scale = 1 }, 0.25, "Back")
			end)

			Sound.Click()
			self.OnClick:Fire()
			pcall(self.Callback)
		end)
	end
end

function Card:SetTitle(title)
	self.Title = title
	if self.TitleLabel then
		self.TitleLabel.Text = title
	end
	return self
end

function Card:SetDescription(description)
	self.Description = description
	if self.DescLabel then
		self.DescLabel.Text = description
	end
	return self
end

function Card:SetImage(imageId)
	self.Image = imageId

	if imageId then
		if not self._image then
			local imageHolder = Instance.new("Frame")
			imageHolder.Name = "ImageHolder"
			imageHolder.Size = UDim2.new(1, 0, 0, 100)
			imageHolder.BackgroundColor3 = ThemeManager.GetTokens().Background
			imageHolder.BackgroundTransparency = 0.4
			imageHolder.BorderSizePixel = 0
			imageHolder.ClipsDescendants = true
			imageHolder.LayoutOrder = 1
			imageHolder.ZIndex = 7
			imageHolder.Parent = self.Container

			UIUtils.Corner(imageHolder, ThemeManager.GetTokens().CornerSmall)

			self._image = Instance.new("ImageLabel")
			self._image.Name = "Image"
			self._image.Size = UDim2.new(1, 0, 1, 0)
			self._image.BackgroundTransparency = 1
			self._image.ScaleType = Enum.ScaleType.Crop
			self._image.ZIndex = 8
			self._image.Parent = imageHolder
		end
		self._image.Image = imageId
	elseif self._image then
		self._image.Parent:Destroy()
		self._image = nil
	end

	return self
end

function Card:Destroy()
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

return Card
