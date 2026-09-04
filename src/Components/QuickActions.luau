local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)
local Icons = require(script.Parent.Parent.Core.Icons)

local QuickActions = {}
QuickActions.__index = QuickActions
setmetatable(QuickActions, { __index = BaseComponent })

function QuickActions.new(options, window)
	options = options or {}

	local self = BaseComponent.new("QuickActions")
	setmetatable(self, { __index = function(t, k)
		if QuickActions[k] then
			return QuickActions[k]
		end
		return BaseComponent[k]
	end })

	self.Window = window
	self.Name = options.Name or "QuickActions"
	self.Position = options.Position or "TopRight"
	self.Size = options.Size or 38
	self.Spacing = options.Spacing or 8
	self.Buttons = {}

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
	}

	self:_build()

	return self
end

function QuickActions:_getRootParent()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	return ok and parent or PlayerGui
end

function QuickActions:_build()
	local tokens = ThemeManager.GetTokens()

	self.Root = Instance.new("ScreenGui")
	self.Root.Name = "NexusUI_QuickActions"
	self.Root.ResetOnSpawn = false
	self.Root.IgnoreGuiInset = true
	self.Root.DisplayOrder = 150
	self.Root.Parent = self:_getRootParent()

	self.Container = Instance.new("Frame")
	self.Container.Name = "QuickActions"
	self.Container.Size = UDim2.new(0, self.Size + 8, 0, 0)
	self.Container.AutomaticSize = Enum.AutomaticSize.Y
	self.Container.BackgroundTransparency = 1
	self.Container.ZIndex = 100

	local offset = 12

	if self.Position == "TopRight" then
		self.Container.AnchorPoint = Vector2.new(1, 0)
		self.Container.Position = UDim2.new(1, -offset, 0, offset)
	elseif self.Position == "TopLeft" then
		self.Container.AnchorPoint = Vector2.new(0, 0)
		self.Container.Position = UDim2.new(0, offset, 0, offset)
	elseif self.Position == "BottomRight" then
		self.Container.AnchorPoint = Vector2.new(1, 1)
		self.Container.Position = UDim2.new(1, -offset, 1, -offset)
	else
		self.Container.AnchorPoint = Vector2.new(0, 1)
		self.Container.Position = UDim2.new(0, offset, 1, -offset)
	end

	self.Container.Parent = self.Root

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, self.Spacing)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Container

	self.DragHandle = Instance.new("Frame")
	self.DragHandle.Name = "DragHandle"
	self.DragHandle.Size = UDim2.new(0, self.Size, 0, 6)
	self.DragHandle.BackgroundColor3 = tokens.Border
	self.DragHandle.BackgroundTransparency = 0.5
	self.DragHandle.BorderSizePixel = 0
	self.DragHandle.LayoutOrder = 0
	self.DragHandle.ZIndex = 101
	self.DragHandle.Parent = self.Container

	UIUtils.Corner(self.DragHandle, tokens.CornerCircle)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.DragHandle.BackgroundColor3 = tk.Border
	end))

	self:_bindDrag()
end

function QuickActions:_bindDrag()
	local dragging = false
	local dragStart = nil
	local startPos = nil

	self.DragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = self.Container.Position
		end
	end)

	local uis = game:GetService("UserInputService")

	self._maid:GiveTask(uis.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			self.Container.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))

	self._maid:GiveTask(uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

function QuickActions:AddButton(options)
	options = options or {}

	local tokens = ThemeManager.GetTokens()

	local buttonHolder = Instance.new("Frame")
	buttonHolder.Name = "ActionButton_" .. (options.Name or #self.Buttons + 1)
	buttonHolder.Size = UDim2.new(0, self.Size, 0, self.Size)
	buttonHolder.BackgroundColor3 = tokens.Surface
	buttonHolder.BackgroundTransparency = 0.12
	buttonHolder.BorderSizePixel = 0
	buttonHolder.LayoutOrder = #self.Buttons + 1
	buttonHolder.ZIndex = 101
	buttonHolder.Parent = self.Container

	UIUtils.Corner(buttonHolder, tokens.Corner)
	UIUtils.Stroke(buttonHolder, tokens.Border, 1, 0.65)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		buttonHolder.BackgroundColor3 = tk.Surface
	end))

	local button = Instance.new("TextButton")
	button.Name = "ClickTarget"
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.ZIndex = 102
	button.Parent = buttonHolder

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.Size = UDim2.new(0, self.Size * 0.55, 0, self.Size * 0.55)
	icon.BackgroundTransparency = 1
	icon.Image = options.Icon or Icons.Assets.Settings
	icon.ImageColor3 = tokens.Text
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 103
	icon.Parent = buttonHolder

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		icon.ImageColor3 = tk.Text
	end))

	local tooltipText = options.Tooltip
	if tooltipText then
		local Tooltip = require(script.Parent.Tooltip)
		Tooltip.new({
			Text = tooltipText,
			Target = button,
			Position = "Left",
		})
	end

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = buttonHolder

	button.MouseEnter:Connect(function()
		Animator.Tween(scale, { Scale = 1.08 }, 0.15, "Back")
		Animator.Tween(buttonHolder, { BackgroundTransparency = 0.02 }, 0.15, "Quad")
		Sound.Hover()
	end)

	button.MouseLeave:Connect(function()
		Animator.Tween(scale, { Scale = 1 }, 0.2, "Quad")
		Animator.Tween(buttonHolder, { BackgroundTransparency = 0.12 }, 0.2, "Quad")
	end)

	button.MouseButton1Click:Connect(function()
		Sound.Click()
		if options.Callback then
			pcall(options.Callback)
		end
	end)

	local handle = {
		Holder = buttonHolder,
		Button = button,
		Icon = icon,
		SetIcon = function(_, imageId)
			icon.Image = imageId
			return handle
		end,
		SetVisible = function(_, visible)
			buttonHolder.Visible = visible
			return handle
		end,
		Destroy = function()
			buttonHolder:Destroy()
		end,
	}

	table.insert(self.Buttons, handle)
	return handle
end

function QuickActions:AddWindowToggle(iconId, tooltip)
	return self:AddButton({
		Name = "WindowToggle",
		Icon = iconId or Icons.Assets.Settings,
		Tooltip = tooltip or "Toggle Window",
		Callback = function()
			if self.Window then
				self.Window:Toggle()
			end
		end,
	})
end

function QuickActions:AddProfileButton(callback, tooltip)
	return self:AddButton({
		Name = "Profile",
		Icon = Icons.Assets.User,
		Tooltip = tooltip or "Profile",
		Callback = callback or function() end,
	})
end

function QuickActions:AddYouTubeButton(url, tooltip)
	return self:AddButton({
		Name = "YouTube",
		Icon = Icons.Assets.YouTube,
		Tooltip = tooltip or "YouTube",
		Callback = function()
			if url then
				local Toast = require(script.Parent.Toast)
				Toast.new({ Text = "YouTube: " .. url, Duration = 3 })
			end
		end,
	})
end

function QuickActions:AddDiscordButton(copyText, tooltip)
	return self:AddButton({
		Name = "Discord",
		Icon = Icons.Assets.Discord,
		Tooltip = tooltip or "Copy Discord Invite",
		Callback = function()
			if copyText then
				pcall(function()
					setclipboard(copyText)
				end)

				local Toast = require(script.Parent.Toast)
				Toast.new({ Text = "Copied: " .. copyText, Duration = 2.5 })
			end
		end,
	})
end

function QuickActions:SetPosition(position)
	self.Position = position
	local offset = 12

	if position == "TopRight" then
		self.Container.AnchorPoint = Vector2.new(1, 0)
		self.Container.Position = UDim2.new(1, -offset, 0, offset)
	elseif position == "TopLeft" then
		self.Container.AnchorPoint = Vector2.new(0, 0)
		self.Container.Position = UDim2.new(0, offset, 0, offset)
	elseif position == "BottomRight" then
		self.Container.AnchorPoint = Vector2.new(1, 1)
		self.Container.Position = UDim2.new(1, -offset, 1, -offset)
	else
		self.Container.AnchorPoint = Vector2.new(0, 1)
		self.Container.Position = UDim2.new(0, offset, 1, -offset)
	end

	return self
end

function QuickActions:Destroy()
	if self.Destroyed then
		return
	end

	for _, button in ipairs(self.Buttons) do
		pcall(function() button:Destroy() end)
	end
	self.Buttons = {}

	if self.Root then
		self.Root:Destroy()
		self.Root = nil
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return QuickActions
