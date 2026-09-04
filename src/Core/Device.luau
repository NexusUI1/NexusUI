local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Signal = require(script.Parent.Signal)

local Device = {}
Device.__index = Device

Device.Platform = "Unknown"
Device.IsTouch = false
Device.IsMobile = false
Device.IsConsole = false
Device.IsVR = false
Device.IsSmall = false
Device.Viewport = Vector2.new(1920, 1080)
Device.Scale = 1

Device.Changed = Signal.new()

function Device.Detect()
	local guiService = game:GetService("GuiService")

	Device.IsVR = UserInputService.VREnabled
	Device.IsTouch = UserInputService.TouchEnabled
	Device.IsConsole = guiService:IsTenFootInterface()

	local camera = workspace.CurrentCamera
	if camera then
		Device.Viewport = camera.ViewportSize
	end

	Device.IsSmall = Device.Viewport.X < 820

	if Device.IsVR then
		Device.Platform = "VR"
		Device.IsMobile = false
	elseif Device.IsConsole then
		Device.Platform = "Console"
		Device.IsMobile = true
	elseif Device.IsTouch and UserInputService.KeyboardEnabled then
		Device.Platform = "Tablet"
		Device.IsMobile = true
	elseif Device.IsTouch then
		Device.Platform = Device.IsSmall and "Mobile" or "Tablet"
		Device.IsMobile = true
	else
		Device.Platform = "PC"
		Device.IsMobile = false
	end

	Device:_updateScale()
	Device.Changed:Fire(Device.Platform, Device.Viewport)
	return Device
end

function Device:_updateScale()
	local scale = 1
	if Device.Platform == "Mobile" then
		scale = 0.85
	elseif Device.Platform == "Tablet" then
		scale = 0.95
	elseif Device.Platform == "Console" then
		scale = 1.1
	end
	if Device.IsSmall then
		scale = scale * 0.92
	end
	Device.Scale = scale
end

function Device.Start()
	Device.Detect()

	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			local oldPlatform = Device.Platform
			Device.Detect()
			if oldPlatform ~= Device.Platform then
				Device.Changed:Fire(Device.Platform, Device.Viewport)
			else
				Device.Changed:Fire(Device.Platform, Device.Viewport)
			end
		end)
	end

	UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function()
		Device.Detect()
	end)

	RunService.Heartbeat:Wait()
end

function Device.IsPlatform(name)
	return Device.Platform == name
end

function Device.IsHandheld()
	return Device.Platform == "Mobile" or Device.Platform == "Tablet"
end

function Device.GetScale()
	return Device.Scale
end

function Device.Scaled(value)
	return math.floor(value * Device.Scale + 0.5)
end

function Device.GetViewport()
	return Device.Viewport
end

function Device.CenterOffset(elementSize)
	return UDim2.new(
		0.5,
		-elementSize.X / 2,
		0.5,
		-elementSize.Y / 2
	)
end

function Device.FitToViewport(targetSize, padding)
	padding = padding or 20
	local vp = Device.Viewport
	local maxWidth = vp.X - padding * 2
	local maxHeight = vp.Y - padding * 2

	return UDim2.new(
		0,
		math.min(targetSize.X, maxWidth),
		0,
		math.min(targetSize.Y, maxHeight)
	)
end

Device.Detect()

return Device
