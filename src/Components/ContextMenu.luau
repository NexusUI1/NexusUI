local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local ContextMenu = {}
ContextMenu.__index = ContextMenu
setmetatable(ContextMenu, { __index = BaseComponent })

ContextMenu.Active = nil

local function getRoot()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	if not ok or parent == nil then
		parent = PlayerGui
	end

	local existing = parent:FindFirstChild("NexusUI_ContextMenu")
	if existing then
		return existing
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NexusUI_ContextMenu"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 400
	screenGui.Parent = parent

	return screenGui
end

function ContextMenu.new(options)
	options = options or {}

	local self = BaseComponent.new("ContextMenu")
	setmetatable(self, { __index = function(t, k)
		if ContextMenu[k] then
			return ContextMenu[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "ContextMenu"
	self.Items = options.Items or {}
	self.ItemHeight = options.ItemHeight or 30

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
	}

	return self
end

function ContextMenu:_build()
	if self.Frame and self.Frame.Parent then
		return
	end

	local tokens = ThemeManager.GetTokens()

	local totalHeight = 0
	for _, item in ipairs(self.Items) do
		if item.Divider then
			totalHeight = totalHeight + 9
		else
			totalHeight = totalHeight + self.ItemHeight + 2
		end
	end

	self.Frame = Instance.new("Frame")
	self.Frame.Name = "ContextMenu"
	self.Frame.Size = UDim2.new(0, 190, 0, totalHeight + 8)
	self.Frame.BackgroundColor3 = tokens.Elevated
	self.Frame.BackgroundTransparency = 0.03
	self.Frame.BorderSizePixel = 0
	self.Frame.ZIndex = 400
	self.Frame.Visible = false
	self.Frame.Parent = getRoot()

	UIUtils.Corner(self.Frame, tokens.Corner)
	UIUtils.Stroke(self.Frame, tokens.BorderLight, 1, 0.45)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Frame.BackgroundColor3 = tk.Elevated
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 4)
	padding.Parent = self.Frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Frame

	for index, item in ipairs(self.Items) do
		if item.Divider then
			local divider = Instance.new("Frame")
			divider.Name = "Divider"
			divider.Size = UDim2.new(1, 0, 0, 1)
			divider.BackgroundColor3 = tokens.Border
			divider.BackgroundTransparency = 0.5
			divider.BorderSizePixel = 0
			divider.LayoutOrder = index
			divider.ZIndex = 401
			divider.Parent = self.Frame

		elseif item.Text then
			local itemButton = Instance.new("TextButton")
			itemButton.Name = "Item_" .. item.Text
			itemButton.Size = UDim2.new(1, 0, 0, self.ItemHeight)
			itemButton.BackgroundColor3 = tokens.SurfaceLight
			itemButton.BackgroundTransparency = 1
			itemButton.BorderSizePixel = 0
			itemButton.AutoButtonColor = false
			itemButton.Font = tokens.Font
			itemButton.Text = item.Text
			itemButton.TextColor3 = item.Disabled and tokens.MutedText or tokens.Text
			itemButton.TextSize = 13
			itemButton.TextXAlignment = Enum.TextXAlignment.Left
			itemButton.LayoutOrder = index
			itemButton.ZIndex = 401
			itemButton.Parent = self.Frame

			UIUtils.Corner(itemButton, tokens.CornerSmall)

			local textPadding = Instance.new("UIPadding")
			textPadding.PaddingLeft = UDim.new(0, 10)
			textPadding.Parent = itemButton

			if not item.Disabled then
				itemButton.MouseEnter:Connect(function()
					Animator.Tween(itemButton, { BackgroundTransparency = 0.75 }, 0.1, "Quad")
				end)

				itemButton.MouseLeave:Connect(function()
					Animator.Tween(itemButton, { BackgroundTransparency = 1 }, 0.1, "Quad")
				end)

				itemButton.MouseButton1Click:Connect(function()
					Sound.Click()
					self:Close()
					if item.Callback then
						task.spawn(function()
							pcall(item.Callback, item)
						end)
					end
				end)
			end
		end
	end
end

function ContextMenu:Open(position)
	if ContextMenu.Active and ContextMenu.Active ~= self then
		ContextMenu.Active:Close()
	end

	self:_build()
	ContextMenu.Active = self

	local tokens = ThemeManager.GetTokens()

	local uis = game:GetService("UserInputService")
	local mousePos = position or uis:GetMouseLocation()

	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)

	local frameWidth = self.Frame.Size.X.Offset
	local frameHeight = self.Frame.Size.Y.Offset

	local posX = math.clamp(mousePos.X, 8, viewport.X - frameWidth - 8)
	local posY = math.clamp(mousePos.Y, 8, viewport.Y - frameHeight - 8)

	self.Frame.Position = UDim2.new(0, posX, 0, posY)
	self.Frame.Visible = true

	local scale = UIUtils.Scale(self.Frame, 0.85)
	self.Frame.BackgroundTransparency = 0.5

	Animator.Tween(scale, { Scale = 1 }, 0.18, "Back")
	Animator.Tween(self.Frame, { BackgroundTransparency = 0.03 }, 0.15, "Quad")

	self:_bindDismiss()

	Sound.Pop()

	return self
end

function ContextMenu:_bindDismiss()
	local uis = game:GetService("UserInputService")

	task.defer(function()
		local connection = uis.InputBegan:Connect(function(input, processed)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.Touch then

				local frame = self.Frame
				if not frame or not frame.Parent then
					connection:Disconnect()
					return
				end

				local absPos = frame.AbsolutePosition
				local absSize = frame.AbsoluteSize
				local pos = input.Position

				local inside = pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
					and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y

				if not inside then
					self:Close()
					connection:Disconnect()
				end
			end
		end)

		self._maid:GiveTask(connection)
	end)
end

function ContextMenu:Close()
	if ContextMenu.Active == self then
		ContextMenu.Active = nil
	end

	if self.Frame and self.Frame.Parent then
		local scale = self.Frame:FindFirstChildOfClass("UIScale")
		if scale then
			Animator.Tween(scale, { Scale = 0.85 }, 0.12, "Quad")
		end
		Animator.Tween(self.Frame, { BackgroundTransparency = 0.5 }, 0.12, "Quad")

		task.delay(0.13, function()
			if self.Frame then
				self.Frame.Visible = false
			end
		end)
	end

	return self
end

function ContextMenu:SetItems(items)
	self.Items = items or {}

	if self.Frame then
		self.Frame:Destroy()
		self.Frame = nil
	end

	return self
end

function ContextMenu:Destroy()
	if self.Destroyed then
		return
	end

	self:Close()

	if self.Frame then
		self.Frame:Destroy()
		self.Frame = nil
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

ContextMenu.CloseAll = function()
	if ContextMenu.Active then
		ContextMenu.Active:Close()
	end
end

return ContextMenu
