local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Icons = require(script.Parent.Parent.Core.Icons)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local Tab = {}
Tab.__index = Tab
setmetatable(Tab, { __index = BaseComponent })

function Tab.new(options, window)
	options = options or {}

	local self = BaseComponent.new("Tab")
	setmetatable(self, { __index = function(t, k)
		if Tab[k] then
			return Tab[k]
		end
		return BaseComponent[k]
	end })

	self.Window = window
	self.Name = options.Name or "Tab"
	self.Icon = options.Icon
	self.Description = options.Description or ""
	self.Compact = false

	self.Sections = {}

	self.OnSelected = Signal.new()
	self.OnDeselected = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Selected = self.OnSelected,
		Deselected = self.OnDeselected,
	}

	self:_build()

	return self
end

function Tab:_build()
	local tokens = ThemeManager.GetTokens()

	self.Button = Instance.new("TextButton")
	self.Button.Name = "Tab_" .. self.Name
	self.Button.Size = UDim2.new(1, 0, 0, 36)
	self.Button.BackgroundColor3 = tokens.SurfaceLight
	self.Button.BackgroundTransparency = 1
	self.Button.BorderSizePixel = 0
	self.Button.AutoButtonColor = false
	self.Button.Text = ""
	self.Button.ZIndex = 6
	self.Button.Parent = self.Window.TabScroll

	UIUtils.Corner(self.Button, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Button.BackgroundColor3 = tk.SurfaceLight
	end))

	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0, 3, 0, 0)
	accentBar.Position = UDim2.new(0, 0, 0.5, 0)
	accentBar.AnchorPoint = Vector2.new(0, 0.5)
	accentBar.BackgroundColor3 = tokens.Accent
	accentBar.BackgroundTransparency = 0.15
	accentBar.BorderSizePixel = 0
	accentBar.ZIndex = 7
	accentBar.Parent = self.Button

	self._accentBar = accentBar

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		accentBar.BackgroundColor3 = tk.Accent
	end))

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, 0)
	content.Position = UDim2.new(0, 10, 0, 0)
	content.BackgroundTransparency = 1
	content.ZIndex = 7
	content.Parent = self.Button

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Horizontal
	contentLayout.Padding = UDim.new(0, 8)
	contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = content

	if self.Icon then
		self.IconImage = Instance.new("ImageLabel")
		self.IconImage.Name = "Icon"
		self.IconImage.BackgroundTransparency = 1
		self.IconImage.Image = self.Icon
		self.IconImage.Size = UDim2.new(0, 18, 0, 18)
		self.IconImage.ImageColor3 = tokens.SecondaryText
		self.IconImage.ScaleType = Enum.ScaleType.Fit
		self.IconImage.LayoutOrder = 1
		self.IconImage.ZIndex = 8
		self.IconImage.Parent = content

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.IconImage.ImageColor3 = self.Selected and tk.Accent or tk.SecondaryText
		end))
	end

	self.Label = Instance.new("TextLabel")
	self.Label.Name = "Label"
	self.Label.BackgroundTransparency = 1
	self.Label.Size = UDim2.new(1, 0, 1, 0)
	self.Label.Font = tokens.Font
	self.Label.Text = self.Name
	self.Label.TextColor3 = tokens.SecondaryText
	self.Label.TextSize = tokens.TextSize
	self.Label.TextXAlignment = Enum.TextXAlignment.Left
	self.Label.TextTruncate = Enum.TextTruncate.AtEnd
	self.Label.LayoutOrder = 2
	self.Label.ZIndex = 8
	self.Label.Parent = content

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Label.Font = tk.Font
		self.Label.TextSize = tk.TextSize
		self.Label.TextColor3 = self.Selected and tk.Text or tk.SecondaryText
	end))

	local badge = options.Badge
	if badge then
		local badgeFrame = Instance.new("Frame")
		badgeFrame.Name = "Badge"
		badgeFrame.Size = UDim2.new(0, 18, 0, 18)
		badgeFrame.BackgroundColor3 = tokens.Accent
		badgeFrame.BorderSizePixel = 0
		badgeFrame.LayoutOrder = 3
		badgeFrame.ZIndex = 8
		badgeFrame.Parent = content

		UIUtils.Corner(badgeFrame, tokens.CornerCircle)

		local badgeText = Instance.new("TextLabel")
		badgeText.Name = "Text"
		badgeText.Size = UDim2.new(1, 0, 1, 0)
		badgeText.BackgroundTransparency = 1
		badgeText.Font = tokens.FontBold
		badgeText.Text = tostring(badge)
		badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
		badgeText.TextSize = 10
		badgeText.ZIndex = 9
		badgeText.Parent = badgeFrame
	end

	local pageContainer = Instance.new("Frame")
	pageContainer.Name = "Page_" .. self.Name
	pageContainer.Size = UDim2.new(1, 0, 1, 0)
	pageContainer.BackgroundTransparency = 1
	pageContainer.BorderSizePixel = 0
	pageContainer.ZIndex = 4
	pageContainer.Visible = false
	pageContainer.Parent = self.Window.Content

	self.Page = pageContainer

	self.Scroll = Instance.new("ScrollingFrame")
	self.Scroll.Name = "Scroll"
	self.Scroll.Size = UDim2.new(1, -8, 1, -8)
	self.Scroll.Position = UDim2.new(0, 4, 0, 4)
	self.Scroll.BackgroundTransparency = 1
	self.Scroll.BorderSizePixel = 0
	self.Scroll.ScrollBarThickness = 3
	self.Scroll.ScrollBarImageColor3 = tokens.ScrollBars or tokens.Accent
	self.Scroll.ScrollBarImageTransparency = 0.35
	self.Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.Scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	self.Scroll.ZIndex = 4
	self.Scroll.Parent = pageContainer

	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingLeft = UDim.new(0, 6)
	scrollPadding.PaddingRight = UDim.new(0, 10)
	scrollPadding.PaddingTop = UDim.new(0, 6)
	scrollPadding.PaddingBottom = UDim.new(0, 6)
	scrollPadding.Parent = self.Scroll

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.FillDirection = Enum.FillDirection.Vertical
	scrollLayout.Padding = UDim.new(0, 10)
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Parent = self.Scroll

	self.Button.MouseEnter:Connect(function()
		if not self.Selected then
			Animator.Tween(self.Button, { BackgroundTransparency = 0.7 }, 0.15, "Quad")
			Animator.Tween(self.Label, { TextColor3 = ThemeManager.GetTokens().Text }, 0.15, "Quad")
		end
		Sound.Hover()
	end)

	self.Button.MouseLeave:Connect(function()
		if not self.Selected then
			Animator.Tween(self.Button, { BackgroundTransparency = 1 }, 0.15, "Quad")
			Animator.Tween(self.Label, { TextColor3 = ThemeManager.GetTokens().SecondaryText }, 0.15, "Quad")
		end
	end)

	self.Button.MouseButton1Click:Connect(function()
		self.Window:SelectTab(self)
	end)

	self:_applyCompact(self.Compact)
end

function Tab:_applyCompact(compact)
	self.Compact = compact

	if compact then
		self.Button.Size = UDim2.new(1, 0, 0, 40)
		self.Label.Visible = false
		self._accentBar.Size = UDim2.new(0, 0, 0, 0)
		if self.IconImage then
			self.IconImage.Size = UDim2.new(0, 22, 0, 22)
			self.IconImage.Position = UDim2.new(0.5, -11, 0.5, -11)
		end
		contentFix(self.Button, compact)
	else
		self.Button.Size = UDim2.new(1, 0, 0, 36)
		self.Label.Visible = true
		if self.IconImage then
			self.IconImage.Size = UDim2.new(0, 18, 0, 18)
			self.IconImage.Position = UDim2.new(0, 0, 0, 0)
		end
		contentFix(self.Button, compact)
	end
end

function contentFix(button, compact)
	local content = button:FindFirstChild("Content")
	if not content then
		return
	end
	local layout = content:FindFirstChildOfClass("UIListLayout")
	if not layout then
		return
	end

	if compact then
		content.Size = UDim2.new(1, 0, 1, 0)
		content.Position = UDim2.new(0, 0, 0, 0)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	else
		content.Size = UDim2.new(1, -20, 1, 0)
		content.Position = UDim2.new(0, 10, 0, 0)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	end
end

function Tab:SetCompact(compact)
	self:_applyCompact(compact)
	return self
end

function Tab:SetSelected(selected)
	self.Selected = selected
	local tokens = ThemeManager.GetTokens()

	if selected then
		Animator.Tween(self.Button, { BackgroundTransparency = 0.82 }, 0.2, "Quad")
		Animator.Tween(self.Label, { TextColor3 = tokens.Text }, 0.2, "Quad")
		Animator.Tween(self._accentBar, { Size = UDim2.new(0, 3, 0, 20) }, 0.25, "Back")

		if self.IconImage then
			Animator.Tween(self.IconImage, { ImageColor3 = tokens.Accent }, 0.2, "Quad")
		end

		self.OnSelected:Fire(self)
	else
		Animator.Tween(self.Button, { BackgroundTransparency = 1 }, 0.2, "Quad")
		Animator.Tween(self.Label, { TextColor3 = tokens.SecondaryText }, 0.2, "Quad")
		Animator.Tween(self._accentBar, { Size = UDim2.new(0, 3, 0, 0) }, 0.2, "Quad")

		if self.IconImage then
			Animator.Tween(self.IconImage, { ImageColor3 = tokens.SecondaryText }, 0.2, "Quad")
		end

		self.OnDeselected:Fire(self)
	end

	return self
end

function Tab:PlayOpenAnimation()
	local children = {}
	for _, child in ipairs(self.Scroll:GetChildren()) do
		if child:IsA("GuiObject") then
			table.insert(children, child)
		end
	end

	for i, child in ipairs(children) do
		local originalPos = child.Position
		child.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset + 14)
		child.GroupTransparency = child.GroupTransparency

		task.delay((i - 1) * 0.03, function()
			Animator.Tween(child, { Position = originalPos }, 0.3, "Quart")
		end)
	end
end

function Tab:AddSection(options)
	options = options or {}

	local Section = require(script.Parent.Section)
	local section = Section.new(options, self)

	table.insert(self.Sections, section)
	return section
end

function Tab:SetName(name)
	self.Name = name
	self.Label.Text = name
	self.Button.Name = "Tab_" .. name
	return self
end

function Tab:SetIcon(icon)
	self.Icon = icon

	if icon then
		if not self.IconImage then
			self.IconImage = Instance.new("ImageLabel")
			self.IconImage.Name = "Icon"
			self.IconImage.BackgroundTransparency = 1
			self.IconImage.Size = UDim2.new(0, 18, 0, 18)
			self.IconImage.ImageColor3 = self.Selected and ThemeManager.GetTokens().Accent or ThemeManager.GetTokens().SecondaryText
			self.IconImage.ScaleType = Enum.ScaleType.Fit
			self.IconImage.LayoutOrder = 1
			self.IconImage.ZIndex = 8
			self.IconImage.Parent = self.Button:FindFirstChild("Content")
		end
		self.IconImage.Image = icon
	else
		if self.IconImage then
			self.IconImage:Destroy()
			self.IconImage = nil
		end
	end

	return self
end

function Tab:SetBadge(count)
	local badge = self.Button:FindFirstChild("Content") and self.Button.Content:FindFirstChild("Badge")

	if count == nil then
		if badge then
			badge:Destroy()
		end
		return self
	end

	if badge then
		badge.Text.Text = tostring(count)
	else
		local content = self.Button:FindFirstChild("Content")
		local tokens = ThemeManager.GetTokens()

		local badgeFrame = Instance.new("Frame")
		badgeFrame.Name = "Badge"
		badgeFrame.Size = UDim2.new(0, 18, 0, 18)
		badgeFrame.BackgroundColor3 = tokens.Accent
		badgeFrame.BorderSizePixel = 0
		badgeFrame.LayoutOrder = 3
		badgeFrame.ZIndex = 8
		badgeFrame.Parent = content

		UIUtils.Corner(badgeFrame, tokens.CornerCircle)

		local badgeText = Instance.new("TextLabel")
		badgeText.Name = "Text"
		badgeText.Size = UDim2.new(1, 0, 1, 0)
		badgeText.BackgroundTransparency = 1
		badgeText.Font = tokens.FontBold
		badgeText.Text = tostring(count)
		badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
		badgeText.TextSize = 10
		badgeText.ZIndex = 9
		badgeText.Parent = badgeFrame
	end

	return self
end

function Tab:Destroy()
	if self.Destroyed then
		return
	end

	for _, section in ipairs(self.Sections) do
		pcall(function() section:Destroy() end)
	end
	self.Sections = {}

	if self.Button then
		self.Button:Destroy()
	end
	if self.Page then
		self.Page:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return Tab
