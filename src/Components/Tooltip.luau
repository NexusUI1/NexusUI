local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)

local Tooltip = {}
Tooltip.__index = Tooltip
setmetatable(Tooltip, { __index = BaseComponent })

Tooltip.Active = nil

local function getRoot()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	if not ok or parent == nil then
		parent = PlayerGui
	end

	local existing = parent:FindFirstChild("NexusUI_Tooltips")
	if existing then
		return existing
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NexusUI_Tooltips"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 500
	screenGui.Parent = parent

	return screenGui
end

function Tooltip.new(options)
	options = options or {}

	local self = BaseComponent.new("Tooltip")
	setmetatable(self, { __index = function(t, k)
		if Tooltip[k] then
			return Tooltip[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Tooltip"
	self.Text = options.Text or "Tooltip"
	self.Target = options.Target
	self.Position = options.Position or "Top"
	self.Delay = options.Delay or 0.35

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
	}

	if self.Target then
		self:BindTo(self.Target)
	end

	return self
end

function Tooltip:_build()
	if self.Frame and self.Frame.Parent then
		return
	end

	local tokens = ThemeManager.GetTokens()

	self.Frame = Instance.new("Frame")
	self.Frame.Name = "Tooltip"
	self.Frame.AnchorPoint = Vector2.new(0.5, 1)
	self.Frame.Size = UDim2.new(0, 0, 0, 0)
	self.Frame.AutomaticSize = Enum.AutomaticSize.XY
	self.Frame.BackgroundColor3 = tokens.Elevated
	self.Frame.BackgroundTransparency = 0.04
	self.Frame.BorderSizePixel = 0
	self.Frame.ZIndex = 500
	self.Frame.Visible = false
	self.Frame.Parent = getRoot()

	UIUtils.Corner(self.Frame, tokens.CornerSmall)
	UIUtils.Stroke(self.Frame, tokens.BorderLight, 1, 0.5)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Frame.BackgroundColor3 = tk.Elevated
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = self.Frame

	self.Label = Instance.new("TextLabel")
	self.Label.Name = "Text"
	self.Label.Size = UDim2.new(0, 0, 0, 0)
	self.Label.AutomaticSize = Enum.AutomaticSize.XY
	self.Label.BackgroundTransparency = 1
	self.Label.Font = tokens.Font
	self.Label.Text = self.Text
	self.Label.TextColor3 = tokens.Text
	self.Label.TextSize = 12
	self.Label.TextWrapped = false
	self.Label.ZIndex = 501
	self.Label.Parent = self.Frame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Label.Font = tk.Font
		self.Label.TextColor3 = tk.Text
	end))
end

function Tooltip:SetText(text)
	self.Text = text
	if self.Label then
		self.Label.Text = text
	end
	return self
end

function Tooltip:Show()
	if Tooltip.Active and Tooltip.Active ~= self then
		Tooltip.Active:Hide()
	end

	self:_build()
	Tooltip.Active = self

	local tokens = ThemeManager.GetTokens()

	local targetFrame = self.Target
	if not targetFrame then
		return self
	end

	local mousePos = game:GetService("UserInputService"):GetMouseLocation()

	local posX = mousePos.X
	local posY = mousePos.Y

	if self.Position == "Top" then
		self.Frame.AnchorPoint = Vector2.new(0.5, 1)
		posY = posY - 12
	elseif self.Position == "Bottom" then
		self.Frame.AnchorPoint = Vector2.new(0.5, 0)
		posY = posY + 12
	elseif self.Position == "Left" then
		self.Frame.AnchorPoint = Vector2.new(1, 0.5)
		posX = posX - 12
	elseif self.Position == "Right" then
		self.Frame.AnchorPoint = Vector2.new(0, 0.5)
		posX = posX + 12
	end

	self.Frame.Position = UDim2.new(0, posX, 0, posY)
	self.Frame.Visible = true
	self.Frame.BackgroundTransparency = 1

	if self.Label then
		self.Label.TextTransparency = 1
		Animator.Tween(self.Label, { TextTransparency = 0 }, 0.18, "Quad")
	end

	Animator.Tween(self.Frame, { BackgroundTransparency = 0.04 }, 0.18, "Quad")

	return self
end

function Tooltip:Hide()
	if Tooltip.Active == self then
		Tooltip.Active = nil
	end

	if self.Frame and self.Frame.Parent then
		self.Frame.Visible = false
	end

	return self
end

function Tooltip:BindTo(target)
	self.Target = target

	if not target then
		return self
	end

	local showThread = nil

	target.MouseEnter:Connect(function()
		showThread = task.delay(self.Delay, function()
			self:Show()
		end)
	end)

	target.MouseLeave:Connect(function()
		if showThread then
			task.cancel(showThread)
			showThread = nil
		end
		self:Hide()
	end)

	target.MouseButton1Down:Connect(function()
		if showThread then
			task.cancel(showThread)
			showThread = nil
		end
		self:Hide()
	end)

	return self
end

function Tooltip:Destroy()
	if self.Destroyed then
		return
	end

	self:Hide()

	if self.Frame then
		self.Frame:Destroy()
		self.Frame = nil
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

Tooltip.HideAll = function()
	if Tooltip.Active then
		Tooltip.Active:Hide()
	end
end

return Tooltip
