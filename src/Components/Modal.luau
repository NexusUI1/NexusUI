local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)
local Button = require(script.Parent.Button)

local Modal = {}
Modal.__index = Modal
setmetatable(Modal, { __index = BaseComponent })

function Modal.new(options)
	options = options or {}

	local self = BaseComponent.new("Modal")
	setmetatable(self, { __index = function(t, k)
		if Modal[k] then
			return Modal[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Modal"
	self.Title = options.Title or "Confirm"
	self.Message = options.Message or ""
	self.Size = options.Size or UDim2.fromOffset(400, 0)
	self.DismissOnBackdrop = options.DismissOnBackdrop ~= false

	self.Buttons = {}

	self.OnOpened = Signal.new()
	self.OnClosed = Signal.new()
	self.OnDismissed = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Opened = self.OnOpened,
		Closed = self.OnClosed,
		Dismissed = self.OnDismissed,
	}

	self:_build()

	return self
end

function Modal:_getRootParent()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	return ok and parent or PlayerGui
end

function Modal:_build()
	local tokens = ThemeManager.GetTokens()

	self.Root = Instance.new("ScreenGui")
	self.Root.Name = "NexusUI_Modal_" .. self.Name
	self.Root.ResetOnSpawn = false
	self.Root.IgnoreGuiInset = true
	self.Root.DisplayOrder = 300
	self.Root.Enabled = false
	self.Root.Parent = self:_getRootParent()

	self.Backdrop = Instance.new("TextButton")
	self.Backdrop.Name = "Backdrop"
	self.Backdrop.Size = UDim2.new(1, 0, 1, 0)
	self.Backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.Backdrop.BackgroundTransparency = 1
	self.Backdrop.BorderSizePixel = 0
	self.Backdrop.Text = ""
	self.Backdrop.AutoButtonColor = false
	self.Backdrop.ZIndex = 1
	self.Backdrop.Parent = self.Root

	if self.DismissOnBackdrop then
		self.Backdrop.MouseButton1Click:Connect(function()
			self:Dismiss()
		end)
	end

	self.Container = Instance.new("Frame")
	self.Container.Name = "Modal"
	self.Container.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Container.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.Container.Size = self.Size
	self.Container.AutomaticSize = Enum.AutomaticSize.Y
	self.Container.BackgroundColor3 = tokens.Background
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 2
	self.Container.Parent = self.Backdrop

	UIUtils.Corner(self.Container, tokens.CornerLarge)
	UIUtils.Stroke(self.Container, tokens.BorderLight, 1, 0.5)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Container.BackgroundColor3 = tk.Background
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.Parent = self.Container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Container

	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Name = "Title"
	self.TitleLabel.Size = UDim2.new(1, 0, 0, 22)
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.Font = tokens.FontBold
	self.TitleLabel.Text = self.Title
	self.TitleLabel.TextColor3 = tokens.Text
	self.TitleLabel.TextSize = 17
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.LayoutOrder = 1
	self.TitleLabel.ZIndex = 3
	self.TitleLabel.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TitleLabel.Font = tk.FontBold
		self.TitleLabel.TextColor3 = tk.Text
	end))

	if self.Message ~= "" then
		self.MessageLabel = Instance.new("TextLabel")
		self.MessageLabel.Name = "Message"
		self.MessageLabel.Size = UDim2.new(1, 0, 0, 0)
		self.MessageLabel.AutomaticSize = Enum.AutomaticSize.Y
		self.MessageLabel.BackgroundTransparency = 1
		self.MessageLabel.Font = tokens.Font
		self.MessageLabel.Text = self.Message
		self.MessageLabel.TextColor3 = tokens.SecondaryText
		self.MessageLabel.TextSize = 13
		self.MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.MessageLabel.TextWrapped = true
		self.MessageLabel.LayoutOrder = 2
		self.MessageLabel.ZIndex = 3
		self.MessageLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.MessageLabel.Font = tk.Font
			self.MessageLabel.TextColor3 = tk.SecondaryText
		end))
	end

	self.ButtonRow = Instance.new("Frame")
	self.ButtonRow.Name = "ButtonRow"
	self.ButtonRow.Size = UDim2.new(1, 0, 0, 36)
	self.ButtonRow.BackgroundTransparency = 1
	self.ButtonRow.LayoutOrder = 3
	self.ButtonRow.ZIndex = 3
	self.ButtonRow.Parent = self.Container

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.Padding = UDim.new(0, 8)
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonLayout.Parent = self.ButtonRow
end

function Modal:AddButton(options)
	options = options or {}

	local modalRef = self
	local button = Button.new({
		Name = options.Name or "Button",
		Text = options.Text or "Action",
		Variant = options.Variant or "Secondary",
		FullWidth = false,
		Callback = function()
			pcall(options.Callback, modalRef)
			if options.CloseOnClick ~= false then
				modalRef:Close()
			end
		end,
	}, self.ButtonRow)

	button.Container.Size = UDim2.new(0, math.max(90, #button.Text * 8 + 30), 0, 34)

	table.insert(self.Buttons, button)
	return button
end

function Modal:AddCloseButton(text, variant)
	return self:AddButton({
		Text = text or "Close",
		Variant = variant or "Secondary",
		Callback = function() end,
	})
end

function Modal:AddConfirmButton(text, callback)
	return self:AddButton({
		Text = text or "Confirm",
		Variant = "Primary",
		Callback = callback or function() end,
	})
end

function Modal:AddDangerButton(text, callback)
	return self:AddButton({
		Text = text or "Delete",
		Variant = "Danger",
		Callback = callback or function() end,
	})
end

function Modal:Open()
	if self.IsOpen then
		return self
	end

	self.IsOpen = true
	self.Root.Enabled = true

	local scale = UIUtils.Scale(self.Container, 0.9)
	self.Container.BackgroundTransparency = 0.5
	self.Backdrop.BackgroundTransparency = 1

	Animator.Tween(self.Backdrop, { BackgroundTransparency = 0.45 }, 0.25, "Quad")
	Animator.Tween(scale, { Scale = 1 }, 0.35, "Back")
	Animator.Tween(self.Container, { BackgroundTransparency = 0 }, 0.25, "Quart")

	Sound.Open()
	self.OnOpened:Fire()

	return self
end

function Modal:Close()
	if not self.IsOpen then
		return self
	end

	self.IsOpen = false

	Animator.Tween(self.Backdrop, { BackgroundTransparency = 1 }, 0.18, "Quad")
	Animator.Tween(self.Container, { BackgroundTransparency = 0.4 }, 0.18, "Quad")

	local scale = self.Container:FindFirstChildOfClass("UIScale")
	if scale then
		Animator.Tween(scale, { Scale = 0.92 }, 0.18, "Quart")
	end

	task.delay(0.2, function()
		if not self.IsOpen then
			self.Root.Enabled = false
		end
	end)

	Sound.Close()
	self.OnClosed:Fire()

	return self
end

function Modal:Dismiss()
	self:Close()
	self.OnDismissed:Fire()
	return self
end

function Modal:SetTitle(title)
	self.Title = title
	self.TitleLabel.Text = title
	return self
end

function Modal:SetMessage(message)
	self.Message = message
	if self.MessageLabel then
		self.MessageLabel.Text = message
	else
		local tokens = ThemeManager.GetTokens()

		self.MessageLabel = Instance.new("TextLabel")
		self.MessageLabel.Name = "Message"
		self.MessageLabel.Size = UDim2.new(1, 0, 0, 0)
		self.MessageLabel.AutomaticSize = Enum.AutomaticSize.Y
		self.MessageLabel.BackgroundTransparency = 1
		self.MessageLabel.Font = tokens.Font
		self.MessageLabel.Text = message
		self.MessageLabel.TextColor3 = tokens.SecondaryText
		self.MessageLabel.TextSize = 13
		self.MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.MessageLabel.TextWrapped = true
		self.MessageLabel.LayoutOrder = 2
		self.MessageLabel.ZIndex = 3
		self.MessageLabel.Parent = self.Container
	end
	return self
end

function Modal:Destroy()
	if self.Destroyed then
		return
	end

	self:Close()

	task.delay(0.25, function()
		for _, button in ipairs(self.Buttons) do
			pcall(function() button:Destroy() end)
		end
		self.Buttons = {}

		if self.Root then
			self.Root:Destroy()
		end

		if self._maid then
			self._maid:Destroy()
		end
	end)

	self.Destroyed = true
end

return Modal
