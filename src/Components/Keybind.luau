local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local Keybind = {}
Keybind.__index = Keybind
setmetatable(Keybind, { __index = BaseComponent })

function Keybind.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Keybind")
	setmetatable(self, { __index = function(t, k)
		if Keybind[k] then
			return Keybind[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Keybind"
	self.Text = options.Text or options.Name or "Keybind"
	self.DefaultValue = options.Value or options.Default or Enum.KeyCode.RightShift
	self.Value = self.DefaultValue
	self.Callback = options.Callback or function() end
	self.Mode = options.Mode or "Toggle"
	self.AllowMouse = options.AllowMouse ~= false

	self.Listening = false

	self.OnChanged = Signal.new()
	self.OnTriggered = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
		Triggered = self.OnTriggered,
	}

	self:_build(parent)
	self:_bindInput()

	return self
end

function Keybind:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Keybind_" .. self.Text
	self.Container.Size = UDim2.new(1, 0, 0, 34)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.TextLabel = Instance.new("TextLabel")
	self.TextLabel.Name = "Text"
	self.TextLabel.BackgroundTransparency = 1
	self.TextLabel.Position = UDim2.new(0, 4, 0, 0)
	self.TextLabel.Size = UDim2.new(1, -80, 1, 0)
	self.TextLabel.Font = tokens.Font
	self.TextLabel.Text = self.Text
	self.TextLabel.TextColor3 = tokens.Text
	self.TextLabel.TextSize = tokens.TextSize
	self.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TextLabel.TextTruncate = Enum.TextTruncate.AtEnd
	self.TextLabel.ZIndex = 7
	self.TextLabel.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TextLabel.Font = tk.Font
		self.TextLabel.TextColor3 = tk.Text
		self.TextLabel.TextSize = tk.TextSize
	end))

	self.BindButton = Instance.new("TextButton")
	self.BindButton.Name = "BindButton"
	self.BindButton.AnchorPoint = Vector2.new(1, 0.5)
	self.BindButton.Position = UDim2.new(1, -2, 0.5, 0)
	self.BindButton.Size = UDim2.new(0, 70, 0, 24)
	self.BindButton.BackgroundColor3 = tokens.SurfaceLight
	self.BindButton.BackgroundTransparency = 0.2
	self.BindButton.BorderSizePixel = 0
	self.BindButton.AutoButtonColor = false
	self.BindButton.Font = tokens.FontBold
	self.BindButton.Text = self:_keyName(self.Value)
	self.BindButton.TextColor3 = tokens.Accent
	self.BindButton.TextSize = 11
	self.BindButton.ZIndex = 7
	self.BindButton.Parent = self.Container

	UIUtils.Corner(self.BindButton, tokens.CornerSmall)
	UIUtils.Stroke(self.BindButton, tokens.Border, 1, 0.6)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.BindButton.BackgroundColor3 = tk.SurfaceLight
		self.BindButton.Font = tk.FontBold
		self.BindButton.TextColor3 = tk.Accent
	end))

	self.BindButton.MouseButton1Click:Connect(function()
		self:StartListening()
	end)

	self.BindButton.MouseEnter:Connect(function()
		Animator.Tween(self.BindButton, { BackgroundTransparency = 0.02 }, 0.15, "Quad")
		Sound.Hover()
	end)

	self.BindButton.MouseLeave:Connect(function()
		Animator.Tween(self.BindButton, { BackgroundTransparency = 0.2 }, 0.15, "Quad")
	end)
end

function Keybind:_keyName(keyCode)
	if not keyCode then
		return "None"
	end

	local UserInputService = game:GetService("UserInputService")
	local ok, name = pcall(function()
		return UserInputService:GetStringForKeyCode(keyCode)
	end)

	if ok and name and name ~= "" then
		return name
	end

	return keyCode.Name
end

function Keybind:StartListening()
	if self.Listening then
		return self
	end

	self.Listening = true
	local tokens = ThemeManager.GetTokens()

	self.BindButton.Text = "..."
	Animator.Tween(self.BindButton, { BackgroundColor3 = tokens.Accent, BackgroundTransparency = 0.7, TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.15, "Quad")

	return self
end

function Keybind:StopListening()
	if not self.Listening then
		return self
	end

	self.Listening = false
	self.BindButton.Text = self:_keyName(self.Value)
	self:_updateBindButtonVisual()

	return self
end

function Keybind:_updateBindButtonVisual()
	local tokens = ThemeManager.GetTokens()
	Animator.Tween(self.BindButton, {
		BackgroundColor3 = tokens.SurfaceLight,
		BackgroundTransparency = 0.2,
		TextColor3 = tokens.Accent,
	}, 0.15, "Quad")
end

function Keybind:_bindInput()
	local UserInputService = game:GetService("UserInputService")

	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
		if not self.Listening then
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				self:StopListening()
				return
			end

			self:SetValue(input.KeyCode, true)
			self:StopListening()

		elseif self.AllowMouse then
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				self:SetValue(input.UserInputType, true)
				self:StopListening()
			end
		end
	end))

	self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input, processed)
		if processed then
			return
		end

		if self.Listening then
			return
		end

		local matches = false
		if input.UserInputType == Enum.UserInputType.Keyboard then
			matches = input.KeyCode == self.Value
		elseif input.UserInputType == self.Value then
			matches = true
		end

		if matches then
			if self.Mode == "Toggle" then
				self.OnTriggered:Fire(self.Value)
				pcall(self.Callback, self.Value)
			elseif self.Mode == "Hold" then
				self.OnTriggered:Fire(self.Value)
				pcall(self.Callback, self.Value)
			end
		end
	end))
end

function Keybind:SetValue(value, fireEvent)
	self.Value = value
	self.BindButton.Text = self:_keyName(value)

	if fireEvent then
		Sound.Click()
		self.OnChanged:Fire(value)
	end

	return self
end

function Keybind:GetValue()
	return self.Value
end

function Keybind:SetText(text)
	self.Text = text
	self.TextLabel.Text = text
	return self
end

function Keybind:SetMode(mode)
	self.Mode = mode
	return self
end

function Keybind:Reset()
	return self:SetValue(self.DefaultValue, true)
end

function Keybind:Destroy()
	if self.Destroyed then
		return
	end

	self:StopListening()

	if self.Container then
		self.Container:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return Keybind
