local ThemeManager = require(script.Parent.Theme.ThemeManager)
local Signal = require(script.Parent.Core.Signal)

local CommandPalette = {}
CommandPalette.__index = CommandPalette

CommandPalette.IsOpen = false
CommandPalette.Root = nil
CommandPalette.Commands = {}
CommandPalette.CommandCount = 0
CommandPalette.OnExecute = Signal.new()

function CommandPalette:_getRootParent()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	return ok and parent or PlayerGui
end

function CommandPalette:EnsureBuilt()
	if self.Root and self.Root.Parent then
		return
	end

	local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
	local tokens = ThemeManager.GetTokens()

	self.Root = Instance.new("ScreenGui")
	self.Root.Name = "NexusUI_CommandPalette"
	self.Root.ResetOnSpawn = false
	self.Root.IgnoreGuiInset = true
	self.Root.DisplayOrder = 600
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

	self.Backdrop.MouseButton1Click:Connect(function()
		self:Close()
	end)

	self.Panel = Instance.new("Frame")
	self.Panel.Name = "Panel"
	self.Panel.AnchorPoint = Vector2.new(0.5, 0)
	self.Panel.Position = UDim2.new(0.5, 0, 0, 120)
	self.Panel.Size = UDim2.new(0, 520, 0, 0)
	self.Panel.BackgroundColor3 = tokens.Elevated
	self.Panel.BackgroundTransparency = 0.04
	self.Panel.BorderSizePixel = 0
	self.Panel.ClipsDescendants = true
	self.Panel.ZIndex = 2
	self.Panel.Parent = self.Backdrop

	UIUtils.Corner(self.Panel, tokens.CornerLarge)
	UIUtils.Stroke(self.Panel, tokens.BorderLight, 1, 0.4)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.Parent = self.Panel

	self.SearchBox = Instance.new("TextBox")
	self.SearchBox.Name = "Search"
	self.SearchBox.Size = UDim2.new(1, 0, 0, 36)
	self.SearchBox.BackgroundColor3 = tokens.Background
	self.SearchBox.BackgroundTransparency = 0.3
	self.SearchBox.BorderSizePixel = 0
	self.SearchBox.Font = tokens.Font
	self.SearchBox.Text = ""
	self.SearchBox.PlaceholderText = "Type a command..."
	self.SearchBox.PlaceholderColor3 = tokens.MutedText
	self.SearchBox.TextColor3 = tokens.Text
	self.SearchBox.TextSize = 14
	self.SearchBox.TextXAlignment = Enum.TextXAlignment.Left
	self.SearchBox.ClearTextOnFocus = false
	self.SearchBox.ZIndex = 3
	self.SearchBox.Parent = self.Panel

	UIUtils.Corner(self.SearchBox, tokens.CornerSmall)

	local searchPadding = Instance.new("UIPadding")
	searchPadding.PaddingLeft = UDim.new(0, 12)
	searchPadding.Parent = self.SearchBox

	self.ResultsFrame = Instance.new("ScrollingFrame")
	self.ResultsFrame.Name = "Results"
	self.ResultsFrame.Position = UDim2.new(0, 0, 0, 44)
	self.ResultsFrame.Size = UDim2.new(1, 0, 0, 200)
	self.ResultsFrame.BackgroundTransparency = 1
	self.ResultsFrame.BorderSizePixel = 0
	self.ResultsFrame.ScrollBarThickness = 2
	self.ResultsFrame.ScrollBarImageColor3 = tokens.Accent
	self.ResultsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.ResultsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.ResultsFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	self.ResultsFrame.ZIndex = 3
	self.ResultsFrame.Parent = self.Panel

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.ResultsFrame

	self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		self:_filterResults(self.SearchBox.Text)
	end)

	self.SearchBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local results = self:_getFiltered(self.SearchBox.Text)
			if #results > 0 then
				self:_executeCommand(results[1].Command)
			end
		end
	end)

	self._selectedIndex = 1
	self._filteredResults = {}
end

function CommandPalette:Register(options)
	assert(type(options.Name) == "string", "Command must have a Name")

	local command = {
		Name = options.Name,
		Description = options.Description or "",
		Category = options.Category or "General",
		Keywords = options.Keywords or {},
		Shortcut = options.Shortcut,
		Callback = options.Callback or function() end,
		Id = CommandPalette.CommandCount + 1,
	}

	CommandPalette.CommandCount = CommandPalette.CommandCount + 1
	table.insert(CommandPalette.Commands, command)

	return command
end

function CommandPalette:Unregister(command)
	for i, cmd in ipairs(CommandPalette.Commands) do
		if cmd == command or cmd.Id == command then
			table.remove(CommandPalette.Commands, i)
			return true
		end
	end
	return false
end

function CommandPalette:_fuzzyScore(query, text)
	if query == "" then
		return 1
	end

	query = query:lower()
	text = text:lower()

	local queryIndex = 1
	local score = 0
	local lastMatch = 0

	for i = 1, #text do
		if queryIndex > #query then
			break
		end

		if text:sub(i, i) == query:sub(queryIndex, queryIndex) then
			score = score + (i == lastMatch + 1 and 3 or 1)
			lastMatch = i
			queryIndex = queryIndex + 1
		end
	end

	if queryIndex <= #query then
		return 0
	end

	return score / #query
end

function CommandPalette:_getFiltered(query)
	local results = {}

	for _, command in ipairs(CommandPalette.Commands) do
		local nameScore = self:_fuzzyScore(query, command.Name)
		local descScore = self:_fuzzyScore(query, command.Description) * 0.5
		local keywordScore = 0

		for _, keyword in ipairs(command.Keywords) do
			keywordScore = math.max(keywordScore, self:_fuzzyScore(query, keyword) * 0.7)
		end

		local totalScore = math.max(nameScore, descScore, keywordScore)
		if totalScore > 0 then
			table.insert(results, { Command = command, Score = totalScore })
		end
	end

	table.sort(results, function(a, b)
		return a.Score > b.Score
	end)

	return results
end

function CommandPalette:_filterResults(query)
	local tokens = ThemeManager.GetTokens()

	for _, child in ipairs(self.ResultsFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local results = self:_getFiltered(query)
	self._filteredResults = results

	for index, result in ipairs(results) do
		if index > 8 then
			break
		end

		local command = result.Command

		local resultButton = Instance.new("TextButton")
		resultButton.Name = "Command_" .. command.Name
		resultButton.Size = UDim2.new(1, 0, 0, 40)
		resultButton.BackgroundColor3 = tokens.SurfaceLight
		resultButton.BackgroundTransparency = index == 1 and 0.7 or 1
		resultButton.BorderSizePixel = 0
		resultButton.AutoButtonColor = false
		resultButton.Font = tokens.Font
		resultButton.Text = ""
		resultButton.LayoutOrder = index
		resultButton.ZIndex = 4
		resultButton.Parent = self.ResultsFrame

		UIUtils.Corner(resultButton, tokens.CornerSmall)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Position = UDim2.new(0, 12, 0, 6)
		nameLabel.Size = UDim2.new(1, -24, 0, 16)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = tokens.FontBold
		nameLabel.Text = command.Name
		nameLabel.TextColor3 = tokens.Text
		nameLabel.TextSize = 13
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
		nameLabel.ZIndex = 5
		nameLabel.Parent = resultButton

		if command.Description ~= "" then
			local descLabel = Instance.new("TextLabel")
			descLabel.Name = "Description"
			descLabel.Position = UDim2.new(0, 12, 0, 22)
			descLabel.Size = UDim2.new(1, -24, 0, 14)
			descLabel.BackgroundTransparency = 1
			descLabel.Font = tokens.Font
			descLabel.Text = command.Description
			descLabel.TextColor3 = tokens.SecondaryText
			descLabel.TextSize = 11
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.TextTruncate = Enum.TextTruncate.AtEnd
			descLabel.ZIndex = 5
			descLabel.Parent = resultButton
		end

		if command.Shortcut then
			local shortcutLabel = Instance.new("TextLabel")
			shortcutLabel.Name = "Shortcut"
			shortcutLabel.AnchorPoint = Vector2.new(1, 0.5)
			shortcutLabel.Position = UDim2.new(1, -12, 0.5, 0)
			shortcutLabel.Size = UDim2.new(0, 80, 0, 14)
			shortcutLabel.BackgroundTransparency = 1
			shortcutLabel.Font = tokens.Font
			shortcutLabel.Text = command.Shortcut
			shortcutLabel.TextColor3 = tokens.MutedText
			shortcutLabel.TextSize = 10
			shortcutLabel.TextXAlignment = Enum.TextXAlignment.Right
			shortcutLabel.ZIndex = 5
			shortcutLabel.Parent = resultButton
		end

		resultButton.MouseEnter:Connect(function()
			Animator.Tween(resultButton, { BackgroundTransparency = 0.7 }, 0.1, "Quad")
		end)

		resultButton.MouseLeave:Connect(function()
			Animator.Tween(resultButton, { BackgroundTransparency = 1 }, 0.1, "Quad")
		end)

		resultButton.MouseButton1Click:Connect(function()
			self:_executeCommand(command)
		end)
	end
end

function CommandPalette:_executeCommand(command)
	self:Close()
	self.CommandCount = CommandPalette.CommandCount
	Sound.Click()

	self.OnExecute:Fire(command)

	task.spawn(function()
		pcall(command.Callback)
	end)
end

function CommandPalette:Open()
	if self.IsOpen then
		return
	end

	self:EnsureBuilt()
	self.IsOpen = true
	self.Root.Enabled = true

	self.SearchBox.Text = ""
	self:_filterResults("")

	self.Backdrop.BackgroundTransparency = 1
	self.Panel.Size = UDim2.new(0, 520, 0, 0)

	Animator.Tween(self.Backdrop, { BackgroundTransparency = 0.4 }, 0.2, "Quad")
	Animator.Tween(self.Panel, { Size = UDim2.new(0, 520, 0, 258) }, 0.3, "Quart")

	task.delay(0.1, function()
		if self.IsOpen then
			self.SearchBox:CaptureFocus()
		end
	end)

	Sound.Open()
end

function CommandPalette:Close()
	if not self.IsOpen then
		return
	end

	self.IsOpen = false

	Animator.Tween(self.Backdrop, { BackgroundTransparency = 1 }, 0.15, "Quad")
	Animator.Tween(self.Panel, { Size = UDim2.new(0, 520, 0, 0) }, 0.18, "Quart")

	task.delay(0.2, function()
		if not self.IsOpen and self.Root then
			self.Root.Enabled = false
		end
	end)

	Sound.Close()
end

function CommandPalette:Toggle()
	if self.IsOpen then
		self:Close()
	else
		self:Open()
	end
end

local UIUtils, Animator, Sound

local function lazyRequire()
	if not UIUtils then
		UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
		Animator = require(script.Parent.Parent.Animation.Animator)
		Sound = require(script.Parent.Parent.Utilities.Sound)
	end
end

local originalOpen = CommandPalette.Open
CommandPalette.Open = function(self, ...)
	lazyRequire()
	return originalOpen(self, ...)
end

local originalEnsureBuilt = CommandPalette.EnsureBuilt
CommandPalette.EnsureBuilt = function(self, ...)
	lazyRequire()
	return originalEnsureBuilt(self, ...)
end

function CommandPalette:BindKeybind(keyCode, modifier)
	keyCode = keyCode or Enum.KeyCode.K
	modifier = modifier or Enum.KeyCode.LeftControl

	local UserInputService = game:GetService("UserInputService")

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end

		if input.KeyCode == keyCode and UserInputService:IsKeyDown(modifier) then
			self:Toggle()
		end
	end)
end

function CommandPalette:Destroy()
	if self.Root then
		self.Root:Destroy()
		self.Root = nil
	end

	self.IsOpen = false
	CommandPalette.Commands = {}
end

return CommandPalette
