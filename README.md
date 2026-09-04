# NexusUI

**Premium Roblox UI Framework — AAA-grade interfaces, themeable, animated, and fully customizable.**

NexusUI is a complete UI framework for Roblox Luau built for modern game interfaces. It ships with 20+ production-ready components, a real theme engine with hot-swapping, an advanced animation layer over TweenService, spring physics, a command palette, notification system, presets, and a full developer debug overlay.

Built to run inside **executors** (Xeno, Delta, Solara, Wave, Codex) and standard Roblox environments.

---

## Features

- **Window System** — draggable, resizable windows with sidebar navigation, animated open/close, image backgrounds, and per-window keybinds
- **Theme Engine** — 10 built-in themes, custom theme registration, live hot-swapping without UI rebuilds, design tokens for every visual property
- **Animation Layer** — 14 easing curves, spring physics with a central manager, stagger sequences, premium presets
- **20+ Components** — Button, Toggle, Checkbox, Slider, Dropdown, MultiDropdown, TextBox, SearchBox, Keybind, ColorPicker, Label, Paragraph, Divider, Badge, Card, Image, ProgressBar, LoadingIndicator, Modal, Tooltip, Toast, ContextMenu, QuickActions
- **Notifications** — Success / Error / Warning / Info / Custom types with progress bars and queue management
- **Command Palette** — Ctrl+K fuzzy-search command system with developer registration API
- **Preset System** — Save and load UI state (theme, window position, toggle/slider values) at runtime
- **State Management** — Reactive state objects that auto-update every bound component
- **Debug Overlay** — Live component, tween, spring, and connection counts plus memory usage
- **Key System** — Built-in key verification gate with shake animation and attempt tracking
- **Welcome Screen** — Animated intro splash
- **Responsive** — Automatic PC / Mobile / Tablet / Console detection and layout adaptation

---

## Quick Start

### Executor (Xeno / Delta / Solara)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NexusUI1/NexusUI/main/build/NexusUI.lua"))()
```

### Load + Launch the full Demo

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NexusUI1/NexusUI/main/build/NexusUI.lua"))()
task.wait(1)
getgenv().NexusUI:LaunchDemo()
```

### Basic Window

```lua
local NexusUI = getgenv().NexusUI
NexusUI:Start()

local Window = NexusUI:CreateWindow({
	Name = "MyScript",
	Title = "My Interface",
	SubTitle = "v1.0",
	Size = UDim2.fromOffset(900, 580),
	ToggleKeybind = Enum.KeyCode.RightShift,
})

local MainTab = Window:AddTab({
	Name = "Home",
	Icon = "rbxassetid://137809702642145",
})

local Section = MainTab:AddSection({
	Name = "Controls",
	Description = "Primary script controls",
})

Section:AddButton({
	Name = "Play",
	Text = "Play",
	Description = "Start the game",
	Callback = function()
		print("Play clicked")
	end,
})
```

---

## API Reference

### Window

```lua
local Window = NexusUI:CreateWindow({
	Name = "UniqueName",
	Title = "Display Title",
	SubTitle = "Optional subtitle",
	Size = UDim2.fromOffset(900, 580),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	ToggleKeybind = Enum.KeyCode.RightShift,
	Closable = true,
	Resizable = true,
	Draggable = true,
	MobileMode = false,
	Background = true,            -- image background
	BackgroundId = "rbxassetid://137809702642145",
	ShowOnCreate = true,
})

Window:SetTitle("New Title")
Window:SetSubTitle("New subtitle")
Window:SetBackgroundImage("rbxassetid://ID", 0.85)
Window:SetMobileMode(true)
Window:Open()
Window:Close()
Window:Toggle()
Window:SelectTab("TabName")

Window.OnOpened:Connect(function() end)
Window.OnClosed:Connect(function() end)
Window.OnTabChanged:Connect(function(tab) end)
```

### Tab

```lua
local Tab = Window:AddTab({
	Name = "Tab Name",
	Icon = "rbxassetid://...",     -- optional image icon
	Badge = 3,                      -- optional count badge
})

Tab:SetName("New Name")
Tab:SetIcon("rbxassetid://...")
Tab:SetBadge(5)          -- nil removes the badge
Tab:SetCompact(true)     -- icon-only sidebar mode
```

### Section

```lua
local Section = Tab:AddSection({
	Name = "Section Title",
	Description = "Optional description",
	Icon = "rbxassetid://...",     -- optional
	Collapsible = true,             -- default true
	Collapsed = false,
})

Section:SetName("New Title")
Section:SetCollapsed(true)
```

### Button

```lua
local Button = Section:AddButton({
	Name = "UniqueName",
	Text = "Click Me",
	Description = "Optional description",
	Icon = "rbxassetid://...",     -- optional image icon
	Variant = "Primary",            -- Primary | Secondary | Outline | Ghost | Danger | Success
	FullWidth = true,
	Callback = function(clickCount)
		print("Clicked", clickCount)
	end,
})

Button:SetText("New Text")
Button:SetIcon("rbxassetid://...")
Button:SetVariant("Danger")
Button:SetFullWidth(false)
Button:PlayClickAnimation()
Button:SetEnabled(false)
Button:SetVisible(false)
Button:Destroy()

Button.OnClick:Connect(function(count) end)
Button.OnPressed:Connect(function() end)
Button.OnReleased:Connect(function() end)
```

### Toggle

```lua
local Toggle = Section:AddToggle({
	Name = "UniqueName",
	Text = "Enable Feature",
	Description = "Optional",
	Value = false,                  -- default state
	Callback = function(value)
		print("Toggled:", value)
	end,
})

Toggle:SetValue(true)
Toggle:SetValue(true, false)     -- false = don't fire callback
Toggle:GetValue()
Toggle:Reset()

Toggle.OnChanged:Connect(function(value) end)
```

### Checkbox

```lua
local Checkbox = Section:AddCheckbox({
	Name = "UniqueName",
	Text = "Accept Terms",
	Value = false,
	Callback = function(value) end,
})

Checkbox:SetValue(true)
Checkbox:GetValue()
Checkbox:Reset()
Checkbox.OnChanged:Connect(function(value) end)
```

### Slider

```lua
local Slider = Section:AddSlider({
	Name = "UniqueName",
	Text = "Volume",
	Min = 0,
	Max = 100,
	Step = 1,
	Value = 50,
	Prefix = "",
	Suffix = "%",
	Callback = function(value) end,
	OnInputEnded = function(value) end,   -- fires on release
})

Slider:SetValue(75)
Slider:SetRange(0, 200)
Slider:SetStep(5)
Slider:SetText("New Label")
Slider:SetSuffix(" FPS")
Slider:Reset()

Slider.OnChanged:Connect(function(value) end)
Slider.OnReleased:Connect(function(value) end)
```

### Dropdown

```lua
local Dropdown = Section:AddDropdown({
	Name = "UniqueName",
	Text = "Select Option",
	Options = { "Option A", "Option B", "Option C" },
	Value = "Option A",             -- default
	MaxVisible = 6,                  -- options before scroll
	Placeholder = "Select...",
	Callback = function(value) end,
})

Dropdown:Select("Option B")
Dropdown:SetOptions({ "New 1", "New 2" })
Dropdown:GetValue()
Dropdown:SetOpen(true)

Dropdown.OnChanged:Connect(function(value) end)
```

### MultiDropdown

```lua
local Multi = Section:AddMultiDropdown({
	Name = "UniqueName",
	Text = "Select Filters",
	Options = { "Players", "NPCs", "Items", "Effects" },
	Value = { "Players" },          -- array of defaults
	MaxVisible = 5,
	Callback = function(selectedArray) end,
})

Multi:ToggleOption("Items")
Multi:SetSelected({ "NPCs", "Items" })
Multi:GetSelected()              -- returns copy of array
Multi:Clear()

Multi.OnChanged:Connect(function(selectedArray) end)
```

### TextBox / SearchBox

```lua
local TextBox = Section:AddTextBox({
	Name = "UniqueName",
	Text = "",                      -- initial value
	Placeholder = "Type here...",
	ClearOnFocus = false,
	NumericOnly = false,
	MaxLength = 200,
	Callback = function(text) end,  -- fires on every change
	OnEnter = function(text) end,   -- fires on submit
})

TextBox:SetText("Hello")
TextBox:GetText()
TextBox:SetPlaceholder("New placeholder")
TextBox:SetNumericOnly(true)
TextBox:Clear()
TextBox:Focus()
TextBox:ReleaseFocus()

TextBox.OnChanged:Connect(function(text) end)
TextBox.OnSubmitted:Connect(function(text) end)
```

```lua
local Search = Section:AddSearchBox({
	Name = "UniqueName",
	Placeholder = "Search...",
	DebounceTime = 0.3,
	Callback = function(query) end,   -- debounced
})

Search:SetText("query")
Search:Clear()
Search:Focus()
Search:SetPlaceholder("New...")

Search.OnSearch:Connect(function(query) end)
Search.OnCleared:Connect(function() end)
```

### Keybind

```lua
local Keybind = Section:AddKeybind({
	Name = "UniqueName",
	Text = "Toggle Menu",
	Value = Enum.KeyCode.RightShift,   -- default bind
	Mode = "Toggle",                    -- Toggle | Hold
	AllowMouse = true,                  -- allow mouse buttons
	Callback = function(key) end,       -- fires when bind pressed
})

Keybind:SetValue(Enum.KeyCode.X)
Keybind:GetValue()
Keybind:SetMode("Hold")
Keybind:StartListening()   -- enter capture mode
Keybind:Reset()

Keybind.OnChanged:Connect(function(key) end)
Keybind.OnTriggered:Connect(function(key) end)
```

### ColorPicker

```lua
local Picker = Section:AddColorPicker({
	Name = "UniqueName",
	Text = "Accent Color",
	Value = Color3.fromRGB(96, 130, 255),
	Callback = function(color) end,
})

Picker:SetColor(Color3.fromRGB(255, 0, 0))
Picker:GetColor()
Picker:Reset()
Picker:SetOpen(true)

Picker.OnChanged:Connect(function(color) end)
```

### Label / Paragraph / Divider / Badge

```lua
local Label = Section:AddLabel({
	Name = "UniqueName",
	Text = "Simple label",
	TextSize = 14,                    -- optional override
	Wrapped = false,
	RichText = false,
})

Label:SetText("New text")
Label:SetTextColor(Color3.new(1, 0.5, 0.5))
Label:SetAlignment(Enum.TextXAlignment.Center)
```

```lua
Section:AddParagraph({
	Name = "UniqueName",
	Title = "Optional title",
	Text = "Long wrapped text body...",
})

Section:AddDivider({ Text = "Optional centered label" })

local Badge = Section:AddBadge({
	Name = "UniqueName",
	Text = "NEW",
	Variant = "Accent",   -- Accent | Success | Error | Warning | Info | Muted | Outline
})

Badge:SetText("UPDATED")
Badge:SetVariant("Success")
Badge:Pulse()
```

### Card / Image

```lua
Section:AddCard({
	Name = "UniqueName",
	Title = "Card Title",
	Description = "Card body text",
	Image = "rbxassetid://...",    -- optional banner
	Clickable = true,
	Callback = function() end,
})

Section:AddImage({
	Name = "UniqueName",
	Image = "rbxassetid://137809702642145",
	Caption = "Optional caption",
	Clickable = true,
	Callback = function() end,
})
```

### ProgressBar / LoadingIndicator

```lua
local Progress = Section:AddProgressBar({
	Name = "UniqueName",
	Text = "Loading",
	Min = 0,
	Max = 100,
	Value = 0,
	ShowPercentage = true,
	Animated = true,
})

Progress:SetValue(50)
Progress:Increment(10)
Progress:Complete()
Progress:Reset()

Progress.OnCompleted:Connect(function() end)
```

```lua
local Loading = Section:AddLoadingIndicator({
	Name = "UniqueName",
	Variant = "Spinner",   -- Spinner | Dots | Bar
	Text = "Loading...",
	Speed = 1,
})

Loading:Stop()
Loading:Start()
Loading:SetText("Fetching data...")
Loading:SetSpeed(2)
```

### Modal / Dialog

```lua
NexusUI:CreateDialog("Confirm", "Proceed with action?", function()
	print("Confirmed")
end)
```

```lua
local Modal = NexusUI:CreateModal({
	Name = "UniqueModal",
	Title = "Custom Modal",
	Message = "Modal body text",
	Size = UDim2.fromOffset(420, 0),
	DismissOnBackdrop = true,
})

Modal:AddButton({ Text = "Cancel", Variant = "Secondary" })
Modal:AddConfirmButton("Confirm", function() end)
Modal:AddDangerButton("Delete", function() end)

Modal:Open()
Modal:Close()
Modal:Dismiss()

Modal.OnOpened:Connect(function() end)
Modal.OnClosed:Connect(function() end)
```

### Notifications

```lua
NexusUI:Notify({
	Title = "Success",
	Description = "Settings saved successfully.",
	Type = "Success",       -- Success | Error | Warning | Info | Custom
	Duration = 4,
	Icon = "rbxassetid://...",   -- optional
	OnClick = function(notification) end,
})

NexusUI:Success("Title", "Description", 4)
NexusUI:Error("Title", "Description", 4)
NexusUI:Warning("Title", "Description", 4)
NexusUI:Info("Title", "Description", 4)

-- Dismiss a specific notification
local n = NexusUI:Info("Hi", "Dismissible")
n:Dismiss()
```

### Toast

```lua
NexusUI:CreateToast("Saved!", {
	Duration = 2,
	Position = "BottomCenter",   -- BottomCenter | TopCenter | BottomLeft
	Variant = "Dark",            -- Dark | Accent | Success | Error
})
```

### Tooltip / ContextMenu

```lua
NexusUI:CreateTooltip("Useful hint", targetGuiObject)
```

```lua
NexusUI:CreateContextMenu({
	{ Text = "Copy",     Callback = function() end },
	{ Text = "Paste",    Callback = function() end, Disabled = false },
	{ Divider = true },
	{ Text = "Delete",   Callback = function() end },
})
```

### QuickActions (floating buttons)

```lua
local QA = NexusUI:CreateQuickActions({
	Position = "TopRight",   -- TopRight | TopLeft | BottomRight | BottomLeft
	Size = 38,
	Window = Window,          -- enables AddWindowToggle
})

QA:AddWindowToggle("rbxassetid://87292430131775", "Toggle Window")
QA:AddProfileButton(function() end, "Profile")
QA:AddYouTubeButton("youtube.com/@channel", "Visit YouTube")
QA:AddDiscordButton("discord.gg/invite", "Copy Discord Invite")  -- copies to clipboard

local custom = QA:AddButton({
	Icon = "rbxassetid://...",
	Tooltip = "Custom action",
	Callback = function() end,
})
custom:SetIcon("rbxassetid://newId")
custom:SetVisible(false)
custom:Destroy()
```

---

## Theme System

### Built-in Themes

`Midnight`, `Ocean`, `Crimson`, `Emerald`, `Amber`, `Light`, `Purple`, `Vampire`, `Solar`

```lua
NexusUI:SetTheme("Ocean")
NexusUI:SetTheme("Crimson")
```

### Custom Theme Table

```lua
NexusUI:SetTheme({
	Accent = Color3.fromRGB(255, 100, 100),
	Background = Color3.fromRGB(10, 10, 14),
	Corner = UDim.new(0, 12),
	Font = Enum.Font.Gotham,
})
```

Partial tables merge onto the active theme — you can override a single token:

```lua
NexusUI:SetTheme({ Accent = Color3.fromRGB(0, 255, 150) })
```

### Register a Reusable Theme

```lua
NexusUI:RegisterTheme("Cyberpunk", {
	Name = "Cyberpunk",
	Background = Color3.fromRGB(8, 8, 16),
	Surface = Color3.fromRGB(14, 14, 28),
	SurfaceLight = Color3.fromRGB(22, 22, 44),
	Elevated = Color3.fromRGB(30, 30, 60),
	Accent = Color3.fromRGB(255, 0, 200),
	AccentDark = Color3.fromRGB(180, 0, 140),
	AccentLight = Color3.fromRGB(255, 100, 230),
	Text = Color3.fromRGB(240, 230, 255),
	SecondaryText = Color3.fromRGB(150, 130, 190),
	MutedText = Color3.fromRGB(100, 85, 130),
	Border = Color3.fromRGB(35, 30, 60),
	BorderLight = Color3.fromRGB(50, 42, 85),
	Shadow = Color3.fromRGB(0, 0, 0),
	Success = Color3.fromRGB(0, 255, 150),
	Error = Color3.fromRGB(255, 50, 90),
	Warning = Color3.fromRGB(255, 190, 0),
	Info = Color3.fromRGB(80, 180, 255),
	Corner = UDim.new(0, 10),
	CornerLarge = UDim.new(0, 16),
	CornerSmall = UDim.new(0, 6),
	CornerCircle = UDim.new(1, 0),
	StrokeThickness = 1,
	StrokeTransparency = 0.6,
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	TextSize = 14,
	TitleSize = 18,
	DescriptionSize = 13,
	Padding = 10,
	Margin = 8,
	Spacing = 6,
	GradientRotation = 90,
	WindowTransparency = 0,
	ScrollBars = Color3.fromRGB(255, 0, 200),
	ScrollThickness = 3,
	HoverLighten = 0.06,
	PressDarken = 0.12,
	AnimationSpeed = 1,
	BlurRadius = 12,
})

NexusUI:SetTheme("Cyberpunk")
```

### Theme Tokens

| Token | Type | Description |
|---|---|---|
| `Background` | Color3 | Window base |
| `Surface` | Color3 | Panels, sections |
| `SurfaceLight` | Color3 | Inputs, hover fills |
| `Elevated` | Color3 | Dropdowns, popups |
| `Accent` | Color3 | Primary interactive color |
| `AccentDark` / `AccentLight` | Color3 | Accent derivatives |
| `Text` / `SecondaryText` / `MutedText` | Color3 | Text hierarchy |
| `Border` / `BorderLight` | Color3 | Strokes |
| `Success` / `Error` / `Warning` / `Info` | Color3 | Status colors |
| `Corner` / `CornerLarge` / `CornerSmall` / `CornerCircle` | UDim | Corner radii |
| `StrokeThickness` / `StrokeTransparency` | number | Stroke tuning |
| `Font` / `FontBold` | Enum.Font | Typography |
| `TextSize` / `TitleSize` / `DescriptionSize` | number | Type scale |
| `Padding` / `Margin` / `Spacing` | number | Layout density |
| `WindowTransparency` | number | Window glass effect |
| `ScrollBars` | Color3 | Scrollbar color |
| `ScrollThickness` | number | Scrollbar width |
| `AnimationSpeed` | number | Global speed multiplier |

All components subscribe to theme changes — switching themes at runtime repaints every element instantly with no rebuild.

---

## Animation System

The animation layer wraps TweenService with organized access, plus a real spring solver with a central Heartbeat manager.

```lua
local Animator = require(NexusUI.Modules.Animation.Animator)
```

- **Tween** — `Animator.Tween(instance, props, duration, easingName)`
- **FadeIn / FadeOut**
- **Scale** — `Animator.Scale(instance, from, to, duration, easing)`
- **Slide** — directional slide with auto-return
- **Stagger** — timed sequential animation across a list
- **Spring** — physical spring values with velocity, impulse, and sleep optimization

Supported easing names: `Linear`, `Sine`, `Quad`, `Cubic`, `Quart`, `Quint`, `Expo`, `Circ`, `Back`, `Elastic`, `Bounce`, `Spring`, `SmoothStep`, `SmootherStep`

Spring example:

```lua
local Spring = require(NexusUI.Modules.Animation.Spring)

local spring = Spring.new(0, { Stiffness = 200, Damping = 20 })
spring:OnUpdate(function(value)
	frame.Position = UDim2.new(0, value, 0, 0)
end)
spring:SetTarget(200)
```

---

## Command Palette

Open with **Ctrl + K** (configurable via `NexusUI.Config.CommandKeybind`).

```lua
local CommandPalette = require(NexusUI.Modules.Services.CommandPalette)

CommandPalette:Register({
	Name = "Open Settings",
	Description = "Navigate to the settings tab",
	Category = "Navigation",
	Keywords = { "settings", "config", "options" },
	Shortcut = "Ctrl+S",
	Callback = function()
		Window:SelectTab("Settings")
	end,
})

CommandPalette:Open()
CommandPalette:Close()
CommandPalette:Toggle()

CommandPalette.OnExecute:Connect(function(command) end)
```

---

## Preset System

Save and restore complete UI state at runtime:

```lua
local Preset = require(NexusUI.Modules.Services.Preset)

Preset:SavePreset("MyUI")     -- theme + window pos/size + tab + all control values
Preset:LoadPreset("MyUI")
Preset:ListPresets()          -- {"MyUI"}
Preset:DeletePreset("MyUI")
Preset:ExportPreset("MyUI")   -- JSON string
Preset:ImportPreset("OtherUI", jsonString)
```

---

## State Management

Reactive state objects — bind once, update everywhere:

```lua
local State = require(NexusUI.Modules.Core.State)

local enabled = State.new(false)

Toggle:BindState(enabled, function(toggle, value)
	toggle:SetValue(value, false)
end)

enabled:Set(true)   -- every bound component updates
```

State supports validators, derived states via `:Map()`, transforms, and instance binding:

```lua
local count = State.new(0)
count:AddValidator(function(v) return v >= 0 end)

local doubled = count:Map(function(v) return v * 2 end)

count:Subscribe(function(value) print("count:", value) end)
count:Set(5)   -- doubled is now 10
```

---

## Configuration

```lua
NexusUI.Config.PerformanceMode = true     -- reduce animations
NexusUI.Config.Debug = true               -- enable debug overlay
NexusUI.Config.AnimationSpeed = 1         -- global multiplier
NexusUI.Config.Sounds.Enabled = true      -- UI sounds
NexusUI.Config.Sounds.Volume = 0.35
NexusUI.Config.Notifications.Position = "Right"
NexusUI.Config.Notifications.MaxVisible = 6
NexusUI.Config.Notifications.Lifetime = 5
```

### Debug Overlay

```lua
local Debug = require(NexusUI.Modules.Services.Debug)
Debug:Enable()    -- live panel: components, tweens, springs, connections, windows, memory
Debug:Disable()
Debug:Toggle()
```

---

## Key System

Built-in verification gate:

```lua
local KeySystem = require(NexusUI.Modules.Services.KeySystem)

KeySystem.new({
	Title = "NexusUI Access",
	SubTitle = "Enter your key to continue",
	Key = "MY_SECRET_KEY",           -- simple string check
	-- or provide a custom validator:
	-- Validate = function(key) return myCheck(key) end,
	MaxAttempts = 3,
	OnValidated = function()
		-- launch your UI here
	end,
	OnFailed = function()
		-- kicked out
	end,
})
```

---

## Welcome Screen

```lua
local Welcome = require(NexusUI.Modules.Services.Welcome)
Welcome.new({
	Title = "NexusUI",
	SubTitle = "Premium Interface Framework",
	Version = "1.0.0",
	Duration = 3,
	OnFinished = function() end,
})
```

---

## Performance Notes

- Springs share a single Heartbeat manager and auto-sleep when settled — zero idle cost
- Tweens auto-cancel conflicting animations on the same instance
- All connections are Maid-tracked and cleaned on `Destroy()`
- `PerformanceMode` reduces animation intensity globally
- Components destroy their instance trees and signal graphs completely
- Notification queue auto-evicts oldest beyond `MaxVisible`

---

## Project Structure

```
NexusUI/
├── Loader.lua                  # HttpGet loader for executors
├── build/
│   ├── NexusUI.lua             # Single-file bundle (load this)
│   └── DemoRunner.lua          # Demo launcher
├── src/
│   ├── init.luau               # Entry point / public API
│   ├── Core/
│   │   ├── Signal.luau         # Custom signal implementation
│   │   ├── Maid.luau           # Task/connection cleanup
│   │   ├── Config.luau         # Global configuration
│   │   ├── Device.luau         # Platform detection & responsive scaling
│   │   ├── Icons.luau          # Icon registry
│   │   ├── Input.luau          # Input utilities (drag, hover, click)
│   │   └── Component.luau      # Base component contract
│   ├── Animation/
│   │   ├── Easing.luau         # 14 easing functions
│   │   ├── Spring.luau         # Spring physics + central manager
│   │   └── Animator.luau       # Tween wrapper, stagger, presets
│   ├── Theme/
│   │   ├── ThemeManager.luau   # Hot-swap engine
│   │   └── DefaultTheme.luau   # 9 built-in themes
│   ├── Components/
│   │   ├── BaseComponent.luau  # Component lifecycle base
│   │   ├── Window.luau
│   │   ├── Tab.luau
│   │   ├── Section.luau
│   │   ├── Button.luau
│   │   ├── Toggle.luau
│   │   ├── Checkbox.luau
│   │   ├── Slider.luau
│   │   ├── Dropdown.luau
│   │   ├── MultiDropdown.luau
│   │   ├── TextBox.luau
│   │   ├── SearchBox.luau
│   │   ├── Keybind.luau
│   │   ├── ColorPicker.luau
│   │   ├── ProgressBar.luau
│   │   ├── LoadingIndicator.luau
│   │   ├── Card.luau
│   │   ├── Image.luau
│   │   ├── Label.luau
│   │   ├── Paragraph.luau
│   │   ├── Divider.luau
│   │   ├── Badge.luau
│   │   ├── Toast.luau
│   │   ├── Tooltip.luau
│   │   ├── ContextMenu.luau
│   │   ├── Modal.luau
│   │   └── QuickActions.luau
│   ├── Services/
│   │   ├── NotificationSystem.luau
│   │   ├── CommandPalette.luau
│   │   ├── Preset.luau
│   │   ├── Debug.luau
│   │   ├── Fluent.luau
│   │   ├── Welcome.luau
│   │   └── KeySystem.luau
│   ├── Utilities/
│   │   ├── UIUtils.luau
│   │   └── Sound.luau
│   └── Demo/
│       └── Demo.luau           # Full interactive showcase
├── tools/
│   └── build.ps1               # Bundle compiler
└── docs/
```

---

## Supported Executors

| Executor | Status |
|---|---|
| Xeno | Supported |
| Delta | Supported |
| Solara | Supported |
| Wave | Supported |
| Codex | Supported |

Requires `loadstring`, `game:HttpGet` (or an `http_request` global), and CoreGui access (falls back to PlayerGui automatically).

---

## Repository

- **GitHub:** https://github.com/NexusUI1
- **Direct load:** https://raw.githubusercontent.com/NexusUI1/NexusUI/main/build/NexusUI.lua

## License

MIT License — see [LICENSE](LICENSE).
