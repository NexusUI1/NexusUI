local Config = {
	Version = "1.0.0",
	Codename = "Nexus",
	Author = "NexusUI Team",
	Repository = "https://github.com/NexusUI1",

	Singleton = true,
	ExportGlobal = true,

	PerformanceMode = false,
	Debug = false,

	AutoMobile = true,
	DeviceScaleOverride = nil,

	Blur = true,
	Shadows = true,
	Ripples = true,
	Glow = true,
	Grain = false,

	Theme = "Midnight",

	Sounds = {
		Enabled = true,
		Volume = 0.35,
		Click = "rbxassetid://6895079853",
		Hover = "rbxassetid://6895076247",
		Open = "rbxassetid://6895070879",
		Close = "rbxassetid://6895069409",
		Error = "rbxassetid://550209561",
		Success = "rbxassetid://876939830",
		Toggle = "rbxassetid://6895079853",
		Pop = "rbxassetid://6895079853",
	},

	Notifications = {
		MaxVisible = 6,
		Lifetime = 5,
		Position = "Right",
		Width = 340,
		Spacing = 10,
	},

	CommandKeybind = Enum.KeyCode.K,
	CommandModifier = Enum.KeyCode.LeftControl,

	Watermark = false,

	AnimationSpeed = 1,

	Presets = {
		StorageFolder = "NexusUI",
		Autosave = false,
	},
}

function Config.Get(key)
	return Config[key]
end

function Config.Set(key, value)
	Config[key] = value
	return value
end

function Config.IsPerformanceMode()
	return Config.PerformanceMode == true
end

return Config
