local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)

local Divider = {}
Divider.__index = Divider
setmetatable(Divider, { __index = BaseComponent })

function Divider.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Divider")
	setmetatable(self, { __index = function(t, k)
		if Divider[k] then
			return Divider[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Divider"
	self.Text = options.Text or ""
	self.Orientation = options.Orientation or "Horizontal"

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

function Divider:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Divider"
	self.Container.BackgroundTransparency = 1
	self.Container.ZIndex = 6

	if self.Orientation == "Horizontal" then
		self.Container.Size = UDim2.new(1, 0, 0, self.Text ~= "" and 18 or 1)
	else
		self.Container.Size = UDim2.new(0, 1, 1, 0)
	end

	self.Container.Parent = parent

	if self.Orientation == "Horizontal" then
		local line = Instance.new("Frame")
		line.Name = "Line"
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = self.Text ~= "" and UDim2.new(0, 0, 1, -1) or UDim2.new(0, 0, 0, 0)
		line.AnchorPoint = Vector2.new(0, 0)
		line.BackgroundColor3 = tokens.Border
		line.BackgroundTransparency = 0.4
		line.BorderSizePixel = 0
		line.ZIndex = 7
		line.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			line.BackgroundColor3 = tk.Border
		end))

		if self.Text ~= "" then
			local textLabel = Instance.new("TextLabel")
			textLabel.Name = "Text"
			textLabel.BackgroundTransparency = 1
			textLabel.Size = UDim2.new(0, 200, 0, 16)
			textLabel.Position = UDim2.new(0.5, 0, 0, 0)
			textLabel.AnchorPoint = Vector2.new(0.5, 0)
			textLabel.Font = tokens.FontBold
			textLabel.Text = self.Text
			textLabel.TextColor3 = tokens.MutedText
			textLabel.TextSize = 11
			textLabel.ZIndex = 7
			textLabel.Parent = self.Container

			self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
				textLabel.Font = tk.FontBold
				textLabel.TextColor3 = tk.MutedText
			end))
		end
	else
		local line = Instance.new("Frame")
		line.Name = "Line"
		line.Size = UDim2.new(0, 1, 1, 0)
		line.BackgroundColor3 = tokens.Border
		line.BackgroundTransparency = 0.4
		line.BorderSizePixel = 0
		line.ZIndex = 7
		line.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			line.BackgroundColor3 = tk.Border
		end))
	end
end

function Divider:SetText(text)
	self.Text = text
	if self.Container then
		self.Container:Destroy()
	end
	self:_build(self.Container.Parent)
	return self
end

function Divider:Destroy()
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

return Divider
