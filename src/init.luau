local Config = require(script.Config)
local ThemeManager = require(script.ThemeManager)

local NexusUI = {}

NexusUI.Version = "1.0.0"
NexusUI.Author = "NexusUI Team"
NexusUI.Repository = "https://github.com/NexusUI1"

NexusUI.Config = Config
NexusUI.Themes = ThemeManager
NexusUI._windows = {}
NexusUI._started = false

local function applyDefaultThemes()
	local DefaultTheme = require(script.DefaultTheme)
	for name, tokens in pairs(DefaultTheme) do
		if type(tokens) == "table" and name ~= "Apply" and type(name) == "string" then
			ThemeManager.RegisterTheme(name, tokens)
		end
	end
end

function NexusUI:CreateWindow(options)
	options = options or {}

	local WindowModule = require(script.Components.Window)
	local window = WindowModule.new(options)

	table.insert(self._windows, window)

	return window
end

function NexusUI:AddElementToWindow(window, options)
	if not window or not window.ActiveTab then
		return nil
	end
	return window.ActiveTab
end

function NexusUI:Notify(options)
	local NotificationSystem = require(script.Services.NotificationSystem)
	return NotificationSystem:Notify(options)
end

function NexusUI:Success(title, description, duration)
	local NotificationSystem = require(script.Services.NotificationSystem)
	return NotificationSystem:Success(title, description, duration)
end

function NexusUI:Error(title, description, duration)
	local NotificationSystem = require(script.Services.NotificationSystem)
	return NotificationSystem:Error(title, description, duration)
end

function NexusUI:Warning(title, description, duration)
	local NotificationSystem = require(script.Services.NotificationSystem)
	return NotificationSystem:Warning(title, description, duration)
end

function NexusUI:Info(title, description, duration)
	local NotificationSystem = require(script.Services.NotificationSystem)
	return NotificationSystem:Info(title, description, duration)
end

function NexusUI:SetTheme(theme)
	return ThemeManager.SetTheme(theme)
end

function NexusUI:GetTheme()
	return ThemeManager.CurrentName, ThemeManager.Current
end

function NexusUI:RegisterTheme(name, tokens)
	return ThemeManager.RegisterTheme(name, tokens)
end

function NexusUI:GetThemeNames()
	return ThemeManager.ListThemes()
end

function NexusUI:CreateModal(options)
	local Modal = require(script.Components.Modal)
	return Modal.new(options)
end

function NexusUI:CreateDialog(title, message, onConfirm)
	local Modal = require(script.Components.Modal)
	local modal = Modal.new({
		Title = title,
		Message = message,
	})

	modal:AddCloseButton("Cancel")
	modal:AddConfirmButton("Confirm", function()
		if onConfirm then
			pcall(onConfirm)
		end
	end)

	modal:Open()
	return modal
end

function NexusUI:CreateToast(text, options)
	local Toast = require(script.Components.Toast)
	return Toast.new({
		Text = text,
		Duration = (options and options.Duration) or 2,
		Position = (options and options.Position) or "BottomCenter",
		Variant = (options and options.Variant) or "Dark",
	})
end

function NexusUI:CreateContextMenu(items)
	local ContextMenu = require(script.Components.ContextMenu)
	local menu = ContextMenu.new({ Items = items })
	menu:Open()
	return menu
end

function NexusUI:CreateTooltip(text, target)
	local Tooltip = require(script.Components.Tooltip)
	return Tooltip.new({
		Text = text,
		Target = target,
	})
end

function NexusUI:CreateQuickActions(options)
	local QuickActions = require(script.Components.QuickActions)
	return QuickActions.new(options)
end

function NexusUI:GetAllWindows()
	local active = {}
	for _, window in ipairs(self._windows) do
		if not window.Destroyed then
			table.insert(active, window)
		end
	end
	return active
end

function NexusUI:DestroyAllWindows()
	for _, window in ipairs(self._windows) do
		pcall(function() window:Destroy() end)
	end
	self._windows = {}
end

function NexusUI:Start()
	if self._started then
		return self
	end

	self._started = true
	applyDefaultThemes()

	local Device = require(script.Device)
	Device.Start()

	ThemeManager.SetTheme(Config.Theme or "Midnight")

	local NotificationSystem = require(script.Services.NotificationSystem)
	NotificationSystem:GetContainer()

	return self
end

function NexusUI:LaunchDemo()
	if self._demoLaunched then
		return nil
	end

	self._demoLaunched = true

	local Demo = require(script.Demo)
	return Demo:Run()
end

function NexusUI:Destroy()
	self:DestroyAllWindows()

	local NotificationSystem = require(script.Services.NotificationSystem)
	NotificationSystem:Destroy()

	self._started = false
end

applyDefaultThemes()

return NexusUI
