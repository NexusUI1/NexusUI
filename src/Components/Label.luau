local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)

local Label = {}
Label.__index = Label
setmetatable(Label, { __index = BaseComponent })

function Label.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Label")
	setmetatable(self, { __index = function(t, k)
		if Label[k] then
			return Label[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Label"
	self.Text = options.Text or ""
	self.Size = options.Size or UDim2.new(1, 0, 0, 20)
	self.TextSize = options.TextSize
	self.TextColor = options.TextColor
	self.Alignment = options.Alignment or Enum.TextXAlignment.Left
	self.Wrapped = options.Wrapped or false
	self.RichText = options.RichText or false

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
	}

	self:_build(parent)

	return self
end

function Label:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("TextLabel")
	self.Container.Name = "Label_" .. self.Name
	self.Container.Size = self.Size
	self.Container.BackgroundTransparency = 1
	self.Container.Font = self.TextSize and tokens.Font or tokens.FontBold
	self.Container.Text = self.Text
	self.Container.TextColor3 = self.TextColor or tokens.Text
	self.Container.TextSize = self.TextSize or tokens.TextSize
	self.Container.TextXAlignment = self.Alignment
	self.Container.TextWrapped = self.Wrapped
	self.Container.RichText = self.RichText
	self.Container.AutomaticSize = self.Wrapped and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Container.Font = self.TextSize and tk.Font or tk.FontBold
		self.Container.TextColor3 = self.TextColor or tk.Text
		self.Container.TextSize = self.TextSize or tk.TextSize
	end))
end

function Label:SetText(text)
	self.Text = text
	self.Container.Text = text
	return self
end

function Label:GetText()
	return self.Container.Text
end

function Label:SetTextColor(color)
	self.TextColor = color
	self.Container.TextColor3 = color
	return self
end

function Label:SetTextSize(size)
	self.TextSize = size
	self.Container.TextSize = size
	return self
end

function Label:SetAlignment(alignment)
	self.Alignment = alignment
	self.Container.TextXAlignment = alignment
	return self
end

function Label:Destroy()
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

return Label
