local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local Dropdown = {}
Dropdown.__index = Dropdown
setmetatable(Dropdown, { __index = BaseComponent })

function Dropdown.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Dropdown")
	setmetatable(self, { __index = function(t, k)
		if Dropdown[k] then
			return Dropdown[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Dropdown"
	self.Text = options.Text or options.Name or "Dropdown"
	self.Options = options.Options or {}
	self.DefaultValue = options.Value or options.Default
	self.Value = self.DefaultValue
	self.Callback = options.Callback or function() end
	self.MaxVisible = options.MaxVisible or 6
	self.PlaceholderText = options.Placeholder or "Select..."

	self.IsOpen = false

	self.OnChanged = Signal.new()
	self.OnOpened = Signal.new()
	self.OnClosed = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
		Opened = self.OnOpened,
		Closed = self.OnClosed,
	}

	self:_build(parent)

	return self
end

function Dropdown:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Dropdown_" .. self.Text
	self.Container.Size = UDim2.new(1, 0, 0, 34)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Header = Instance.new("TextButton")
	self.Header.Name = "Header"
	self.Header.Size = UDim2.new(1, 0, 0, 34)
	self.Header.BackgroundColor3 = tokens.SurfaceLight
	self.Header.BackgroundTransparency = 0.2
	self.Header.BorderSizePixel = 0
	self.Header.AutoButtonColor = false
	self.Header.Text = ""
	self.Header.ZIndex = 7
	self.Header.Parent = self.Container

	UIUtils.Corner(self.Header, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Header.BackgroundColor3 = tk.SurfaceLight
	end))

	self.SelectedLabel = Instance.new("TextLabel")
	self.SelectedLabel.Name = "Selected"
	self.SelectedLabel.Position = UDim2.new(0, 10, 0, 0)
	self.SelectedLabel.Size = UDim2.new(1, -40, 1, 0)
	self.SelectedLabel.BackgroundTransparency = 1
	self.SelectedLabel.Font = tokens.Font
	self.SelectedLabel.Text = self.Value and tostring(self.Value) or self.PlaceholderText
	self.SelectedLabel.TextColor3 = self.Value and tokens.Text or tokens.MutedText
	self.SelectedLabel.TextSize = tokens.TextSize
	self.SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.SelectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
	self.SelectedLabel.ZIndex = 8
	self.SelectedLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.SelectedLabel.Font = tk.Font
		self.SelectedLabel.TextSize = tk.TextSize
		if not self.Value then
			self.SelectedLabel.TextColor3 = tk.MutedText
		end
	end))

	self.Chevron = Instance.new("TextLabel")
	self.Chevron.Name = "Chevron"
	self.Chevron.AnchorPoint = Vector2.new(1, 0.5)
	self.Chevron.Position = UDim2.new(1, -10, 0.5, 0)
	self.Chevron.Size = UDim2.new(0, 20, 1, 0)
	self.Chevron.BackgroundTransparency = 1
	self.Chevron.Font = tokens.FontBold
	self.Chevron.Text = "v"
	self.Chevron.TextColor3 = tokens.SecondaryText
	self.Chevron.TextSize = 14
	self.Chevron.Rotation = 0
	self.Chevron.ZIndex = 8
	self.Chevron.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Chevron.Font = tk.FontBold
		self.Chevron.TextColor3 = tk.SecondaryText
	end))

	self.OptionList = Instance.new("Frame")
	self.OptionList.Name = "OptionList"
	self.OptionList.Position = UDim2.new(0, 0, 0, 38)
	self.OptionList.Size = UDim2.new(1, 0, 0, 0)
	self.OptionList.BackgroundColor3 = tokens.Elevated
	self.OptionList.BorderSizePixel = 0
	self.OptionList.ZIndex = 20
	self.OptionList.ClipsDescendants = true
	self.OptionList.Visible = false
	self.OptionList.Parent = self.Container

	UIUtils.Corner(self.OptionList, tokens.CornerSmall)
	UIUtils.Stroke(self.OptionList, tokens.BorderLight, 1, 0.5)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.OptionList.BackgroundColor3 = tk.Elevated
	end))

	self.OptionScroll = Instance.new("ScrollingFrame")
	self.OptionScroll.Name = "OptionScroll"
	self.OptionScroll.Size = UDim2.new(1, 0, 1, 0)
	self.OptionScroll.BackgroundTransparency = 1
	self.OptionScroll.BorderSizePixel = 0
	self.OptionScroll.ScrollBarThickness = 2
	self.OptionScroll.ScrollBarImageColor3 = tokens.Accent
	self.OptionScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.OptionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.OptionScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	self.OptionScroll.ZIndex = 21
	self.OptionScroll.Parent = self.OptionList

	local optionLayout = Instance.new("UIListLayout")
	optionLayout.FillDirection = Enum.FillDirection.Vertical
	optionLayout.Padding = UDim.new(0, 2)
	optionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	optionLayout.Parent = self.OptionScroll

	local optionPadding = Instance.new("UIPadding")
	optionPadding.PaddingTop = UDim.new(0, 4)
	optionPadding.PaddingBottom = UDim.new(0, 4)
	optionPadding.PaddingLeft = UDim.new(0, 4)
	optionPadding.PaddingRight = UDim.new(0, 4)
	optionPadding.Parent = self.OptionScroll

	self:_populateOptions()

	self.Header.MouseButton1Click:Connect(function()
		self:SetOpen(not self.IsOpen)
	end)

	self.Header.MouseEnter:Connect(function()
		Animator.Tween(self.Header, { BackgroundTransparency = 0.05 }, 0.15, "Quad")
		Sound.Hover()
	end)

	self.Header.MouseLeave:Connect(function()
		Animator.Tween(self.Header, { BackgroundTransparency = 0.2 }, 0.15, "Quad")
	end)

	self:_updateListSize()
end

function Dropdown:_populateOptions()
	for _, child in ipairs(self.OptionScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for index, option in ipairs(self.Options) do
		local optionText = type(option) == "table" and option.Name or tostring(option)
		local optionValue = type(option) == "table" and option.Value or option

		local optionButton = Instance.new("TextButton")
		optionButton.Name = "Option_" .. optionText
		optionButton.Size = UDim2.new(1, 0, 0, 28)
		optionButton.BackgroundColor3 = ThemeManager.GetTokens().SurfaceLight
		optionButton.BackgroundTransparency = 1
		optionButton.BorderSizePixel = 0
		optionButton.AutoButtonColor = false
		optionButton.Font = ThemeManager.GetTokens().Font
		optionButton.Text = optionText
		optionButton.TextColor3 = ThemeManager.GetTokens().SecondaryText
		optionButton.TextSize = 13
		optionButton.TextXAlignment = Enum.TextXAlignment.Left
		optionButton.ZIndex = 22
		optionButton.LayoutOrder = index
		optionButton.Parent = self.OptionScroll

		UIUtils.Corner(optionButton, ThemeManager.GetTokens().CornerSmall)

		local textPadding = Instance.new("UIPadding")
		textPadding.PaddingLeft = UDim.new(0, 8)
		textPadding.Parent = optionButton

		optionButton.MouseEnter:Connect(function()
			Animator.Tween(optionButton, { BackgroundTransparency = 0.75, TextColor3 = ThemeManager.GetTokens().Text }, 0.12, "Quad")
		end)

		optionButton.MouseLeave:Connect(function()
			local tokens = ThemeManager.GetTokens()
			local isSelected = self.Value == optionValue
			Animator.Tween(optionButton, {
				BackgroundTransparency = isSelected and 0.7 or 1,
				TextColor3 = isSelected and tokens.Accent or tokens.SecondaryText,
			}, 0.12, "Quad")
		end)

		optionButton.MouseButton1Click:Connect(function()
			self:Select(optionValue)
		end)

		if self.Value == optionValue then
			optionButton.BackgroundTransparency = 0.7
			optionButton.TextColor3 = ThemeManager.GetTokens().Accent
		end
	end
end

function Dropdown:_updateListSize()
	local optionCount = #self.Options
	local visibleCount = math.min(optionCount, self.MaxVisible)
	local height = visibleCount * 30 + 8

	if self.IsOpen then
		self.OptionList.Size = UDim2.new(1, 0, 0, height)
	else
		self.OptionList.Size = UDim2.new(1, 0, 0, 0)
	end
end

function Dropdown:SetOpen(open)
	if open == self.IsOpen then
		return self
	end

	self.IsOpen = open

	if open then
		self.OptionList.Visible = true
		self:_updateListSize()
		Animator.Tween(self.Chevron, { Rotation = 180 }, 0.25, "Quart")
		Animator.Tween(self.OptionList, { Size = UDim2.new(1, 0, 0, self:_listHeight()) }, 0.25, "Quart")
		Sound.Pop()
		self.OnOpened:Fire()
	else
		Animator.Tween(self.Chevron, { Rotation = 0 }, 0.2, "Quad")
		Animator.Tween(self.OptionList, { Size = UDim2.new(1, 0, 0, 0) }, 0.2, "Quad")
		task.delay(0.2, function()
			if not self.IsOpen then
				self.OptionList.Visible = false
			end
		end)
		Sound.Close()
		self.OnClosed:Fire()
	end

	return self
end

function Dropdown:_listHeight()
	local optionCount = #self.Options
	local visibleCount = math.min(optionCount, self.MaxVisible)
	return visibleCount * 30 + 8
end

function Dropdown:Select(value)
	if not table.find(self.Options, value) and type(value) ~= "string" then
		for _, option in ipairs(self.Options) do
			if type(option) == "table" and option.Value == value then
				self.Value = value
				break
			end
		end
	else
		self.Value = value
	end

	local tokens = ThemeManager.GetTokens()
	self.SelectedLabel.Text = tostring(value)
	self.SelectedLabel.TextColor3 = tokens.Text

	for _, button in ipairs(self.OptionScroll:GetChildren()) do
		if button:IsA("TextButton") then
			local isSelected = button.Text == tostring(value)
			button.BackgroundTransparency = isSelected and 0.7 or 1
			button.TextColor3 = isSelected and tokens.Accent or tokens.SecondaryText
		end
	end

	self:SetOpen(false)
	Sound.Click()
	self.OnChanged:Fire(value)

	local ok, err = pcall(self.Callback, value)
	if not ok then
		warn("[NexusUI] Dropdown callback error:", err)
	end

	return self
end

function Dropdown:SetOptions(options)
	self.Options = options or {}
	self:_populateOptions()
	self:_updateListSize()
	return self
end

function Dropdown:GetValue()
	return self.Value
end

function Dropdown:SetText(text)
	self.Text = text
	return self
end

function Dropdown:Destroy()
	if self.Destroyed then
		return
	end

	self:SetOpen(false)

	if self.Container then
		self.Container:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return Dropdown
