local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local TextBox = {}
TextBox.__index = TextBox
setmetatable(TextBox, { __index = BaseComponent })

function TextBox.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("TextBox")
	setmetatable(self, { __index = function(t, k)
		if TextBox[k] then
			return TextBox[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "TextBox"
	self.Text = options.Text or options.Value or ""
	self.Placeholder = options.Placeholder or "Type here..."
	self.DefaultValue = self.Text
	self.Callback = options.Callback or function() end
	self.OnEnter = options.OnEnter
	self.ClearOnFocus = options.ClearOnFocus or false
	self.NumericOnly = options.NumericOnly or false
	self.MaxLength = options.MaxLength or 200

	self.OnChanged = Signal.new()
	self.OnFocused = Signal.new()
	self.OnFocusLost = Signal.new()
	self.OnSubmitted = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
		Focused = self.OnFocused,
		FocusLost = self.OnFocusLost,
		Submitted = self.OnSubmitted,
	}

	self:_build(parent)

	return self
end

function TextBox:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "TextBox_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, 34)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.InputFrame = Instance.new("Frame")
	self.InputFrame.Name = "InputFrame"
	self.InputFrame.Size = UDim2.new(1, 0, 1, 0)
	self.InputFrame.BackgroundColor3 = tokens.Background
	self.InputFrame.BackgroundTransparency = 0.2
	self.InputFrame.BorderSizePixel = 0
	self.InputFrame.ZIndex = 7
	self.InputFrame.Parent = self.Container

	UIUtils.Corner(self.InputFrame, tokens.CornerSmall)
	self.Stroke = UIUtils.Stroke(self.InputFrame, tokens.Border, 1, 0.6)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.InputFrame.BackgroundColor3 = tk.Background
	end))

	self.Input = Instance.new("TextBox")
	self.Input.Name = "Input"
	self.Input.Position = UDim2.new(0, 10, 0, 0)
	self.Input.Size = UDim2.new(1, -20, 1, 0)
	self.Input.BackgroundTransparency = 1
	self.Input.Font = tokens.Font
	self.Input.Text = self.Text
	self.Input.PlaceholderText = self.Placeholder
	self.Input.PlaceholderColor3 = tokens.MutedText
	self.Input.TextColor3 = tokens.Text
	self.Input.TextSize = tokens.TextSize
	self.Input.TextXAlignment = Enum.TextXAlignment.Left
	self.Input.ClearTextOnFocus = self.ClearOnFocus
	self.Input.TextTruncate = Enum.TextTruncate.AtEnd
	self.Input.ZIndex = 8
	self.Input.Parent = self.InputFrame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Input.Font = tk.Font
		self.Input.TextSize = tk.TextSize
		self.Input.TextColor3 = tk.Text
		self.Input.PlaceholderColor3 = tk.MutedText
	end))

	self.Input:GetPropertyChangedSignal("Text"):Connect(function()
		local text = self.Input.Text

		if self.NumericOnly then
			local filtered = text:gsub("[^%d%.%-]", "")
			if filtered ~= text then
				self.Input.Text = filtered
				text = filtered
			end
		end

		if #text > self.MaxLength then
			self.Input.Text = text:sub(1, self.MaxLength)
			text = self.Input.Text
		end

		self.Text = text
		self.OnChanged:Fire(text)
	end)

	self.Input.Focused:Connect(function()
		Animator.Tween(self.Stroke, { Color = ThemeManager.GetTokens().Accent, Transparency = 0.1 }, 0.18, "Quad")
		Animator.Tween(self.InputFrame, { BackgroundTransparency = 0.05 }, 0.18, "Quad")
		self.OnFocused:Fire(self.Text)
	end)

	self.Input.FocusLost:Connect(function(enterPressed)
		local tokensNow = ThemeManager.GetTokens()
		Animator.Tween(self.Stroke, { Color = tokensNow.Border, Transparency = 0.6 }, 0.18, "Quad")
		Animator.Tween(self.InputFrame, { BackgroundTransparency = 0.2 }, 0.18, "Quad")

		self.OnFocusLost:Fire(self.Text, enterPressed)

		if enterPressed then
			Sound.Click()
			self.OnSubmitted:Fire(self.Text)

			if self.OnEnter then
				pcall(self.OnEnter, self.Text)
			end
		end
	end)
end

function TextBox:SetText(text)
	self.Text = text
	self.Input.Text = text
	return self
end

function TextBox:GetText()
	return self.Input.Text
end

function TextBox:SetPlaceholder(placeholder)
	self.Placeholder = placeholder
	self.Input.PlaceholderText = placeholder
	return self
end

function TextBox:SetNumericOnly(enabled)
	self.NumericOnly = enabled
	return self
end

function TextBox:SetMaxLength(maxLength)
	self.MaxLength = maxLength
	return self
end

function TextBox:Clear()
	return self:SetText("")
end

function TextBox:Focus()
	self.Input:CaptureFocus()
	return self
end

function TextBox:ReleaseFocus()
	self.Input:ReleaseFocus()
	return self
end

function TextBox:Reset()
	return self:SetText(self.DefaultValue)
end

function TextBox:Destroy()
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

return TextBox
