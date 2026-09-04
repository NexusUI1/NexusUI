local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local ColorPicker = {}
ColorPicker.__index = ColorPicker
setmetatable(ColorPicker, { __index = BaseComponent })

function ColorPicker.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("ColorPicker")
	setmetatable(self, { __index = function(t, k)
		if ColorPicker[k] then
			return ColorPicker[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "ColorPicker"
	self.Text = options.Text or options.Name or "Color"
	self.DefaultColor = options.Value or options.Default or Color3.fromRGB(96, 130, 255)
	self.Color = self.DefaultColor
	self.Callback = options.Callback or function() end

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

	local h, s, v = self.Color:ToHSV()
	self._hue = h
	self._sat = s
	self._val = v

	self:_build(parent)

	return self
end

function ColorPicker:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "ColorPicker_" .. self.Text
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

	self.ColorPreview = Instance.new("Frame")
	self.ColorPreview.Name = "Preview"
	self.ColorPreview.AnchorPoint = Vector2.new(0, 0.5)
	self.ColorPreview.Position = UDim2.new(0, 8, 0.5, 0)
	self.ColorPreview.Size = UDim2.new(0, 22, 0, 22)
	self.ColorPreview.BackgroundColor3 = self.Color
	self.ColorPreview.BorderSizePixel = 0
	self.ColorPreview.ZIndex = 8
	self.ColorPreview.Parent = self.Header

	UIUtils.Corner(self.ColorPreview, tokens.CornerSmall)
	UIUtils.Stroke(self.ColorPreview, tokens.BorderLight, 1, 0.4)

	self.TextLabel = Instance.new("TextLabel")
	self.TextLabel.Name = "Text"
	self.TextLabel.Position = UDim2.new(0, 38, 0, 0)
	self.TextLabel.Size = UDim2.new(0.6, -38, 1, 0)
	self.TextLabel.BackgroundTransparency = 1
	self.TextLabel.Font = tokens.Font
	self.TextLabel.Text = self.Text
	self.TextLabel.TextColor3 = tokens.Text
	self.TextLabel.TextSize = tokens.TextSize
	self.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TextLabel.ZIndex = 8
	self.TextLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TextLabel.Font = tk.Font
		self.TextLabel.TextColor3 = tk.Text
		self.TextLabel.TextSize = tk.TextSize
	end))

	self.HexLabel = Instance.new("TextLabel")
	self.HexLabel.Name = "Hex"
	self.HexLabel.AnchorPoint = Vector2.new(1, 0.5)
	self.HexLabel.Position = UDim2.new(1, -8, 0.5, 0)
	self.HexLabel.Size = UDim2.new(0, 70, 1, 0)
	self.HexLabel.BackgroundTransparency = 1
	self.HexLabel.Font = tokens.FontBold
	self.HexLabel.Text = UIUtils.ToHex(self.Color)
	self.HexLabel.TextColor3 = tokens.SecondaryText
	self.HexLabel.TextSize = 11
	self.HexLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.HexLabel.ZIndex = 8
	self.HexLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.HexLabel.Font = tk.FontBold
		self.HexLabel.TextColor3 = tk.SecondaryText
	end))

	self.Popup = Instance.new("Frame")
	self.Popup.Name = "Popup"
	self.Popup.Position = UDim2.new(0, 0, 0, 38)
	self.Popup.Size = UDim2.new(1, 0, 0, 0)
	self.Popup.BackgroundColor3 = tokens.Elevated
	self.Popup.BorderSizePixel = 0
	self.Popup.ZIndex = 20
	self.Popup.ClipsDescendants = true
	self.Popup.Visible = false
	self.Popup.Parent = self.Container

	UIUtils.Corner(self.Popup, tokens.Corner)
	UIUtils.Stroke(self.Popup, tokens.BorderLight, 1, 0.5)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Popup.BackgroundColor3 = tk.Elevated
	end))

	self:_buildSatVal()
	self:_buildHueBar()
	self:_buildPreviewRow()

	self.Header.MouseButton1Click:Connect(function()
		self:SetOpen(not self.IsOpen)
	end)
end

function ColorPicker:_buildSatVal()
	local tokens = ThemeManager.GetTokens()

	self.SatVal = Instance.new("TextButton")
	self.SatVal.Name = "SatVal"
	self.SatVal.Position = UDim2.new(0, 10, 0, 10)
	self.SatVal.Size = UDim2.new(1, -30, 0, 110)
	self.SatVal.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1)
	self.SatVal.BorderSizePixel = 0
	self.SatVal.AutoButtonColor = false
	self.SatVal.Text = ""
	self.SatVal.ZIndex = 21
	self.SatVal.Parent = self.Popup

	UIUtils.Corner(self.SatVal, tokens.CornerSmall)

	self.SatGradient = Instance.new("UIGradient")
	self.SatGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	self.SatGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	self.SatGradient.Rotation = 0
	self.SatGradient.Parent = self.SatVal

	self.ValGradient = Instance.new("Frame")
	self.ValGradient.Name = "ValOverlay"
	self.ValGradient.Size = UDim2.new(1, 0, 1, 0)
	self.ValGradient.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.ValGradient.BorderSizePixel = 0
	self.ValGradient.ZIndex = 22
	self.ValGradient.Parent = self.SatVal

	UIUtils.Corner(self.ValGradient, tokens.CornerSmall)

	self.ValGradientObj = Instance.new("UIGradient")
	self.ValGradientObj.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
	})
	self.ValGradientObj.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	self.ValGradientObj.Rotation = 90
	self.ValGradientObj.Parent = self.ValGradient

	self.SatValKnob = Instance.new("Frame")
	self.SatValKnob.Name = "Knob"
	self.SatValKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	self.SatValKnob.Size = UDim2.new(0, 12, 0, 12)
	self.SatValKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.SatValKnob.BorderSizePixel = 0
	self.SatValKnob.ZIndex = 23
	self.SatValKnob.Parent = self.SatVal

	UIUtils.Corner(self.SatValKnob, UDim.new(1, 0))
	UIUtils.Stroke(self.SatValKnob, Color3.fromRGB(0, 0, 0), 1, 0.4)

	self:_bindSatValDrag()
end

function ColorPicker:_buildHueBar()
	local tokens = ThemeManager.GetTokens()

	self.HueBar = Instance.new("TextButton")
	self.HueBar.Name = "HueBar"
	self.HueBar.AnchorPoint = Vector2.new(1, 0)
	self.HueBar.Position = UDim2.new(1, -10, 0, 10)
	self.HueBar.Size = UDim2.new(0, 14, 0, 110)
	self.HueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.HueBar.BorderSizePixel = 0
	self.HueBar.AutoButtonColor = false
	self.HueBar.Text = ""
	self.HueBar.ZIndex = 21
	self.HueBar.Parent = self.Popup

	UIUtils.Corner(self.HueBar, tokens.CornerSmall)

	self.HueGradient = Instance.new("UIGradient")
	self.HueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	})
	self.HueGradient.Rotation = 90
	self.HueGradient.Parent = self.HueBar

	self.HueKnob = Instance.new("Frame")
	self.HueKnob.Name = "Knob"
	self.HueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	self.HueKnob.Size = UDim2.new(1, 4, 0, 6)
	self.HueKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.HueKnob.BorderSizePixel = 0
	self.HueKnob.ZIndex = 23
	self.HueKnob.Parent = self.HueBar

	UIUtils.Corner(self.HueKnob, tokens.CornerSmall)
	UIUtils.Stroke(self.HueKnob, Color3.fromRGB(0, 0, 0), 1, 0.4)

	self:_bindHueDrag()
end

function ColorPicker:_buildPreviewRow()
	local tokens = ThemeManager.GetTokens()

	local row = Instance.new("Frame")
	row.Name = "PreviewRow"
	row.Position = UDim2.new(0, 10, 0, 130)
	row.Size = UDim2.new(1, -20, 0, 28)
	row.BackgroundTransparency = 1
	row.ZIndex = 21
	row.Parent = self.Popup

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row

	self.Swatch = Instance.new("Frame")
	self.Swatch.Name = "Swatch"
	self.Swatch.Size = UDim2.new(0, 46, 1, 0)
	self.Swatch.BackgroundColor3 = self.Color
	self.Swatch.BorderSizePixel = 0
	self.Swatch.LayoutOrder = 1
	self.Swatch.ZIndex = 22
	self.Swatch.Parent = row

	UIUtils.Corner(self.Swatch, tokens.CornerSmall)
	UIUtils.Stroke(self.Swatch, tokens.BorderLight, 1, 0.5)

	self.HexInput = Instance.new("TextBox")
	self.HexInput.Name = "HexInput"
	self.HexInput.Size = UDim2.new(1, -52, 1, 0)
	self.HexInput.Position = UDim2.new(0, 52, 0, 0)
	self.HexInput.BackgroundColor3 = tokens.Background
	self.HexInput.BackgroundTransparency = 0.2
	self.HexInput.BorderSizePixel = 0
	self.HexInput.Font = tokens.FontCode
	self.HexInput.Text = UIUtils.ToHex(self.Color)
	self.HexInput.PlaceholderText = "#FFFFFF"
	self.HexInput.PlaceholderColor3 = tokens.MutedText
	self.HexInput.TextColor3 = tokens.Text
	self.HexInput.TextSize = 12
	self.HexInput.ClearTextOnFocus = false
	self.HexInput.LayoutOrder = 2
	self.HexInput.ZIndex = 22
	self.HexInput.Parent = row

	UIUtils.Corner(self.HexInput, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.HexInput.BackgroundColor3 = tk.Background
		self.HexInput.Font = tk.FontCode
		self.HexInput.TextColor3 = tk.Text
	end))

	self.HexInput.FocusLost:Connect(function(enterPressed)
		if not enterPressed then
			return
		end

		local success, color = pcall(UIUtils.FromHex, self.HexInput.Text)
		if success and color then
			self:SetColor(color, true)
		else
			self.HexInput.Text = UIUtils.ToHex(self.Color)
		end
	end)
end

function ColorPicker:_bindSatValDrag()
	local dragging = false

	local function updateFromInput(position)
		local absPos = self.SatVal.AbsolutePosition
		local absSize = self.SatVal.AbsoluteSize

		local relX = math.clamp((position.X - absPos.X) / absSize.X, 0, 1)
		local relY = math.clamp((position.Y - absPos.Y) / absSize.Y, 0, 1)

		self._sat = relX
		self._val = 1 - relY

		self:_applyHSV(true)
	end

	self.SatVal.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromInput(input.Position)
		end
	end)

	local uis = game:GetService("UserInputService")
	self._maid:GiveTask(uis.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position)
		end
	end))

	self._maid:GiveTask(uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

function ColorPicker:_bindHueDrag()
	local dragging = false

	local function updateFromInput(position)
		local absPos = self.HueBar.AbsolutePosition
		local absSize = self.HueBar.AbsoluteSize

		local relY = math.clamp((position.Y - absPos.Y) / absSize.Y, 0, 1)
		self._hue = relY

		self:_applyHSV(true)
	end

	self.HueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromInput(input.Position)
		end
	end)

	local uis = game:GetService("UserInputService")
	self._maid:GiveTask(uis.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position)
		end
	end))

	self._maid:GiveTask(uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

function ColorPicker:_applyHSV(fireEvent)
	self.Color = Color3.fromHSV(self._hue, self._sat, self._val)

	self.SatVal.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1)
	self.SatValKnob.Position = UDim2.new(self._sat, 0, 1 - self._val, 0)
	self.HueKnob.Position = UDim2.new(0.5, 0, self._hue, 0)

	self.ColorPreview.BackgroundColor3 = self.Color
	self.Swatch.BackgroundColor3 = self.Color
	self.HexLabel.Text = UIUtils.ToHex(self.Color)
	self.HexInput.Text = UIUtils.ToHex(self.Color)

	if fireEvent then
		self.OnChanged:Fire(self.Color)

		local ok, err = pcall(self.Callback, self.Color)
		if not ok then
			warn("[NexusUI] ColorPicker callback error:", err)
		end
	end
end

function ColorPicker:SetColor(color, fireEvent)
	self.Color = color

	local h, s, v = color:ToHSV()
	self._hue = h
	self._sat = s
	self._val = v

	self:_applyHSV(fireEvent)
	return self
end

function ColorPicker:GetColor()
	return self.Color
end

function ColorPicker:SetOpen(open)
	if open == self.IsOpen then
		return self
	end

	self.IsOpen = open

	if open then
		self.Popup.Visible = true
		Animator.Tween(self.Popup, { Size = UDim2.new(1, 0, 0, 168) }, 0.28, "Quart")
		Sound.Pop()
		self.OnOpened:Fire()
	else
		Animator.Tween(self.Popup, { Size = UDim2.new(1, 0, 0, 0) }, 0.22, "Quad")
		task.delay(0.22, function()
			if not self.IsOpen then
				self.Popup.Visible = false
			end
		end)
		Sound.Close()
		self.OnClosed:Fire()
	end

	return self
end

function ColorPicker:SetText(text)
	self.Text = text
	self.TextLabel.Text = text
	return self
end

function ColorPicker:Reset()
	return self:SetColor(self.DefaultColor, true)
end

function ColorPicker:Destroy()
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

return ColorPicker
