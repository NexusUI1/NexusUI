local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)
local Sound = require(script.Parent.Parent.Utilities.Sound)
local Config = require(script.Parent.Parent.Core.Config)

local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

NotificationSystem.Container = nil
NotificationSystem.Active = {}
NotificationSystem.Root = nil

function NotificationSystem:GetRoot()
	if self.Root and self.Root.Parent then
		return self.Root
	end

	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local parent
	local ok = pcall(function()
		parent = CoreGui
	end)

	if not ok or parent == nil then
		parent = PlayerGui
	end

	self.Root = Instance.new("ScreenGui")
	self.Root.Name = "NexusUI_Notifications"
	self.Root.ResetOnSpawn = false
	self.Root.IgnoreGuiInset = true
	self.Root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.Root.DisplayOrder = 200
	self.Root.Parent = parent

	return self.Root
end

function NotificationSystem:GetContainer()
	local root = self:GetRoot()

	if self.Container and self.Container.Parent then
		return self.Container
	end

	local position = Config.Notifications.Position or "Right"

	self.Container = Instance.new("Frame")
	self.Container.Name = "Container"
	self.Container.AnchorPoint = position == "Right" and Vector2.new(1, 1) or Vector2.new(0, 1)
	self.Container.Position = position == "Right" and UDim2.new(1, -16, 1, -16) or UDim2.new(0, 16, 1, -16)
	self.Container.Size = UDim2.new(0, Config.Notifications.Width or 340, 1, -100)
	self.Container.BackgroundTransparency = 1
	self.Container.ZIndex = 100
	self.Container.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, Config.Notifications.Spacing or 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Container

	return self.Container
end

function NotificationSystem:_typeColors(notificationType)
	local tokens = ThemeManager.GetTokens()

	local types = {
		Success = { Color = tokens.Success, Glyph = "✓", Label = "Success" },
		Error = { Color = tokens.Error, Glyph = "✕", Label = "Error" },
		Warning = { Color = tokens.Warning, Glyph = "!", Label = "Warning" },
		Info = { Color = tokens.Info, Glyph = "i", Label = "Info" },
		Custom = { Color = tokens.Accent, Glyph = "◆", Label = "Notice" },
	}

	return types[notificationType] or types.Info
end

function NotificationSystem:Notify(options)
	options = options or {}

	local title = options.Title or "Notification"
	local description = options.Description or ""
	local notificationType = options.Type or "Info"
	local duration = options.Duration or Config.Notifications.Lifetime
	local icon = options.Icon
	local onClick = options.OnClick

	if #self.Active >= (Config.Notifications.MaxVisible or 6) then
		local oldest = table.remove(self.Active, 1)
		if oldest and oldest.Dismiss then
			oldest:Dismiss(true)
		end
	end

	local tokens = ThemeManager.GetTokens()
	local typeInfo = self:_typeColors(notificationType)

	local maid = Maid.new()

	local card = Instance.new("Frame")
	card.Name = "Notification"
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = tokens.Surface
	card.BackgroundTransparency = 0.06
	card.BorderSizePixel = 0
	card.ZIndex = 100
	card.Parent = self:GetContainer()

	UIUtils.Corner(card, tokens.Corner)
	UIUtils.Stroke(card, tokens.BorderLight, 1, 0.55)

	maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		card.BackgroundColor3 = tk.Surface
	end))

	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0, 3, 1, 0)
	accentBar.Position = UDim2.new(0, 0, 0, 0)
	accentBar.BackgroundColor3 = typeInfo.Color
	accentBar.BorderSizePixel = 0
	accentBar.ZIndex = 101
	accentBar.Parent = card

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingLeft = UDim.new(0, 14)
	contentPadding.PaddingRight = UDim.new(0, 12)
	contentPadding.PaddingTop = UDim.new(0, 10)
	contentPadding.PaddingBottom = UDim.new(0, 10)
	contentPadding.Parent = card

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	contentLayout.Padding = UDim.new(0, 4)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = card

	local titleRow = Instance.new("Frame")
	titleRow.Name = "TitleRow"
	titleRow.Size = UDim2.new(1, 0, 0, 18)
	titleRow.BackgroundTransparency = 1
	titleRow.LayoutOrder = 1
	titleRow.ZIndex = 102
	titleRow.Parent = card

	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "IconFrame"
	iconFrame.Size = UDim2.new(0, 18, 0, 18)
	iconFrame.BackgroundColor3 = typeInfo.Color
	iconFrame.BackgroundTransparency = 0.85
	iconFrame.BorderSizePixel = 0
	iconFrame.ZIndex = 103
	iconFrame.Parent = titleRow

	UIUtils.Corner(iconFrame, tokens.CornerSmall)

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Glyph"
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Font = tokens.FontBold
	iconLabel.Text = icon and "" or typeInfo.Glyph
	iconLabel.TextColor3 = typeInfo.Color
	iconLabel.TextSize = 11
	iconLabel.ZIndex = 104
	iconLabel.Parent = iconFrame

	if icon then
		local iconImage = Instance.new("ImageLabel")
		iconImage.Name = "Image"
		iconImage.Size = UDim2.new(1, -4, 1, -4)
		iconImage.Position = UDim2.new(0, 2, 0, 2)
		iconImage.BackgroundTransparency = 1
		iconImage.Image = icon
		iconImage.ImageColor3 = typeInfo.Color
		iconImage.ScaleType = Enum.ScaleType.Fit
		iconImage.ZIndex = 104
		iconImage.Parent = iconFrame
	end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Position = UDim2.new(0, 26, 0, 0)
	titleLabel.Size = UDim2.new(1, -30, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = tokens.FontBold
	titleLabel.Text = title
	titleLabel.TextColor3 = tokens.Text
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.ZIndex = 103
	titleLabel.Parent = titleRow

	maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		titleLabel.Font = tk.FontBold
		titleLabel.TextColor3 = tk.Text
	end))

	if description ~= "" then
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "Description"
		descLabel.BackgroundTransparency = 1
		descLabel.Size = UDim2.new(1, -26, 0, 0)
		descLabel.AutomaticSize = Enum.AutomaticSize.Y
		descLabel.Position = UDim2.new(0, 26, 0, 0)
		descLabel.Font = tokens.Font
		descLabel.Text = description
		descLabel.TextColor3 = tokens.SecondaryText
		descLabel.TextSize = 12
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.LayoutOrder = 2
		descLabel.ZIndex = 103
		descLabel.Parent = card

		maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			descLabel.Font = tk.Font
			descLabel.TextColor3 = tk.SecondaryText
		end))
	end

	local progressBar = Instance.new("Frame")
	progressBar.Name = "Progress"
	progressBar.AnchorPoint = Vector2.new(0, 1)
	progressBar.Position = UDim2.new(0, 0, 1, 0)
	progressBar.Size = UDim2.new(1, 0, 0, 2)
	progressBar.BackgroundColor3 = typeInfo.Color
	progressBar.BackgroundTransparency = 0.3
	progressBar.BorderSizePixel = 0
	progressBar.ZIndex = 105
	progressBar.Parent = card

	local progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.new(1, 0, 1, 0)
	progressFill.BackgroundColor3 = typeInfo.Color
	progressFill.BorderSizePixel = 0
	progressFill.ZIndex = 106
	progressFill.Parent = progressBar

	local self2 = self
	local notification = {
		Card = card,
		Title = title,
		Type = notificationType,
		Duration = duration,
		Dismissed = false,
		Dismiss = function(_, instant)
			if notification.Dismissed then
				return
			end
			notification.Dismissed = true

			for i, n in ipairs(self2.Active) do
				if n == notification then
					table.remove(self2.Active, i)
					break
				end
			end

			Animator.Tween(card, { BackgroundTransparency = 1 }, 0.2, "Quad")
			Animator.Tween(card, { Position = card.Position + UDim2.new(0.1, 0, 0, 0) }, 0.2, "Quad")

			task.delay(0.2, function()
				card:Destroy()
				maid:Destroy()
			end)
		end,
	}

	table.insert(self.Active, notification)

	if onClick then
		local clickButton = Instance.new("TextButton")
		clickButton.Size = UDim2.new(1, 0, 1, 0)
		clickButton.BackgroundTransparency = 1
		clickButton.Text = ""
		clickButton.ZIndex = 110
		clickButton.Parent = card

		clickButton.MouseButton1Click:Connect(function()
			Sound.Click()
			pcall(onClick, notification)
			notification:Dismiss()
		end)
	else
		local hoverButton = Instance.new("TextButton")
		hoverButton.Size = UDim2.new(1, 0, 1, 0)
		hoverButton.BackgroundTransparency = 1
		hoverButton.Text = ""
		hoverButton.ZIndex = 110
		hoverButton.Parent = card

		hoverButton.MouseEnter:Connect(function()
			Animator.Tween(card, { BackgroundTransparency = 0 }, 0.15, "Quad")
		end)

		hoverButton.MouseLeave:Connect(function()
			Animator.Tween(card, { BackgroundTransparency = 0.06 }, 0.15, "Quad")
		end)

		hoverButton.MouseButton1Click:Connect(function()
			notification:Dismiss()
		end)
	end

	card.BackgroundTransparency = 1
	Animator.Tween(card, { BackgroundTransparency = 0.06 }, 0.3, "Quart")

	if duration and duration > 0 then
		Animator.Tween(progressFill, { Size = UDim2.new(0, 0, 1, 0) }, duration, "Linear")

		task.delay(duration, function()
			notification:Dismiss()
		end)
	end

	Sound.Pop()

	return notification
end

function NotificationSystem:Success(title, description, duration)
	return self:Notify({
		Title = title,
		Description = description,
		Type = "Success",
		Duration = duration,
	})
end

function NotificationSystem:Error(title, description, duration)
	return self:Notify({
		Title = title,
		Description = description,
		Type = "Error",
		Duration = duration,
	})
end

function NotificationSystem:Warning(title, description, duration)
	return self:Notify({
		Title = title,
		Description = description,
		Type = "Warning",
		Duration = duration,
	})
end

function NotificationSystem:Info(title, description, duration)
	return self:Notify({
		Title = title,
		Description = description,
		Type = "Info",
		Duration = duration,
	})
end

function NotificationSystem:ClearAll()
	for _, notification in ipairs(self.Active) do
		notification:Dismiss()
	end
	self.Active = {}
end

function NotificationSystem:Destroy()
	self:ClearAll()

	if self.Root then
		self.Root:Destroy()
		self.Root = nil
	end

	self.Container = nil
end

NotificationSystem.Notify = NotificationSystem.Notify

return NotificationSystem
