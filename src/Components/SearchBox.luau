local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local SearchBox = {}
SearchBox.__index = SearchBox
setmetatable(SearchBox, { __index = BaseComponent })

function SearchBox.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("SearchBox")
	setmetatable(self, { __index = function(t, k)
		if SearchBox[k] then
			return SearchBox[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "SearchBox"
	self.Placeholder = options.Placeholder or "Search..."
	self.DebounceTime = options.DebounceTime or 0.3
	self.Callback = options.Callback or function() end

	self.OnSearch = Signal.new()
	self.OnCleared = Signal.new()
	self.OnTextChanged = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Search = self.OnSearch,
		Cleared = self.OnCleared,
		TextChanged = self.OnTextChanged,
	}

	self:_build(parent)

	return self
end

function SearchBox:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "SearchBox_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, 34)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Frame = Instance.new("Frame")
	self.Frame.Name = "Holder"
	self.Frame.Size = UDim2.new(1, 0, 1, 0)
	self.Frame.BackgroundColor3 = tokens.Background
	self.Frame.BackgroundTransparency = 0.2
	self.Frame.BorderSizePixel = 0
	self.Frame.ZIndex = 7
	self.Frame.Parent = self.Container

	UIUtils.Corner(self.Frame, tokens.CornerSmall)
	self.Stroke = UIUtils.Stroke(self.Frame, tokens.Border, 1, 0.6)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Frame.BackgroundColor3 = tk.Background
	end))

	self.SearchIcon = Instance.new("ImageLabel")
	self.SearchIcon.Name = "SearchIcon"
	self.SearchIcon.Position = UDim2.new(0, 10, 0.5, 0)
	self.SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
	self.SearchIcon.Size = UDim2.new(0, 15, 0, 15)
	self.SearchIcon.BackgroundTransparency = 1
	self.SearchIcon.Image = "rbxassetid://10747387627"
	self.SearchIcon.ImageColor3 = tokens.MutedText
	self.SearchIcon.ScaleType = Enum.ScaleType.Fit
	self.SearchIcon.ZIndex = 8
	self.SearchIcon.Parent = self.Frame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.SearchIcon.ImageColor3 = tk.MutedText
	end))

	self.Input = Instance.new("TextBox")
	self.Input.Name = "Input"
	self.Input.Position = UDim2.new(0, 32, 0, 0)
	self.Input.Size = UDim2.new(1, -58, 1, 0)
	self.Input.BackgroundTransparency = 1
	self.Input.Font = tokens.Font
	self.Input.Text = ""
	self.Input.PlaceholderText = self.Placeholder
	self.Input.PlaceholderColor3 = tokens.MutedText
	self.Input.TextColor3 = tokens.Text
	self.Input.TextSize = tokens.TextSize
	self.Input.TextXAlignment = Enum.TextXAlignment.Left
	self.Input.ClearTextOnFocus = false
	self.Input.ZIndex = 8
	self.Input.Parent = self.Frame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Input.Font = tk.Font
		self.Input.TextSize = tk.TextSize
		self.Input.TextColor3 = tk.Text
		self.Input.PlaceholderColor3 = tk.MutedText
	end))

	self.ClearButton = Instance.new("TextButton")
	self.ClearButton.Name = "Clear"
	self.ClearButton.AnchorPoint = Vector2.new(1, 0.5)
	self.ClearButton.Position = UDim2.new(1, -8, 0.5, 0)
	self.ClearButton.Size = UDim2.new(0, 18, 0, 18)
	self.ClearButton.BackgroundTransparency = 1
	self.ClearButton.BorderSizePixel = 0
	self.ClearButton.AutoButtonColor = false
	self.ClearButton.Font = tokens.FontBold
	self.ClearButton.Text = "x"
	self.ClearButton.TextColor3 = tokens.MutedText
	self.ClearButton.TextSize = 13
	self.ClearButton.Visible = false
	self.ClearButton.ZIndex = 8
	self.ClearButton.Parent = self.Frame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.ClearButton.Font = tk.FontBold
		self.ClearButton.TextColor3 = tk.MutedText
	end))

	self:_bindEvents()
end

function SearchBox:_bindEvents()
	local debounceThread = nil

	local function scheduleSearch(text)
		if debounceThread then
			task.cancel(debounceThread)
		end

		debounceThread = task.delay(self.DebounceTime, function()
			self.OnSearch:Fire(text)
			pcall(self.Callback, text)
		end)
	end

	self.Input:GetPropertyChangedSignal("Text"):Connect(function()
		local text = self.Input.Text
		self.ClearButton.Visible = #text > 0

		self.OnTextChanged:Fire(text)
		scheduleSearch(text)
	end)

	self.Input.Focused:Connect(function()
		Animator.Tween(self.Stroke, { Color = ThemeManager.GetTokens().Accent, Transparency = 0.1 }, 0.18, "Quad")
	end)

	self.Input.FocusLost:Connect(function()
		Animator.Tween(self.Stroke, { Color = ThemeManager.GetTokens().Border, Transparency = 0.6 }, 0.18, "Quad")
	end)

	self.ClearButton.MouseButton1Click:Connect(function()
		self.Input.Text = ""
		self.ClearButton.Visible = false
		Sound.Click()
		self.OnCleared:Fire()
		self.OnSearch:Fire("")
	end)

	self.ClearButton.MouseEnter:Connect(function()
		Animator.Tween(self.ClearButton, { TextColor3 = ThemeManager.GetTokens().Error }, 0.15, "Quad")
	end)

	self.ClearButton.MouseLeave:Connect(function()
		Animator.Tween(self.ClearButton, { TextColor3 = ThemeManager.GetTokens().MutedText }, 0.15, "Quad")
	end)
end

function SearchBox:SetText(text)
	self.Input.Text = text
	self.ClearButton.Visible = #text > 0
	return self
end

function SearchBox:GetText()
	return self.Input.Text
end

function SearchBox:Clear()
	self.Input.Text = ""
	self.ClearButton.Visible = false
	self.OnCleared:Fire()
	self.OnSearch:Fire("")
	return self
end

function SearchBox:Focus()
	self.Input:CaptureFocus()
	return self
end

function SearchBox:SetPlaceholder(text)
	self.Placeholder = text
	self.Input.PlaceholderText = text
	return self
end

function SearchBox:Destroy()
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

return SearchBox
