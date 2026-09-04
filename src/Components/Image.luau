local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Icons = require(script.Parent.Parent.Core.Icons)

local Image = {}
Image.__index = Image
setmetatable(Image, { __index = BaseComponent })

function Image.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Image")
	setmetatable(self, { __index = function(t, k)
		if Image[k] then
			return Image[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Image"
	self.ImageId = options.Image or options.ImageId or Icons.Assets.Background
	self.Caption = options.Caption or ""
	self.Clickable = options.Clickable or false
	self.Callback = options.Callback or function() end
	self.ScaleType = options.ScaleType or Enum.ScaleType.Crop
	self.CornerRadius = options.CornerRadius

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

function Image:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Image_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, self.Caption ~= "" and 140 or 120)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Frame = Instance.new("Frame")
	self.Frame.Name = "Holder"
	self.Frame.Size = UDim2.new(1, 0, 1, self.Caption ~= "" and -22 or 0)
	self.Frame.BackgroundColor3 = tokens.Background
	self.Frame.BackgroundTransparency = 0.3
	self.Frame.BorderSizePixel = 0
	self.Frame.ClipsDescendants = true
	self.Frame.ZIndex = 7
	self.Frame.Parent = self.Container

	UIUtils.Corner(self.Frame, self.CornerRadius or tokens.Corner)
	UIUtils.Stroke(self.Frame, tokens.Border, 1, 0.7)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Frame.BackgroundColor3 = tk.Background
	end))

	self.ImageLabel = Instance.new("ImageLabel")
	self.ImageLabel.Name = "Image"
	self.ImageLabel.Size = UDim2.new(1, 0, 1, 0)
	self.ImageLabel.BackgroundTransparency = 1
	self.ImageLabel.Image = self.ImageId
	self.ImageLabel.ScaleType = self.ScaleType
	self.ImageLabel.ZIndex = 8
	self.ImageLabel.Parent = self.Frame

	if self.Caption ~= "" then
		self.CaptionLabel = Instance.new("TextLabel")
		self.CaptionLabel.Name = "Caption"
		self.CaptionLabel.Position = UDim2.new(0, 0, 1, -20)
		self.CaptionLabel.Size = UDim2.new(1, 0, 0, 18)
		self.CaptionLabel.BackgroundTransparency = 1
		self.CaptionLabel.Font = tokens.Font
		self.CaptionLabel.Text = self.Caption
		self.CaptionLabel.TextColor3 = tokens.SecondaryText
		self.CaptionLabel.TextSize = 11
		self.CaptionLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.CaptionLabel.TextTruncate = Enum.TextTruncate.AtEnd
		self.CaptionLabel.ZIndex = 7
		self.CaptionLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.CaptionLabel.Font = tk.Font
			self.CaptionLabel.TextColor3 = tk.SecondaryText
		end))
	end

	if self.Clickable then
		local clickButton = Instance.new("TextButton")
		clickButton.Name = "ClickTarget"
		clickButton.Size = UDim2.new(1, 0, 1, 0)
		clickButton.BackgroundTransparency = 1
		clickButton.Text = ""
		clickButton.ZIndex = 10
		clickButton.Parent = self.Frame

		clickButton.MouseButton1Click:Connect(function()
			self.OnClick:Fire()
			pcall(self.Callback)
		end)

		clickButton.MouseEnter:Connect(function()
			Animator.Tween(self.ImageLabel, { ImageTransparency = 0.15 }, 0.18, "Quad")
		end)

		clickButton.MouseLeave:Connect(function()
			Animator.Tween(self.ImageLabel, { ImageTransparency = 0 }, 0.22, "Quad")
		end)
	end
end

function Image:SetImage(imageId)
	self.ImageId = imageId
	self.ImageLabel.Image = imageId
	return self
end

function Image:SetCaption(caption)
	self.Caption = caption
	if self.CaptionLabel then
		self.CaptionLabel.Text = caption
	end
	return self
end

function Image:SetScaleType(scaleType)
	self.ScaleType = scaleType
	self.ImageLabel.ScaleType = scaleType
	return self
end

function Image:Destroy()
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

return Image
