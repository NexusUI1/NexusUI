local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)

local Section = {}
Section.__index = Section
setmetatable(Section, { __index = BaseComponent })

function Section.new(options, tab)
	options = options or {}

	local self = BaseComponent.new("Section")
	setmetatable(self, { __index = function(t, k)
		if Section[k] then
			return Section[k]
		end
		return BaseComponent[k]
	end })

	self.Tab = tab
	self.Name = options.Name or "Section"
	self.Icon = options.Icon
	self.Description = options.Description or ""
	self.Collapsible = options.Collapsible ~= false
	self.Collapsed = options.Collapsed or false
	self.Side = options.Side or "Left"

	self.Elements = {}

	self.OnToggled = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Toggled = self.OnToggled,
	}

	self:_build()

	return self
end

function Section:_build()
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Section_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, 0)
	self.Container.AutomaticSize = Enum.AutomaticSize.Y
	self.Container.BackgroundColor3 = tokens.Surface
	self.Container.BackgroundTransparency = 0.4
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 5
	self.Container.ClipsDescendants = true
	self.Container.Parent = self.Tab.Scroll

	UIUtils.Corner(self.Container, tokens.Corner)
	UIUtils.Stroke(self.Container, tokens.Border, 1, 0.75)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Container.BackgroundColor3 = tk.Surface
	end))

	self.Header = Instance.new("TextButton")
	self.Header.Name = "Header"
	self.Header.Size = UDim2.new(1, 0, 0, 34)
	self.Header.BackgroundColor3 = tokens.SurfaceLight
	self.Header.BackgroundTransparency = 1
	self.Header.BorderSizePixel = 0
	self.Header.AutoButtonColor = false
	self.Header.Text = ""
	self.Header.ZIndex = 6
	self.Header.Parent = self.Container

	local headerLayout = Instance.new("UIListLayout")
	headerLayout.FillDirection = Enum.FillDirection.Horizontal
	headerLayout.Padding = UDim.new(0, 6)
	headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	headerLayout.Parent = self.Header

	local headerPadding = Instance.new("UIPadding")
	headerPadding.PaddingLeft = UDim.new(0, 10)
	headerPadding.PaddingRight = UDim.new(0, 10)
	headerPadding.Parent = self.Header

	if self.Icon then
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.Image = self.Icon
		icon.Size = UDim2.new(0, 16, 0, 16)
		icon.ImageColor3 = tokens.Accent
		icon.ScaleType = Enum.ScaleType.Fit
		icon.LayoutOrder = 1
		icon.ZIndex = 7
		icon.Parent = self.Header

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			icon.ImageColor3 = tk.Accent
		end))
	end

	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Name = "Title"
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.Size = UDim2.new(1, -30, 0, 16)
	self.TitleLabel.Font = tokens.FontBold
	self.TitleLabel.Text = self.Name
	self.TitleLabel.TextColor3 = tokens.Text
	self.TitleLabel.TextSize = 13
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	self.TitleLabel.LayoutOrder = 2
	self.TitleLabel.ZIndex = 7
	self.TitleLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TitleLabel.Font = tk.FontBold
		self.TitleLabel.TextColor3 = tk.Text
	end))

	if self.Collapsible then
		self.Chevron = Instance.new("TextLabel")
		self.Chevron.Name = "Chevron"
		self.Chevron.BackgroundTransparency = 1
		self.Chevron.Size = UDim2.new(0, 20, 1, 0)
		self.Chevron.Font = tokens.FontBold
		self.Chevron.Text = "-"
		self.Chevron.TextColor3 = tokens.SecondaryText
		self.Chevron.TextSize = 14
		self.Chevron.LayoutOrder = 3
		self.Chevron.ZIndex = 7
		self.Chevron.Parent = self.Header

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.Chevron.TextColor3 = tk.SecondaryText
		end))

		self.Header.MouseButton1Click:Connect(function()
			self:Toggle()
		end)
	end

	self.Body = Instance.new("Frame")
	self.Body.Name = "Body"
	self.Body.Size = UDim2.new(1, 0, 0, 0)
	self.Body.AutomaticSize = Enum.AutomaticSize.Y
	self.Body.BackgroundTransparency = 1
	self.Body.BorderSizePixel = 0
	self.Body.ZIndex = 6
	self.Body.Parent = self.Container

	local bodyPadding = Instance.new("UIPadding")
	bodyPadding.PaddingLeft = UDim.new(0, 8)
	bodyPadding.PaddingRight = UDim.new(0, 8)
	bodyPadding.PaddingBottom = UDim.new(0, 8)
	bodyPadding.Parent = self.Body

	self.BodyLayout = Instance.new("UIListLayout")
	self.BodyLayout.FillDirection = Enum.FillDirection.Vertical
	self.BodyLayout.Padding = UDim.new(0, 6)
	self.BodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	self.BodyLayout.Parent = self.Body

	if self.Description ~= "" then
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "Description"
		descLabel.BackgroundTransparency = 1
		descLabel.Size = UDim2.new(1, -20, 0, 14)
		descLabel.Position = UDim2.new(0, 10, 0, 30)
		descLabel.Font = tokens.Font
		descLabel.Text = self.Description
		descLabel.TextColor3 = tokens.SecondaryText
		descLabel.TextSize = 11
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.AutomaticSize = Enum.AutomaticSize.Y
		descLabel.LayoutOrder = 0
		descLabel.ZIndex = 6
		descLabel.Parent = self.Body

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			descLabel.TextColor3 = tk.SecondaryText
		end))
	end

	if self.Collapsed then
		task.defer(function()
			self:SetCollapsed(true, true)
		end)
	end
end

function Section:Toggle()
	self:SetCollapsed(not self.Collapsed)
	Sound.Click()
	self.OnToggled:Fire(self.Collapsed)
	return self
end

function Section:SetCollapsed(collapsed, instant)
	self.Collapsed = collapsed

	if collapsed then
		self.Body.Visible = false
		if self.Chevron then
			self.Chevron.Text = "+"
		end
	else
		self.Body.Visible = true
		if self.Chevron then
			self.Chevron.Text = "-"
		end
	end

	return self
end

function Section:SetName(name)
	self.Name = name
	self.TitleLabel.Text = name
	return self
end

function Section:AddButton(options)
	options = options or {}
	local Button = require(script.Parent.Button)
	local button = Button.new(options, self.Body)
	button:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, button)
	return button
end

function Section:AddToggle(options)
	options = options or {}
	local Toggle = require(script.Parent.Toggle)
	local toggle = Toggle.new(options, self.Body)
	toggle:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, toggle)
	return toggle
end

function Section:AddCheckbox(options)
	options = options or {}
	local Checkbox = require(script.Parent.Checkbox)
	local checkbox = Checkbox.new(options, self.Body)
	checkbox:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, checkbox)
	return checkbox
end

function Section:AddSlider(options)
	options = options or {}
	local Slider = require(script.Parent.Slider)
	local slider = Slider.new(options, self.Body)
	slider:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, slider)
	return slider
end

function Section:AddDropdown(options)
	options = options or {}
	local Dropdown = require(script.Parent.Dropdown)
	local dropdown = Dropdown.new(options, self.Body)
	dropdown:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, dropdown)
	return dropdown
end

function Section:AddMultiDropdown(options)
	options = options or {}
	local MultiDropdown = require(script.Parent.MultiDropdown)
	local dropdown = MultiDropdown.new(options, self.Body)
	dropdown:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, dropdown)
	return dropdown
end

function Section:AddTextBox(options)
	options = options or {}
	local TextBox = require(script.Parent.TextBox)
	local textBox = TextBox.new(options, self.Body)
	textBox:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, textBox)
	return textBox
end

function Section:AddSearchBox(options)
	options = options or {}
	local SearchBox = require(script.Parent.SearchBox)
	local searchBox = SearchBox.new(options, self.Body)
	searchBox:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, searchBox)
	return searchBox
end

function Section:AddKeybind(options)
	options = options or {}
	local Keybind = require(script.Parent.Keybind)
	local keybind = Keybind.new(options, self.Body)
	keybind:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, keybind)
	return keybind
end

function Section:AddColorPicker(options)
	options = options or {}
	local ColorPicker = require(script.Parent.ColorPicker)
	local picker = ColorPicker.new(options, self.Body)
	picker:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, picker)
	return picker
end

function Section:AddLabel(options)
	options = options or {}
	local Label = require(script.Parent.Label)
	local label = Label.new(options, self.Body)
	label:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, label)
	return label
end

function Section:AddParagraph(options)
	options = options or {}
	local Paragraph = require(script.Parent.Paragraph)
	local paragraph = Paragraph.new(options, self.Body)
	paragraph:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, paragraph)
	return paragraph
end

function Section:AddDivider(options)
	options = options or {}
	local Divider = require(script.Parent.Divider)
	local divider = Divider.new(options, self.Body)
	divider:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, divider)
	return divider
end

function Section:AddBadge(options)
	options = options or {}
	local Badge = require(script.Parent.Badge)
	local badge = Badge.new(options, self.Body)
	badge:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, badge)
	return badge
end

function Section:AddCard(options)
	options = options or {}
	local Card = require(script.Parent.Card)
	local card = Card.new(options, self.Body)
	card:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, card)
	return card
end

function Section:AddImage(options)
	options = options or {}
	local Image = require(script.Parent.Image)
	local image = Image.new(options, self.Body)
	image:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, image)
	return image
end

function Section:AddProgressBar(options)
	options = options or {}
	local ProgressBar = require(script.Parent.ProgressBar)
	local progress = ProgressBar.new(options, self.Body)
	progress:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, progress)
	return progress
end

function Section:AddLoadingIndicator(options)
	options = options or {}
	local LoadingIndicator = require(script.Parent.LoadingIndicator)
	local loading = LoadingIndicator.new(options, self.Body)
	loading:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, loading)
	return loading
end

function Section:Destroy()
	if self.Destroyed then
		return
	end

	for _, element in ipairs(self.Elements) do
		pcall(function() element:Destroy() end)
	end
	self.Elements = {}

	if self.Container then
		self.Container:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return Section
