local NexusUI = require(script.Parent.Parent)
local Icons = require(script.Parent.Parent.Core.Icons)

local Demo = {}
Demo.__index = Demo

function Demo:Run()
	local NexusUIRef = NexusUI

	if not NexusUIRef._started then
		NexusUIRef:Start()
	end

	task.wait(0.2)

	local Window = NexusUIRef:CreateWindow({
		Name = "NexusDemo",
		Title = "NexusUI",
		SubTitle = "v1.0.0 | " .. NexusUIRef.Version,
		Size = UDim2.fromOffset(900, 580),
		ToggleKeybind = Enum.KeyCode.RightShift,
	})

	local HomeTab = Window:AddTab({
		Name = "Home",
		Icon = Icons.Assets.Background,
	})

	local HomeSection = HomeTab:AddSection({
		Name = "Welcome",
		Description = "NexusUI is a premium Roblox UI framework.",
		Collapsible = true,
	})

	HomeSection:AddParagraph({
		Name = "Intro",
		Title = "About NexusUI",
		Text = "A modern, animated, and themeable UI framework for Roblox. Every component is fully customizable with 20+ built-in elements, theme hot-swapping, animations, and a professional API.",
	})

	HomeSection:AddButton({
		Name = "Show Welcome",
		Text = "Show Welcome Screen",
		Variant = "Primary",
		Description = "Replays the animated welcome overlay",
		Callback = function()
			local Welcome = require(script.Parent.Parent.Services.Welcome)
			Welcome.new({
				Title = "NexusUI",
				SubTitle = "Premium Interface Framework",
				Duration = 2.5,
			})
		end,
	})

	HomeSection:AddDivider({})

	local QuickSection = HomeTab:AddSection({
		Name = "Quick Actions",
		Collapsible = false,
	})

	QuickSection:AddButton({
		Name = "SuccessNotify",
		Text = "Success Notification",
		Variant = "Success",
		Callback = function()
			NexusUIRef:Success("Success", "Operation completed successfully!")
		end,
	})

	QuickSection:AddButton({
		Name = "ErrorNotify",
		Text = "Error Notification",
		Variant = "Danger",
		Callback = function()
			NexusUIRef:Error("Error", "Something went wrong!")
		end,
	})

	QuickSection:AddButton({
		Name = "InfoNotify",
		Text = "Info Notification",
		Variant = "Secondary",
		Callback = function()
			NexusUIRef:Info("Info", "This is an informational message.")
		end,
	})

	local AppearanceTab = Window:AddTab({
		Name = "Appearance",
		Icon = Icons.Assets.Ornament1,
	})

	local ThemeSection = AppearanceTab:AddSection({
		Name = "Theme Manager",
		Description = "Switch between built-in themes or register your own.",
	})

	local themeDropdown = ThemeSection:AddDropdown({
		Name = "ThemeSelect",
		Text = "Active Theme",
		Options = NexusUIRef:GetThemeNames(),
		Value = "Midnight",
		Callback = function(themeName)
			NexusUIRef:SetTheme(themeName)
		end,
	})

	ThemeSection:AddButton({
		Name = "RandomTheme",
		Text = "Random Theme",
		Variant = "Secondary",
		Callback = function()
			local themes = NexusUIRef:GetThemeNames()
			local random = themes[math.random(1, #themes)]
			NexusUIRef:SetTheme(random)
			NexusUIRef:Info("Theme Changed", "Switched to " .. random)
			themeDropdown:Select(random)
		end,
	})

	local CustomSection = AppearanceTab:AddSection({
		Name = "Custom Theme",
		Description = "Fine-tune theme colors with the color pickers below.",
	})

	local accentPicker = CustomSection:AddColorPicker({
		Name = "AccentColor",
		Text = "Accent Color",
		Value = Color3.fromRGB(96, 130, 255),
		Callback = function(color)
			NexusUIRef:SetTheme({
				Accent = color,
				AccentDark = Color3.new(color.R * 0.75, color.G * 0.75, color.B * 0.75),
				AccentLight = Color3.new(math.min(1, color.R * 1.25), math.min(1, color.G * 1.25), math.min(1, color.B * 1.25)),
				ScrollBars = color,
			})
		end,
	})

	local backgroundPicker = CustomSection:AddColorPicker({
		Name = "BgColor",
		Text = "Background Color",
		Value = Color3.fromRGB(11, 13, 20),
		Callback = function(color)
			NexusUIRef:SetTheme({ Background = color })
		end,
	})

	CustomSection:AddButton({
		Name = "ResetTheme",
		Text = "Reset to Midnight",
		Variant = "Outline",
		Callback = function()
			NexusUIRef:SetTheme("Midnight")
			accentPicker:SetColor(Color3.fromRGB(96, 130, 255), false)
			backgroundPicker:SetColor(Color3.fromRGB(11, 13, 20), false)
		end,
	})

	CustomSection:AddDropdown({
		Name = "FontSelect",
		Text = "Font",
		Options = { "Gotham", "GothamBold", "GothamMedium", "Montserrat", "Roboto" },
		Value = "Gotham",
		Callback = function(fontName)
			local ok, font = pcall(function()
				return Enum.Font[fontName]
			end)
			if ok and font then
				NexusUIRef:SetTheme({ Font = font })
			end
		end,
	})

	local ControlsTab = Window:AddTab({
		Name = "Controls",
		Icon = Icons.Assets.Ornament2,
	})

	local TogglesSection = ControlsTab:AddSection({
		Name = "Toggles & Checkboxes",
	})

	local autoUpdateToggle = TogglesSection:AddToggle({
		Name = "AutoUpdate",
		Text = "Auto Update",
		Description = "Automatically refresh values",
		Value = true,
		Callback = function(value)
			print("[NexusDemo] AutoUpdate:", value)
		end,
	})

	local notificationsToggle = TogglesSection:AddToggle({
		Name = "Notifications",
		Text = "Enable Notifications",
		Value = true,
		Callback = function(value)
			print("[NexusDemo] Notifications:", value)
		end,
	})

	TogglesSection:AddCheckbox({
		Name = "TermsCheckbox",
		Text = "I agree to the terms",
		Callback = function(value)
			print("[NexusDemo] Terms accepted:", value)
		end,
	})

	local SlidersSection = ControlsTab:AddSection({
		Name = "Sliders",
	})

	SlidersSection:AddSlider({
		Name = "Volume",
		Text = "Volume",
		Min = 0,
		Max = 100,
		Value = 50,
		Suffix = "%",
		Callback = function(value)
			print("[NexusDemo] Volume:", value)
		end,
	})

	SlidersSection:AddSlider({
		Name = "Precision",
		Text = "Precision",
		Min = 0,
		Max = 1,
		Step = 0.01,
		Value = 0.5,
		Callback = function(value)
			print("[NexusDemo] Precision:", value)
		end,
	})

	SlidersSection:AddProgressBar({
		Name = "DemoProgress",
		Text = "Loading Progress",
		Value = 35,
	})

	local DropdownsSection = ControlsTab:AddSection({
		Name = "Dropdowns",
	})

	DropdownsSection:AddDropdown({
		Name = "GameMode",
		Text = "Game Mode",
		Options = { "Casual", "Ranked", "Custom", "Practice" },
		Value = "Casual",
		Callback = function(value)
			print("[NexusDemo] Game Mode:", value)
		end,
	})

	DropdownsSection:AddMultiDropdown({
		Name = "Filters",
		Text = "Active Filters",
		Options = { "Players", "NPCs", "Vehicles", "Items", "Effects" },
		Callback = function(selected)
			print("[NexusDemo] Filters:", table.concat(selected, ", "))
		end,
	})

	local InputSection = ControlsTab:AddSection({
		Name = "Input Fields",
	})

	InputSection:AddTextBox({
		Name = "Username",
		Text = "Username",
		Placeholder = "Enter username...",
		Callback = function(text)
			print("[NexusDemo] Username:", text)
		end,
	})

	InputSection:AddSearchBox({
		Name = "Search",
		Placeholder = "Search settings...",
		Callback = function(query)
			print("[NexusDemo] Search:", query)
		end,
	})

	InputSection:AddKeybind({
		Name = "MenuKeybind",
		Text = "Toggle Menu",
		Value = Enum.KeyCode.RightShift,
		Callback = function(key)
			print("[NexusDemo] Menu Keybind pressed:", key.Name)
		end,
	})

	local ComponentsTab = Window:AddTab({
		Name = "Components",
		Icon = Icons.Assets.Ornament3,
	})

	local CardsSection = ComponentsTab:AddSection({
		Name = "Cards & Media",
	})

	CardsSection:AddCard({
		Name = "InfoCard",
		Title = "NexusUI Framework",
		Description = "A modern, fully themeable UI framework with 20+ components and premium animations.",
		Image = Icons.Assets.Background,
		Clickable = true,
		Callback = function()
			NexusUIRef:Info("Card Clicked", "You clicked the NexusUI card!")
		end,
	})

	local MediaSection = ComponentsTab:AddSection({
		Name = "Media & Badges",
	})

	MediaSection:AddImage({
		Name = "BannerImage",
		Image = Icons.Assets.Ornament1,
		Caption = "Custom banner image",
		Clickable = true,
		Callback = function()
			NexusUIRef:Info("Image Clicked", "You clicked the banner!")
		end,
	})

	MediaSection:AddBadge({
		Name = "StatusBadge",
		Text = "Active",
		Variant = "Success",
	})

	local MiscSection = ComponentsTab:AddSection({
		Name = "Interactive Elements",
	})

	MiscSection:AddButton({
		Name = "OpenModal",
		Text = "Open Modal Dialog",
		Variant = "Primary",
		Callback = function()
			NexusUIRef:CreateDialog("Confirm Action", "Are you sure you want to proceed with this action?", function()
				NexusUIRef:Success("Confirmed", "Action completed successfully!")
			end)
		end,
	})

	MiscSection:AddButton({
		Name = "ShowToast",
		Text = "Show Toast",
		Variant = "Secondary",
		Callback = function()
			NexusUIRef:CreateToast("This is a toast notification!", { Duration = 2.5 })
		end,
	})

	MiscSection:AddButton({
		Name = "OpenContextMenu",
		Text = "Open Context Menu",
		Variant = "Outline",
		Callback = function()
			NexusUIRef:CreateContextMenu({
				{ Text = "Copy", Callback = function() NexusUIRef:Info("Copied", "Text copied to clipboard") end },
				{ Text = "Paste", Callback = function() NexusUIRef:Info("Pasted", "Text pasted") end },
				{ Divider = true },
				{ Text = "Delete", Callback = function() NexusUIRef:Warning("Deleted", "Item deleted") end },
			})
		end,
	})

	MiscSection:AddLoadingIndicator({
		Name = "Spinner",
		Variant = "Spinner",
		Text = "Loading...",
	})

	local CommandsTab = Window:AddTab({
		Name = "Commands",
		Icon = Icons.Assets.Ornament4,
	})

	local CmdSection = CommandsTab:AddSection({
		Name = "Command Palette",
		Description = "Press Ctrl + K to open the command palette.",
	})

	CmdSection:AddButton({
		Name = "OpenPalette",
		Text = "Open Command Palette",
		Variant = "Primary",
		Callback = function()
			local CommandPalette = require(script.Parent.Parent.Services.CommandPalette)
			CommandPalette:Open()
		end,
	})

	CmdSection:AddParagraph({
		Name = "PaletteInfo",
		Title = "About Commands",
		Text = "The command palette provides quick fuzzy-search access to all registered commands. Press Ctrl+K anywhere to open it, type to filter, and press Enter to execute the top result.",
	})

	local SettingsTab = Window:AddTab({
		Name = "Settings",
		Icon = Icons.Assets.Settings,
	})

	local PerfSection = SettingsTab:AddSection({
		Name = "Performance",
	})

	PerfSection:AddToggle({
		Name = "PerformanceMode",
		Text = "Performance Mode",
		Description = "Reduces animations for better FPS",
		Value = false,
		Callback = function(value)
			NexusUIRef.Config.PerformanceMode = value
			NexusUIRef:Info("Performance Mode", value and "Enabled" or "Disabled")
		end,
	})

	PerfSection:AddToggle({
		Name = "DebugMode",
		Text = "Debug Overlay",
		Description = "Shows component and connection counts",
		Value = false,
		Callback = function(value)
			local Debug = require(script.Parent.Parent.Services.Debug)
			if value then
				Debug:Enable()
			else
				Debug:Disable()
			end
		end,
	})

	PerfSection:AddSlider({
		Name = "AnimSpeed",
		Text = "Animation Speed",
		Min = 0.5,
		Max = 2,
		Step = 0.1,
		Value = 1,
		Suffix = "x",
		Callback = function(value)
			NexusUIRef.Config.AnimationSpeed = value
		end,
	})

	local SocialSection = SettingsTab:AddSection({
		Name = "Community",
		Description = "Quick action buttons appear on screen edges.",
	})

	SocialSection:AddButton({
		Name = "SetupQuickActions",
		Text = "Enable Quick Actions",
		Variant = "Primary",
		Callback = function()
			local quickActions = NexusUIRef:CreateQuickActions({
				Position = "TopRight",
			})

			quickActions:AddWindowToggle(Icons.Assets.Settings, "Toggle Window")
			quickActions:AddProfileButton(function()
				NexusUIRef:Info("Profile", "Showing profile information...")
			end, "Profile")

			quickActions:AddYouTubeButton("https://youtube.com/@NexusUI", "Visit YouTube")
			quickActions:AddDiscordButton("https://discord.gg/nexusui", "Copy Discord Invite")

			NexusUIRef:Success("Quick Actions", "Quick action buttons enabled!")
		end,
	})

	SocialSection:AddParagraph({
		Name = "Credits",
		Title = "Credits",
		Text = "NexusUI Framework v1.0.0 | https://github.com/NexusUI1 | MIT License",
	})

	Window:Open()

	task.delay(1, function()
		NexusUIRef:Success("Welcome!", "NexusUI demo loaded. Press RightShift to toggle.")
	end)

	task.delay(2.5, function()
		NexusUIRef:Info("Tip", "Press Ctrl+K to open the Command Palette")
	end)

	return {
		Window = Window,
		HomeTab = HomeTab,
		AppearanceTab = AppearanceTab,
		ControlsTab = ControlsTab,
		ComponentsTab = ComponentsTab,
		CommandsTab = CommandsTab,
		SettingsTab = SettingsTab,
	}
end

return Demo
