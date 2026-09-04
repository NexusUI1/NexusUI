local Debug = {}
Debug.__index = Debug

Debug.Enabled = false
Debug.Frame = nil
Debug.Root = nil
Debug.Connection = nil
Debug.UpdateInterval = 0.5

function Debug:CountConnections()
	local ok, Signal = pcall(function()
		return require(script.Parent.Parent.Core.Signal)
	end)

	if ok and Signal then
		return Signal.GlobalConnections or 0
	end

	return 0
end

function Debug:CountComponents()
	local ok, Component = pcall(function()
		return require(script.Parent.Parent.Core.Component)
	end)

	if ok and Component and Component.Count then
		return Component.Count()
	end

	return 0
end

function Debug:CountTweens()
	local ok, Animator = pcall(function()
		return require(script.Parent.Parent.Animation.Animator)
	end)

	if ok and Animator and Animator.ActiveCount then
		return Animator.ActiveCount()
	end

	return 0
end

function Debug:CountSprings()
	local ok, Spring = pcall(function()
		return require(script.Parent.Parent.Animation.Spring)
	end)

	if ok and Spring and Spring.Stats then
		local stats = Spring.Stats()
		return stats.Active or 0
	end

	return 0
end

function Debug:CountWindows()
	local ok, NexusUI = pcall(function()
		return require(script.Parent.Parent.init)
	end)

	if ok and NexusUI and NexusUI.GetAllWindows then
		return #NexusUI:GetAllWindows()
	end

	return 0
end

function Debug:MemoryUsage()
	return collectgarbage("count") / 1024
end

function Debug:Build()
	if self.Root and self.Root.Parent then
		return
	end

	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	if not ok or parent == nil then
		parent = PlayerGui
	end

	self.Root = Instance.new("ScreenGui")
	self.Root.Name = "NexusUI_Debug"
	self.Root.ResetOnSpawn = false
	self.Root.IgnoreGuiInset = true
	self.Root.DisplayOrder = 900
	self.Root.Parent = parent

	self.Frame = Instance.new("Frame")
	self.Frame.Name = "DebugPanel"
	self.Frame.AnchorPoint = Vector2.new(0, 1)
	self.Frame.Position = UDim2.new(0, 10, 1, -10)
	self.Frame.Size = UDim2.new(0, 230, 0, 0)
	self.Frame.AutomaticSize = Enum.AutomaticSize.Y
	self.Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	self.Frame.BackgroundTransparency = 0.1
	self.Frame.BorderSizePixel = 0
	self.Frame.Active = true
	self.Frame.Draggable = true
	self.Frame.ZIndex = 900
	self.Frame.Parent = self.Root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = self.Frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 70, 90)
	stroke.Thickness = 1
	stroke.Transparency = 0.4
	stroke.Parent = self.Frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = self.Frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 3)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 20)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "NexusUI Debug"
	title.TextColor3 = Color3.fromRGB(96, 130, 255)
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.LayoutOrder = 1
	title.ZIndex = 901
	title.Parent = self.Frame

	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.BackgroundColor3 = Color3.fromRGB(60, 70, 90)
	divider.BackgroundTransparency = 0.4
	divider.BorderSizePixel = 0
	divider.LayoutOrder = 2
	divider.ZIndex = 901
	divider.Parent = self.Frame

	self.Rows = {}

	local rows = {
		"Components",
		"Active Tweens",
		"Active Springs",
		"Connections",
		"Windows",
		"Memory (MB)",
	}

	for index, rowName in ipairs(rows) do
		local row = Instance.new("TextLabel")
		row.Name = "Row_" .. rowName
		row.Size = UDim2.new(1, 0, 0, 16)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.Gotham
		row.Text = rowName .. ": ..."
		row.TextColor3 = Color3.fromRGB(200, 205, 215)
		row.TextSize = 11
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.LayoutOrder = index + 2
		row.ZIndex = 901
		row.Parent = self.Frame

		self.Rows[rowName] = row
	end
end

function Debug:Update()
	if not self.Enabled or not self.Frame then
		return
	end

	local components = self:CountComponents()
	local tweens = self:CountTweens()
	local springs = self:CountSprings()
	local connections = self:CountConnections()
	local windows = self:CountWindows()
	local memory = self:MemoryUsage()

	if self.Rows then
		if self.Rows["Components"] then
			self.Rows["Components"].Text = ("Components: %d"):format(components)
		end
		if self.Rows["Active Tweens"] then
			self.Rows["Active Tweens"].Text = ("Active Tweens: %d"):format(tweens)
		end
		if self.Rows["Active Springs"] then
			self.Rows["Active Springs"].Text = ("Active Springs: %d"):format(springs)
		end
		if self.Rows["Connections"] then
			self.Rows["Connections"].Text = ("Connections: %d"):format(connections)
		end
		if self.Rows["Windows"] then
			self.Rows["Windows"].Text = ("Windows: %d"):format(windows)
		end
		if self.Rows["Memory (MB)"] then
			self.Rows["Memory (MB)"].Text = ("Memory: %.2f MB"):format(memory)
		end
	end
end

function Debug:Enable()
	if self.Enabled then
		return
	end

	self.Enabled = true
	self:Build()

	self.Connection = task.spawn(function()
		while self.Enabled do
			self:Update()
			task.wait(self.UpdateInterval)
		end
	end)

	return self
end

function Debug:Disable()
	if not self.Enabled then
		return
	end

	self.Enabled = false

	if self.Connection then
		task.cancel(self.Connection)
		self.Connection = nil
	end

	if self.Root then
		self.Root:Destroy()
		self.Root = nil
	end

	self.Frame = nil
	self.Rows = nil

	return self
end

function Debug:Toggle()
	if self.Enabled then
		return self:Disable()
	end
	return self:Enable()
end

function Debug:Destroy()
	self:Disable()
end

return Debug
