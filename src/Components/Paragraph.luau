local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)

local Paragraph = {}
Paragraph.__index = Paragraph
setmetatable(Paragraph, { __index = BaseComponent })

function Paragraph.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Paragraph")
	setmetatable(self, { __index = function(t, k)
		if Paragraph[k] then
			return Paragraph[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Paragraph"
	self.Title = options.Title or ""
	self.Text = options.Text or ""

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

function Paragraph:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Paragraph_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, 0)
	self.Container.AutomaticSize = Enum.AutomaticSize.Y
	self.Container.BackgroundColor3 = tokens.Surface
	self.Container.BackgroundTransparency = 0.5
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	UIUtils.Corner(self.Container, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Container.BackgroundColor3 = tk.Surface
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = self.Container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Container

	if self.Title ~= "" then
		self.TitleLabel = Instance.new("TextLabel")
		self.TitleLabel.Name = "Title"
		self.TitleLabel.Size = UDim2.new(1, 0, 0, 16)
		self.TitleLabel.BackgroundTransparency = 1
		self.TitleLabel.Font = tokens.FontBold
		self.TitleLabel.Text = self.Title
		self.TitleLabel.TextColor3 = tokens.Text
		self.TitleLabel.TextSize = 13
		self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.TitleLabel.TextWrapped = true
		self.TitleLabel.LayoutOrder = 1
		self.TitleLabel.ZIndex = 7
		self.TitleLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.TitleLabel.Font = tk.FontBold
			self.TitleLabel.TextColor3 = tk.Text
		end))
	end

	self.BodyLabel = Instance.new("TextLabel")
	self.BodyLabel.Name = "Body"
	self.BodyLabel.Size = UDim2.new(1, 0, 0, 0)
	self.BodyLabel.AutomaticSize = Enum.AutomaticSize.Y
	self.BodyLabel.BackgroundTransparency = 1
	self.BodyLabel.Font = tokens.Font
	self.BodyLabel.Text = self.Text
	self.BodyLabel.TextColor3 = tokens.SecondaryText
	self.BodyLabel.TextSize = 12
	self.BodyLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.BodyLabel.TextWrapped = true
	self.BodyLabel.LayoutOrder = 2
	self.BodyLabel.ZIndex = 7
	self.BodyLabel.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.BodyLabel.Font = tk.Font
		self.BodyLabel.TextColor3 = tk.SecondaryText
	end))
end

function Paragraph:SetText(text)
	self.Text = text
	self.BodyLabel.Text = text
	return self
end

function Paragraph:SetTitle(title)
	self.Title = title
	if self.TitleLabel then
		self.TitleLabel.Text = title
	end
	return self
end

function Paragraph:Destroy()
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

return Paragraph
