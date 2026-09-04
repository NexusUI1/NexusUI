local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local MultiDropdown = {}
MultiDropdown.__index = MultiDropdown
setmetatable(MultiDropdown, { __index = BaseComponent })

function MultiDropdown.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("MultiDropdown")
	setmetatable(self, { __index = function(t, k)
		if MultiDropdown[k] then
			return MultiDropdown[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "MultiDropdown"
	self.Text = options.Text or options.Name or "Multi Select"
	self.Options = options.Options or {}
	self.SelectedOptions = {}
	self.Callback = options.Callback or function() end
	self.MaxVisible = options.MaxVisible or 5
	self.PlaceholderText = options.Placeholder or "Select multiple..."

	self.IsOpen = false

	if options.Value then
		if type(options.Value) == "table" then
			for _, v in ipairs(options.Value) do
				table.insert(self.SelectedOptions, v)
			end
		end
	end

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

function MultiDropdown:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "MultiDropdown_" .. self.Text
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
	self.SelectedLabel.Text = self:_formatSelected()
	self.SelectedLabel.TextColor3 = tokens.Text
	self.SelectedLabel.TextSize = tokens.TextSize
	self.SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.SelectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
	self.SelectedLabel.ZIndex = 8
	self.SelectedLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.SelectedLabel.Font = tk.Font
		self.SelectedLabel.TextSize = tk.TextSize
	end))

	self.CountBadge = Instance.new("TextLabel")
	self.CountBadge.Name = "Count"
	self.CountBadge.AnchorPoint = Vector2.new(1, 0.5)
	self.CountBadge.Position = UDim2.new(1, -30, 0.5, 0)
	self.CountBadge.Size = UDim2.new(0, 20, 0, 20)
	self.CountBadge.BackgroundColor3 = tokens.Accent
	self.CountBadge.BackgroundTransparency = 0.85
	self.CountBadge.Font = tokens.FontBold
	self.CountBadge.Text = tostring(#self.SelectedOptions)
	self.CountBadge.TextColor3 = tokens.Accent
	self.CountBadge.TextSize = 11
	self.CountBadge.ZIndex = 8
	self.CountBadge.Parent = self.Header

	UIUtils.Corner(self.CountBadge, tokens.CornerCircle)

	self.Chevron = Instance.new("TextLabel")
	self.Chevron.Name = "Chevron"
	self.Chevron.AnchorPoint = Vector2.new(1, 0.5)
	self.Chevron.Position = UDim2.new(1, -8, 0.5, 0)
	self.Chevron.Size = UDim2.new(0, 20, 1, 0)
	self.Chevron.BackgroundTransparency = 1
	self.Chevron.Font = tokens.FontBold
	self.Chevron.Text = "v"
	self.Chevron.TextColor3 = tokens.SecondaryText
	self.Chevron.TextSize = 14
	self.Chevron.ZIndex = 8
	self.Chevron.Parent = self.Header

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
	self.OptionScroll.Size = UDim2.new(1, 0, 1, 0)
	self.OptionScroll.BackgroundTransparency = 1
	self.OptionScroll.BorderSizePixel = 0
	self.OptionScroll.ScrollBarThickness = 2
	self.OptionScroll.ScrollBarImageColor3 = tokens.Accent
	self.OptionScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.OptionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.OptionScroll.ZIndex = 21
	self.OptionScroll.Parent = self.OptionList

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.OptionScroll

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 4)
	padding.Parent = self.OptionScroll

	self:_populateOptions()

	self.Header.MouseButton1Click:Connect(function()
		self:SetOpen(not self.IsOpen)
	end)

	self:_updateListHeight()
end

function MultiDropdown:_formatSelected()
	if #self.SelectedOptions == 0 then
		return self.PlaceholderText
	end
	if #self.SelectedOptions <= 3 then
		return table.concat(self.SelectedOptions, ", ")
	end
	return self.SelectedOptions[1] .. ", " .. self.SelectedOptions[2] .. " +" .. (#self.SelectedOptions - 2)
end

function MultiDropdown:_populateOptions()
	for _, child in ipairs(self.OptionScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for index, option in ipairs(self.Options) do
		local optionText = tostring(option)
		local isSelected = table.find(self.SelectedOptions, option) ~= nil

		local optionButton = Instance.new("TextButton")
		optionButton.Name = "Option_" .. optionText
		optionButton.Size = UDim2.new(1, 0, 0, 28)
		optionButton.BackgroundColor3 = ThemeManager.GetTokens().SurfaceLight
		optionButton.BackgroundTransparency = 1
		optionButton.BorderSizePixel = 0
		optionButton.AutoButtonColor = false
		optionButton.Font = ThemeManager.GetTokens().Font
		optionButton.Text = (isSelected and "[x] " or "[ ] ") .. optionText
		optionButton.TextColor3 = isSelected and ThemeManager.GetTokens().Accent or ThemeManager.GetTokens().SecondaryText
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
			Animator.Tween(optionButton, { BackgroundTransparency = 0.75 }, 0.12, "Quad")
		end)

		optionButton.MouseLeave:Connect(function()
			Animator.Tween(optionButton, { BackgroundTransparency = 1 }, 0.12, "Quad")
		end)

		optionButton.MouseButton1Click:Connect(function()
			self:ToggleOption(option)
		end)

		optionButton._optionValue = option
	end
end

function MultiDropdown:_updateListHeight()
	local optionCount = #self.Options
	local visibleCount = math.min(optionCount, self.MaxVisible)
	local height = visibleCount * 30 + 8

	if self.IsOpen then
		self.OptionList.Size = UDim2.new(1, 0, 0, height)
	else
		self.OptionList.Size = UDim2.new(1, 0, 0, 0)
	end
end

function MultiDropdown:SetOpen(open)
	if open == self.IsOpen then
		return self
	end

	self.IsOpen = open

	if open then
		self.OptionList.Visible = true
		Animator.Tween(self.Chevron, { Rotation = 180 }, 0.25, "Quart")
		Animator.Tween(self.OptionList, { Size = UDim2.new(1, 0, 0, math.min(#self.Options, self.MaxVisible) * 30 + 8) }, 0.25, "Quart")
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

function MultiDropdown:ToggleOption(option)
	local index = table.find(self.SelectedOptions, option)

	if index then
		table.remove(self.SelectedOptions, index)
	else
		table.insert(self.SelectedOptions, option)
	end

	self:_refreshDisplay()
	Sound.Toggle()
	self.OnChanged:Fire(self.SelectedOptions)

	local ok, err = pcall(self.Callback, self.SelectedOptions)
	if not ok then
		warn("[NexusUI] MultiDropdown callback error:", err)
	end

	return self
end

function MultiDropdown:_refreshDisplay()
	self.SelectedLabel.Text = self:_formatSelected()
	self.CountBadge.Text = tostring(#self.SelectedOptions)

	for _, button in ipairs(self.OptionScroll:GetChildren()) do
		if button:IsA("TextButton") and button._optionValue ~= nil then
			local isSelected = table.find(self.SelectedOptions, button._optionValue) ~= nil
			button.Text = (isSelected and "[x] " or "[ ] ") .. button.Text:sub(5)
			button.TextColor3 = isSelected and ThemeManager.GetTokens().Accent or ThemeManager.GetTokens().SecondaryText
		end
	end
end

function MultiDropdown:SetSelected(options)
	self.SelectedOptions = {}

	if type(options) == "table" then
		for _, option in ipairs(options) do
			if table.find(self.Options, option) then
				table.insert(self.SelectedOptions, option)
			end
		end
	end

	self:_refreshDisplay()
	self.OnChanged:Fire(self.SelectedOptions)
	return self
end

function MultiDropdown:GetSelected()
	local copy = {}
	for _, option in ipairs(self.SelectedOptions) do
		table.insert(copy, option)
	end
	return copy
end

function MultiDropdown:Clear()
	self.SelectedOptions = {}
	self:_refreshDisplay()
	return self
end

function MultiDropdown:SetOptions(options)
	self.Options = options or {}
	self.SelectedOptions = {}
	self:_populateOptions()
	self:_updateListHeight()
	return self
end

function MultiDropdown:SetText(text)
	self.Text = text
	return self
end

function MultiDropdown:Destroy()
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

return MultiDropdown
