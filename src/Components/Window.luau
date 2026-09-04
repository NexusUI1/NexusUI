local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Device = require(script.Parent.Parent.Core.Device)
local Icons = require(script.Parent.Parent.Core.Icons)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local Window = {}
Window.__index = Window
setmetatable(Window, { __index = BaseComponent })

Window.ActiveWindows = {}

local CoreGui = game:GetService("CoreGui")
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local function getParent()
	local ok = pcall(function()
		local test = CoreGui:GetChildren()
		return test
	end)
	if ok then
		return CoreGui
	end
	return PlayerGui
end

function Window.new(options)
	options = options or {}

	local self = BaseComponent.new("Window")
	setmetatable(self, { __index = function(t, k)
		if Window[k] then
			return Window[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "NexusUI"
	self.Title = options.Title or options.Name or "Nexus"
	self.SubTitle = options.SubTitle or ""
	self.Size = options.Size or UDim2.fromOffset(880, 560)
	self.Position = options.Position or UDim2.new(0.5, 0, 0.5, 0)
	self.Closable = options.Closable ~= false
	self.Resizable = options.Resizable ~= false
	self.Draggable = options.Draggable ~= false
	self.ShowOnCreate = options.ShowOnCreate ~= false
	self.MobileMode = options.MobileMode or false
	self.ImageBackground = options.Background ~= false
	self.BackgroundId = options.BackgroundId or Icons.Assets.Background
	self.ToggleKeybind = options.ToggleKeybind or Enum.KeyCode.RightShift

	self.Tabs = {}
	self.ActiveTab = nil
	self.Opened = false

	self.OnOpened = Signal.new()
	self.OnClosed = Signal.new()
	self.OnTabChanged = Signal.new()
	self.OnThemeChanged = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = self.OnClosed,
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Opened = self.OnOpened,
		Closed = self.OnClosed,
		TabChanged = self.OnTabChanged,
	}

	self._build()

	if self.ShowOnCreate then
		self:Open()
	end

	Window.ActiveWindows[self] = true

	return self
end

function Window:_build()
	local tokens = ThemeManager.GetTokens()
	local parent = getParent()

	self.Root = Instance.new("ScreenGui")
	self.Root.Name = self.Name .. "_NexusUI"
	self.Root.ResetOnSpawn = false
	self.Root.IgnoreGuiInset = true
	self.Root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.Root.DisplayOrder = 100
	self.Root.Enabled = false
	self.Root.Parent = parent

	self.Overlay = Instance.new("Frame")
	self.Overlay.Name = "Overlay"
	self.Overlay.Size = UDim2.new(1, 0, 1, 0)
	self.Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.Overlay.BackgroundTransparency = 1
	self.Overlay.BorderSizePixel = 0
	self.Overlay.ZIndex = 1
	self.Overlay.Parent = self.Root

	self.Container = Instance.new("Frame")
	self.Container.Name = "Window"
	self.Container.Size = self.Size
	self.Container.Position = self.Position
	self.Container.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Container.BackgroundColor3 = tokens.Background
	self.Container.BackgroundTransparency = tokens.WindowTransparency
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 2
	self.Container.ClipsDescendants = true
	self.Container.Parent = self.Overlay

	UIUtils.Corner(self.Container, tokens.CornerLarge)
	UIUtils.Stroke(self.Container, tokens.BorderLight, 1, 0.5)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Container.BackgroundColor3 = tk.Background
		self.Container.BackgroundTransparency = tk.WindowTransparency
	end))

	if self.ImageBackground then
		self.Background = Instance.new("ImageLabel")
		self.Background.Name = "Background"
		self.Background.Image = self.BackgroundId
		self.Background.Size = UDim2.new(1, 0, 1, 0)
		self.Background.Position = UDim2.new(0, 0, 0, 0)
		self.Background.BackgroundTransparency = 1
		self.Background.ImageTransparency = 0.88
		self.Background.ImageColor3 = tokens.Accent
		self.Background.ScaleType = Enum.ScaleType.Crop
		self.Background.ZIndex = 3
		self.Background.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.Background.ImageColor3 = tk.Accent
		end))
	end

	self:_buildTopbar()
	self:_buildSidebar()
	self:_buildContent()
	self:_buildDrag()
	self:_buildResize()
	self:_buildKeybind()

	Device.Changed:Connect(function()
		self:_applyResponsive()
	end)
end

function Window:_buildTopbar()
	local tokens = ThemeManager.GetTokens()

	self.Topbar = Instance.new("Frame")
	self.Topbar.Name = "Topbar"
	self.Topbar.Size = UDim2.new(1, 0, 0, 46)
	self.Topbar.BackgroundColor3 = tokens.Surface
	self.Topbar.BackgroundTransparency = 0.35
	self.Topbar.BorderSizePixel = 0
	self.Topbar.ZIndex = 5
	self.Topbar.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Topbar.BackgroundColor3 = tk.Surface
	end))

	local bottomLine = Instance.new("Frame")
	bottomLine.Name = "BottomLine"
	bottomLine.Size = UDim2.new(1, 0, 0, 1)
	bottomLine.Position = UDim2.new(0, 0, 1, -1)
	bottomLine.BackgroundColor3 = tokens.Border
	bottomLine.BackgroundTransparency = 0.4
	bottomLine.BorderSizePixel = 0
	bottomLine.ZIndex = 5
	bottomLine.Parent = self.Topbar

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		bottomLine.BackgroundColor3 = tk.Border
	end))

	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "IconFrame"
	iconFrame.Size = UDim2.new(0, 30, 0, 30)
	iconFrame.Position = UDim2.new(0, 10, 0.5, 0)
	iconFrame.AnchorPoint = Vector2.new(0, 0.5)
	iconFrame.BackgroundColor3 = tokens.Accent
	iconFrame.BackgroundTransparency = 0.88
	iconFrame.BorderSizePixel = 0
	iconFrame.ZIndex = 6
	iconFrame.Parent = self.Topbar

	UIUtils.Corner(iconFrame, tokens.CornerSmall)

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Image = Icons.Assets.Background
	icon.Size = UDim2.new(0, 18, 0, 18)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.ImageColor3 = tokens.Accent
	icon.ZIndex = 7
	icon.Parent = iconFrame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		icon.ImageColor3 = tk.Accent
	end))

	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Name = "Title"
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.Position = UDim2.new(0, 50, 0, 0)
	self.TitleLabel.Size = UDim2.new(0.5, -60, 1, 0)
	self.TitleLabel.Font = tokens.FontBold
	self.TitleLabel.Text = self.Title
	self.TitleLabel.TextColor3 = tokens.Text
	self.TitleLabel.TextSize = tokens.TitleSize
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	self.TitleLabel.ZIndex = 6
	self.TitleLabel.Parent = self.Topbar

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TitleLabel.Font = tk.FontBold
		self.TitleLabel.TextColor3 = tk.Text
		self.TitleLabel.TextSize = tk.TitleSize
	end))

	if self.SubTitle ~= "" then
		self.SubTitleLabel = Instance.new("TextLabel")
		self.SubTitleLabel.Name = "SubTitle"
		self.SubTitleLabel.BackgroundTransparency = 1
		self.SubTitleLabel.Position = UDim2.new(0, 52, 0, 24)
		self.SubTitleLabel.Size = UDim2.new(0.4, -60, 0, 14)
		self.SubTitleLabel.Font = tokens.Font
		self.SubTitleLabel.Text = self.SubTitle
		self.SubTitleLabel.TextColor3 = tokens.SecondaryText
		self.SubTitleLabel.TextSize = 11
		self.SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.SubTitleLabel.ZIndex = 6
		self.SubTitleLabel.Parent = self.Topbar

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.SubTitleLabel.TextColor3 = tk.SecondaryText
		end))
	end

	self.ButtonRow = Instance.new("Frame")
	self.ButtonRow.Name = "ButtonRow"
	self.ButtonRow.AnchorPoint = Vector2.new(1, 0.5)
	self.ButtonRow.Position = UDim2.new(1, -10, 0.5, 0)
	self.ButtonRow.Size = UDim2.new(0, 0, 0, 28)
	self.ButtonRow.BackgroundTransparency = 1
	self.ButtonRow.ZIndex = 6
	self.ButtonRow.Parent = self.Topbar

	local buttonList = UIUtils.ListLayout(self.ButtonRow, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right)

	if self.Closable then
		self.CloseButton = self:_createTopbarButton("Close", "X", function()
			self:Close()
		end)
	end
end

function Window:_createTopbarButton(name, glyph, callback)
	local tokens = ThemeManager.GetTokens()

	local button = Instance.new("TextButton")
	button.Name = name .. "Button"
	button.Size = UDim2.new(0, 28, 0, 28)
	button.BackgroundColor3 = tokens.SurfaceLight
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Font = tokens.FontBold
	button.Text = glyph
	button.TextColor3 = tokens.SecondaryText
	button.TextSize = 14
	button.AutoButtonColor = false
	button.ZIndex = 7
	button.LayoutOrder = 1
	button.Parent = self.ButtonRow

	UIUtils.Corner(button, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		button.BackgroundColor3 = tk.SurfaceLight
		button.TextColor3 = tk.SecondaryText
	end))

	button.MouseEnter:Connect(function()
		Animator.Tween(button, { BackgroundTransparency = 0.5, TextColor3 = ThemeManager.GetTokens().Text }, 0.15, "Quad")
		Sound.Hover()
	end)

	button.MouseLeave:Connect(function()
		Animator.Tween(button, { BackgroundTransparency = 1, TextColor3 = ThemeManager.GetTokens().SecondaryText }, 0.15, "Quad")
	end)

	button.MouseButton1Click:Connect(function()
		Sound.Click()
		callback()
	end)

	return button
end

function Window:_buildSidebar()
	local tokens = ThemeManager.GetTokens()

	self.Sidebar = Instance.new("Frame")
	self.Sidebar.Name = "Sidebar"
	self.Sidebar.Size = UDim2.new(0, 190, 1, -46)
	self.Sidebar.Position = UDim2.new(0, 0, 0, 46)
	self.Sidebar.BackgroundColor3 = tokens.Surface
	self.Sidebar.BackgroundTransparency = 0.5
	self.Sidebar.BorderSizePixel = 0
	self.Sidebar.ZIndex = 4
	self.Sidebar.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Sidebar.BackgroundColor3 = tk.Surface
	end))

	local sidebarLine = Instance.new("Frame")
	sidebarLine.Name = "Line"
	sidebarLine.Size = UDim2.new(0, 1, 1, 0)
	sidebarLine.Position = UDim2.new(1, -1, 0, 0)
	sidebarLine.BackgroundColor3 = tokens.Border
	sidebarLine.BackgroundTransparency = 0.5
	sidebarLine.BorderSizePixel = 0
	sidebarLine.ZIndex = 5
	sidebarLine.Parent = self.Sidebar

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		sidebarLine.BackgroundColor3 = tk.Border
	end))

	self.TabScroll = Instance.new("ScrollingFrame")
	self.TabScroll.Name = "TabScroll"
	self.TabScroll.Size = UDim2.new(1, 0, 1, -20)
	self.TabScroll.Position = UDim2.new(0, 0, 0, 10)
	self.TabScroll.BackgroundTransparency = 1
	self.TabScroll.BorderSizePixel = 0
	self.TabScroll.ScrollBarThickness = 2
	self.TabScroll.ScrollBarImageColor3 = tokens.Accent
	self.TabScroll.ScrollBarImageTransparency = 0.4
	self.TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.TabScroll.ZIndex = 5
	self.TabScroll.Parent = self.Sidebar

	local tabList = Instance.new("UIListLayout")
	tabList.FillDirection = Enum.FillDirection.Vertical
	tabList.Padding = UDim.new(0, 4)
	tabList.SortOrder = Enum.SortOrder.LayoutOrder
	tabList.Parent = self.TabScroll

	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingLeft = UDim.new(0, 8)
	tabPadding.PaddingRight = UDim.new(0, 8)
	tabPadding.Parent = self.TabScroll
end

function Window:_buildContent()
	local tokens = ThemeManager.GetTokens()

	self.Content = Instance.new("Frame")
	self.Content.Name = "Content"
	self.Content.Size = UDim2.new(1, -190, 1, -46)
	self.Content.Position = UDim2.new(0, 190, 0, 46)
	self.Content.BackgroundTransparency = 1
	self.Content.BorderSizePixel = 0
	self.Content.ZIndex = 4
	self.Content.ClipsDescendants = true
	self.Content.Parent = self.Container
end

function Window:_buildDrag()
	if not self.Draggable then
		return
	end

	local dragging = false
	local dragStart = nil
	local startPos = nil

	self.Topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = self.Container.Position

			local moveConnection
			local endConnection

			moveConnection = game:GetService("UserInputService").InputChanged:Connect(function(moveInput)
				if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement
					or moveInput.UserInputType == Enum.UserInputType.Touch) then
					local delta = moveInput.Position - dragStart
					self.Container.Position = UDim2.new(
						startPos.X.Scale,
						startPos.X.Offset + delta.X,
						startPos.Y.Scale,
						startPos.Y.Offset + delta.Y
					)
				end
			end)

			endConnection = game:GetService("UserInputService").InputEnded:Connect(function(endInput)
				if endInput.UserInputType == Enum.UserInputType.MouseButton1
					or endInput.UserInputType == Enum.UserInputType.Touch then
					dragging = false
					moveConnection:Disconnect()
					endConnection:Disconnect()
				end
			end)
		end
	end)
end

function Window:_buildResize()
	if not self.Resizable then
		return
	end

	local tokens = ThemeManager.GetTokens()

	local resizeHandle = Instance.new("Frame")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.new(0, 16, 0, 16)
	resizeHandle.Position = UDim2.new(1, -16, 1, -16)
	resizeHandle.BackgroundColor3 = tokens.Accent
	resizeHandle.BackgroundTransparency = 0.92
	resizeHandle.BorderSizePixel = 0
	resizeHandle.ZIndex = 10
	resizeHandle.Parent = self.Container

	UIUtils.Corner(resizeHandle, UDim.new(0, 4))

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		resizeHandle.BackgroundColor3 = tk.Accent
	end))

	local dragging = false
	local dragStart = nil
	local startSize = nil

	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startSize = self.Container.Size
		end
	end)

	local uis = game:GetService("UserInputService")

	uis.InputChanged:Connect(function(moveInput)
		if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement
			or moveInput.UserInputType == Enum.UserInputType.Touch) then
			local delta = moveInput.Position - dragStart
			local minSize = 560
			local newSize = UDim2.new(
				0,
				math.max(minSize, startSize.X.Offset + delta.X),
				0,
				math.max(400, startSize.Y.Offset + delta.Y)
			)
			self.Container.Size = newSize
			self.Size = newSize
		end
	end)

	uis.InputEnded:Connect(function(endInput)
		if endInput.UserInputType == Enum.UserInputType.MouseButton1
			or endInput.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

function Window:_buildKeybind()
	if not self.ToggleKeybind then
		return
	end

	local uis = game:GetService("UserInputService")
	self._maid:GiveTask(uis.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == self.ToggleKeybind then
			if self.Opened then
				self:Close()
			else
				self:Open()
			end
		end
	end))
end

function Window:_applyResponsive()
	if Device.IsHandheld() or self.MobileMode then
		self.Sidebar.Size = UDim2.new(0, 56, 1, -46)
		self.Content.Position = UDim2.new(0, 56, 0, 46)
		self.Content.Size = UDim2.new(1, -56, 1, -46)
		self._sidebarCompact = true

		for _, tab in ipairs(self.Tabs) do
			if tab.SetCompact then
				tab:SetCompact(true)
			end
		end
	else
		self.Sidebar.Size = UDim2.new(0, 190, 1, -46)
		self.Content.Position = UDim2.new(0, 190, 0, 46)
		self.Content.Size = UDim2.new(1, -190, 1, -46)
		self._sidebarCompact = false

		for _, tab in ipairs(self.Tabs) do
			if tab.SetCompact then
				tab:SetCompact(false)
			end
		end
	end
end

function Window:SetMobileMode(enabled)
	self.MobileMode = enabled
	self:_applyResponsive()
	return self
end

function Window:AddTab(options)
	options = options or {}

	local Tab = require(script.Parent.Tab)
	local tab = Tab.new(options, self)

	table.insert(self.Tabs, tab)

	if not self.ActiveTab then
		self.ActiveTab = tab
		tab:SetSelected(true)
	end

	tab.Instance.Visible = (tab == self.ActiveTab)

	return tab
end

function Window:SelectTab(tabOrName)
	local target = nil

	if type(tabOrName) == "string" then
		for _, tab in ipairs(self.Tabs) do
			if tab.Name == tabOrName then
				target = tab
				break
			end
		end
	else
		target = tabOrName
	end

	if not target or target == self.ActiveTab then
		return self
	end

	if self.ActiveTab then
		self.ActiveTab:SetSelected(false)
		self.ActiveTab.Instance.Visible = false
	end

	self.ActiveTab = target
	target:SetSelected(true)
	target.Instance.Visible = true

	if target.PlayOpenAnimation then
		target:PlayOpenAnimation()
	end

	Sound.Click()
	self.OnTabChanged:Fire(target)

	return self
end

function Window:Open()
	if self.Opened then
		return self
	end

	self.Opened = true
	self.Root.Enabled = true

	local tokens = ThemeManager.GetTokens()

	self.Container.Size = self.Size

	local scale = UIUtils.Scale(self.Container, 0.9)
	self.Container.BackgroundTransparency = 0.4
	self.Overlay.BackgroundTransparency = 1

	Animator.Tween(self.Overlay, { BackgroundTransparency = 0.35 }, 0.3, "Quad")
	Animator.Tween(scale, { Scale = 1 }, 0.45, "Back")
	Animator.Tween(self.Container, { BackgroundTransparency = tokens.WindowTransparency }, 0.35, "Quart")

	if self.Background then
		self.Background.ImageTransparency = 1
		Animator.Tween(self.Background, { ImageTransparency = 0.88 }, 0.5, "Quad")
	end

	Sound.Open()
	self.OnOpened:Fire()

	return self
end

function Window:Close()
	if not self.Opened then
		return self
	end

	self.Opened = false

	local scale = self.Container:FindFirstChildOfClass("UIScale") or UIUtils.Scale(self.Container, 1)
	Animator.Tween(self.Overlay, { BackgroundTransparency = 1 }, 0.2, "Quad")
	Animator.Tween(scale, { Scale = 0.92 }, 0.22, "Quart")
	Animator.Tween(self.Container, { BackgroundTransparency = 0.35 }, 0.2, "Quad")

	task.delay(0.22, function()
		if not self.Opened then
			self.Root.Enabled = false
		end
	end)

	Sound.Close()
	self.OnClosed:Fire()

	return self
end

function Window:Toggle()
	if self.Opened then
		return self:Close()
	end
	return self:Open()
end

function Window:SetTitle(title)
	self.Title = title
	self.TitleLabel.Text = title
	return self
end

function Window:SetSubTitle(subTitle)
	self.SubTitle = subTitle

	if subTitle == "" then
		if self.SubTitleLabel then
			self.SubTitleLabel:Destroy()
			self.SubTitleLabel = nil
		end
	else
		if self.SubTitleLabel then
			self.SubTitleLabel.Text = subTitle
		end
	end

	return self
end

function Window:SetBackgroundImage(assetId, transparency)
	self.BackgroundId = assetId or self.BackgroundId

	if not self.Background and self.ImageBackground then
		self.Background = Instance.new("ImageLabel")
		self.Background.Name = "Background"
		self.Background.Size = UDim2.new(1, 0, 1, 0)
		self.Background.BackgroundTransparency = 1
		self.Background.ScaleType = Enum.ScaleType.Crop
		self.Background.ZIndex = 3
		self.Background.Parent = self.Container
	end

	if self.Background then
		self.Background.Image = self.BackgroundId
		self.Background.ImageTransparency = transparency or 0.88
	end

	return self
end

function Window:Destroy()
	if self.Destroyed then
		return
	end

	Window.ActiveWindows[self] = nil

	if self.Root then
		self.Root:Destroy()
		self.Root = nil
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Tabs = {}
	self.Destroyed = true
end

return Window
