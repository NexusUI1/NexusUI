-- NexusUI v1.0.0 | https://github.com/NexusUI1 | MIT License
-- Bundled build. Do not edit manually - rebuild with tools/build.py

local __MODULES = {}
local __CACHE = {}

__MODULES["Core.Signal"] = [[local Signal = {}
Signal.__index = Signal

Signal.GlobalConnections = 0

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn, once)
	local self = setmetatable({}, Connection)
	self.Connected = true
	self._signal = signal
	self._fn = fn
	self._once = once and true or false
	return self
end

function Connection:Disconnect()
	if not self.Connected then
		return
	end
	self.Connected = false

	local handlers = self._signal._handlers
	local index = table.find(handlers, self)
	if index then
		table.remove(handlers, index)
	end

	Signal.GlobalConnections = Signal.GlobalConnections - 1
	self._signal.Count = math.max(0, self._signal.Count - 1)
end

function Signal.new()
	local self = setmetatable({}, Signal)
	self._handlers = {}
	self._waiters = {}
	self.Count = 0
	self.Destroyed = false
	return self
end

function Signal:Connect(fn)
	assert(type(fn) == "function", "Signal:Connect expects a function")
	if self.Destroyed then
		warn("[NexusUI] Connect called on a destroyed Signal")
		return { Disconnect = function() end, Connected = false }
	end

	local connection = Connection.new(self, fn, false)
	table.insert(self._handlers, connection)
	self.Count = self.Count + 1
	Signal.GlobalConnections = Signal.GlobalConnections + 1
	return connection
end

function Signal:Once(fn)
	assert(type(fn) == "function", "Signal:Once expects a function")
	if self.Destroyed then
		return { Disconnect = function() end, Connected = false }
	end

	local connection = Connection.new(self, fn, true)
	table.insert(self._handlers, connection)
	self.Count = self.Count + 1
	Signal.GlobalConnections = Signal.GlobalConnections + 1
	return connection
end

function Signal:Fire(...)
	if self.Destroyed then
		return
	end

	local snapshot = table.create(#self._handlers)
	for i = 1, #self._handlers do
		snapshot[i] = self._handlers[i]
	end

	local args = table.pack(...)

	for i = 1, #snapshot do
		local connection = snapshot[i]
		if connection.Connected then
			if connection._once then
				connection:Disconnect()
			end
			task.spawn(connection._fn, table.unpack(args, 1, args.n))
		end
	end

	if #self._waiters > 0 then
		local waiters = self._waiters
		self._waiters = {}
		for i = 1, #waiters do
			task.spawn(waiters[i], table.unpack(args, 1, args.n))
		end
	end
end

function Signal:Wait()
	if self.Destroyed then
		return nil
	end
	local thread = coroutine.running()
	table.insert(self._waiters, thread)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	local handlers = self._handlers
	for i = #handlers, 1, -1 do
		handlers[i]:Disconnect()
	end
	self._handlers = {}

	local waiters = self._waiters
	for i = 1, #waiters do
		pcall(task.cancel, waiters[i])
	end
	self._waiters = {}
	self.Count = 0
end

function Signal:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	self:DisconnectAll()
end

return Signal
]]
__MODULES["Core.Maid"] = [[local Maid = {}
Maid.__index = Maid

Maid.TotalTasks = 0

local function isConnection(value)
	return type(value) == "table" and typeof == nil
end

local function cleanupTask(task)
	local taskType = typeof(task)

	if taskType == "RBXScriptConnection" then
		if task.Connected then
			task:Disconnect()
		end
	elseif taskType == "Instance" then
		task:Destroy()
	elseif taskType == "function" then
		task()
	elseif taskType == "table" then
		if type(task.Destroy) == "function" then
			task:Destroy()
		elseif type(task.Disconnect) == "function" then
			task:Disconnect()
		elseif type(task.Clean) == "function" then
			task:Clean()
		end
	end
end

function Maid.new()
	local self = setmetatable({}, Maid)
	self._tasks = {}
	self._count = 0
	self.Destroyed = false
	return self
end

function Maid:GiveTask(a, b)
	if type(a) == "string" and b ~= nil then
		self:RemoveTask(a)
		self._tasks[a] = b
		Maid.TotalTasks = Maid.TotalTasks + 1
		return b
	end

	if a == nil then
		return nil
	end

	table.insert(self._tasks, a)
	Maid.TotalTasks = Maid.TotalTasks + 1
	return a
end

function Maid:SetTask(key, task)
	return self:GiveTask(key, task)
end

function Maid:GetTask(key)
	return self._tasks[key]
end

function Maid:RemoveTask(key)
	local task = self._tasks[key]
	if task ~= nil then
		self._tasks[key] = nil
		pcall(cleanupTask, task)
		return true
	end
	return false
end

function Maid:GiveCleanup(fn)
	assert(type(fn) == "function", "Maid:GiveCleanup expects a function")
	return self:GiveTask(fn)
end

function Maid:Clean()
	if self.Destroyed then
		return
	end

	local tasks = self._tasks
	for _, task in pairs(tasks) do
		pcall(cleanupTask, task)
	end
	self._tasks = {}
	self._count = 0
end

function Maid:TaskCount()
	local n = 0
	for _ in pairs(self._tasks) do
		n = n + 1
	end
	return n
end

function Maid:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	self:Clean()
end

return Maid
]]
__MODULES["Core.Config"] = [[local Config = {
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
]]
__MODULES["Core.Device"] = [[local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Signal = __require("Core.Signal")

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
]]
__MODULES["Core.Icons"] = [[local ThemeManager = __require("Theme.ThemeManager")

local Icons = {}

Icons.Assets = {
	Settings = "rbxassetid://87292430131775",
	User = "rbxassetid://120021202596168",
	YouTube = "rbxassetid://121599916185381",
	Discord = "rbxassetid://90648224432355",
	Roblox = "rbxassetid://132237899568051",
	Ornament1 = "rbxassetid://75998043458177",
	Ornament2 = "rbxassetid://93581848875809",
	Ornament3 = "rbxassetid://127900961105983",
	Ornament4 = "rbxassetid://83188478411160",
	Ornament5 = "rbxassetid://116174880608666",
	Ornament6 = "rbxassetid://99586711007519",
	Background = "rbxassetid://137809702642145",
	Shadow = "rbxassetid://6015897843",
}

Icons.Glyphs = {
	Check = "M",
	Cross = "X",
	Chevron = "C",
	ChevronUp = "^",
	ChevronDown = "v",
	ChevronLeft = "<",
	ChevronRight = ">",
	Plus = "+",
	Minus = "-",
	Dot = "o",
	Menu = "=",
	Search = "s",
	Dots = "...",
	Circle = "O",
	ArrowUp = "^",
	ArrowDown = "|",
	Star = "*",
	Bell = "b",
	Heart = "h",
	Home = "H",
	Grid = "G",
	List = "L",
	Play = "P",
	Pause = "|",
	Stop = ".",
	Square = "#",
}

function Icons.Get(name)
	return Icons.Assets[name] or Icons.Assets.Ornament1
end

function Icons.GetGlyph(name)
	return Icons.Glyphs[name] or Icons.Glyphs.Dot
end

function Icons.IsAsset(name)
	return Icons.Assets[name] ~= nil
end

function Icons.CreateImage(parent, name, size, position, anchorPoint)
	local image = Instance.new("ImageLabel")
	image.Name = name .. "Icon"
	image.BackgroundTransparency = 1
	image.Image = Icons.Get(name)
	image.ImageColor3 = ThemeManager.GetTokens().Text
	image.ScaleType = Enum.ScaleType.Fit
	image.Size = size or UDim2.new(0, 24, 0, 24)
	image.Position = position or UDim2.new(0, 0, 0.5, 0)
	image.AnchorPoint = anchorPoint or Vector2.new(0, 0.5)
	image.ZIndex = parent.ZIndex + 1
	image.Parent = parent
	return image
end

function Icons.CreateGlyph(parent, name, size, position)
	local label = Instance.new("TextLabel")
	label.Name = name .. "Glyph"
	label.BackgroundTransparency = 1
	label.Text = Icons.GetGlyph(name)
	label.TextColor3 = ThemeManager.GetTokens().Text
	label.Font = Enum.Font.GothamBold
	label.TextSize = size or 16
	label.Size = UDim2.new(0, (size or 16) + 8, 0, (size or 16) + 8)
	label.Position = position or UDim2.new(0, 0, 0.5, 0)
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.ZIndex = parent.ZIndex + 1
	label.Parent = parent
	return label
end

function Icons.BindColor(imageLabel, tokenName)
	ThemeManager.Subscribe(function(tk)
		imageLabel.ImageColor3 = tk[tokenName] or tk.Text
	end)
	imageLabel.ImageColor3 = ThemeManager.GetTokens()[tokenName] or ThemeManager.GetTokens().Text
	return imageLabel
end

Icons.List = function()
	local names = {}
	for name in pairs(Icons.Assets) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return Icons
]]
__MODULES["Core.Input"] = [[local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Maid = __require("Core.Maid")

local Input = {}
Input.__index = Input

Input.Connected = false
Input._mouseListeners = {}
Input._keyListeners = {}

function Input.GetMouseLocation()
	local location = UserInputService:GetMouseLocation()
	local camera = workspace.CurrentCamera
	if camera then
		local viewport = camera.ViewportSize
		if location.Y > viewport.Y or location.X > viewport.X then
			return Vector2.new(
				math.clamp(location.X, 0, viewport.X),
				math.clamp(location.Y, 0, viewport.Y)
			)
		end
	end
	return location
end

function Input.IsMouseButtonDown(button)
	return UserInputService:IsMouseButtonPressed(button or Enum.UserInputType.MouseButton1)
end

function Input.IsKeyDown(keyCode)
	return UserInputService:IsKeyDown(keyCode)
end

function Input.IsGamepadButtonDown(button)
	return UserInputService:IsGamepadButtonDown(Enum.GamepadType.Gamepad1, button)
end

function Input.IsTouch()
	return UserInputService.TouchEnabled
end

function Input.IsKeyboard()
	return UserInputService.KeyboardEnabled
end

function Input.IsMouse()
	return UserInputService.MouseEnabled
end

function Input.OnMouseMoved(fn)
	local connection = UserInputService.InputChanged:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			fn(input.Position, processed)
		end
	end)
	return connection
end

function Input.OnMouseDown(fn)
	local connection = UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			fn(input.Position, processed)
		end
	end)
	return connection
end

function Input.OnMouseUp(fn)
	local connection = UserInputService.InputEnded:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			fn(input.Position, processed)
		end
	end)
	return connection
end

function Input.OnKeyDown(fn)
	local connection = UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			fn(input.KeyCode, processed)
		end
	end)
	return connection
end

function Input.OnGamepadInput(fn)
	local connection = UserInputService.InputBegan:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.Gamepad1 then
			fn(input.KeyCode, processed)
		end
	end)
	return connection
end

function Input.PositionInBounds(frame, position)
	local absPos = frame.AbsolutePosition
	local absSize = frame.AbsoluteSize
	return position.X >= absPos.X
		and position.X <= absPos.X + absSize.X
		and position.Y >= absPos.Y
		and position.Y <= absPos.Y + absSize.Y
end

function Input.RelativeToFrame(frame, position)
	local absPos = frame.AbsolutePosition
	return Vector2.new(position.X - absPos.X, position.Y - absPos.Y)
end

function Input.DragHandler(frame, callbacks)
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local connection = { Disconnections = {} }

	local maid = Maid.new()

	maid:GiveTask(frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			if callbacks.OnStart then
				callbacks.OnStart(input.Position, frame.Position)
			end

			local moveConnection = UserInputService.InputChanged:Connect(function(moveInput)
				if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement
					or moveInput.UserInputType == Enum.UserInputType.Touch) then
					local delta = moveInput.Position - dragStart
					local newPos = UDim2.new(
						startPos.X.Scale,
						startPos.X.Offset + delta.X,
						startPos.Y.Scale,
						startPos.Y.Offset + delta.Y
					)
					frame.Position = newPos

					if callbacks.OnMove then
						callbacks.OnMove(newPos, delta, moveInput.Position)
					end
				end
			end)

			local endConnection = UserInputService.InputEnded:Connect(function(endInput)
				if endInput.UserInputType == Enum.UserInputType.MouseButton1
					or endInput.UserInputType == Enum.UserInputType.Touch then
					dragging = false
					moveConnection:Disconnect()
					endConnection:Disconnect()

					if callbacks.OnEnd then
						callbacks.OnEnd(frame.Position)
					end
				end
			end)

			maid:GiveTask(moveConnection)
			maid:GiveTask(endConnection)
		end
	end))

	maid:GiveTask(function()
		dragging = false
	end)

	return maid
end

function Input.ClickHandler(frame, callbacks)
	local pressed = false

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			pressed = true

			if callbacks.OnPress then
				callbacks.OnPress(input.Position)
			end
		end
	end)

	frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if pressed then
				pressed = false

				if callbacks.OnRelease then
					callbacks.OnRelease(input.Position)
				end
			end
		end
	end)

	frame.MouseButton1Click:Connect(function()
		if callbacks.OnClick then
			callbacks.OnClick()
		end
	end)

	frame.MouseEnter:Connect(function()
		if callbacks.OnHover then
			callbacks.OnHover()
		end
	end)

	frame.MouseLeave:Connect(function()
		if callbacks.OnUnhover then
			callbacks.OnUnhover()
		end
	end)
end

function Input.ScrollHandler(frame, callbacks)
	local scrollConnection = frame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if callbacks.OnScroll then
			callbacks.OnScroll(frame.CanvasPosition.Y)
		end
	end)

	if callbacks.OnScrollDown then
		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseWheel then
				if input.Position.Z < 0 then
					callbacks.OnScrollDown()
				else
					if callbacks.OnScrollUp then
						callbacks.OnScrollUp()
					end
				end
			end
		end)
	end

	return scrollConnection
end

function Input.HoverTracker(frame, callbacks)
	frame.MouseEnter:Connect(function()
		if callbacks.OnEnter then
			callbacks.OnEnter()
		end
	end)

	frame.MouseLeave:Connect(function()
		if callbacks.OnLeave then
			callbacks.OnLeave()
		end
	end)
end

function Input.GetTextFromUser(placeHolder, parent)
	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(0, 200, 0, 30)
	textBox.PlaceholderText = placeHolder or "Enter text..."
	textBox.Text = ""
	textBox.ClearTextOnFocus = false
	textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.Font = Enum.Font.Gotham
	textBox.TextSize = 14
	textBox.Parent = parent or game:GetService("CoreGui")

	return textBox
end

function Input.MouseInFrame(frame)
	local mousePos = Input.GetMouseLocation()
	return Input.PositionInBounds(frame, mousePos)
end

function Input.TrackHover(frame, onEnter, onLeave)
	frame.MouseEnter:Connect(onEnter)
	frame.MouseLeave:Connect(onLeave)
end

function Input.KeyName(keyCode)
	if keyCode == Enum.KeyCode.Unknown then
		return "Unknown"
	end

	local name = UserInputService:GetStringForKeyCode(keyCode)
	if name and name ~= "" then
		return name
	end

	local names = {
		[Enum.KeyCode.LeftShift] = "LShift",
		[Enum.KeyCode.RightShift] = "RShift",
		[Enum.KeyCode.LeftControl] = "LCtrl",
		[Enum.KeyCode.RightControl] = "RCtrl",
		[Enum.KeyCode.LeftAlt] = "LAlt",
		[Enum.KeyCode.RightAlt] = "RAlt",
		[Enum.KeyCode.Return] = "Enter",
		[Enum.KeyCode.Escape] = "Esc",
		[Enum.KeyCode.Backspace] = "Backspace",
		[Enum.KeyCode.Tab] = "Tab",
		[Enum.KeyCode.CapsLock] = "CapsLock",
		[Enum.KeyCode.Space] = "Space",
		[Enum.KeyCode.PageUp] = "PageUp",
		[Enum.KeyCode.PageDown] = "PageDown",
		[Enum.KeyCode.Home] = "Home",
		[Enum.KeyCode.End] = "End",
		[Enum.KeyCode.Insert] = "Insert",
		[Enum.KeyCode.Delete] = "Delete",
	}

	return names[keyCode] or keyCode.Name
end

function Input.GetLastInputType()
	return UserInputService:GetLastInputType()
end

function Input.IsLastInputTouch()
	local last = UserInputService:GetLastInputType()
	return last == Enum.UserInputType.Touch
end

function Input.IsLastInputGamepad()
	local last = UserInputService:GetLastInputType()
	return last == Enum.UserInputType.Gamepad1
		or last == Enum.UserInputType.Gamepad2
		or last == Enum.UserInputType.Gamepad3
		or last == Enum.UserInputType.Gamepad4
end

Input.GuiInset = Vector2.new(0, 58)
pcall(function()
	local guiService = game:GetService("GuiService")
	local inset = guiService:GetGuiInset()
	Input.GuiInset = inset
end)

return Input
]]
__MODULES["Animation.Easing"] = [[local Easing = {}

Easing.Linear = function(t)
	return t
end

Easing.Sine = function(t)
	return -(math.cos(math.pi * t) - 1) / 2
end

Easing.Quad = function(t)
	if t < 0.5 then
		return 2 * t * t
	end
	return 1 - math.pow(-2 * t + 2, 2) / 2
end

Easing.Cubic = function(t)
	if t < 0.5 then
		return 4 * t * t * t
	end
	return 1 - math.pow(-2 * t + 2, 3) / 2
end

Easing.Quart = function(t)
	if t < 0.5 then
		return 8 * t * t * t * t
	end
	return 1 - math.pow(-2 * t + 2, 4) / 2
end

Easing.Quint = function(t)
	if t < 0.5 then
		return 16 * t * t * t * t * t
	end
	return 1 - math.pow(-2 * t + 2, 5) / 2
end

Easing.Expo = function(t)
	if t == 0 then
		return 0
	end
	if t == 1 then
		return 1
	end
	if t < 0.5 then
		return math.pow(2, 20 * t - 10) / 2
	end
	return (2 - math.pow(2, -20 * t + 10)) / 2
end

Easing.Circ = function(t)
	if t < 0.5 then
		return (1 - math.sqrt(1 - math.pow(2 * t, 2))) / 2
	end
	return (math.sqrt(1 - math.pow(-2 * t + 2, 2)) + 1) / 2
end

Easing.Back = function(t)
	local c1 = 1.70158
	local c2 = c1 * 1.525
	if t < 0.5 then
		return (math.pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
	end
	return (math.pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
end

Easing.Elastic = function(t)
	local c4 = (2 * math.pi) / 3
	if t == 0 then
		return 0
	end
	if t == 1 then
		return 1
	end
	if t < 0.5 then
		return -(math.pow(2, 20 * t - 10) * math.sin((20 * t - 11.125) * c4)) / 2
	end
	return (math.pow(2, -20 * t + 10) * math.sin((20 * t - 11.125) * c4)) / 2 + 1
end

Easing.Bounce = function(t)
	local n1 = 7.5625
	local d1 = 2.75
	if t < 1 / d1 then
		return n1 * t * t
	elseif t < 2 / d1 then
		t = t - 1.5 / d1
		return n1 * t * t + 0.75
	elseif t < 2.5 / d1 then
		t = t - 2.25 / d1
		return n1 * t * t + 0.9375
	else
		t = t - 2.625 / d1
		return n1 * t * t + 0.984375
	end
end

Easing.Spring = function(t)
	local damping = 26
	local mass = 1
	local stiffness = 170
	local initial = 0
	local target = 1

	local omega = math.sqrt(stiffness / mass)
	local zeta = damping / (2 * math.sqrt(stiffness * mass))
	local x = t - 1

	if zeta < 1 then
		local omegaD = omega * math.sqrt(1 - zeta * zeta)
		return 1 - math.exp(-zeta * omega * t) * (math.cos(omegaD * t) + (zeta * omega / omegaD) * math.sin(omegaD * t))
	else
		return 1 - (1 + omega * t) * math.exp(-omega * t)
	end
end

Easing.SmoothStep = function(t)
	return t * t * (3 - 2 * t)
end

Easing.SmootherStep = function(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

Easing.InOut = function(t, fn)
	return fn(t)
end

Easing.In = function(t, fn)
	return fn(t * t)
end

Easing.Out = function(t, fn)
	return 1 - fn(1 - t)
end

Easing.Resolve = function(name)
	if type(name) == "function" then
		return name
	end
	return Easing[name] or Easing.Quad
end

Easing.Names = {
	"Linear", "Sine", "Quad", "Cubic", "Quart", "Quint",
	"Expo", "Circ", "Back", "Elastic", "Bounce", "Spring",
	"SmoothStep", "SmootherStep",
}

return Easing
]]
__MODULES["Animation.Spring"] = [[local Easing = __require("Animation.Easing")

local Spring = {}
Spring.__index = Spring

Spring.Active = {}
Spring.ActiveCount = 0
Spring.ManagerRunning = false

local RunService = game:GetService("RunService")

function Spring.new(initialValue, config)
	config = config or {}

	local self = setmetatable({}, Spring)
	self.Value = initialValue
	self.Target = initialValue
	self.Velocity = 0
	self.Damping = config.Damping or 24
	self.Stiffness = config.Stiffness or 180
	self.Precision = config.Precision or 0.001
	self.Speed = config.Speed or 1

	self._onUpdate = nil
	self._destroyed = false
	self._sleeping = true

	return self
end

function Spring:SetTarget(target)
	self.Target = target
	self._sleeping = false
	Spring._addToManager(self)
	return self
end

function Spring:SetValue(value)
	self.Value = value
	self.Target = value
	self.Velocity = 0
	self._sleeping = true
	self:_emit()
	return self
end

function Spring:Impulse(velocity)
	self.Velocity = self.Velocity + velocity
	self._sleeping = false
	Spring._addToManager(self)
	return self
end

function Spring:OnUpdate(fn)
	self._onUpdate = fn
	if self._sleeping then
		fn(self.Value)
	end
	return self
end

function Spring:_emit()
	if self._onUpdate then
		self._onUpdate(self.Value)
	end
end

function Spring:Step(dt)
	if self._destroyed or self._sleeping then
		return true
	end

	dt = math.min(dt, 1 / 30) * self.Speed

	local displacement = self.Value - self.Target
	local springForce = -self.Stiffness * displacement
	local dampingForce = -self.Damping * self.Velocity
	local acceleration = springForce + dampingForce

	self.Velocity = self.Velocity + acceleration * dt
	self.Value = self.Value + self.Velocity * dt

	if
		math.abs(self.Value - self.Target) < self.Precision
		and math.abs(self.Velocity) < self.Precision * 10
	then
		self.Value = self.Target
		self.Velocity = 0
		self._sleeping = true
		self:_emit()
		return true
	end

	self:_emit()
	return false
end

function Spring:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	Spring._removeFromManager(self)
	self._onUpdate = nil
end

function Spring.IsSleeping(spring)
	return spring._sleeping
end

function Spring._addToManager(spring)
	if Spring.Active[spring] then
		return
	end
	Spring.Active[spring] = true
	Spring.ActiveCount = Spring.ActiveCount + 1
	Spring._startManager()
end

function Spring._removeFromManager(spring)
	if not Spring.Active[spring] then
		return
	end
	Spring.Active[spring] = nil
	Spring.ActiveCount = Spring.ActiveCount - 1
end

function Spring._startManager()
	if Spring.ManagerRunning then
		return
	end
	Spring.ManagerRunning = true

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		local finished = {}

		for spring in pairs(Spring.Active) do
			local done = spring:Step(dt)
			if done then
				table.insert(finished, spring)
			end
		end

		for i = 1, #finished do
			Spring._removeFromManager(finished[i])
		end

		if Spring.ActiveCount == 0 then
			connection:Disconnect()
			Spring.ManagerRunning = false
		end
	end)
end

function Spring.Stats()
	return {
		Active = Spring.ActiveCount,
		Running = Spring.ManagerRunning,
	}
end

Spring.Easing = Easing

return Spring
]]
__MODULES["Animation.Animator"] = [[local TweenService = game:GetService("TweenService")

local Easing = __require("Animation.Easing")

local Animator = {}
Animator.__index = Animator

local activeTweens = {}

local function tweenInfo(duration, easingStyle, easingDirection)
	return TweenInfo.new(
		duration or 0.3,
		easingStyle or Enum.EasingStyle.Quad,
		easingDirection or Enum.EasingDirection.Out
	)
end

local function mapEasing(name, direction)
	if type(name) == "table" and name.Style then
		return tweenInfo(name.Duration or 0.3, name.Style, name.Direction or Enum.EasingDirection.Out)
	end

	local styleMap = {
		Linear = Enum.EasingStyle.Linear,
		Sine = Enum.EasingStyle.Sine,
		Quad = Enum.EasingStyle.Quad,
		Cubic = Enum.EasingStyle.Cubic,
		Quart = Enum.EasingStyle.Quart,
		Quint = Enum.EasingStyle.Quint,
		Expo = Enum.EasingStyle.Exponential,
		Circ = Enum.EasingStyle.Circular,
		Back = Enum.EasingStyle.Back,
		Elastic = Enum.EasingStyle.Elastic,
		Bounce = Enum.EasingStyle.Bounce,
	}

	local style = styleMap[name] or Enum.EasingStyle.Quad
	local dir = direction == "In" and Enum.EasingDirection.In
		or direction == "InOut" and Enum.EasingDirection.InOut
		or Enum.EasingDirection.Out

	return tweenInfo(0.3, style, dir)
end

function Animator.Tween(instance, props, duration, easingName, direction)
	if typeof(instance) ~= "Instance" then
		return nil
	end

	local info
	if type(duration) == "table" then
		info = TweenInfo.new(
			duration.Duration or 0.3,
			duration.Style or Enum.EasingStyle.Quad,
			duration.Direction or Enum.EasingDirection.Out
		)
	else
		info = mapEasing(easingName, direction)
		info = TweenInfo.new(duration or 0.3, info.EasingStyle, info.EasingDirection)
	end

	local old = activeTweens[instance]
	if old then
		pcall(function() old:Cancel() end)
	end

	local tween = TweenService:Create(instance, info, props)
	activeTweens[instance] = tween
	tween:Play()

	tween.Completed:Once(function()
		if activeTweens[instance] == tween then
			activeTweens[instance] = nil
		end
	end)

	return tween
end

function Animator.Cancel(instance)
	local tween = activeTweens[instance]
	if tween then
		tween:Cancel()
		activeTweens[instance] = nil
	end
end

function Animator.IsActive(instance)
	return activeTweens[instance] ~= nil
end

function Animator.ActiveCount()
	local n = 0
	for _ in pairs(activeTweens) do
		n = n + 1
	end
	return n
end

function Animator.FadeIn(instance, duration, easingName)
	if typeof(instance) ~= "Instance" then return end
	local startTransparency = 1
	if instance:IsA("GuiObject") then
		instance.BackgroundTransparency = startTransparency
	end
	for _, child in ipairs(instance:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child.TextTransparency = startTransparency
			child.TextStrokeTransparency = startTransparency
		elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
			child.ImageTransparency = startTransparency
		end
	end
	return Animator.Tween(instance, { BackgroundTransparency = 0 }, duration or 0.35, easingName or "Quad")
end

function Animator.FadeOut(instance, duration, easingName)
	if typeof(instance) ~= "Instance" then return end
	return Animator.Tween(instance, { BackgroundTransparency = 1 }, duration or 0.3, easingName or "Quad")
end

function Animator.Scale(instance, from, to, duration, easingName)
	if typeof(instance) ~= "Instance" then return end

	local scale = instance:FindFirstChild("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = instance
	end

	scale.Scale = from or 0.85
	return Animator.Tween(scale, { Scale = to or 1 }, duration or 0.35, easingName or "Back")
end

function Animator.Slide(instance, direction, distance, duration, easingName)
	if typeof(instance) ~= "Instance" then return end

	local original = instance.Position
	local offset
	if direction == "Up" then
		offset = UDim2.new(original.X.Scale, original.X.Offset, original.Y.Scale, original.Y.Offset + (distance or 20))
	elseif direction == "Down" then
		offset = UDim2.new(original.X.Scale, original.X.Offset, original.Y.Scale, original.Y.Offset - (distance or 20))
	elseif direction == "Left" then
		offset = UDim2.new(original.X.Scale, original.X.Offset + (distance or 30), original.Y.Scale, original.Y.Offset)
	else
		offset = UDim2.new(original.X.Scale, original.X.Offset - (distance or 30), original.Y.Scale, original.Y.Offset)
	end

	instance.Position = offset
	return Animator.Tween(instance, { Position = original }, duration or 0.4, easingName or "Quart")
end

function Animator.Stagger(instances, applyFn, staggerDelay, startDelay)
	if type(instances) ~= "table" or type(applyFn) ~= "function" then
		return
	end

	staggerDelay = staggerDelay or 0.04
	startDelay = startDelay or 0

	task.spawn(function()
		for i, instance in ipairs(instances) do
			task.delay(startDelay + (i - 1) * staggerDelay, function()
				applyFn(instance, i)
			end)
		end
	end)
end

function Animator.Sequence(steps)
	task.spawn(function()
		for _, step in ipairs(steps) do
			if type(step) == "function" then
				step()
			elseif type(step) == "table" and step.Run then
				step.Run()
			end
		end
	end)
end

Animator.Easing = Easing

return Animator
]]
__MODULES["Theme.ThemeManager"] = [[local ThemeManager = {}
ThemeManager.__index = ThemeManager

local Tokens = __require("Theme.DefaultTheme")

ThemeManager.Current = Tokens.Midnight
ThemeManager.CurrentName = "Midnight"
ThemeManager.CustomThemes = {}
ThemeManager.Subscribers = {}

local function shallowCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = v
	end
	return copy
end

function ThemeManager.GetTheme(name)
	if ThemeManager.CustomThemes[name] then
		return shallowCopy(ThemeManager.CustomThemes[name])
	end
	return shallowCopy(Tokens[name] or {})
end

function ThemeManager.ListThemes()
	local names = {}
	for name in pairs(Tokens) do
		table.insert(names, name)
	end
	for name in pairs(ThemeManager.CustomThemes) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function ThemeManager.GetTokens()
	return ThemeManager.Current
end

function ThemeManager.RegisterTheme(name, tokens)
	assert(type(name) == "string", "RegisterTheme expects a string name")
	assert(type(tokens) == "table", "RegisterTheme expects a token table")

	ThemeManager.CustomThemes[name] = shallowCopy(tokens)
	return ThemeManager
end

function ThemeManager.UnregisterTheme(name)
	if ThemeManager.CurrentName == name then
		return false
	end
	ThemeManager.CustomThemes[name] = nil
	return true
end

function ThemeManager.SetTheme(theme)
	if type(theme) == "string" then
		local found = ThemeManager.CustomThemes[theme] or Tokens[theme]
		assert(found, "[NexusUI] Unknown theme: " .. tostring(theme))
		ThemeManager.Current = shallowCopy(found)
		ThemeManager.CurrentName = theme
	elseif type(theme) == "table" then
		local merged = shallowCopy(ThemeManager.Current)
		for k, v in pairs(theme) do
			merged[k] = v
		end
		ThemeManager.Current = merged
		ThemeManager.CurrentName = "Custom"
	end

	for _, fn in ipairs(ThemeManager.Subscribers) do
		task.spawn(fn, ThemeManager.Current, ThemeManager.CurrentName)
	end

	return ThemeManager
end

function ThemeManager.Subscribe(fn)
	if type(fn) ~= "function" then
		return function() end
	end

	table.insert(ThemeManager.Subscribers, fn)

	local index = #ThemeManager.Subscribers
	return function()
		table.remove(ThemeManager.Subscribers, index)
	end
end

function ThemeManager.IsDark(theme)
	local tokens = theme or ThemeManager.Current
	local bg = tokens.Background
	if not bg then
		return true
	end
	local lum = 0.299 * bg.R + 0.587 * bg.G + 0.114 * bg.B
	return lum < 0.5
end

return ThemeManager
]]
__MODULES["Theme.DefaultTheme"] = [[local ThemeManager = __require("Theme.ThemeManager")

local DefaultTheme = {}

DefaultTheme.Midnight = {
	Name = "Midnight",
	Background = Color3.fromRGB(11, 13, 20),
	Surface = Color3.fromRGB(18, 21, 31),
	SurfaceLight = Color3.fromRGB(26, 30, 44),
	Elevated = Color3.fromRGB(32, 37, 54),
	Accent = Color3.fromRGB(96, 130, 255),
	AccentDark = Color3.fromRGB(62, 92, 214),
	AccentLight = Color3.fromRGB(140, 165, 255),
	Text = Color3.fromRGB(240, 243, 250),
	SecondaryText = Color3.fromRGB(152, 160, 178),
	MutedText = Color3.fromRGB(102, 110, 128),
	Border = Color3.fromRGB(38, 44, 62),
	BorderLight = Color3.fromRGB(52, 60, 82),
	Shadow = Color3.fromRGB(0, 0, 0),
	Success = Color3.fromRGB(60, 200, 120),
	Error = Color3.fromRGB(240, 84, 96),
	Warning = Color3.fromRGB(255, 176, 72),
	Info = Color3.fromRGB(84, 170, 255),

	Corner = UDim.new(0, 10),
	CornerLarge = UDim.new(0, 16),
	CornerSmall = UDim.new(0, 6),
	CornerCircle = UDim.new(1, 0),

	StrokeThickness = 1,
	StrokeTransparency = 0.6,

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontLight = Enum.Font.Gotham,

	TextSize = 14,
	TitleSize = 18,
	DescriptionSize = 13,

	Padding = 10,
	Margin = 8,
	Spacing = 6,

	GradientRotation = 90,
	AccentTransparency = 0,

	WindowTransparency = 0,
	ScrollBars = Color3.fromRGB(96, 130, 255),
	ScrollThickness = 3,

	HoverLighten = 0.06,
	PressDarken = 0.12,

	AnimationSpeed = 1,
	BlurRadius = 12,
}

DefaultTheme.Ocean = {
	Name = "Ocean",
	Background = Color3.fromRGB(8, 24, 38),
	Surface = Color3.fromRGB(13, 35, 54),
	SurfaceLight = Color3.fromRGB(19, 47, 70),
	Elevated = Color3.fromRGB(26, 60, 88),
	Accent = Color3.fromRGB(52, 190, 224),
	AccentDark = Color3.fromRGB(34, 148, 182),
	AccentLight = Color3.fromRGB(120, 216, 244),
	Text = Color3.fromRGB(232, 246, 252),
	SecondaryText = Color3.fromRGB(134, 172, 190),
	MutedText = Color3.fromRGB(94, 130, 148),
	Border = Color3.fromRGB(26, 54, 76),
	BorderLight = Color3.fromRGB(38, 74, 100),
	Shadow = Color3.fromRGB(0, 0, 0),
	Success = Color3.fromRGB(66, 210, 150),
	Error = Color3.fromRGB(244, 90, 106),
	Warning = Color3.fromRGB(255, 186, 90),
	Info = Color3.fromRGB(94, 190, 240),

	Corner = UDim.new(0, 10),
	CornerLarge = UDim.new(0, 16),
	CornerSmall = UDim.new(0, 6),
	CornerCircle = UDim.new(1, 0),

	StrokeThickness = 1,
	StrokeTransparency = 0.6,

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontLight = Enum.Font.Gotham,

	TextSize = 14,
	TitleSize = 18,
	DescriptionSize = 13,

	Padding = 10,
	Margin = 8,
	Spacing = 6,

	GradientRotation = 90,
	AccentTransparency = 0,

	WindowTransparency = 0,
	ScrollBars = Color3.fromRGB(52, 190, 224),
	ScrollThickness = 3,

	HoverLighten = 0.06,
	PressDarken = 0.12,

	AnimationSpeed = 1,
	BlurRadius = 12,
}

DefaultTheme.Crimson = {
	Name = "Crimson",
	Background = Color3.fromRGB(20, 10, 14),
	Surface = Color3.fromRGB(32, 17, 22),
	SurfaceLight = Color3.fromRGB(44, 24, 31),
	Elevated = Color3.fromRGB(58, 32, 41),
	Accent = Color3.fromRGB(235, 74, 94),
	AccentDark = Color3.fromRGB(192, 50, 68),
	AccentLight = Color3.fromRGB(255, 130, 146),
	Text = Color3.fromRGB(250, 236, 240),
	SecondaryText = Color3.fromRGB(186, 146, 156),
	MutedText = Color3.fromRGB(140, 106, 116),
	Border = Color3.fromRGB(56, 30, 38),
	BorderLight = Color3.fromRGB(76, 42, 52),
	Shadow = Color3.fromRGB(0, 0, 0),
	Success = Color3.fromRGB(80, 210, 140),
	Error = Color3.fromRGB(250, 96, 110),
	Warning = Color3.fromRGB(255, 190, 100),
	Info = Color3.fromRGB(120, 180, 250),

	Corner = UDim.new(0, 10),
	CornerLarge = UDim.new(0, 16),
	CornerSmall = UDim.new(0, 6),
	CornerCircle = UDim.new(1, 0),

	StrokeThickness = 1,
	StrokeTransparency = 0.6,

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontLight = Enum.Font.Gotham,

	TextSize = 14,
	TitleSize = 18,
	DescriptionSize = 13,

	Padding = 10,
	Margin = 8,
	Spacing = 6,

	GradientRotation = 90,
	AccentTransparency = 0,

	WindowTransparency = 0,
	ScrollBars = Color3.fromRGB(235, 74, 94),
	ScrollThickness = 3,

	HoverLighten = 0.06,
	PressDarken = 0.12,

	AnimationSpeed = 1,
	BlurRadius = 12,
}

DefaultTheme.Emerald = {
	Name = "Emerald",
	Background = Color3.fromRGB(8, 20, 16),
	Surface = Color3.fromRGB(14, 32, 26),
	SurfaceLight = Color3.fromRGB(20, 44, 36),
	Elevated = Color3.fromRGB(28, 58, 48),
	Accent = Color3.fromRGB(64, 212, 140),
	AccentDark = Color3.fromRGB(42, 170, 110),
	AccentLight = Color3.fromRGB(130, 240, 185),
	Text = Color3.fromRGB(234, 250, 242),
	SecondaryText = Color3.fromRGB(148, 186, 168),
	MutedText = Color3.fromRGB(108, 142, 126),
	Border = Color3.fromRGB(30, 54, 44),
	BorderLight = Color3.fromRGB(44, 74, 62),
	Shadow = Color3.fromRGB(0, 0, 0),
	Success = Color3.fromRGB(70, 220, 150),
	Error = Color3.fromRGB(248, 100, 110),
	Warning = Color3.fromRGB(255, 192, 96),
	Info = Color3.fromRGB(110, 190, 250),

	Corner = UDim.new(0, 10),
	CornerLarge = UDim.new(0, 16),
	CornerSmall = UDim.new(0, 6),
	CornerCircle = UDim.new(1, 0),

	StrokeThickness = 1,
	StrokeTransparency = 0.6,

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontLight = Enum.Font.Gotham,

	TextSize = 14,
	TitleSize = 18,
	DescriptionSize = 13,

	Padding = 10,
	Margin = 8,
	Spacing = 6,

	GradientRotation = 90,
	AccentTransparency = 0,

	WindowTransparency = 0,
	ScrollBars = Color3.fromRGB(64, 212, 140),
	ScrollThickness = 3,

	HoverLighten = 0.06,
	PressDarken = 0.12,

	AnimationSpeed = 1,
	BlurRadius = 12,
}

DefaultTheme.Amber = {
	Name = "Amber",
	Background = Color3.fromRGB(22, 17, 8),
	Surface = Color3.fromRGB(34, 26, 13),
	SurfaceLight = Color3.fromRGB(46, 36, 18),
	Elevated = Color3.fromRGB(62, 48, 25),
	Accent = Color3.fromRGB(255, 176, 60),
	AccentDark = Color3.fromRGB(210, 138, 40),
	AccentLight = Color3.fromRGB(255, 208, 130),
	Text = Color3.fromRGB(252, 244, 228),
	SecondaryText = Color3.fromRGB(196, 174, 138),
	MutedText = Color3.fromRGB(150, 132, 104),
	Border = Color3.fromRGB(62, 48, 24),
	BorderLight = Color3.fromRGB(84, 66, 34),
	Shadow = Color3.fromRGB(0, 0, 0),
	Success = Color3.fromRGB(90, 210, 140),
	Error = Color3.fromRGB(250, 96, 96),
	Warning = Color3.fromRGB(255, 200, 90),
	Info = Color3.fromRGB(120, 190, 250),

	Corner = UDim.new(0, 10),
	CornerLarge = UDim.new(0, 16),
	CornerSmall = UDim.new(0, 6),
	CornerCircle = UDim.new(1, 0),

	StrokeThickness = 1,
	StrokeTransparency = 0.6,

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontLight = Enum.Font.Gotham,

	TextSize = 14,
	TitleSize = 18,
	DescriptionSize = 13,

	Padding = 10,
	Margin = 8,
	Spacing = 6,

	GradientRotation = 90,
	AccentTransparency = 0,

	WindowTransparency = 0,
	ScrollBars = Color3.fromRGB(255, 176, 60),
	ScrollThickness = 3,

	HoverLighten = 0.06,
	PressDarken = 0.12,

	AnimationSpeed = 1,
	BlurRadius = 12,
}

DefaultTheme.Light = {
	Name = "Light",
	Background = Color3.fromRGB(242, 244, 248),
	Surface = Color3.fromRGB(255, 255, 255),
	SurfaceLight = Color3.fromRGB(246, 248, 252),
	Elevated = Color3.fromRGB(235, 239, 246),
	Accent = Color3.fromRGB(60, 100, 246),
	AccentDark = Color3.fromRGB(44, 78, 200),
	AccentLight = Color3.fromRGB(122, 152, 255),
	Text = Color3.fromRGB(28, 32, 42),
	SecondaryText = Color3.fromRGB(96, 104, 122),
	MutedText = Color3.fromRGB(140, 148, 164),
	Border = Color3.fromRGB(222, 228, 238),
	BorderLight = Color3.fromRGB(204, 212, 226),
	Shadow = Color3.fromRGB(180, 188, 204),
	Success = Color3.fromRGB(40, 190, 110),
	Error = Color3.fromRGB(230, 74, 88),
	Warning = Color3.fromRGB(246, 168, 56),
	Info = Color3.fromRGB(70, 160, 250),

	Corner = UDim.new(0, 10),
	CornerLarge = UDim.new(0, 16),
	CornerSmall = UDim.new(0, 6),
	CornerCircle = UDim.new(1, 0),

	StrokeThickness = 1,
	StrokeTransparency = 0.5,

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontLight = Enum.Font.Gotham,

	TextSize = 14,
	TitleSize = 18,
	DescriptionSize = 13,

	Padding = 10,
	Margin = 8,
	Spacing = 6,

	GradientRotation = 90,
	AccentTransparency = 0,

	WindowTransparency = 0,
	ScrollBars = Color3.fromRGB(60, 100, 246),
	ScrollThickness = 3,

	HoverLighten = 0.03,
	PressDarken = 0.06,

	AnimationSpeed = 1,
	BlurRadius = 8,
}

DefaultTheme.Purple = {
	Name = "Purple",
	Background = Color3.fromRGB(16, 11, 26),
	Surface = Color3.fromRGB(25, 18, 40),
	SurfaceLight = Color3.fromRGB(34, 25, 55),
	Elevated = Color3.fromRGB(45, 33, 72),
	Accent = Color3.fromRGB(168, 108, 250),
	AccentDark = Color3.fromRGB(136, 82, 212),
	AccentLight = Color3.fromRGB(200, 158, 255),
	Text = Color3.fromRGB(244, 238, 252),
	SecondaryText = Color3.fromRGB(172, 156, 198),
	MutedText = Color3.fromRGB(130, 116, 158),
	Border = Color3.fromRGB(48, 36, 76),
	BorderLight = Color3.fromRGB(66, 50, 102),
	Shadow = Color3.fromRGB(0, 0, 0),
	Success = Color3.fromRGB(80, 210, 140),
	Error = Color3.fromRGB(248, 92, 104),
	Warning = Color3.fromRGB(255, 186, 88),
	Info = Color3.fromRGB(110, 180, 250),

	Corner = UDim.new(0, 10),
	CornerLarge = UDim.new(0, 16),
	CornerSmall = UDim.new(0, 6),
	CornerCircle = UDim.new(1, 0),

	StrokeThickness = 1,
	StrokeTransparency = 0.6,

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontLight = Enum.Font.Gotham,

	TextSize = 14,
	TitleSize = 18,
	DescriptionSize = 13,

	Padding = 10,
	Margin = 8,
	Spacing = 6,

	GradientRotation = 90,
	AccentTransparency = 0,

	WindowTransparency = 0,
	ScrollBars = Color3.fromRGB(168, 108, 250),
	ScrollThickness = 3,

	HoverLighten = 0.06,
	PressDarken = 0.12,

	AnimationSpeed = 1,
	BlurRadius = 12,
}

DefaultTheme.Vampire = {
	Name = "Vampire",
	Background = Color3.fromRGB(14, 6, 12),
	Surface = Color3.fromRGB(24, 10, 20),
	SurfaceLight = Color3.fromRGB(34, 14, 28),
	Elevated = Color3.fromRGB(48, 20, 40),
	Accent = Color3.fromRGB(240, 70, 130),
	AccentDark = Color3.fromRGB(196, 48, 102),
	AccentLight = Color3.fromRGB(255, 130, 180),
	Text = Color3.fromRGB(250, 238, 246),
	SecondaryText = Color3.fromRGB(190, 150, 176),
	MutedText = Color3.fromRGB(146, 110, 132),
	Border = Color3.fromRGB(52, 24, 44),
	BorderLight = Color3.fromRGB(72, 34, 60),
	Shadow = Color3.fromRGB(0, 0, 0),
	Success = Color3.fromRGB(80, 210, 140),
	Error = Color3.fromRGB(250, 88, 100),
	Warning = Color3.fromRGB(255, 186, 90),
	Info = Color3.fromRGB(120, 180, 250),

	Corner = UDim.new(0, 10),
	CornerLarge = UDim.new(0, 16),
	CornerSmall = UDim.new(0, 6),
	CornerCircle = UDim.new(1, 0),

	StrokeThickness = 1,
	StrokeTransparency = 0.6,

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontLight = Enum.Font.Gotham,

	TextSize = 14,
	TitleSize = 18,
	DescriptionSize = 13,

	Padding = 10,
	Margin = 8,
	Spacing = 6,

	GradientRotation = 90,
	AccentTransparency = 0,

	WindowTransparency = 0,
	ScrollBars = Color3.fromRGB(240, 70, 130),
	ScrollThickness = 3,

	HoverLighten = 0.06,
	PressDarken = 0.12,

	AnimationSpeed = 1,
	BlurRadius = 12,
}

DefaultTheme.Solar = {
	Name = "Solar",
	Background = Color3.fromRGB(18, 14, 6),
	Surface = Color3.fromRGB(30, 23, 10),
	SurfaceLight = Color3.fromRGB(42, 32, 14),
	Elevated = Color3.fromRGB(58, 44, 20),
	Accent = Color3.fromRGB(255, 148, 40),
	AccentDark = Color3.fromRGB(214, 118, 28),
	AccentLight = Color3.fromRGB(255, 192, 120),
	Text = Color3.fromRGB(252, 246, 232),
	SecondaryText = Color3.fromRGB(198, 180, 148),
	MutedText = Color3.fromRGB(152, 136, 108),
	Border = Color3.fromRGB(64, 48, 22),
	BorderLight = Color3.fromRGB(88, 66, 30),
	Shadow = Color3.fromRGB(0, 0, 0),
	Success = Color3.fromRGB(90, 210, 140),
	Error = Color3.fromRGB(250, 96, 96),
	Warning = Color3.fromRGB(255, 196, 80),
	Info = Color3.fromRGB(120, 190, 250),

	Corner = UDim.new(0, 10),
	CornerLarge = UDim.new(0, 16),
	CornerSmall = UDim.new(0, 6),
	CornerCircle = UDim.new(1, 0),

	StrokeThickness = 1,
	StrokeTransparency = 0.6,

	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	FontLight = Enum.Font.Gotham,

	TextSize = 14,
	TitleSize = 18,
	DescriptionSize = 13,

	Padding = 10,
	Margin = 8,
	Spacing = 6,

	GradientRotation = 90,
	AccentTransparency = 0,

	WindowTransparency = 0,
	ScrollBars = Color3.fromRGB(255, 148, 40),
	ScrollThickness = 3,

	HoverLighten = 0.06,
	PressDarken = 0.12,

	AnimationSpeed = 1,
	BlurRadius = 12,
}

function DefaultTheme.Apply(t)
	local ThemeManager = __require("Theme.ThemeManager")
	for name, tokens in pairs(t or DefaultTheme) do
		if type(tokens) == "table" and name ~= "Apply" then
			ThemeManager.RegisterTheme(name, tokens)
		end
	end
end

return DefaultTheme
]]
__MODULES["Utilities.UIUtils"] = [[local ThemeManager = __require("Theme.ThemeManager")

local UIUtils = {}

local function tokens()
	return ThemeManager.GetTokens()
end

local function resolveRadius(value)
	if typeof(value) == "UDim" then
		return value
	end
	local t = tokens()
	if value == "small" then
		return t.CornerSmall
	end
	if value == "large" then
		return t.CornerLarge
	end
	if value == "circle" or value == "full" then
		return t.CornerCircle
	end
	return t.Corner
end

function UIUtils.Corner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = resolveRadius(radius)
	corner.Parent = parent
	return corner
end

function UIUtils.Stroke(parent, color, thickness, transparency)
	local t = tokens()
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or t.Border
	stroke.Thickness = thickness or t.StrokeThickness
	stroke.Transparency = transparency or t.StrokeTransparency
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
	return stroke
end

function UIUtils.Gradient(parent, colorSequence, rotation, transparencyNumber)
	local t = tokens()
	local gradient = Instance.new("UIGradient")
	gradient.Color = colorSequence
	gradient.Rotation = rotation or t.GradientRotation or 90
	if transparencyNumber then
		gradient.Transparency = transparencyNumber
	end
	gradient.Parent = parent
	return gradient
end

function UIUtils.Padding(parent, top, bottom, left, right)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingBottom = UDim.new(0, bottom or 0)
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.PaddingRight = UDim.new(0, right or 0)
	padding.Parent = parent
	return padding
end

function UIUtils.ListLayout(parent, direction, spacing, alignment, sortOrder)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction or Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, spacing or 6)
	layout.HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left
	layout.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

function UIUtils.GridLayout(parent, cellSize, cellPadding)
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = cellSize or UDim2.new(0, 100, 0, 100)
	layout.CellPadding = cellPadding or UDim2.new(0, 8, 0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

function UIUtils.Scale(parent, value)
	local scale = Instance.new("UIScale")
	scale.Scale = value or 1
	scale.Parent = parent
	return scale
end

function UIUtils.AspectRatio(parent, ratio)
	local constraint = Instance.new("UIAspectRatioConstraint")
	constraint.AspectRatio = ratio or 1
	constraint.AspectType = Enum.AspectType.FitWithinMaxSize
	constraint.DominantAxis = Enum.DominantAxis.Width
	constraint.Parent = parent
	return constraint
end

function UIUtils.Lighten(color, amount)
	return Color3.new(
		math.clamp(color.R + amount, 0, 1),
		math.clamp(color.G + amount, 0, 1),
		math.clamp(color.B + amount, 0, 1)
	)
end

function UIUtils.Darken(color, amount)
	return Color3.new(
		math.clamp(color.R - amount, 0, 1),
		math.clamp(color.G - amount, 0, 1),
		math.clamp(color.B - amount, 0, 1)
	)
end

function UIUtils.Lerp(a, b, alpha)
	return a:Lerp(b, alpha)
end

function UIUtils.ToHex(color)
	return string.format("#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

function UIUtils.FromHex(hex)
	hex = hex:gsub("#", "")
	if #hex == 3 then
		return Color3.fromRGB(
			tonumber(hex:sub(1, 1), 16) * 17,
			tonumber(hex:sub(2, 2), 16) * 17,
			tonumber(hex:sub(3, 3), 16) * 17
		)
	end
	return Color3.fromRGB(
		tonumber(hex:sub(1, 2), 16),
		tonumber(hex:sub(3, 4), 16),
		tonumber(hex:sub(5, 6), 16)
	)
end

function UIUtils.SafeDestroy(instance)
	if typeof(instance) == "Instance" then
		instance:Destroy()
	elseif type(instance) == "table" and type(instance.Destroy) == "function" then
		instance:Destroy()
	end
end

function UIUtils.Shadow(parent, spread, transparency)
	local t = tokens()
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6015897843"
	shadow.ImageColor3 = t.Shadow
	shadow.ImageTransparency = transparency or 0.55
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.Size = UDim2.new(1, spread or 40, 1, spread or 40)
	shadow.Position = UDim2.new(0, -(spread or 40) / 2, 0, -(spread or 40) / 2)
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Parent = parent
	return shadow
end

function UIUtils.BindTheme(applyFn)
	return ThemeManager.Subscribe(applyFn)
end

function UIUtils.tokens()
	return tokens()
end

function UIUtils.Create(className, props, children)
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				inst[k] = v
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

return UIUtils
]]
__MODULES["Utilities.Sound"] = [[local SoundService = game:GetService("SoundService")

local Config = __require("Core.Config")

local Sound = {}
Sound.__index = Sound

Sound._cache = {}
Sound.Enabled = true
Sound.Volume = 0.5

local function getSound(id)
	if not id then
		return nil
	end

	if Sound._cache[id] then
		return Sound._cache[id]
	end

	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = Sound.Volume
	sound.Name = "NexusSound"

	Sound._cache[id] = sound
	return sound
end

function Sound.Play(name, customVolume, playbackSpeed)
	if not Sound.Enabled then
		return
	end
	if not Config.Sounds.Enabled then
		return
	end

	local id = Config.Sounds[name] or name
	if type(id) ~= "string" then
		return
	end

	local sound = getSound(id)
	if not sound then
		return
	end

	sound.Volume = customVolume or Config.Sounds.Volume or 0.4
	sound.PlaybackSpeed = playbackSpeed or 1

	local success, err = pcall(function()
		SoundService:PlayLocalSound(sound)
	end)

	if not success then
		warn("[NexusUI] Failed to play sound:", name, err)
	end

	return sound
end

function Sound.SetVolume(volume)
	Sound.Volume = volume
	Config.Sounds.Volume = volume
end

function Sound.SetEnabled(enabled)
	Sound.Enabled = enabled
	Config.Sounds.Enabled = enabled
end

function Sound.ClearCache()
	for id, sound in pairs(Sound._cache) do
		pcall(function() sound:Destroy() end)
		Sound._cache[id] = nil
	end
end

Sound.Click = function() return Sound.Play("Click", nil, 1.1) end
Sound.Hover = function() return Sound.Play("Hover", nil, 1.2) end
Sound.Open = function() return Sound.Play("Open") end
Sound.Close = function() return Sound.Play("Close") end
Sound.Error = function() return Sound.Play("Error") end
Sound.Success = function() return Sound.Play("Success") end
Sound.Toggle = function() return Sound.Play("Toggle", nil, 1.15) end
Sound.Pop = function() return Sound.Play("Pop", nil, 1.3) end

return Sound
]]
__MODULES["Core.Component"] = [[local Signal = __require("Core.Signal")
local Maid = __require("Core.Maid")

local Component = {}
Component.__index = Component

Component.Registry = {}

local nextId = 0
local function generateId(class)
	nextId = nextId + 1
	return ("%s_%d_%d"):format(class, os.clock() * 1000 % 1e6, nextId)
end

function Component.new(class, options)
	options = options or {}

	local self = setmetatable({}, Component)
	self.Class = class
	self.Id = generateId(class)
	self.Name = options.Name or class
	self.Visible = true
	self.Enabled = true
	self.Selected = false
	self.Loading = false
	self.Destroyed = false

	self._maid = Maid.new()
	self._signals = {
		StateChanged = Signal.new(),
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		EnabledChanged = Signal.new(),
	}
	self._stateBindings = {}

	Component.Registry[self] = true

	return self
end

function Component:On(eventName)
	return self._signals[eventName]
end

function Component:BindSignal(name)
	local signal = self._signals[name]
	if not signal then
		signal = Signal.new()
		self._signals[name] = signal
		self._maid:GiveTask(signal)
	end
	return signal
end

function Component:BindState(state, applyFn)
	if not state or type(applyFn) ~= "function" then
		return self
	end

	local connection = state:Subscribe(function(value)
		applyFn(self, value)
	end)

	self._maid:GiveTask(connection)
	table.insert(self._stateBindings, state)

	if not self._maid:GetTask("StateDestroyHook_" .. tostring(state)) then
		local originalDestroy = state.Destroy
		self._maid:GiveTask("StateDestroyHook_" .. tostring(state), function()
			originalDestroy(state)
		end)
	end

	return self
end

function Component:SetState(stateName, value)
	self[stateName] = value
	self._signals.StateChanged:Fire(stateName, value)
	return self
end

function Component:SetVisible(visible)
	visible = visible and true or false
	if self.Visible == visible then
		return self
	end

	self.Visible = visible
	self._signals.VisibleChanged:Fire(visible)
	return self
end

function Component:Show()
	return self:SetVisible(true)
end

function Component:Hide()
	return self:SetVisible(false)
end

function Component:SetEnabled(enabled)
	enabled = enabled and true or false
	if self.Enabled == enabled then
		return self
	end

	self.Enabled = enabled
	self._signals.EnabledChanged:Fire(enabled)
	return self
end

function Component:SetLoading(loading)
	self.Loading = loading and true or false
	self._signals.StateChanged:Fire("Loading", self.Loading)
	return self
end

function Component:SetSelected(selected)
	self.Selected = selected and true or false
	self._signals.StateChanged:Fire("Selected", self.Selected)
	return self
end

function Component:Destroy()
	if self.Destroyed then
		return
	end

	self.Destroyed = true

	for _, signal in pairs(self._signals) do
		signal:Destroy()
	end
	self._signals = {}

	for _, state in ipairs(self._stateBindings) do
		pcall(function() state:Destroy() end)
	end
	self._stateBindings = {}

	self._maid:Destroy()
	Component.Registry[self] = nil
	self._signals.Destroyed:Fire()
end

function Component.Count()
	local n = 0
	for _ in pairs(Component.Registry) do
		n = n + 1
	end
	return n
end

return Component
]]
__MODULES["Components.BaseComponent"] = [[local ThemeManager = __require("Theme.ThemeManager")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")

local BaseComponent = {}
BaseComponent.__index = BaseComponent

BaseComponent.Counter = 0

function BaseComponent.new(name)
	local self = setmetatable({}, BaseComponent)
	BaseComponent.Counter = BaseComponent.Counter + 1
	self.ClassName = name
	self.Id = name .. "_" .. BaseComponent.Counter
	self.Instance = nil
	self.Enabled = true
	self.Loading = false
	self.Selected = false
	self.Destroyed = false
	return self
end

function BaseComponent:Init(instance)
	self.Instance = instance
	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
	}

	self._maid:GiveTask(self._signals.Destroyed)
	self._maid:GiveTask(self._signals.VisibleChanged)
	self._maid:GiveTask(self._signals.ThemeChanged)
	self._maid:GiveTask(self._signals.StateChanged)

	local themeConnection = ThemeManager.Subscribe(function(tokens)
		if self.ApplyTheme then
			self:ApplyTheme(tokens)
		end
	end)
	self._maid:GiveTask(themeConnection)

	return self
end

function BaseComponent:GetSignal(name)
	local sig = self._signals[name]
	if not sig then
		sig = Signal.new()
		self._signals[name] = sig
		self._maid:GiveTask(sig)
	end
	return sig
end

function BaseComponent:SetVisible(visible)
	if not self.Instance then
		return self
	end

	visible = visible and true or false
	if self.Instance.Visible == visible then
		return self
	end

	self.Instance.Visible = visible
	self._signals.VisibleChanged:Fire(visible)
	return self
end

function BaseComponent:Show()
	return self:SetVisible(true)
end

function BaseComponent:Hide()
	return self:SetVisible(false)
end

function BaseComponent:IsVisible()
	return self.Instance and self.Instance.Visible or false
end

function BaseComponent:SetEnabled(enabled)
	if not self.Instance then
		return self
	end

	enabled = enabled and true or false
	if self.Instance:IsA("GuiButton") then
		self.Instance.AutoButtonColor = false
	end
	self.Enabled = enabled
	self._signals.StateChanged:Fire("Enabled", enabled)

	if self.OnEnabledChanged then
		self:OnEnabledChanged(enabled)
	end

	return self
end

function BaseComponent:IsEnabled()
	return self.Enabled ~= false
end

function BaseComponent:SetLoading(loading)
	self.Loading = loading and true or false
	self._signals.StateChanged:Fire("Loading", self.Loading)

	if self.OnLoadingChanged then
		self:OnLoadingChanged(self.Loading)
	end

	return self
end

function BaseComponent:SetSelected(selected)
	self.Selected = selected and true or false
	self._signals.StateChanged:Fire("Selected", self.Selected)

	if self.OnSelectedChanged then
		self:OnSelectedChanged(self.Selected)
	end

	return self
end

function BaseComponent:SetPosition(position)
	if self.Instance then
		self.Instance.Position = position
	end
	return self
end

function BaseComponent:SetSize(size)
	if self.Instance then
		self.Instance.Size = size
	end
	return self
end

function BaseComponent:SetZIndex(zIndex)
	if self.Instance then
		self.Instance.ZIndex = zIndex
	end
	return self
end

function BaseComponent:SetLayoutOrder(order)
	if self.Instance then
		self.Instance.LayoutOrder = order
	end
	return self
end

function BaseComponent:Animate(props, duration, easing)
	if self.Instance then
		return Animator.Tween(self.Instance, props, duration, easing)
	end
	return nil
end

function BaseComponent:BindState(state, applyFn)
	if not state or type(applyFn) ~= "function" then
		return self
	end

	local connection = state:Subscribe(function(value)
		applyFn(self, value)
	end)

	self._maid:GiveTask(connection)

	return self
end

function BaseComponent:Fire(signalName, ...)
	local sig = self._signals[signalName]
	if sig then
		sig:Fire(...)
	end
	return self
end

function BaseComponent:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true

	if self.Instance then
		pcall(function() self.Instance:Destroy() end)
		self.Instance = nil
	end

	if self._maid then
		self._maid:Destroy()
	end

	self._signals = nil
end

BaseComponent.IsBaseComponent = function(obj)
	return type(obj) == "table" and getmetatable(obj) == BaseComponent
end

return BaseComponent
]]
__MODULES["Components.Label"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")

local Label = {}
Label.__index = Label
setmetatable(Label, { __index = BaseComponent })

function Label.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Label")
	setmetatable(self, { __index = function(t, k)
		if Label[k] then
			return Label[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Label"
	self.Text = options.Text or ""
	self.Size = options.Size or UDim2.new(1, 0, 0, 20)
	self.TextSize = options.TextSize
	self.TextColor = options.TextColor
	self.Alignment = options.Alignment or Enum.TextXAlignment.Left
	self.Wrapped = options.Wrapped or false
	self.RichText = options.RichText or false

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

function Label:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("TextLabel")
	self.Container.Name = "Label_" .. self.Name
	self.Container.Size = self.Size
	self.Container.BackgroundTransparency = 1
	self.Container.Font = self.TextSize and tokens.Font or tokens.FontBold
	self.Container.Text = self.Text
	self.Container.TextColor3 = self.TextColor or tokens.Text
	self.Container.TextSize = self.TextSize or tokens.TextSize
	self.Container.TextXAlignment = self.Alignment
	self.Container.TextWrapped = self.Wrapped
	self.Container.RichText = self.RichText
	self.Container.AutomaticSize = self.Wrapped and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Container.Font = self.TextSize and tk.Font or tk.FontBold
		self.Container.TextColor3 = self.TextColor or tk.Text
		self.Container.TextSize = self.TextSize or tk.TextSize
	end))
end

function Label:SetText(text)
	self.Text = text
	self.Container.Text = text
	return self
end

function Label:GetText()
	return self.Container.Text
end

function Label:SetTextColor(color)
	self.TextColor = color
	self.Container.TextColor3 = color
	return self
end

function Label:SetTextSize(size)
	self.TextSize = size
	self.Container.TextSize = size
	return self
end

function Label:SetAlignment(alignment)
	self.Alignment = alignment
	self.Container.TextXAlignment = alignment
	return self
end

function Label:Destroy()
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

return Label
]]
__MODULES["Components.Paragraph"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")

local Paragraph = {}
Paragraph.__index = Paragraph
setmetatable(Paragraph, { __index = BaseComponent })

function Paragraph.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Paragraph")
	setmetatable(self, { __index = function(t, k)
		if Paragraph[k] then
			return Paragraph[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Paragraph"
	self.Title = options.Title or ""
	self.Text = options.Text or ""

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

function Paragraph:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Paragraph_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, 0)
	self.Container.AutomaticSize = Enum.AutomaticSize.Y
	self.Container.BackgroundColor3 = tokens.Surface
	self.Container.BackgroundTransparency = 0.5
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	UIUtils.Corner(self.Container, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Container.BackgroundColor3 = tk.Surface
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = self.Container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Container

	if self.Title ~= "" then
		self.TitleLabel = Instance.new("TextLabel")
		self.TitleLabel.Name = "Title"
		self.TitleLabel.Size = UDim2.new(1, 0, 0, 16)
		self.TitleLabel.BackgroundTransparency = 1
		self.TitleLabel.Font = tokens.FontBold
		self.TitleLabel.Text = self.Title
		self.TitleLabel.TextColor3 = tokens.Text
		self.TitleLabel.TextSize = 13
		self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.TitleLabel.TextWrapped = true
		self.TitleLabel.LayoutOrder = 1
		self.TitleLabel.ZIndex = 7
		self.TitleLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.TitleLabel.Font = tk.FontBold
			self.TitleLabel.TextColor3 = tk.Text
		end))
	end

	self.BodyLabel = Instance.new("TextLabel")
	self.BodyLabel.Name = "Body"
	self.BodyLabel.Size = UDim2.new(1, 0, 0, 0)
	self.BodyLabel.AutomaticSize = Enum.AutomaticSize.Y
	self.BodyLabel.BackgroundTransparency = 1
	self.BodyLabel.Font = tokens.Font
	self.BodyLabel.Text = self.Text
	self.BodyLabel.TextColor3 = tokens.SecondaryText
	self.BodyLabel.TextSize = 12
	self.BodyLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.BodyLabel.TextWrapped = true
	self.BodyLabel.LayoutOrder = 2
	self.BodyLabel.ZIndex = 7
	self.BodyLabel.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.BodyLabel.Font = tk.Font
		self.BodyLabel.TextColor3 = tk.SecondaryText
	end))
end

function Paragraph:SetText(text)
	self.Text = text
	self.BodyLabel.Text = text
	return self
end

function Paragraph:SetTitle(title)
	self.Title = title
	if self.TitleLabel then
		self.TitleLabel.Text = title
	end
	return self
end

function Paragraph:Destroy()
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

return Paragraph
]]
__MODULES["Components.Divider"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")

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
]]
__MODULES["Components.Badge"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")

local Badge = {}
Badge.__index = Badge
setmetatable(Badge, { __index = BaseComponent })

function Badge.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Badge")
	setmetatable(self, { __index = function(t, k)
		if Badge[k] then
			return Badge[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Badge"
	self.Text = options.Text or "New"
	self.Variant = options.Variant or "Accent"
	self.Size = options.Size or UDim2.new(0, 60, 0, 20)

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

function Badge:_variantColors(variant)
	local tokens = ThemeManager.GetTokens()
	local variants = {
		Accent = { Background = tokens.Accent, Text = Color3.fromRGB(255, 255, 255) },
		Success = { Background = tokens.Success, Text = Color3.fromRGB(255, 255, 255) },
		Error = { Background = tokens.Error, Text = Color3.fromRGB(255, 255, 255) },
		Warning = { Background = tokens.Warning, Text = Color3.fromRGB(40, 30, 10) },
		Info = { Background = tokens.Info, Text = Color3.fromRGB(255, 255, 255) },
		Muted = { Background = tokens.SurfaceLight, Text = tokens.SecondaryText },
		Outline = { Background = tokens.Background, Text = tokens.Accent },
	}
	return variants[variant] or variants.Accent
end

function Badge:_build(parent)
	local tokens = ThemeManager.GetTokens()
	local colors = self:_variantColors(self.Variant)

	self.Container = Instance.new("Frame")
	self.Container.Name = "Badge_" .. self.Text
	self.Container.Size = self.Size
	self.Container.BackgroundColor3 = colors.Background
	self.Container.BackgroundTransparency = self.Variant == "Outline" and 0.8 or 0
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	UIUtils.Corner(self.Container, tokens.CornerSmall)

	if self.Variant == "Outline" then
		UIUtils.Stroke(self.Container, tokens.Accent, 1, 0.3)
	end

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		local vc = self:_variantColors(self.Variant)
		self.Container.BackgroundColor3 = vc.Background
	end))

	self.Label = Instance.new("TextLabel")
	self.Label.Name = "Text"
	self.Label.Size = UDim2.new(1, 0, 1, 0)
	self.Label.BackgroundTransparency = 1
	self.Label.Font = tokens.FontBold
	self.Label.Text = self.Text
	self.Label.TextColor3 = colors.Text
	self.Label.TextSize = 10
	self.Label.ZIndex = 7
	self.Label.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		local vc = self:_variantColors(self.Variant)
		self.Label.Font = tk.FontBold
		self.Label.TextColor3 = vc.Text
	end))
end

function Badge:SetText(text)
	self.Text = text
	self.Label.Text = text
	return self
end

function Badge:SetVariant(variant)
	self.Variant = variant
	local colors = self:_variantColors(variant)

	Animator.Tween(self.Container, { BackgroundColor3 = colors.Background }, 0.2, "Quad")
	Animator.Tween(self.Label, { TextColor3 = colors.Text }, 0.2, "Quad")

	return self
end

function Badge:Pulse()
	Animator.Tween(self.Container, { BackgroundTransparency = 0.4 }, 0.15, "Quad")
	task.delay(0.15, function()
		Animator.Tween(self.Container, { BackgroundTransparency = self.Variant == "Outline" and 0.8 or 0 }, 0.3, "Back")
	end)
	return self
end

function Badge:Destroy()
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

return Badge
]]
__MODULES["Components.Button"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

local Button = {}
Button.__index = Button
setmetatable(Button, { __index = BaseComponent })

function Button.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Button")
	setmetatable(self, { __index = function(t, k)
		if Button[k] then
			return Button[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Button"
	self.Text = options.Text or options.Name or "Button"
	self.Description = options.Description or ""
	self.Callback = options.Callback or function() end
	self.Variant = options.Variant or "Primary"
	self.FullWidth = options.FullWidth ~= false
	self.Icon = options.Icon

	self.ClickCount = 0

	self.OnClick = Signal.new()
	self.OnPressed = Signal.new()
	self.OnReleased = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Click = self.OnClick,
		Pressed = self.OnPressed,
		Released = self.OnReleased,
	}

	self:_build(parent)

	return self
end

function Button:_variantColors(variant)
	local tokens = ThemeManager.GetTokens()

	local variants = {
		Primary = {
			Background = tokens.Accent,
			Text = Color3.fromRGB(255, 255, 255),
			Stroke = tokens.AccentDark,
			StrokeTransparency = 0.4,
			BackgroundTransparency = 0,
		},
		Secondary = {
			Background = tokens.SurfaceLight,
			Text = tokens.Text,
			Stroke = tokens.Border,
			StrokeTransparency = 0.5,
			BackgroundTransparency = 0.1,
		},
		Outline = {
			Background = tokens.Background,
			Text = tokens.Text,
			Stroke = tokens.Accent,
			StrokeTransparency = 0.35,
			BackgroundTransparency = 0.85,
		},
		Ghost = {
			Background = tokens.Surface,
			Text = tokens.SecondaryText,
			Stroke = tokens.Surface,
			StrokeTransparency = 1,
			BackgroundTransparency = 1,
		},
		Danger = {
			Background = tokens.Error,
			Text = Color3.fromRGB(255, 255, 255),
			Stroke = tokens.Error,
			StrokeTransparency = 0.4,
			BackgroundTransparency = 0,
		},
		Success = {
			Background = tokens.Success,
			Text = Color3.fromRGB(255, 255, 255),
			Stroke = tokens.Success,
			StrokeTransparency = 0.4,
			BackgroundTransparency = 0,
		},
	}

	return variants[variant] or variants.Primary
end

function Button:_build(parent)
	local tokens = ThemeManager.GetTokens()
	local colors = self:_variantColors(self.Variant)

	self.Container = Instance.new("Frame")
	self.Container.Name = "Button_" .. self.Text
	self.Container.Size = self.FullWidth and UDim2.new(1, 0, 0, 36) or UDim2.new(0, 120, 0, 36)
	self.Container.AutomaticSize = self.FullWidth and Enum.AutomaticSize.None or Enum.AutomaticSize.None
	self.Container.BackgroundColor3 = colors.Background
	self.Container.BackgroundTransparency = colors.BackgroundTransparency
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	UIUtils.Corner(self.Container, tokens.CornerSmall)

	self.Stroke = UIUtils.Stroke(self.Container, colors.Stroke, 1, colors.StrokeTransparency)

	self.Button = Instance.new("TextButton")
	self.Button.Name = "ClickTarget"
	self.Button.Size = UDim2.new(1, 0, 1, 0)
	self.Button.BackgroundTransparency = 1
	self.Button.BorderSizePixel = 0
	self.Button.AutoButtonColor = false
	self.Button.Font = tokens.FontBold
	self.Button.Text = self.Text
	self.Button.TextColor3 = colors.Text
	self.Button.TextSize = tokens.TextSize
	self.Button.TextXAlignment = Enum.TextXAlignment.Center
	self.Button.ZIndex = 7
	self.Button.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		local vc = self:_variantColors(self.Variant)
		self.Container.BackgroundColor3 = vc.Background
		self.Container.BackgroundTransparency = vc.BackgroundTransparency
		self.Stroke.Color = vc.Stroke
		self.Stroke.Transparency = vc.StrokeTransparency
		self.Button.Font = tk.FontBold
		self.Button.TextColor3 = vc.Text
		self.Button.TextSize = tk.TextSize
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = self.Container

	if self.Icon then
		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.Image = self.Icon
		icon.Size = UDim2.new(0, 16, 0, 16)
		icon.ImageColor3 = colors.Text
		icon.ScaleType = Enum.ScaleType.Fit
		icon.LayoutOrder = 1
		icon.ZIndex = 8
		icon.Parent = self.Container

		self._icon = icon

		local iconCorner = UDim.new(0, 8)
		local holderLayout = Instance.new("UIListLayout")
		holderLayout.FillDirection = Enum.FillDirection.Horizontal
		holderLayout.Padding = UDim.new(0, 6)
		holderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		holderLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		holderLayout.SortOrder = Enum.SortOrder.LayoutOrder
		holderLayout.Parent = self.Container

		self.Button.TextXAlignment = Enum.TextXAlignment.Center
	end

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = self.Container
	self._scale = scale

	local pressed = false

	self.Button.MouseEnter:Connect(function()
		if not self.Enabled then
			return
		end
		Animator.Tween(scale, { Scale = 1.02 }, 0.15, "Quad")
		Animator.Tween(self.Container, { BackgroundTransparency = math.max(0, colors.BackgroundTransparency - 0.05) }, 0.15, "Quad")
		Sound.Hover()
	end)

	self.Button.MouseLeave:Connect(function()
		Animator.Tween(scale, { Scale = 1 }, 0.2, "Quad")
		Animator.Tween(self.Container, { BackgroundTransparency = colors.BackgroundTransparency }, 0.2, "Quad")
		pressed = false
	end)

	self.Button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			pressed = true
			Animator.Tween(scale, { Scale = 0.96 }, 0.08, "Quad")
			self.OnPressed:Fire()
		end
	end)

	self.Button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if pressed then
				pressed = false
				Animator.Tween(scale, { Scale = 1 }, 0.2, "Back")
				self.OnReleased:Fire()
			end
		end
	end)

	self.Button.MouseButton1Click:Connect(function()
		if not self.Enabled then
			return
		end

		self.ClickCount = self.ClickCount + 1
		Sound.Click()
		self.OnClick:Fire(self.ClickCount)

		local ok, err = pcall(self.Callback, self.ClickCount)
		if not ok then
			warn("[NexusUI] Button callback error:", err)
		end
	end)
end

function Button:SetText(text)
	self.Text = text
	self.Button.Text = text
	self.Container.Name = "Button_" .. text
	return self
end

function Button:SetIcon(icon)
	self.Icon = icon

	if icon then
		if not self._icon then
			self._icon = Instance.new("ImageLabel")
			self._icon.Name = "Icon"
			self._icon.BackgroundTransparency = 1
			self._icon.Size = UDim2.new(0, 16, 0, 16)
			self._icon.ScaleType = Enum.ScaleType.Fit
			self._icon.LayoutOrder = 1
			self._icon.ZIndex = 8
			self._icon.Parent = self.Container
		end
		self._icon.Image = icon
	elseif self._icon then
		self._icon:Destroy()
		self._icon = nil
	end

	return self
end

function Button:SetVariant(variant)
	self.Variant = variant
	local tokens = ThemeManager.GetTokens()
	local colors = self:_variantColors(variant)

	Animator.Tween(self.Container, { BackgroundColor3 = colors.Background }, 0.2, "Quad")
	Animator.Tween(self.Button, { TextColor3 = colors.Text }, 0.2, "Quad")
	Animator.Tween(self.Stroke, { Color = colors.Stroke, Transparency = colors.StrokeTransparency }, 0.2, "Quad")

	if self._icon then
		self._icon.ImageColor3 = colors.Text
	end

	return self
end

function Button:SetFullWidth(fullWidth)
	self.FullWidth = fullWidth
	if fullWidth then
		self.Container.Size = UDim2.new(1, 0, 0, 36)
	else
		self.Container.Size = UDim2.new(0, 120, 0, 36)
	end
	return self
end

function Button:OnEnabledChanged(enabled)
	local tokens = ThemeManager.GetTokens()

	if enabled then
		local vc = self:_variantColors(self.Variant)
		Animator.Tween(self.Container, { BackgroundTransparency = vc.BackgroundTransparency }, 0.2, "Quad")
		Animator.Tween(self.Button, { TextTransparency = 0 }, 0.2, "Quad")
	else
		Animator.Tween(self.Container, { BackgroundTransparency = 0.6 }, 0.2, "Quad")
		Animator.Tween(self.Button, { TextTransparency = 0.5 }, 0.2, "Quad")
	end
end

function Button:PlayClickAnimation()
	local scale = self._scale
	if scale then
		Animator.Tween(scale, { Scale = 0.94 }, 0.07, "Quad")
		task.delay(0.07, function()
			Animator.Tween(scale, { Scale = 1 }, 0.25, "Back")
		end)
	end
	return self
end

function Button:Destroy()
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

return Button
]]
__MODULES["Components.Toggle"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Spring = __require("Animation.Spring")
local Sound = __require("Utilities.Sound")

local Toggle = {}
Toggle.__index = Toggle
setmetatable(Toggle, { __index = BaseComponent })

function Toggle.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Toggle")
	setmetatable(self, { __index = function(t, k)
		if Toggle[k] then
			return Toggle[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Toggle"
	self.Text = options.Text or options.Name or "Toggle"
	self.Description = options.Description or ""
	self.Value = options.Value or false
	self.Callback = options.Callback or function() end
	self.DefaultValue = self.Value

	self.OnChanged = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
	}

	self:_build(parent)

	return self
end

function Toggle:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Toggle_" .. self.Text
	self.Container.Size = UDim2.new(1, 0, 0, 32)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Hitbox = Instance.new("TextButton")
	self.Hitbox.Name = "Hitbox"
	self.Hitbox.Size = UDim2.new(1, 0, 1, 0)
	self.Hitbox.BackgroundTransparency = 1
	self.Hitbox.BorderSizePixel = 0
	self.Hitbox.AutoButtonColor = false
	self.Hitbox.Text = ""
	self.Hitbox.ZIndex = 7
	self.Hitbox.Parent = self.Container

	self.Switch = Instance.new("Frame")
	self.Switch.Name = "Switch"
	self.Switch.AnchorPoint = Vector2.new(1, 0.5)
	self.Switch.Position = UDim2.new(1, -4, 0.5, 0)
	self.Switch.Size = UDim2.new(0, 40, 0, 22)
	self.Switch.BackgroundColor3 = tokens.SurfaceLight
	self.Switch.BorderSizePixel = 0
	self.Switch.ZIndex = 8
	self.Switch.Parent = self.Hitbox

	UIUtils.Corner(self.Switch, tokens.CornerCircle)
	UIUtils.Stroke(self.Switch, tokens.Border, 1, 0.6)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		if not self.Value then
			self.Switch.BackgroundColor3 = tk.SurfaceLight
		end
	end))

	self.Knob = Instance.new("Frame")
	self.Knob.Name = "Knob"
	self.Knob.AnchorPoint = Vector2.new(0, 0.5)
	self.Knob.Position = UDim2.new(0, 3, 0.5, 0)
	self.Knob.Size = UDim2.new(0, 16, 0, 16)
	self.Knob.BackgroundColor3 = tokens.SecondaryText
	self.Knob.BorderSizePixel = 0
	self.Knob.ZIndex = 9
	self.Knob.Parent = self.Switch

	UIUtils.Corner(self.Knob, tokens.CornerCircle)

	self._knobSpring = Spring.new(0, { Stiffness = 260, Damping = 22 })
	self._knobSpring:OnUpdate(function(value)
		self.Knob.Position = UDim2.new(0, 3 + value * 18, 0.5, 0)
	end)

	self.TextLabel = Instance.new("TextLabel")
	self.TextLabel.Name = "Text"
	self.TextLabel.BackgroundTransparency = 1
	self.TextLabel.Position = UDim2.new(0, 4, 0, 0)
	self.TextLabel.Size = UDim2.new(1, -56, 1, 0)
	self.TextLabel.Font = tokens.Font
	self.TextLabel.Text = self.Text
	self.TextLabel.TextColor3 = tokens.Text
	self.TextLabel.TextSize = tokens.TextSize
	self.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TextLabel.TextTruncate = Enum.TextTruncate.AtEnd
	self.TextLabel.ZIndex = 7
	self.TextLabel.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TextLabel.Font = tk.Font
		self.TextLabel.TextColor3 = tk.Text
		self.TextLabel.TextSize = tk.TextSize
	end))

	self.Hitbox.MouseEnter:Connect(function()
		Sound.Hover()
	end)

	self.Hitbox.MouseButton1Click:Connect(function()
		self:SetValue(not self.Value, true)
	end)

	self:_updateVisual(true)
end

function Toggle:_updateVisual(instant)
	local tokens = ThemeManager.GetTokens()
	local targetKnobPos = self.Value and 1 or 0

	if instant then
		self._knobSpring:SetValue(targetKnobPos)
	else
		self._knobSpring:SetTarget(targetKnobPos)
	end

	if self.Value then
		Animator.Tween(self.Switch, { BackgroundColor3 = tokens.Accent }, 0.2, "Quad")
		Animator.Tween(self.Knob, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, 0.15, "Quad")
	else
		Animator.Tween(self.Switch, { BackgroundColor3 = tokens.SurfaceLight }, 0.2, "Quad")
		Animator.Tween(self.Knob, { BackgroundColor3 = tokens.SecondaryText }, 0.15, "Quad")
	end
end

function Toggle:SetValue(value, fireEvent)
	value = value and true or false

	if value == self.Value then
		return self
	end

	self.Value = value
	self:_updateVisual(false)

	if fireEvent then
		Sound.Toggle()
		self.OnChanged:Fire(value)

		local ok, err = pcall(self.Callback, value)
		if not ok then
			warn("[NexusUI] Toggle callback error:", err)
		end
	end

	return self
end

function Toggle:GetValue()
	return self.Value
end

function Toggle:SetText(text)
	self.Text = text
	self.TextLabel.Text = text
	return self
end

function Toggle:Reset()
	return self:SetValue(self.DefaultValue, true)
end

function Toggle:Destroy()
	if self.Destroyed then
		return
	end

	if self._knobSpring then
		self._knobSpring:Destroy()
	end

	if self.Container then
		self.Container:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return Toggle
]]
__MODULES["Components.Checkbox"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

local Checkbox = {}
Checkbox.__index = Checkbox
setmetatable(Checkbox, { __index = BaseComponent })

function Checkbox.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Checkbox")
	setmetatable(self, { __index = function(t, k)
		if Checkbox[k] then
			return Checkbox[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Checkbox"
	self.Text = options.Text or options.Name or "Checkbox"
	self.Value = options.Value or false
	self.DefaultValue = self.Value
	self.Callback = options.Callback or function() end

	self.OnChanged = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
	}

	self:_build(parent)

	return self
end

function Checkbox:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Checkbox_" .. self.Text
	self.Container.Size = UDim2.new(1, 0, 0, 26)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Hitbox = Instance.new("TextButton")
	self.Hitbox.Name = "Hitbox"
	self.Hitbox.Size = UDim2.new(1, 0, 1, 0)
	self.Hitbox.BackgroundTransparency = 1
	self.Hitbox.BorderSizePixel = 0
	self.Hitbox.AutoButtonColor = false
	self.Hitbox.Text = ""
	self.Hitbox.ZIndex = 7
	self.Hitbox.Parent = self.Container

	self.Box = Instance.new("Frame")
	self.Box.Name = "Box"
	self.Box.AnchorPoint = Vector2.new(0, 0.5)
	self.Box.Position = UDim2.new(0, 4, 0.5, 0)
	self.Box.Size = UDim2.new(0, 18, 0, 18)
	self.Box.BackgroundColor3 = self.Value and tokens.Accent or tokens.Background
	self.Box.BorderSizePixel = 0
	self.Box.ZIndex = 8
	self.Box.Parent = self.Hitbox

	UIUtils.Corner(self.Box, tokens.CornerSmall)
	self.BoxStroke = UIUtils.Stroke(self.Box, self.Value and tokens.Accent or tokens.Border, 1.5, 0.3)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		if not self.Value then
			self.Box.BackgroundColor3 = tk.Background
		end
		self.BoxStroke.Color = self.Value and tk.Accent or tk.Border
	end))

	self.Check = Instance.new("ImageLabel")
	self.Check.Name = "Check"
	self.Check.Size = UDim2.new(0, 12, 0, 12)
	self.Check.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.Check.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Check.BackgroundTransparency = 1
	self.Check.Image = "rbxassetid://10709759999"
	self.Check.ImageColor3 = Color3.fromRGB(255, 255, 255)
	self.Check.ScaleType = Enum.ScaleType.Fit
	self.Check.ImageTransparency = self.Value and 0 or 1
	self.Check.Rotation = self.Value and 0 or -45
	self.Check.ZIndex = 9
	self.Check.Parent = self.Box

	self.TextLabel = Instance.new("TextLabel")
	self.TextLabel.Name = "Text"
	self.TextLabel.Position = UDim2.new(0, 30, 0, 0)
	self.TextLabel.Size = UDim2.new(1, -34, 1, 0)
	self.TextLabel.BackgroundTransparency = 1
	self.TextLabel.Font = tokens.Font
	self.TextLabel.Text = self.Text
	self.TextLabel.TextColor3 = tokens.Text
	self.TextLabel.TextSize = tokens.TextSize
	self.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TextLabel.ZIndex = 7
	self.TextLabel.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TextLabel.Font = tk.Font
		self.TextLabel.TextColor3 = tk.Text
		self.TextLabel.TextSize = tk.TextSize
	end))

	self.Hitbox.MouseButton1Click:Connect(function()
		self:SetValue(not self.Value, true)
	end)

	self.Hitbox.MouseEnter:Connect(function()
		Sound.Hover()
	end)
end

function Checkbox:SetValue(value, fireEvent)
	value = value and true or false

	if value == self.Value then
		return self
	end

	self.Value = value
	local tokens = ThemeManager.GetTokens()

	if value then
		Animator.Tween(self.Box, { BackgroundColor3 = tokens.Accent }, 0.15, "Quad")
		Animator.Tween(self.BoxStroke, { Color = tokens.Accent }, 0.15, "Quad")
		Animator.Tween(self.Check, { ImageTransparency = 0, Rotation = 0 }, 0.2, "Back")
	else
		Animator.Tween(self.Box, { BackgroundColor3 = tokens.Background }, 0.15, "Quad")
		Animator.Tween(self.BoxStroke, { Color = tokens.Border }, 0.15, "Quad")
		Animator.Tween(self.Check, { ImageTransparency = 1, Rotation = -45 }, 0.15, "Quad")
	end

	if fireEvent then
		Sound.Toggle()
		self.OnChanged:Fire(value)

		local ok, err = pcall(self.Callback, value)
		if not ok then
			warn("[NexusUI] Checkbox callback error:", err)
		end
	end

	return self
end

function Checkbox:GetValue()
	return self.Value
end

function Checkbox:SetText(text)
	self.Text = text
	self.TextLabel.Text = text
	return self
end

function Checkbox:Reset()
	return self:SetValue(self.DefaultValue, true)
end

function Checkbox:Destroy()
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

return Checkbox
]]
__MODULES["Components.Slider"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

local Slider = {}
Slider.__index = Slider
setmetatable(Slider, { __index = BaseComponent })

function Slider.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Slider")
	setmetatable(self, { __index = function(t, k)
		if Slider[k] then
			return Slider[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Slider"
	self.Text = options.Text or options.Name or "Slider"
	self.Min = options.Min or 0
	self.Max = options.Max or 100
	self.Step = options.Step or 1
	self.DefaultValue = options.Value or options.Default or self.Min
	self.Value = math.clamp(self.DefaultValue, self.Min, self.Max)
	self.Suffix = options.Suffix or ""
	self.Prefix = options.Prefix or ""
	self.Callback = options.Callback or function() end
	self.OnInputEnded = options.OnInputEnded

	self.OnChanged = Signal.new()
	self.OnDragging = Signal.new()
	self.OnReleased = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
		Dragging = self.OnDragging,
		Released = self.OnReleased,
	}

	self:_build(parent)
	self:_setValue(self.Value, false, true)

	return self
end

function Slider:_roundToStep(value)
	local stepped = math.floor((value - self.Min) / self.Step + 0.5) * self.Step + self.Min
	return math.clamp(stepped, self.Min, self.Max)
end

function Slider:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Slider_" .. self.Text
	self.Container.Size = UDim2.new(1, 0, 0, 48)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Header = Instance.new("Frame")
	self.Header.Name = "Header"
	self.Header.Size = UDim2.new(1, 0, 0, 18)
	self.Header.BackgroundTransparency = 1
	self.Header.ZIndex = 7
	self.Header.Parent = self.Container

	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Name = "Title"
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.Size = UDim2.new(0.6, 0, 1, 0)
	self.TitleLabel.Font = tokens.Font
	self.TitleLabel.Text = self.Text
	self.TitleLabel.TextColor3 = tokens.Text
	self.TitleLabel.TextSize = tokens.TextSize
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.ZIndex = 7
	self.TitleLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TitleLabel.Font = tk.Font
		self.TitleLabel.TextColor3 = tk.Text
		self.TitleLabel.TextSize = tk.TextSize
	end))

	self.ValueLabel = Instance.new("TextLabel")
	self.ValueLabel.Name = "Value"
	self.ValueLabel.AnchorPoint = Vector2.new(1, 0)
	self.ValueLabel.Position = UDim2.new(1, 0, 0, 0)
	self.ValueLabel.Size = UDim2.new(0.4, 0, 1, 0)
	self.ValueLabel.Font = tokens.FontBold
	self.ValueLabel.Text = self:_formatValue(self.Value)
	self.ValueLabel.TextColor3 = tokens.Accent
	self.ValueLabel.TextSize = 12
	self.ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.ValueLabel.ZIndex = 7
	self.ValueLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.ValueLabel.Font = tk.FontBold
		self.ValueLabel.TextColor3 = tk.Accent
	end))

	self.Track = Instance.new("TextButton")
	self.Track.Name = "Track"
	self.Track.Position = UDim2.new(0, 0, 0, 24)
	self.Track.Size = UDim2.new(1, 0, 0, 18)
	self.Track.BackgroundColor3 = tokens.SurfaceLight
	self.Track.BackgroundTransparency = 0.3
	self.Track.BorderSizePixel = 0
	self.Track.AutoButtonColor = false
	self.Track.Text = ""
	self.Track.ZIndex = 7
	self.Track.Parent = self.Container

	UIUtils.Corner(self.Track, tokens.CornerCircle)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Track.BackgroundColor3 = tk.SurfaceLight
	end))

	self.Fill = Instance.new("Frame")
	self.Fill.Name = "Fill"
	self.Fill.Size = UDim2.new(0, 0, 1, 0)
	self.Fill.BackgroundColor3 = tokens.Accent
	self.Fill.BorderSizePixel = 0
	self.Fill.ZIndex = 8
	self.Fill.Parent = self.Track

	UIUtils.Corner(self.Fill, tokens.CornerCircle)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Fill.BackgroundColor3 = tk.Accent
	end))

	self.Thumb = Instance.new("Frame")
	self.Thumb.Name = "Thumb"
	self.Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Thumb.Position = UDim2.new(0, 0, 0.5, 0)
	self.Thumb.Size = UDim2.new(0, 14, 0, 14)
	self.Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.Thumb.BorderSizePixel = 0
	self.Thumb.ZIndex = 9
	self.Thumb.Parent = self.Track

	UIUtils.Corner(self.Thumb, tokens.CornerCircle)
	UIUtils.Stroke(self.Thumb, tokens.Accent, 1.5, 0.15)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Thumb.Stroke.Color = tk.Accent
	end))

	self:_bindDrag()
end

function Slider:_formatValue(value)
	local decimals = 0
	local step = self.Step
	while step < 1 and decimals < 4 do
		step = step * 10
		decimals = decimals + 1
	end

	local formatted = string.format("%." .. decimals .. "f", value)
	return self.Prefix .. formatted .. self.Suffix
end

function Slider:_getAlpha()
	return (self.Value - self.Min) / math.max(0.0001, self.Max - self.Min)
end

function Slider:_applyAlpha(alpha, fireEvent)
	alpha = math.clamp(alpha, 0, 1)
	local rawValue = self.Min + alpha * (self.Max - self.Min)
	self:_setValue(rawValue, fireEvent, false)
end

function Slider:_setValue(value, fireEvent, instant)
	value = self:_roundToStep(value)

	local changed = value ~= self.Value
	self.Value = value

	local alpha = self:_getAlpha()
	self.Fill.Size = UDim2.new(alpha, 0, 1, 0)
	self.Thumb.Position = UDim2.new(alpha, 0, 0.5, 0)
	self.ValueLabel.Text = self:_formatValue(value)

	if fireEvent and changed then
		Sound.Pop()
		self.OnChanged:Fire(value)

		local ok, err = pcall(self.Callback, value)
		if not ok then
			warn("[NexusUI] Slider callback error:", err)
		end
	end
end

function Slider:_bindDrag()
	local dragging = false

	self.Track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true

			local alpha = (input.Position.X - self.Track.AbsolutePosition.X) / self.Track.AbsoluteSize.X
			self:_applyAlpha(alpha, true)
			self.OnDragging:Fire(self.Value)

			Animator.Tween(self.Thumb, { Size = UDim2.new(0, 17, 0, 17) }, 0.1, "Quad")
		end
	end)

	local uis = game:GetService("UserInputService")

	local moveConnection = uis.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local alpha = (input.Position.X - self.Track.AbsolutePosition.X) / self.Track.AbsoluteSize.X
			self:_applyAlpha(alpha, true)
		end
	end)

	local endConnection = uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				Animator.Tween(self.Thumb, { Size = UDim2.new(0, 14, 0, 14) }, 0.15, "Back")
				self.OnReleased:Fire(self.Value)

				if self.OnInputEnded then
					pcall(self.OnInputEnded, self.Value)
				end
			end
		end
	end)

	self._maid:GiveTask(moveConnection)
	self._maid:GiveTask(endConnection)
end

function Slider:SetValue(value, fireEvent)
	self:_setValue(value, fireEvent ~= false, false)
	return self
end

function Slider:GetValue()
	return self.Value
end

function Slider:SetRange(min, max)
	self.Min = min
	self.Max = max
	self:_setValue(math.clamp(self.Value, min, max), false, false)
	return self
end

function Slider:SetStep(step)
	self.Step = step or 1
	self:_setValue(self.Value, false, false)
	return self
end

function Slider:SetText(text)
	self.Text = text
	self.TitleLabel.Text = text
	return self
end

function Slider:SetSuffix(suffix)
	self.Suffix = suffix or ""
	self.ValueLabel.Text = self:_formatValue(self.Value)
	return self
end

function Slider:Reset()
	return self:SetValue(self.DefaultValue)
end

function Slider:Destroy()
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

return Slider
]]
__MODULES["Components.Dropdown"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

local Dropdown = {}
Dropdown.__index = Dropdown
setmetatable(Dropdown, { __index = BaseComponent })

function Dropdown.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Dropdown")
	setmetatable(self, { __index = function(t, k)
		if Dropdown[k] then
			return Dropdown[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Dropdown"
	self.Text = options.Text or options.Name or "Dropdown"
	self.Options = options.Options or {}
	self.DefaultValue = options.Value or options.Default
	self.Value = self.DefaultValue
	self.Callback = options.Callback or function() end
	self.MaxVisible = options.MaxVisible or 6
	self.PlaceholderText = options.Placeholder or "Select..."

	self.IsOpen = false

	self.OnChanged = Signal.new()
	self.OnOpened = Signal.new()
	self.OnClosed = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
		Opened = self.OnOpened,
		Closed = self.OnClosed,
	}

	self:_build(parent)

	return self
end

function Dropdown:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Dropdown_" .. self.Text
	self.Container.Size = UDim2.new(1, 0, 0, 34)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Header = Instance.new("TextButton")
	self.Header.Name = "Header"
	self.Header.Size = UDim2.new(1, 0, 0, 34)
	self.Header.BackgroundColor3 = tokens.SurfaceLight
	self.Header.BackgroundTransparency = 0.2
	self.Header.BorderSizePixel = 0
	self.Header.AutoButtonColor = false
	self.Header.Text = ""
	self.Header.ZIndex = 7
	self.Header.Parent = self.Container

	UIUtils.Corner(self.Header, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Header.BackgroundColor3 = tk.SurfaceLight
	end))

	self.SelectedLabel = Instance.new("TextLabel")
	self.SelectedLabel.Name = "Selected"
	self.SelectedLabel.Position = UDim2.new(0, 10, 0, 0)
	self.SelectedLabel.Size = UDim2.new(1, -40, 1, 0)
	self.SelectedLabel.BackgroundTransparency = 1
	self.SelectedLabel.Font = tokens.Font
	self.SelectedLabel.Text = self.Value and tostring(self.Value) or self.PlaceholderText
	self.SelectedLabel.TextColor3 = self.Value and tokens.Text or tokens.MutedText
	self.SelectedLabel.TextSize = tokens.TextSize
	self.SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.SelectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
	self.SelectedLabel.ZIndex = 8
	self.SelectedLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.SelectedLabel.Font = tk.Font
		self.SelectedLabel.TextSize = tk.TextSize
		if not self.Value then
			self.SelectedLabel.TextColor3 = tk.MutedText
		end
	end))

	self.Chevron = Instance.new("TextLabel")
	self.Chevron.Name = "Chevron"
	self.Chevron.AnchorPoint = Vector2.new(1, 0.5)
	self.Chevron.Position = UDim2.new(1, -10, 0.5, 0)
	self.Chevron.Size = UDim2.new(0, 20, 1, 0)
	self.Chevron.BackgroundTransparency = 1
	self.Chevron.Font = tokens.FontBold
	self.Chevron.Text = "v"
	self.Chevron.TextColor3 = tokens.SecondaryText
	self.Chevron.TextSize = 14
	self.Chevron.Rotation = 0
	self.Chevron.ZIndex = 8
	self.Chevron.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Chevron.Font = tk.FontBold
		self.Chevron.TextColor3 = tk.SecondaryText
	end))

	self.OptionList = Instance.new("Frame")
	self.OptionList.Name = "OptionList"
	self.OptionList.Position = UDim2.new(0, 0, 0, 38)
	self.OptionList.Size = UDim2.new(1, 0, 0, 0)
	self.OptionList.BackgroundColor3 = tokens.Elevated
	self.OptionList.BorderSizePixel = 0
	self.OptionList.ZIndex = 20
	self.OptionList.ClipsDescendants = true
	self.OptionList.Visible = false
	self.OptionList.Parent = self.Container

	UIUtils.Corner(self.OptionList, tokens.CornerSmall)
	UIUtils.Stroke(self.OptionList, tokens.BorderLight, 1, 0.5)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.OptionList.BackgroundColor3 = tk.Elevated
	end))

	self.OptionScroll = Instance.new("ScrollingFrame")
	self.OptionScroll.Name = "OptionScroll"
	self.OptionScroll.Size = UDim2.new(1, 0, 1, 0)
	self.OptionScroll.BackgroundTransparency = 1
	self.OptionScroll.BorderSizePixel = 0
	self.OptionScroll.ScrollBarThickness = 2
	self.OptionScroll.ScrollBarImageColor3 = tokens.Accent
	self.OptionScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.OptionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.OptionScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	self.OptionScroll.ZIndex = 21
	self.OptionScroll.Parent = self.OptionList

	local optionLayout = Instance.new("UIListLayout")
	optionLayout.FillDirection = Enum.FillDirection.Vertical
	optionLayout.Padding = UDim.new(0, 2)
	optionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	optionLayout.Parent = self.OptionScroll

	local optionPadding = Instance.new("UIPadding")
	optionPadding.PaddingTop = UDim.new(0, 4)
	optionPadding.PaddingBottom = UDim.new(0, 4)
	optionPadding.PaddingLeft = UDim.new(0, 4)
	optionPadding.PaddingRight = UDim.new(0, 4)
	optionPadding.Parent = self.OptionScroll

	self:_populateOptions()

	self.Header.MouseButton1Click:Connect(function()
		self:SetOpen(not self.IsOpen)
	end)

	self.Header.MouseEnter:Connect(function()
		Animator.Tween(self.Header, { BackgroundTransparency = 0.05 }, 0.15, "Quad")
		Sound.Hover()
	end)

	self.Header.MouseLeave:Connect(function()
		Animator.Tween(self.Header, { BackgroundTransparency = 0.2 }, 0.15, "Quad")
	end)

	self:_updateListSize()
end

function Dropdown:_populateOptions()
	for _, child in ipairs(self.OptionScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for index, option in ipairs(self.Options) do
		local optionText = type(option) == "table" and option.Name or tostring(option)
		local optionValue = type(option) == "table" and option.Value or option

		local optionButton = Instance.new("TextButton")
		optionButton.Name = "Option_" .. optionText
		optionButton.Size = UDim2.new(1, 0, 0, 28)
		optionButton.BackgroundColor3 = ThemeManager.GetTokens().SurfaceLight
		optionButton.BackgroundTransparency = 1
		optionButton.BorderSizePixel = 0
		optionButton.AutoButtonColor = false
		optionButton.Font = ThemeManager.GetTokens().Font
		optionButton.Text = optionText
		optionButton.TextColor3 = ThemeManager.GetTokens().SecondaryText
		optionButton.TextSize = 13
		optionButton.TextXAlignment = Enum.TextXAlignment.Left
		optionButton.ZIndex = 22
		optionButton.LayoutOrder = index
		optionButton.Parent = self.OptionScroll

		UIUtils.Corner(optionButton, ThemeManager.GetTokens().CornerSmall)

		local textPadding = Instance.new("UIPadding")
		textPadding.PaddingLeft = UDim.new(0, 8)
		textPadding.Parent = optionButton

		optionButton.MouseEnter:Connect(function()
			Animator.Tween(optionButton, { BackgroundTransparency = 0.75, TextColor3 = ThemeManager.GetTokens().Text }, 0.12, "Quad")
		end)

		optionButton.MouseLeave:Connect(function()
			local tokens = ThemeManager.GetTokens()
			local isSelected = self.Value == optionValue
			Animator.Tween(optionButton, {
				BackgroundTransparency = isSelected and 0.7 or 1,
				TextColor3 = isSelected and tokens.Accent or tokens.SecondaryText,
			}, 0.12, "Quad")
		end)

		optionButton.MouseButton1Click:Connect(function()
			self:Select(optionValue)
		end)

		if self.Value == optionValue then
			optionButton.BackgroundTransparency = 0.7
			optionButton.TextColor3 = ThemeManager.GetTokens().Accent
		end
	end
end

function Dropdown:_updateListSize()
	local optionCount = #self.Options
	local visibleCount = math.min(optionCount, self.MaxVisible)
	local height = visibleCount * 30 + 8

	if self.IsOpen then
		self.OptionList.Size = UDim2.new(1, 0, 0, height)
	else
		self.OptionList.Size = UDim2.new(1, 0, 0, 0)
	end
end

function Dropdown:SetOpen(open)
	if open == self.IsOpen then
		return self
	end

	self.IsOpen = open

	if open then
		self.OptionList.Visible = true
		self:_updateListSize()
		Animator.Tween(self.Chevron, { Rotation = 180 }, 0.25, "Quart")
		Animator.Tween(self.OptionList, { Size = UDim2.new(1, 0, 0, self:_listHeight()) }, 0.25, "Quart")
		Sound.Pop()
		self.OnOpened:Fire()
	else
		Animator.Tween(self.Chevron, { Rotation = 0 }, 0.2, "Quad")
		Animator.Tween(self.OptionList, { Size = UDim2.new(1, 0, 0, 0) }, 0.2, "Quad")
		task.delay(0.2, function()
			if not self.IsOpen then
				self.OptionList.Visible = false
			end
		end)
		Sound.Close()
		self.OnClosed:Fire()
	end

	return self
end

function Dropdown:_listHeight()
	local optionCount = #self.Options
	local visibleCount = math.min(optionCount, self.MaxVisible)
	return visibleCount * 30 + 8
end

function Dropdown:Select(value)
	if not table.find(self.Options, value) and type(value) ~= "string" then
		for _, option in ipairs(self.Options) do
			if type(option) == "table" and option.Value == value then
				self.Value = value
				break
			end
		end
	else
		self.Value = value
	end

	local tokens = ThemeManager.GetTokens()
	self.SelectedLabel.Text = tostring(value)
	self.SelectedLabel.TextColor3 = tokens.Text

	for _, button in ipairs(self.OptionScroll:GetChildren()) do
		if button:IsA("TextButton") then
			local isSelected = button.Text == tostring(value)
			button.BackgroundTransparency = isSelected and 0.7 or 1
			button.TextColor3 = isSelected and tokens.Accent or tokens.SecondaryText
		end
	end

	self:SetOpen(false)
	Sound.Click()
	self.OnChanged:Fire(value)

	local ok, err = pcall(self.Callback, value)
	if not ok then
		warn("[NexusUI] Dropdown callback error:", err)
	end

	return self
end

function Dropdown:SetOptions(options)
	self.Options = options or {}
	self:_populateOptions()
	self:_updateListSize()
	return self
end

function Dropdown:GetValue()
	return self.Value
end

function Dropdown:SetText(text)
	self.Text = text
	return self
end

function Dropdown:Destroy()
	if self.Destroyed then
		return
	end

	self:SetOpen(false)

	if self.Container then
		self.Container:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return Dropdown
]]
__MODULES["Components.MultiDropdown"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

local MultiDropdown = {}
MultiDropdown.__index = MultiDropdown
setmetatable(MultiDropdown, { __index = BaseComponent })

function MultiDropdown.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("MultiDropdown")
	setmetatable(self, { __index = function(t, k)
		if MultiDropdown[k] then
			return MultiDropdown[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "MultiDropdown"
	self.Text = options.Text or options.Name or "Multi Select"
	self.Options = options.Options or {}
	self.SelectedOptions = {}
	self.Callback = options.Callback or function() end
	self.MaxVisible = options.MaxVisible or 5
	self.PlaceholderText = options.Placeholder or "Select multiple..."

	self.IsOpen = false

	if options.Value then
		if type(options.Value) == "table" then
			for _, v in ipairs(options.Value) do
				table.insert(self.SelectedOptions, v)
			end
		end
	end

	self.OnChanged = Signal.new()
	self.OnOpened = Signal.new()
	self.OnClosed = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
		Opened = self.OnOpened,
		Closed = self.OnClosed,
	}

	self:_build(parent)

	return self
end

function MultiDropdown:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "MultiDropdown_" .. self.Text
	self.Container.Size = UDim2.new(1, 0, 0, 34)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Header = Instance.new("TextButton")
	self.Header.Name = "Header"
	self.Header.Size = UDim2.new(1, 0, 0, 34)
	self.Header.BackgroundColor3 = tokens.SurfaceLight
	self.Header.BackgroundTransparency = 0.2
	self.Header.BorderSizePixel = 0
	self.Header.AutoButtonColor = false
	self.Header.Text = ""
	self.Header.ZIndex = 7
	self.Header.Parent = self.Container

	UIUtils.Corner(self.Header, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Header.BackgroundColor3 = tk.SurfaceLight
	end))

	self.SelectedLabel = Instance.new("TextLabel")
	self.SelectedLabel.Name = "Selected"
	self.SelectedLabel.Position = UDim2.new(0, 10, 0, 0)
	self.SelectedLabel.Size = UDim2.new(1, -40, 1, 0)
	self.SelectedLabel.BackgroundTransparency = 1
	self.SelectedLabel.Font = tokens.Font
	self.SelectedLabel.Text = self:_formatSelected()
	self.SelectedLabel.TextColor3 = tokens.Text
	self.SelectedLabel.TextSize = tokens.TextSize
	self.SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.SelectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
	self.SelectedLabel.ZIndex = 8
	self.SelectedLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.SelectedLabel.Font = tk.Font
		self.SelectedLabel.TextSize = tk.TextSize
	end))

	self.CountBadge = Instance.new("TextLabel")
	self.CountBadge.Name = "Count"
	self.CountBadge.AnchorPoint = Vector2.new(1, 0.5)
	self.CountBadge.Position = UDim2.new(1, -30, 0.5, 0)
	self.CountBadge.Size = UDim2.new(0, 20, 0, 20)
	self.CountBadge.BackgroundColor3 = tokens.Accent
	self.CountBadge.BackgroundTransparency = 0.85
	self.CountBadge.Font = tokens.FontBold
	self.CountBadge.Text = tostring(#self.SelectedOptions)
	self.CountBadge.TextColor3 = tokens.Accent
	self.CountBadge.TextSize = 11
	self.CountBadge.ZIndex = 8
	self.CountBadge.Parent = self.Header

	UIUtils.Corner(self.CountBadge, tokens.CornerCircle)

	self.Chevron = Instance.new("TextLabel")
	self.Chevron.Name = "Chevron"
	self.Chevron.AnchorPoint = Vector2.new(1, 0.5)
	self.Chevron.Position = UDim2.new(1, -8, 0.5, 0)
	self.Chevron.Size = UDim2.new(0, 20, 1, 0)
	self.Chevron.BackgroundTransparency = 1
	self.Chevron.Font = tokens.FontBold
	self.Chevron.Text = "v"
	self.Chevron.TextColor3 = tokens.SecondaryText
	self.Chevron.TextSize = 14
	self.Chevron.ZIndex = 8
	self.Chevron.Parent = self.Header

	self.OptionList = Instance.new("Frame")
	self.OptionList.Name = "OptionList"
	self.OptionList.Position = UDim2.new(0, 0, 0, 38)
	self.OptionList.Size = UDim2.new(1, 0, 0, 0)
	self.OptionList.BackgroundColor3 = tokens.Elevated
	self.OptionList.BorderSizePixel = 0
	self.OptionList.ZIndex = 20
	self.OptionList.ClipsDescendants = true
	self.OptionList.Visible = false
	self.OptionList.Parent = self.Container

	UIUtils.Corner(self.OptionList, tokens.CornerSmall)
	UIUtils.Stroke(self.OptionList, tokens.BorderLight, 1, 0.5)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.OptionList.BackgroundColor3 = tk.Elevated
	end))

	self.OptionScroll = Instance.new("ScrollingFrame")
	self.OptionScroll.Size = UDim2.new(1, 0, 1, 0)
	self.OptionScroll.BackgroundTransparency = 1
	self.OptionScroll.BorderSizePixel = 0
	self.OptionScroll.ScrollBarThickness = 2
	self.OptionScroll.ScrollBarImageColor3 = tokens.Accent
	self.OptionScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.OptionScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.OptionScroll.ZIndex = 21
	self.OptionScroll.Parent = self.OptionList

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.OptionScroll

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 4)
	padding.Parent = self.OptionScroll

	self:_populateOptions()

	self.Header.MouseButton1Click:Connect(function()
		self:SetOpen(not self.IsOpen)
	end)

	self:_updateListHeight()
end

function MultiDropdown:_formatSelected()
	if #self.SelectedOptions == 0 then
		return self.PlaceholderText
	end
	if #self.SelectedOptions <= 3 then
		return table.concat(self.SelectedOptions, ", ")
	end
	return self.SelectedOptions[1] .. ", " .. self.SelectedOptions[2] .. " +" .. (#self.SelectedOptions - 2)
end

function MultiDropdown:_populateOptions()
	for _, child in ipairs(self.OptionScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for index, option in ipairs(self.Options) do
		local optionText = tostring(option)
		local isSelected = table.find(self.SelectedOptions, option) ~= nil

		local optionButton = Instance.new("TextButton")
		optionButton.Name = "Option_" .. optionText
		optionButton.Size = UDim2.new(1, 0, 0, 28)
		optionButton.BackgroundColor3 = ThemeManager.GetTokens().SurfaceLight
		optionButton.BackgroundTransparency = 1
		optionButton.BorderSizePixel = 0
		optionButton.AutoButtonColor = false
		optionButton.Font = ThemeManager.GetTokens().Font
		optionButton.Text = (isSelected and "[x] " or "[ ] ") .. optionText
		optionButton.TextColor3 = isSelected and ThemeManager.GetTokens().Accent or ThemeManager.GetTokens().SecondaryText
		optionButton.TextSize = 13
		optionButton.TextXAlignment = Enum.TextXAlignment.Left
		optionButton.ZIndex = 22
		optionButton.LayoutOrder = index
		optionButton.Parent = self.OptionScroll

		UIUtils.Corner(optionButton, ThemeManager.GetTokens().CornerSmall)

		local textPadding = Instance.new("UIPadding")
		textPadding.PaddingLeft = UDim.new(0, 8)
		textPadding.Parent = optionButton

		optionButton.MouseEnter:Connect(function()
			Animator.Tween(optionButton, { BackgroundTransparency = 0.75 }, 0.12, "Quad")
		end)

		optionButton.MouseLeave:Connect(function()
			Animator.Tween(optionButton, { BackgroundTransparency = 1 }, 0.12, "Quad")
		end)

		optionButton.MouseButton1Click:Connect(function()
			self:ToggleOption(option)
		end)

		optionButton._optionValue = option
	end
end

function MultiDropdown:_updateListHeight()
	local optionCount = #self.Options
	local visibleCount = math.min(optionCount, self.MaxVisible)
	local height = visibleCount * 30 + 8

	if self.IsOpen then
		self.OptionList.Size = UDim2.new(1, 0, 0, height)
	else
		self.OptionList.Size = UDim2.new(1, 0, 0, 0)
	end
end

function MultiDropdown:SetOpen(open)
	if open == self.IsOpen then
		return self
	end

	self.IsOpen = open

	if open then
		self.OptionList.Visible = true
		Animator.Tween(self.Chevron, { Rotation = 180 }, 0.25, "Quart")
		Animator.Tween(self.OptionList, { Size = UDim2.new(1, 0, 0, math.min(#self.Options, self.MaxVisible) * 30 + 8) }, 0.25, "Quart")
		Sound.Pop()
		self.OnOpened:Fire()
	else
		Animator.Tween(self.Chevron, { Rotation = 0 }, 0.2, "Quad")
		Animator.Tween(self.OptionList, { Size = UDim2.new(1, 0, 0, 0) }, 0.2, "Quad")
		task.delay(0.2, function()
			if not self.IsOpen then
				self.OptionList.Visible = false
			end
		end)
		Sound.Close()
		self.OnClosed:Fire()
	end

	return self
end

function MultiDropdown:ToggleOption(option)
	local index = table.find(self.SelectedOptions, option)

	if index then
		table.remove(self.SelectedOptions, index)
	else
		table.insert(self.SelectedOptions, option)
	end

	self:_refreshDisplay()
	Sound.Toggle()
	self.OnChanged:Fire(self.SelectedOptions)

	local ok, err = pcall(self.Callback, self.SelectedOptions)
	if not ok then
		warn("[NexusUI] MultiDropdown callback error:", err)
	end

	return self
end

function MultiDropdown:_refreshDisplay()
	self.SelectedLabel.Text = self:_formatSelected()
	self.CountBadge.Text = tostring(#self.SelectedOptions)

	for _, button in ipairs(self.OptionScroll:GetChildren()) do
		if button:IsA("TextButton") and button._optionValue ~= nil then
			local isSelected = table.find(self.SelectedOptions, button._optionValue) ~= nil
			button.Text = (isSelected and "[x] " or "[ ] ") .. button.Text:sub(5)
			button.TextColor3 = isSelected and ThemeManager.GetTokens().Accent or ThemeManager.GetTokens().SecondaryText
		end
	end
end

function MultiDropdown:SetSelected(options)
	self.SelectedOptions = {}

	if type(options) == "table" then
		for _, option in ipairs(options) do
			if table.find(self.Options, option) then
				table.insert(self.SelectedOptions, option)
			end
		end
	end

	self:_refreshDisplay()
	self.OnChanged:Fire(self.SelectedOptions)
	return self
end

function MultiDropdown:GetSelected()
	local copy = {}
	for _, option in ipairs(self.SelectedOptions) do
		table.insert(copy, option)
	end
	return copy
end

function MultiDropdown:Clear()
	self.SelectedOptions = {}
	self:_refreshDisplay()
	return self
end

function MultiDropdown:SetOptions(options)
	self.Options = options or {}
	self.SelectedOptions = {}
	self:_populateOptions()
	self:_updateListHeight()
	return self
end

function MultiDropdown:SetText(text)
	self.Text = text
	return self
end

function MultiDropdown:Destroy()
	if self.Destroyed then
		return
	end

	self:SetOpen(false)

	if self.Container then
		self.Container:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return MultiDropdown
]]
__MODULES["Components.TextBox"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

local TextBox = {}
TextBox.__index = TextBox
setmetatable(TextBox, { __index = BaseComponent })

function TextBox.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("TextBox")
	setmetatable(self, { __index = function(t, k)
		if TextBox[k] then
			return TextBox[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "TextBox"
	self.Text = options.Text or options.Value or ""
	self.Placeholder = options.Placeholder or "Type here..."
	self.DefaultValue = self.Text
	self.Callback = options.Callback or function() end
	self.OnEnter = options.OnEnter
	self.ClearOnFocus = options.ClearOnFocus or false
	self.NumericOnly = options.NumericOnly or false
	self.MaxLength = options.MaxLength or 200

	self.OnChanged = Signal.new()
	self.OnFocused = Signal.new()
	self.OnFocusLost = Signal.new()
	self.OnSubmitted = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
		Focused = self.OnFocused,
		FocusLost = self.OnFocusLost,
		Submitted = self.OnSubmitted,
	}

	self:_build(parent)

	return self
end

function TextBox:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "TextBox_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, 34)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.InputFrame = Instance.new("Frame")
	self.InputFrame.Name = "InputFrame"
	self.InputFrame.Size = UDim2.new(1, 0, 1, 0)
	self.InputFrame.BackgroundColor3 = tokens.Background
	self.InputFrame.BackgroundTransparency = 0.2
	self.InputFrame.BorderSizePixel = 0
	self.InputFrame.ZIndex = 7
	self.InputFrame.Parent = self.Container

	UIUtils.Corner(self.InputFrame, tokens.CornerSmall)
	self.Stroke = UIUtils.Stroke(self.InputFrame, tokens.Border, 1, 0.6)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.InputFrame.BackgroundColor3 = tk.Background
	end))

	self.Input = Instance.new("TextBox")
	self.Input.Name = "Input"
	self.Input.Position = UDim2.new(0, 10, 0, 0)
	self.Input.Size = UDim2.new(1, -20, 1, 0)
	self.Input.BackgroundTransparency = 1
	self.Input.Font = tokens.Font
	self.Input.Text = self.Text
	self.Input.PlaceholderText = self.Placeholder
	self.Input.PlaceholderColor3 = tokens.MutedText
	self.Input.TextColor3 = tokens.Text
	self.Input.TextSize = tokens.TextSize
	self.Input.TextXAlignment = Enum.TextXAlignment.Left
	self.Input.ClearTextOnFocus = self.ClearOnFocus
	self.Input.TextTruncate = Enum.TextTruncate.AtEnd
	self.Input.ZIndex = 8
	self.Input.Parent = self.InputFrame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Input.Font = tk.Font
		self.Input.TextSize = tk.TextSize
		self.Input.TextColor3 = tk.Text
		self.Input.PlaceholderColor3 = tk.MutedText
	end))

	self.Input:GetPropertyChangedSignal("Text"):Connect(function()
		local text = self.Input.Text

		if self.NumericOnly then
			local filtered = text:gsub("[^%d%.%-]", "")
			if filtered ~= text then
				self.Input.Text = filtered
				text = filtered
			end
		end

		if #text > self.MaxLength then
			self.Input.Text = text:sub(1, self.MaxLength)
			text = self.Input.Text
		end

		self.Text = text
		self.OnChanged:Fire(text)
	end)

	self.Input.Focused:Connect(function()
		Animator.Tween(self.Stroke, { Color = ThemeManager.GetTokens().Accent, Transparency = 0.1 }, 0.18, "Quad")
		Animator.Tween(self.InputFrame, { BackgroundTransparency = 0.05 }, 0.18, "Quad")
		self.OnFocused:Fire(self.Text)
	end)

	self.Input.FocusLost:Connect(function(enterPressed)
		local tokensNow = ThemeManager.GetTokens()
		Animator.Tween(self.Stroke, { Color = tokensNow.Border, Transparency = 0.6 }, 0.18, "Quad")
		Animator.Tween(self.InputFrame, { BackgroundTransparency = 0.2 }, 0.18, "Quad")

		self.OnFocusLost:Fire(self.Text, enterPressed)

		if enterPressed then
			Sound.Click()
			self.OnSubmitted:Fire(self.Text)

			if self.OnEnter then
				pcall(self.OnEnter, self.Text)
			end
		end
	end)
end

function TextBox:SetText(text)
	self.Text = text
	self.Input.Text = text
	return self
end

function TextBox:GetText()
	return self.Input.Text
end

function TextBox:SetPlaceholder(placeholder)
	self.Placeholder = placeholder
	self.Input.PlaceholderText = placeholder
	return self
end

function TextBox:SetNumericOnly(enabled)
	self.NumericOnly = enabled
	return self
end

function TextBox:SetMaxLength(maxLength)
	self.MaxLength = maxLength
	return self
end

function TextBox:Clear()
	return self:SetText("")
end

function TextBox:Focus()
	self.Input:CaptureFocus()
	return self
end

function TextBox:ReleaseFocus()
	self.Input:ReleaseFocus()
	return self
end

function TextBox:Reset()
	return self:SetText(self.DefaultValue)
end

function TextBox:Destroy()
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

return TextBox
]]
__MODULES["Components.SearchBox"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

local SearchBox = {}
SearchBox.__index = SearchBox
setmetatable(SearchBox, { __index = BaseComponent })

function SearchBox.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("SearchBox")
	setmetatable(self, { __index = function(t, k)
		if SearchBox[k] then
			return SearchBox[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "SearchBox"
	self.Placeholder = options.Placeholder or "Search..."
	self.DebounceTime = options.DebounceTime or 0.3
	self.Callback = options.Callback or function() end

	self.OnSearch = Signal.new()
	self.OnCleared = Signal.new()
	self.OnTextChanged = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Search = self.OnSearch,
		Cleared = self.OnCleared,
		TextChanged = self.OnTextChanged,
	}

	self:_build(parent)

	return self
end

function SearchBox:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "SearchBox_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, 34)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Frame = Instance.new("Frame")
	self.Frame.Name = "Holder"
	self.Frame.Size = UDim2.new(1, 0, 1, 0)
	self.Frame.BackgroundColor3 = tokens.Background
	self.Frame.BackgroundTransparency = 0.2
	self.Frame.BorderSizePixel = 0
	self.Frame.ZIndex = 7
	self.Frame.Parent = self.Container

	UIUtils.Corner(self.Frame, tokens.CornerSmall)
	self.Stroke = UIUtils.Stroke(self.Frame, tokens.Border, 1, 0.6)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Frame.BackgroundColor3 = tk.Background
	end))

	self.SearchIcon = Instance.new("ImageLabel")
	self.SearchIcon.Name = "SearchIcon"
	self.SearchIcon.Position = UDim2.new(0, 10, 0.5, 0)
	self.SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
	self.SearchIcon.Size = UDim2.new(0, 15, 0, 15)
	self.SearchIcon.BackgroundTransparency = 1
	self.SearchIcon.Image = "rbxassetid://10747387627"
	self.SearchIcon.ImageColor3 = tokens.MutedText
	self.SearchIcon.ScaleType = Enum.ScaleType.Fit
	self.SearchIcon.ZIndex = 8
	self.SearchIcon.Parent = self.Frame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.SearchIcon.ImageColor3 = tk.MutedText
	end))

	self.Input = Instance.new("TextBox")
	self.Input.Name = "Input"
	self.Input.Position = UDim2.new(0, 32, 0, 0)
	self.Input.Size = UDim2.new(1, -58, 1, 0)
	self.Input.BackgroundTransparency = 1
	self.Input.Font = tokens.Font
	self.Input.Text = ""
	self.Input.PlaceholderText = self.Placeholder
	self.Input.PlaceholderColor3 = tokens.MutedText
	self.Input.TextColor3 = tokens.Text
	self.Input.TextSize = tokens.TextSize
	self.Input.TextXAlignment = Enum.TextXAlignment.Left
	self.Input.ClearTextOnFocus = false
	self.Input.ZIndex = 8
	self.Input.Parent = self.Frame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Input.Font = tk.Font
		self.Input.TextSize = tk.TextSize
		self.Input.TextColor3 = tk.Text
		self.Input.PlaceholderColor3 = tk.MutedText
	end))

	self.ClearButton = Instance.new("TextButton")
	self.ClearButton.Name = "Clear"
	self.ClearButton.AnchorPoint = Vector2.new(1, 0.5)
	self.ClearButton.Position = UDim2.new(1, -8, 0.5, 0)
	self.ClearButton.Size = UDim2.new(0, 18, 0, 18)
	self.ClearButton.BackgroundTransparency = 1
	self.ClearButton.BorderSizePixel = 0
	self.ClearButton.AutoButtonColor = false
	self.ClearButton.Font = tokens.FontBold
	self.ClearButton.Text = "x"
	self.ClearButton.TextColor3 = tokens.MutedText
	self.ClearButton.TextSize = 13
	self.ClearButton.Visible = false
	self.ClearButton.ZIndex = 8
	self.ClearButton.Parent = self.Frame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.ClearButton.Font = tk.FontBold
		self.ClearButton.TextColor3 = tk.MutedText
	end))

	self:_bindEvents()
end

function SearchBox:_bindEvents()
	local debounceThread = nil

	local function scheduleSearch(text)
		if debounceThread then
			task.cancel(debounceThread)
		end

		debounceThread = task.delay(self.DebounceTime, function()
			self.OnSearch:Fire(text)
			pcall(self.Callback, text)
		end)
	end

	self.Input:GetPropertyChangedSignal("Text"):Connect(function()
		local text = self.Input.Text
		self.ClearButton.Visible = #text > 0

		self.OnTextChanged:Fire(text)
		scheduleSearch(text)
	end)

	self.Input.Focused:Connect(function()
		Animator.Tween(self.Stroke, { Color = ThemeManager.GetTokens().Accent, Transparency = 0.1 }, 0.18, "Quad")
	end)

	self.Input.FocusLost:Connect(function()
		Animator.Tween(self.Stroke, { Color = ThemeManager.GetTokens().Border, Transparency = 0.6 }, 0.18, "Quad")
	end)

	self.ClearButton.MouseButton1Click:Connect(function()
		self.Input.Text = ""
		self.ClearButton.Visible = false
		Sound.Click()
		self.OnCleared:Fire()
		self.OnSearch:Fire("")
	end)

	self.ClearButton.MouseEnter:Connect(function()
		Animator.Tween(self.ClearButton, { TextColor3 = ThemeManager.GetTokens().Error }, 0.15, "Quad")
	end)

	self.ClearButton.MouseLeave:Connect(function()
		Animator.Tween(self.ClearButton, { TextColor3 = ThemeManager.GetTokens().MutedText }, 0.15, "Quad")
	end)
end

function SearchBox:SetText(text)
	self.Input.Text = text
	self.ClearButton.Visible = #text > 0
	return self
end

function SearchBox:GetText()
	return self.Input.Text
end

function SearchBox:Clear()
	self.Input.Text = ""
	self.ClearButton.Visible = false
	self.OnCleared:Fire()
	self.OnSearch:Fire("")
	return self
end

function SearchBox:Focus()
	self.Input:CaptureFocus()
	return self
end

function SearchBox:SetPlaceholder(text)
	self.Placeholder = text
	self.Input.PlaceholderText = text
	return self
end

function SearchBox:Destroy()
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

return SearchBox
]]
__MODULES["Components.Keybind"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

local Keybind = {}
Keybind.__index = Keybind
setmetatable(Keybind, { __index = BaseComponent })

function Keybind.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Keybind")
	setmetatable(self, { __index = function(t, k)
		if Keybind[k] then
			return Keybind[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Keybind"
	self.Text = options.Text or options.Name or "Keybind"
	self.DefaultValue = options.Value or options.Default or Enum.KeyCode.RightShift
	self.Value = self.DefaultValue
	self.Callback = options.Callback or function() end
	self.Mode = options.Mode or "Toggle"
	self.AllowMouse = options.AllowMouse ~= false

	self.Listening = false

	self.OnChanged = Signal.new()
	self.OnTriggered = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
		Triggered = self.OnTriggered,
	}

	self:_build(parent)
	self:_bindInput()

	return self
end

function Keybind:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Keybind_" .. self.Text
	self.Container.Size = UDim2.new(1, 0, 0, 34)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.TextLabel = Instance.new("TextLabel")
	self.TextLabel.Name = "Text"
	self.TextLabel.BackgroundTransparency = 1
	self.TextLabel.Position = UDim2.new(0, 4, 0, 0)
	self.TextLabel.Size = UDim2.new(1, -80, 1, 0)
	self.TextLabel.Font = tokens.Font
	self.TextLabel.Text = self.Text
	self.TextLabel.TextColor3 = tokens.Text
	self.TextLabel.TextSize = tokens.TextSize
	self.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TextLabel.TextTruncate = Enum.TextTruncate.AtEnd
	self.TextLabel.ZIndex = 7
	self.TextLabel.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TextLabel.Font = tk.Font
		self.TextLabel.TextColor3 = tk.Text
		self.TextLabel.TextSize = tk.TextSize
	end))

	self.BindButton = Instance.new("TextButton")
	self.BindButton.Name = "BindButton"
	self.BindButton.AnchorPoint = Vector2.new(1, 0.5)
	self.BindButton.Position = UDim2.new(1, -2, 0.5, 0)
	self.BindButton.Size = UDim2.new(0, 70, 0, 24)
	self.BindButton.BackgroundColor3 = tokens.SurfaceLight
	self.BindButton.BackgroundTransparency = 0.2
	self.BindButton.BorderSizePixel = 0
	self.BindButton.AutoButtonColor = false
	self.BindButton.Font = tokens.FontBold
	self.BindButton.Text = self:_keyName(self.Value)
	self.BindButton.TextColor3 = tokens.Accent
	self.BindButton.TextSize = 11
	self.BindButton.ZIndex = 7
	self.BindButton.Parent = self.Container

	UIUtils.Corner(self.BindButton, tokens.CornerSmall)
	UIUtils.Stroke(self.BindButton, tokens.Border, 1, 0.6)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.BindButton.BackgroundColor3 = tk.SurfaceLight
		self.BindButton.Font = tk.FontBold
		self.BindButton.TextColor3 = tk.Accent
	end))

	self.BindButton.MouseButton1Click:Connect(function()
		self:StartListening()
	end)

	self.BindButton.MouseEnter:Connect(function()
		Animator.Tween(self.BindButton, { BackgroundTransparency = 0.02 }, 0.15, "Quad")
		Sound.Hover()
	end)

	self.BindButton.MouseLeave:Connect(function()
		Animator.Tween(self.BindButton, { BackgroundTransparency = 0.2 }, 0.15, "Quad")
	end)
end

function Keybind:_keyName(keyCode)
	if not keyCode then
		return "None"
	end

	local UserInputService = game:GetService("UserInputService")
	local ok, name = pcall(function()
		return UserInputService:GetStringForKeyCode(keyCode)
	end)

	if ok and name and name ~= "" then
		return name
	end

	return keyCode.Name
end

function Keybind:StartListening()
	if self.Listening then
		return self
	end

	self.Listening = true
	local tokens = ThemeManager.GetTokens()

	self.BindButton.Text = "..."
	Animator.Tween(self.BindButton, { BackgroundColor3 = tokens.Accent, BackgroundTransparency = 0.7, TextColor3 = Color3.fromRGB(255, 255, 255) }, 0.15, "Quad")

	return self
end

function Keybind:StopListening()
	if not self.Listening then
		return self
	end

	self.Listening = false
	self.BindButton.Text = self:_keyName(self.Value)
	self:_updateBindButtonVisual()

	return self
end

function Keybind:_updateBindButtonVisual()
	local tokens = ThemeManager.GetTokens()
	Animator.Tween(self.BindButton, {
		BackgroundColor3 = tokens.SurfaceLight,
		BackgroundTransparency = 0.2,
		TextColor3 = tokens.Accent,
	}, 0.15, "Quad")
end

function Keybind:_bindInput()
	local UserInputService = game:GetService("UserInputService")

	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input, processed)
		if not self.Listening then
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				self:StopListening()
				return
			end

			self:SetValue(input.KeyCode, true)
			self:StopListening()

		elseif self.AllowMouse then
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				self:SetValue(input.UserInputType, true)
				self:StopListening()
			end
		end
	end))

	self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input, processed)
		if processed then
			return
		end

		if self.Listening then
			return
		end

		local matches = false
		if input.UserInputType == Enum.UserInputType.Keyboard then
			matches = input.KeyCode == self.Value
		elseif input.UserInputType == self.Value then
			matches = true
		end

		if matches then
			if self.Mode == "Toggle" then
				self.OnTriggered:Fire(self.Value)
				pcall(self.Callback, self.Value)
			elseif self.Mode == "Hold" then
				self.OnTriggered:Fire(self.Value)
				pcall(self.Callback, self.Value)
			end
		end
	end))
end

function Keybind:SetValue(value, fireEvent)
	self.Value = value
	self.BindButton.Text = self:_keyName(value)

	if fireEvent then
		Sound.Click()
		self.OnChanged:Fire(value)
	end

	return self
end

function Keybind:GetValue()
	return self.Value
end

function Keybind:SetText(text)
	self.Text = text
	self.TextLabel.Text = text
	return self
end

function Keybind:SetMode(mode)
	self.Mode = mode
	return self
end

function Keybind:Reset()
	return self:SetValue(self.DefaultValue, true)
end

function Keybind:Destroy()
	if self.Destroyed then
		return
	end

	self:StopListening()

	if self.Container then
		self.Container:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return Keybind
]]
__MODULES["Components.ColorPicker"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

local ColorPicker = {}
ColorPicker.__index = ColorPicker
setmetatable(ColorPicker, { __index = BaseComponent })

function ColorPicker.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("ColorPicker")
	setmetatable(self, { __index = function(t, k)
		if ColorPicker[k] then
			return ColorPicker[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "ColorPicker"
	self.Text = options.Text or options.Name or "Color"
	self.DefaultColor = options.Value or options.Default or Color3.fromRGB(96, 130, 255)
	self.Color = self.DefaultColor
	self.Callback = options.Callback or function() end

	self.IsOpen = false

	self.OnChanged = Signal.new()
	self.OnOpened = Signal.new()
	self.OnClosed = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Changed = self.OnChanged,
		Opened = self.OnOpened,
		Closed = self.OnClosed,
	}

	local h, s, v = self.Color:ToHSV()
	self._hue = h
	self._sat = s
	self._val = v

	self:_build(parent)

	return self
end

function ColorPicker:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "ColorPicker_" .. self.Text
	self.Container.Size = UDim2.new(1, 0, 0, 34)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Header = Instance.new("TextButton")
	self.Header.Name = "Header"
	self.Header.Size = UDim2.new(1, 0, 0, 34)
	self.Header.BackgroundColor3 = tokens.SurfaceLight
	self.Header.BackgroundTransparency = 0.2
	self.Header.BorderSizePixel = 0
	self.Header.AutoButtonColor = false
	self.Header.Text = ""
	self.Header.ZIndex = 7
	self.Header.Parent = self.Container

	UIUtils.Corner(self.Header, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Header.BackgroundColor3 = tk.SurfaceLight
	end))

	self.ColorPreview = Instance.new("Frame")
	self.ColorPreview.Name = "Preview"
	self.ColorPreview.AnchorPoint = Vector2.new(0, 0.5)
	self.ColorPreview.Position = UDim2.new(0, 8, 0.5, 0)
	self.ColorPreview.Size = UDim2.new(0, 22, 0, 22)
	self.ColorPreview.BackgroundColor3 = self.Color
	self.ColorPreview.BorderSizePixel = 0
	self.ColorPreview.ZIndex = 8
	self.ColorPreview.Parent = self.Header

	UIUtils.Corner(self.ColorPreview, tokens.CornerSmall)
	UIUtils.Stroke(self.ColorPreview, tokens.BorderLight, 1, 0.4)

	self.TextLabel = Instance.new("TextLabel")
	self.TextLabel.Name = "Text"
	self.TextLabel.Position = UDim2.new(0, 38, 0, 0)
	self.TextLabel.Size = UDim2.new(0.6, -38, 1, 0)
	self.TextLabel.BackgroundTransparency = 1
	self.TextLabel.Font = tokens.Font
	self.TextLabel.Text = self.Text
	self.TextLabel.TextColor3 = tokens.Text
	self.TextLabel.TextSize = tokens.TextSize
	self.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TextLabel.ZIndex = 8
	self.TextLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TextLabel.Font = tk.Font
		self.TextLabel.TextColor3 = tk.Text
		self.TextLabel.TextSize = tk.TextSize
	end))

	self.HexLabel = Instance.new("TextLabel")
	self.HexLabel.Name = "Hex"
	self.HexLabel.AnchorPoint = Vector2.new(1, 0.5)
	self.HexLabel.Position = UDim2.new(1, -8, 0.5, 0)
	self.HexLabel.Size = UDim2.new(0, 70, 1, 0)
	self.HexLabel.BackgroundTransparency = 1
	self.HexLabel.Font = tokens.FontBold
	self.HexLabel.Text = UIUtils.ToHex(self.Color)
	self.HexLabel.TextColor3 = tokens.SecondaryText
	self.HexLabel.TextSize = 11
	self.HexLabel.TextXAlignment = Enum.TextXAlignment.Right
	self.HexLabel.ZIndex = 8
	self.HexLabel.Parent = self.Header

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.HexLabel.Font = tk.FontBold
		self.HexLabel.TextColor3 = tk.SecondaryText
	end))

	self.Popup = Instance.new("Frame")
	self.Popup.Name = "Popup"
	self.Popup.Position = UDim2.new(0, 0, 0, 38)
	self.Popup.Size = UDim2.new(1, 0, 0, 0)
	self.Popup.BackgroundColor3 = tokens.Elevated
	self.Popup.BorderSizePixel = 0
	self.Popup.ZIndex = 20
	self.Popup.ClipsDescendants = true
	self.Popup.Visible = false
	self.Popup.Parent = self.Container

	UIUtils.Corner(self.Popup, tokens.Corner)
	UIUtils.Stroke(self.Popup, tokens.BorderLight, 1, 0.5)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Popup.BackgroundColor3 = tk.Elevated
	end))

	self:_buildSatVal()
	self:_buildHueBar()
	self:_buildPreviewRow()

	self.Header.MouseButton1Click:Connect(function()
		self:SetOpen(not self.IsOpen)
	end)
end

function ColorPicker:_buildSatVal()
	local tokens = ThemeManager.GetTokens()

	self.SatVal = Instance.new("TextButton")
	self.SatVal.Name = "SatVal"
	self.SatVal.Position = UDim2.new(0, 10, 0, 10)
	self.SatVal.Size = UDim2.new(1, -30, 0, 110)
	self.SatVal.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1)
	self.SatVal.BorderSizePixel = 0
	self.SatVal.AutoButtonColor = false
	self.SatVal.Text = ""
	self.SatVal.ZIndex = 21
	self.SatVal.Parent = self.Popup

	UIUtils.Corner(self.SatVal, tokens.CornerSmall)

	self.SatGradient = Instance.new("UIGradient")
	self.SatGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	self.SatGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	self.SatGradient.Rotation = 0
	self.SatGradient.Parent = self.SatVal

	self.ValGradient = Instance.new("Frame")
	self.ValGradient.Name = "ValOverlay"
	self.ValGradient.Size = UDim2.new(1, 0, 1, 0)
	self.ValGradient.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.ValGradient.BorderSizePixel = 0
	self.ValGradient.ZIndex = 22
	self.ValGradient.Parent = self.SatVal

	UIUtils.Corner(self.ValGradient, tokens.CornerSmall)

	self.ValGradientObj = Instance.new("UIGradient")
	self.ValGradientObj.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
	})
	self.ValGradientObj.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	self.ValGradientObj.Rotation = 90
	self.ValGradientObj.Parent = self.ValGradient

	self.SatValKnob = Instance.new("Frame")
	self.SatValKnob.Name = "Knob"
	self.SatValKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	self.SatValKnob.Size = UDim2.new(0, 12, 0, 12)
	self.SatValKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.SatValKnob.BorderSizePixel = 0
	self.SatValKnob.ZIndex = 23
	self.SatValKnob.Parent = self.SatVal

	UIUtils.Corner(self.SatValKnob, UDim.new(1, 0))
	UIUtils.Stroke(self.SatValKnob, Color3.fromRGB(0, 0, 0), 1, 0.4)

	self:_bindSatValDrag()
end

function ColorPicker:_buildHueBar()
	local tokens = ThemeManager.GetTokens()

	self.HueBar = Instance.new("TextButton")
	self.HueBar.Name = "HueBar"
	self.HueBar.AnchorPoint = Vector2.new(1, 0)
	self.HueBar.Position = UDim2.new(1, -10, 0, 10)
	self.HueBar.Size = UDim2.new(0, 14, 0, 110)
	self.HueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.HueBar.BorderSizePixel = 0
	self.HueBar.AutoButtonColor = false
	self.HueBar.Text = ""
	self.HueBar.ZIndex = 21
	self.HueBar.Parent = self.Popup

	UIUtils.Corner(self.HueBar, tokens.CornerSmall)

	self.HueGradient = Instance.new("UIGradient")
	self.HueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	})
	self.HueGradient.Rotation = 90
	self.HueGradient.Parent = self.HueBar

	self.HueKnob = Instance.new("Frame")
	self.HueKnob.Name = "Knob"
	self.HueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	self.HueKnob.Size = UDim2.new(1, 4, 0, 6)
	self.HueKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.HueKnob.BorderSizePixel = 0
	self.HueKnob.ZIndex = 23
	self.HueKnob.Parent = self.HueBar

	UIUtils.Corner(self.HueKnob, tokens.CornerSmall)
	UIUtils.Stroke(self.HueKnob, Color3.fromRGB(0, 0, 0), 1, 0.4)

	self:_bindHueDrag()
end

function ColorPicker:_buildPreviewRow()
	local tokens = ThemeManager.GetTokens()

	local row = Instance.new("Frame")
	row.Name = "PreviewRow"
	row.Position = UDim2.new(0, 10, 0, 130)
	row.Size = UDim2.new(1, -20, 0, 28)
	row.BackgroundTransparency = 1
	row.ZIndex = 21
	row.Parent = self.Popup

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row

	self.Swatch = Instance.new("Frame")
	self.Swatch.Name = "Swatch"
	self.Swatch.Size = UDim2.new(0, 46, 1, 0)
	self.Swatch.BackgroundColor3 = self.Color
	self.Swatch.BorderSizePixel = 0
	self.Swatch.LayoutOrder = 1
	self.Swatch.ZIndex = 22
	self.Swatch.Parent = row

	UIUtils.Corner(self.Swatch, tokens.CornerSmall)
	UIUtils.Stroke(self.Swatch, tokens.BorderLight, 1, 0.5)

	self.HexInput = Instance.new("TextBox")
	self.HexInput.Name = "HexInput"
	self.HexInput.Size = UDim2.new(1, -52, 1, 0)
	self.HexInput.Position = UDim2.new(0, 52, 0, 0)
	self.HexInput.BackgroundColor3 = tokens.Background
	self.HexInput.BackgroundTransparency = 0.2
	self.HexInput.BorderSizePixel = 0
	self.HexInput.Font = tokens.FontCode
	self.HexInput.Text = UIUtils.ToHex(self.Color)
	self.HexInput.PlaceholderText = "#FFFFFF"
	self.HexInput.PlaceholderColor3 = tokens.MutedText
	self.HexInput.TextColor3 = tokens.Text
	self.HexInput.TextSize = 12
	self.HexInput.ClearTextOnFocus = false
	self.HexInput.LayoutOrder = 2
	self.HexInput.ZIndex = 22
	self.HexInput.Parent = row

	UIUtils.Corner(self.HexInput, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.HexInput.BackgroundColor3 = tk.Background
		self.HexInput.Font = tk.FontCode
		self.HexInput.TextColor3 = tk.Text
	end))

	self.HexInput.FocusLost:Connect(function(enterPressed)
		if not enterPressed then
			return
		end

		local success, color = pcall(UIUtils.FromHex, self.HexInput.Text)
		if success and color then
			self:SetColor(color, true)
		else
			self.HexInput.Text = UIUtils.ToHex(self.Color)
		end
	end)
end

function ColorPicker:_bindSatValDrag()
	local dragging = false

	local function updateFromInput(position)
		local absPos = self.SatVal.AbsolutePosition
		local absSize = self.SatVal.AbsoluteSize

		local relX = math.clamp((position.X - absPos.X) / absSize.X, 0, 1)
		local relY = math.clamp((position.Y - absPos.Y) / absSize.Y, 0, 1)

		self._sat = relX
		self._val = 1 - relY

		self:_applyHSV(true)
	end

	self.SatVal.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromInput(input.Position)
		end
	end)

	local uis = game:GetService("UserInputService")
	self._maid:GiveTask(uis.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position)
		end
	end))

	self._maid:GiveTask(uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

function ColorPicker:_bindHueDrag()
	local dragging = false

	local function updateFromInput(position)
		local absPos = self.HueBar.AbsolutePosition
		local absSize = self.HueBar.AbsoluteSize

		local relY = math.clamp((position.Y - absPos.Y) / absSize.Y, 0, 1)
		self._hue = relY

		self:_applyHSV(true)
	end

	self.HueBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromInput(input.Position)
		end
	end)

	local uis = game:GetService("UserInputService")
	self._maid:GiveTask(uis.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position)
		end
	end))

	self._maid:GiveTask(uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

function ColorPicker:_applyHSV(fireEvent)
	self.Color = Color3.fromHSV(self._hue, self._sat, self._val)

	self.SatVal.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1)
	self.SatValKnob.Position = UDim2.new(self._sat, 0, 1 - self._val, 0)
	self.HueKnob.Position = UDim2.new(0.5, 0, self._hue, 0)

	self.ColorPreview.BackgroundColor3 = self.Color
	self.Swatch.BackgroundColor3 = self.Color
	self.HexLabel.Text = UIUtils.ToHex(self.Color)
	self.HexInput.Text = UIUtils.ToHex(self.Color)

	if fireEvent then
		self.OnChanged:Fire(self.Color)

		local ok, err = pcall(self.Callback, self.Color)
		if not ok then
			warn("[NexusUI] ColorPicker callback error:", err)
		end
	end
end

function ColorPicker:SetColor(color, fireEvent)
	self.Color = color

	local h, s, v = color:ToHSV()
	self._hue = h
	self._sat = s
	self._val = v

	self:_applyHSV(fireEvent)
	return self
end

function ColorPicker:GetColor()
	return self.Color
end

function ColorPicker:SetOpen(open)
	if open == self.IsOpen then
		return self
	end

	self.IsOpen = open

	if open then
		self.Popup.Visible = true
		Animator.Tween(self.Popup, { Size = UDim2.new(1, 0, 0, 168) }, 0.28, "Quart")
		Sound.Pop()
		self.OnOpened:Fire()
	else
		Animator.Tween(self.Popup, { Size = UDim2.new(1, 0, 0, 0) }, 0.22, "Quad")
		task.delay(0.22, function()
			if not self.IsOpen then
				self.Popup.Visible = false
			end
		end)
		Sound.Close()
		self.OnClosed:Fire()
	end

	return self
end

function ColorPicker:SetText(text)
	self.Text = text
	self.TextLabel.Text = text
	return self
end

function ColorPicker:Reset()
	return self:SetColor(self.DefaultColor, true)
end

function ColorPicker:Destroy()
	if self.Destroyed then
		return
	end

	self:SetOpen(false)

	if self.Container then
		self.Container:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return ColorPicker
]]
__MODULES["Components.ProgressBar"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")

local ProgressBar = {}
ProgressBar.__index = ProgressBar
setmetatable(ProgressBar, { __index = BaseComponent })

function ProgressBar.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("ProgressBar")
	setmetatable(self, { __index = function(t, k)
		if ProgressBar[k] then
			return ProgressBar[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "ProgressBar"
	self.Text = options.Text or ""
	self.Min = options.Min or 0
	self.Max = options.Max or 100
	self.Value = options.Value or 0
	self.ShowPercentage = options.ShowPercentage ~= false
	self.Animated = options.Animated ~= false

	self.OnCompleted = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Completed = self.OnCompleted,
	}

	self:_build(parent)
	self:_updateFill(true)

	return self
end

function ProgressBar:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "ProgressBar_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, self.Text ~= "" and 40 or 14)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	if self.Text ~= "" then
		self.Label = Instance.new("TextLabel")
		self.Label.Name = "Label"
		self.Label.Size = UDim2.new(1, 0, 0, 16)
		self.Label.BackgroundTransparency = 1
		self.Label.Font = tokens.Font
		self.Label.Text = self.Text
		self.Label.TextColor3 = tokens.Text
		self.Label.TextSize = tokens.TextSize
		self.Label.TextXAlignment = Enum.TextXAlignment.Left
		self.Label.ZIndex = 7
		self.Label.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.Label.Font = tk.Font
			self.Label.TextColor3 = tk.Text
		end))
	end

	self.Track = Instance.new("Frame")
	self.Track.Name = "Track"
	self.Track.Position = self.Text ~= "" and UDim2.new(0, 0, 0, 20) or UDim2.new(0, 0, 0, 0)
	self.Track.Size = UDim2.new(1, 0, 0, 8)
	self.Track.BackgroundColor3 = tokens.SurfaceLight
	self.Track.BackgroundTransparency = 0.2
	self.Track.BorderSizePixel = 0
	self.Track.ZIndex = 7
	self.Track.Parent = self.Container

	UIUtils.Corner(self.Track, tokens.CornerCircle)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Track.BackgroundColor3 = tk.SurfaceLight
	end))

	self.Fill = Instance.new("Frame")
	self.Fill.Name = "Fill"
	self.Fill.Size = UDim2.new(0, 0, 1, 0)
	self.Fill.BackgroundColor3 = tokens.Accent
	self.Fill.BorderSizePixel = 0
	self.Fill.ZIndex = 8
	self.Fill.Parent = self.Track

	UIUtils.Corner(self.Fill, tokens.CornerCircle)

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	gradient.Parent = self.Fill

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Fill.BackgroundColor3 = tk.Accent
	end))

	if self.ShowPercentage then
		self.PercentageLabel = Instance.new("TextLabel")
		self.PercentageLabel.Name = "Percentage"
		self.PercentageLabel.AnchorPoint = Vector2.new(1, 0)
		self.PercentageLabel.Position = UDim2.new(1, 0, self.Text ~= "" and 0 or 0, self.Text ~= "" and 0 or -2)
		self.PercentageLabel.Size = UDim2.new(0, 50, 0, 12)
		self.PercentageLabel.BackgroundTransparency = 1
		self.PercentageLabel.Font = tokens.FontBold
		self.PercentageLabel.Text = "0%"
		self.PercentageLabel.TextColor3 = tokens.SecondaryText
		self.PercentageLabel.TextSize = 10
		self.PercentageLabel.TextXAlignment = Enum.TextXAlignment.Right
		self.PercentageLabel.ZIndex = 8
		self.PercentageLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.PercentageLabel.Font = tk.FontBold
			self.PercentageLabel.TextColor3 = tk.SecondaryText
		end))
	end
end

function ProgressBar:_updateFill(instant)
	local alpha = math.clamp((self.Value - self.Min) / math.max(0.0001, self.Max - self.Min), 0, 1)
	local targetSize = UDim2.new(alpha, 0, 1, 0)

	if instant or not self.Animated then
		self.Fill.Size = targetSize
	else
		Animator.Tween(self.Fill, { Size = targetSize }, 0.3, "Quart")
	end

	if self.PercentageLabel then
		self.PercentageLabel.Text = math.floor(alpha * 100 + 0.5) .. "%"
	end

	if alpha >= 1 then
		self.OnCompleted:Fire()
	end
end

function ProgressBar:SetValue(value, instant)
	self.Value = math.clamp(value, self.Min, self.Max)
	self:_updateFill(instant == true)
	return self
end

function ProgressBar:GetValue()
	return self.Value
end

function ProgressBar:SetText(text)
	self.Text = text
	if self.Label then
		self.Label.Text = text
	end
	return self
end

function ProgressBar:SetRange(min, max)
	self.Min = min
	self.Max = max
	self:_updateFill()
	return self
end

function ProgressBar:Increment(amount)
	return self:SetValue(self.Value + (amount or 1))
end

function ProgressBar:Reset()
	return self:SetValue(self.Min, true)
end

function ProgressBar:Complete()
	return self:SetValue(self.Max)
end

function ProgressBar:Destroy()
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

return ProgressBar
]]
__MODULES["Components.LoadingIndicator"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")

local LoadingIndicator = {}
LoadingIndicator.__index = LoadingIndicator
setmetatable(LoadingIndicator, { __index = BaseComponent })

local function getRunService()
	return game:GetService("RunService")
end

function LoadingIndicator.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("LoadingIndicator")
	setmetatable(self, { __index = function(t, k)
		if LoadingIndicator[k] then
			return LoadingIndicator[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Loading"
	self.Variant = options.Variant or "Spinner"
	self.Size = options.Size or UDim2.new(0, 24, 0, 24)
	self.Speed = options.Speed or 1
	self.Text = options.Text or ""
	self.Running = true

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
	}

	self:_build(parent)
	self:_startAnimation()

	return self
end

function LoadingIndicator:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Loading_" .. self.Name
	self.Container.Size = self.Text ~= "" and UDim2.new(1, 0, 0, math.max(self.Size.Y.Offset, 24) + 20) or self.Size
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	if self.Variant == "Spinner" then
		self.Spinner = Instance.new("Frame")
		self.Spinner.Name = "Spinner"
		self.Spinner.Size = self.Size
		self.Spinner.BackgroundTransparency = 1
		self.Spinner.AnchorPoint = Vector2.new(0.5, 0)
		self.Spinner.Position = self.Text ~= "" and UDim2.new(0.5, 0, 0, 0) or UDim2.new(0.5, 0, 0.5, 0)
		self.Spinner.ZIndex = 7
		self.Spinner.Parent = self.Container

		local arc = Instance.new("Frame")
		arc.Name = "Arc"
		arc.Size = UDim2.new(1, 0, 1, 0)
		arc.BackgroundTransparency = 1
		arc.ZIndex = 8
		arc.Parent = self.Spinner

		local stroke = Instance.new("UIStroke")
		stroke.Color = tokens.Accent
		stroke.Thickness = 2.5
		stroke.Transparency = 0.2
		stroke.Parent = arc

		local arcCorner = Instance.new("UICorner")
		arcCorner.CornerRadius = UDim.new(1, 0)
		arcCorner.Parent = arc

		local gradient = Instance.new("UIGradient")
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Rotation = 45
		gradient.Parent = stroke

		self.Arc = arc

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			stroke.Color = tk.Accent
		end))

	elseif self.Variant == "Dots" then
		self.Dots = {}

		local holder = Instance.new("Frame")
		holder.Name = "DotsHolder"
		holder.Size = UDim2.new(0, 40, 0, 10)
		holder.BackgroundTransparency = 1
		holder.AnchorPoint = Vector2.new(0.5, 0)
		holder.Position = self.Text ~= "" and UDim2.new(0.5, 0, 0, 0) or UDim2.new(0.5, 0, 0.5, -5)
		holder.ZIndex = 7
		holder.Parent = self.Container

		for i = 1, 3 do
			local dot = Instance.new("Frame")
			dot.Name = "Dot" .. i
			dot.Size = UDim2.new(0, 8, 0, 8)
			dot.Position = UDim2.new(0, (i - 1) * 14, 0, 0)
			dot.BackgroundColor3 = tokens.Accent
			dot.BackgroundTransparency = 0.3
			dot.BorderSizePixel = 0
			dot.ZIndex = 8
			dot.Parent = holder

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = dot

			self.Dots[i] = dot
		end

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			for _, dot in ipairs(self.Dots) do
				dot.BackgroundColor3 = tk.Accent
			end
		end))

	elseif self.Variant == "Bar" then
		self.BarHolder = Instance.new("Frame")
		self.BarHolder.Name = "BarHolder"
		self.BarHolder.Size = UDim2.new(0, 80, 0, 4)
		self.BarHolder.BackgroundTransparency = 1
		self.BarHolder.AnchorPoint = Vector2.new(0.5, 0)
		self.BarHolder.Position = self.Text ~= "" and UDim2.new(0.5, 0, 0, 0) or UDim2.new(0.5, 0, 0.5, -2)
		self.BarHolder.BackgroundColor3 = tokens.SurfaceLight
		self.BarHolder.BackgroundTransparency = 0.4
		self.BarHolder.BorderSizePixel = 0
		self.BarHolder.ZIndex = 7
		self.BarHolder.Parent = self.Container

		UIUtils.Corner(self.BarHolder, tokens.CornerCircle)

		self.BarFill = Instance.new("Frame")
		self.BarFill.Name = "Fill"
		self.BarFill.Size = UDim2.new(0, 20, 1, 0)
		self.BarFill.BackgroundColor3 = tokens.Accent
		self.BarFill.BorderSizePixel = 0
		self.BarFill.ZIndex = 8
		self.BarFill.Parent = self.BarHolder

		UIUtils.Corner(self.BarFill, tokens.CornerCircle)

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.BarHolder.BackgroundColor3 = tk.SurfaceLight
			self.BarFill.BackgroundColor3 = tk.Accent
		end))
	end

	if self.Text ~= "" then
		self.TextLabel = Instance.new("TextLabel")
		self.TextLabel.Name = "Text"
		self.TextLabel.Position = UDim2.new(0, 0, 0, math.max(self.Size.Y.Offset, 24) + 4)
		self.TextLabel.Size = UDim2.new(1, 0, 0, 16)
		self.TextLabel.BackgroundTransparency = 1
		self.TextLabel.Font = tokens.Font
		self.TextLabel.Text = self.Text
		self.TextLabel.TextColor3 = tokens.SecondaryText
		self.TextLabel.TextSize = 12
		self.TextLabel.ZIndex = 7
		self.TextLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.TextLabel.Font = tk.Font
			self.TextLabel.TextColor3 = tk.SecondaryText
		end))
	end
end

function LoadingIndicator:_startAnimation()
	if self.Variant == "Spinner" then
		local connection
		connection = getRunService().RenderStepped:Connect(function(dt)
			if not self.Running or not self.Spinner or not self.Spinner.Parent then
				return
			end
			self.Spinner.Rotation = (self.Spinner.Rotation + dt * 240 * self.Speed) % 360
		end)
		self._maid:GiveTask(connection)

	elseif self.Variant == "Dots" then
		task.spawn(function()
			while true do
				if not self.Running then
					task.wait(0.1)
					continue
				end

				for i, dot in ipairs(self.Dots) do
					if not dot.Parent then
						break
					end
					task.delay((i - 1) * 0.15, function()
						if dot.Parent and self.Running then
							Animator.Tween(dot, { Position = dot.Position - UDim2.new(0, 0, 0, 4), BackgroundTransparency = 0 }, 0.15, "Quad")
						end
					end)
				end

				task.wait(0.45)

				for i, dot in ipairs(self.Dots) do
					if dot.Parent then
						task.delay((i - 1) * 0.15, function()
							if dot.Parent and self.Running then
								Animator.Tween(dot, { Position = dot.Position + UDim2.new(0, 0, 0, 4), BackgroundTransparency = 0.3 }, 0.2, "Quad")
							end
						end)
					end
				end

				task.wait(0.65)
			end
		end)

	elseif self.Variant == "Bar" then
		task.spawn(function()
			while true do
				if not self.Running then
					task.wait(0.1)
					continue
				end

				if self.BarFill and self.BarFill.Parent then
					self.BarFill.Position = UDim2.new(0, -20, 0, 0)
					Animator.Tween(self.BarFill, { Position = UDim2.new(1, 0, 0, 0) }, 1.2 / self.Speed, "Sine")
				end

				task.wait(1.3 / self.Speed)
			end
		end)
	end
end

function LoadingIndicator:Stop()
	self.Running = false
	return self
end

function LoadingIndicator:Start()
	self.Running = true
	return self
end

function LoadingIndicator:SetText(text)
	self.Text = text
	if self.TextLabel then
		self.TextLabel.Text = text
	end
	return self
end

function LoadingIndicator:SetSpeed(speed)
	self.Speed = speed
	return self
end

function LoadingIndicator:Destroy()
	if self.Destroyed then
		return
	end

	self.Running = false

	if self.Container then
		self.Container:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return LoadingIndicator
]]
__MODULES["Components.Card"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

local Card = {}
Card.__index = Card
setmetatable(Card, { __index = BaseComponent })

function Card.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Card")
	setmetatable(self, { __index = function(t, k)
		if Card[k] then
			return Card[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Card"
	self.Title = options.Title or ""
	self.Description = options.Description or ""
	self.Image = options.Image
	self.Clickable = options.Clickable or false
	self.Callback = options.Callback or function() end
	self.Layout = options.Layout or "Vertical"

	self.OnClick = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Click = self.OnClick,
	}

	self:_build(parent)

	return self
end

function Card:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Card_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, 0)
	self.Container.AutomaticSize = Enum.AutomaticSize.Y
	self.Container.BackgroundColor3 = tokens.Surface
	self.Container.BackgroundTransparency = 0.2
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	UIUtils.Corner(self.Container, tokens.Corner)
	UIUtils.Stroke(self.Container, tokens.Border, 1, 0.7)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Container.BackgroundColor3 = tk.Surface
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = self.Container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Container

	if self.Image then
		local imageHolder = Instance.new("Frame")
		imageHolder.Name = "ImageHolder"
		imageHolder.Size = UDim2.new(1, 0, 0, 100)
		imageHolder.BackgroundColor3 = tokens.Background
		imageHolder.BackgroundTransparency = 0.4
		imageHolder.BorderSizePixel = 0
		imageHolder.ClipsDescendants = true
		imageHolder.LayoutOrder = 1
		imageHolder.ZIndex = 7
		imageHolder.Parent = self.Container

		UIUtils.Corner(imageHolder, tokens.CornerSmall)

		local image = Instance.new("ImageLabel")
		image.Name = "Image"
		image.Size = UDim2.new(1, 0, 1, 0)
		image.BackgroundTransparency = 1
		image.Image = self.Image
		image.ScaleType = Enum.ScaleType.Crop
		image.ZIndex = 8
		image.Parent = imageHolder

		self._image = image
	end

	if self.Title ~= "" then
		self.TitleLabel = Instance.new("TextLabel")
		self.TitleLabel.Name = "Title"
		self.TitleLabel.Size = UDim2.new(1, 0, 0, 18)
		self.TitleLabel.BackgroundTransparency = 1
		self.TitleLabel.Font = tokens.FontBold
		self.TitleLabel.Text = self.Title
		self.TitleLabel.TextColor3 = tokens.Text
		self.TitleLabel.TextSize = 14
		self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.TitleLabel.LayoutOrder = 2
		self.TitleLabel.ZIndex = 7
		self.TitleLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.TitleLabel.Font = tk.FontBold
			self.TitleLabel.TextColor3 = tk.Text
		end))
	end

	if self.Description ~= "" then
		self.DescLabel = Instance.new("TextLabel")
		self.DescLabel.Name = "Description"
		self.DescLabel.Size = UDim2.new(1, 0, 0, 0)
		self.DescLabel.AutomaticSize = Enum.AutomaticSize.Y
		self.DescLabel.BackgroundTransparency = 1
		self.DescLabel.Font = tokens.Font
		self.DescLabel.Text = self.Description
		self.DescLabel.TextColor3 = tokens.SecondaryText
		self.DescLabel.TextSize = 12
		self.DescLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.DescLabel.TextWrapped = true
		self.DescLabel.LayoutOrder = 3
		self.DescLabel.ZIndex = 7
		self.DescLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.DescLabel.Font = tk.Font
			self.DescLabel.TextColor3 = tk.SecondaryText
		end))
	end

	if self.Clickable then
		local clickButton = Instance.new("TextButton")
		clickButton.Name = "ClickTarget"
		clickButton.Size = UDim2.new(1, 0, 1, 0)
		clickButton.BackgroundTransparency = 1
		clickButton.Text = ""
		clickButton.ZIndex = 10
		clickButton.Parent = self.Container

		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = self.Container

		clickButton.MouseEnter:Connect(function()
			Animator.Tween(scale, { Scale = 1.015 }, 0.18, "Quad")
			Animator.Tween(self.Container, { BackgroundTransparency = 0.05 }, 0.18, "Quad")
			Sound.Hover()
		end)

		clickButton.MouseLeave:Connect(function()
			Animator.Tween(scale, { Scale = 1 }, 0.22, "Quad")
			Animator.Tween(self.Container, { BackgroundTransparency = 0.2 }, 0.22, "Quad")
		end)

		clickButton.MouseButton1Click:Connect(function()
			Animator.Tween(scale, { Scale = 0.985 }, 0.08, "Quad")
			task.delay(0.08, function()
				Animator.Tween(scale, { Scale = 1 }, 0.25, "Back")
			end)

			Sound.Click()
			self.OnClick:Fire()
			pcall(self.Callback)
		end)
	end
end

function Card:SetTitle(title)
	self.Title = title
	if self.TitleLabel then
		self.TitleLabel.Text = title
	end
	return self
end

function Card:SetDescription(description)
	self.Description = description
	if self.DescLabel then
		self.DescLabel.Text = description
	end
	return self
end

function Card:SetImage(imageId)
	self.Image = imageId

	if imageId then
		if not self._image then
			local imageHolder = Instance.new("Frame")
			imageHolder.Name = "ImageHolder"
			imageHolder.Size = UDim2.new(1, 0, 0, 100)
			imageHolder.BackgroundColor3 = ThemeManager.GetTokens().Background
			imageHolder.BackgroundTransparency = 0.4
			imageHolder.BorderSizePixel = 0
			imageHolder.ClipsDescendants = true
			imageHolder.LayoutOrder = 1
			imageHolder.ZIndex = 7
			imageHolder.Parent = self.Container

			UIUtils.Corner(imageHolder, ThemeManager.GetTokens().CornerSmall)

			self._image = Instance.new("ImageLabel")
			self._image.Name = "Image"
			self._image.Size = UDim2.new(1, 0, 1, 0)
			self._image.BackgroundTransparency = 1
			self._image.ScaleType = Enum.ScaleType.Crop
			self._image.ZIndex = 8
			self._image.Parent = imageHolder
		end
		self._image.Image = imageId
	elseif self._image then
		self._image.Parent:Destroy()
		self._image = nil
	end

	return self
end

function Card:Destroy()
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

return Card
]]
__MODULES["Components.Image"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Icons = __require("Core.Icons")

local Image = {}
Image.__index = Image
setmetatable(Image, { __index = BaseComponent })

function Image.new(options, parent)
	options = options or {}

	local self = BaseComponent.new("Image")
	setmetatable(self, { __index = function(t, k)
		if Image[k] then
			return Image[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Image"
	self.ImageId = options.Image or options.ImageId or Icons.Assets.Background
	self.Caption = options.Caption or ""
	self.Clickable = options.Clickable or false
	self.Callback = options.Callback or function() end
	self.ScaleType = options.ScaleType or Enum.ScaleType.Crop
	self.CornerRadius = options.CornerRadius

	self.OnClick = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Click = self.OnClick,
	}

	self:_build(parent)

	return self
end

function Image:_build(parent)
	local tokens = ThemeManager.GetTokens()

	self.Container = Instance.new("Frame")
	self.Container.Name = "Image_" .. self.Name
	self.Container.Size = UDim2.new(1, 0, 0, self.Caption ~= "" and 140 or 120)
	self.Container.BackgroundTransparency = 1
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 6
	self.Container.Parent = parent

	self.Frame = Instance.new("Frame")
	self.Frame.Name = "Holder"
	self.Frame.Size = UDim2.new(1, 0, 1, self.Caption ~= "" and -22 or 0)
	self.Frame.BackgroundColor3 = tokens.Background
	self.Frame.BackgroundTransparency = 0.3
	self.Frame.BorderSizePixel = 0
	self.Frame.ClipsDescendants = true
	self.Frame.ZIndex = 7
	self.Frame.Parent = self.Container

	UIUtils.Corner(self.Frame, self.CornerRadius or tokens.Corner)
	UIUtils.Stroke(self.Frame, tokens.Border, 1, 0.7)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Frame.BackgroundColor3 = tk.Background
	end))

	self.ImageLabel = Instance.new("ImageLabel")
	self.ImageLabel.Name = "Image"
	self.ImageLabel.Size = UDim2.new(1, 0, 1, 0)
	self.ImageLabel.BackgroundTransparency = 1
	self.ImageLabel.Image = self.ImageId
	self.ImageLabel.ScaleType = self.ScaleType
	self.ImageLabel.ZIndex = 8
	self.ImageLabel.Parent = self.Frame

	if self.Caption ~= "" then
		self.CaptionLabel = Instance.new("TextLabel")
		self.CaptionLabel.Name = "Caption"
		self.CaptionLabel.Position = UDim2.new(0, 0, 1, -20)
		self.CaptionLabel.Size = UDim2.new(1, 0, 0, 18)
		self.CaptionLabel.BackgroundTransparency = 1
		self.CaptionLabel.Font = tokens.Font
		self.CaptionLabel.Text = self.Caption
		self.CaptionLabel.TextColor3 = tokens.SecondaryText
		self.CaptionLabel.TextSize = 11
		self.CaptionLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.CaptionLabel.TextTruncate = Enum.TextTruncate.AtEnd
		self.CaptionLabel.ZIndex = 7
		self.CaptionLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.CaptionLabel.Font = tk.Font
			self.CaptionLabel.TextColor3 = tk.SecondaryText
		end))
	end

	if self.Clickable then
		local clickButton = Instance.new("TextButton")
		clickButton.Name = "ClickTarget"
		clickButton.Size = UDim2.new(1, 0, 1, 0)
		clickButton.BackgroundTransparency = 1
		clickButton.Text = ""
		clickButton.ZIndex = 10
		clickButton.Parent = self.Frame

		clickButton.MouseButton1Click:Connect(function()
			self.OnClick:Fire()
			pcall(self.Callback)
		end)

		clickButton.MouseEnter:Connect(function()
			Animator.Tween(self.ImageLabel, { ImageTransparency = 0.15 }, 0.18, "Quad")
		end)

		clickButton.MouseLeave:Connect(function()
			Animator.Tween(self.ImageLabel, { ImageTransparency = 0 }, 0.22, "Quad")
		end)
	end
end

function Image:SetImage(imageId)
	self.ImageId = imageId
	self.ImageLabel.Image = imageId
	return self
end

function Image:SetCaption(caption)
	self.Caption = caption
	if self.CaptionLabel then
		self.CaptionLabel.Text = caption
	end
	return self
end

function Image:SetScaleType(scaleType)
	self.ScaleType = scaleType
	self.ImageLabel.ScaleType = scaleType
	return self
end

function Image:Destroy()
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

return Image
]]
__MODULES["Components.Toast"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

local Toast = {}
Toast.__index = Toast
setmetatable(Toast, { __index = BaseComponent })

local function getRoot()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	if not ok or parent == nil then
		parent = PlayerGui
	end

	local existing = parent:FindFirstChild("NexusUI_Toasts")
	if existing then
		return existing
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NexusUI_Toasts"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 250
	screenGui.Parent = parent

	return screenGui
end

local ToastContainer = nil

local function getContainer(position)
	local root = getRoot()

	local containerName = "Container_" .. position
	local existing = root:FindFirstChild(containerName)
	if existing then
		return existing
	end

	local container = Instance.new("Frame")
	container.Name = containerName
	container.BackgroundTransparency = 1
	container.ZIndex = 100

	if position == "BottomCenter" then
		container.AnchorPoint = Vector2.new(0.5, 1)
		container.Position = UDim2.new(0.5, 0, 1, -40)
	elseif position == "TopCenter" then
		container.AnchorPoint = Vector2.new(0.5, 0)
		container.Position = UDim2.new(0.5, 0, 0, 40)
	elseif position == "BottomLeft" then
		container.AnchorPoint = Vector2.new(0, 1)
		container.Position = UDim2.new(0, 20, 1, -40)
	else
		container.AnchorPoint = Vector2.new(0.5, 1)
		container.Position = UDim2.new(0.5, 0, 1, -80)
	end

	container.Size = UDim2.new(0, 360, 0, 300)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = position == "TopCenter" and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	container.Parent = root
	return container
end

function Toast.new(options)
	options = options or {}

	local self = BaseComponent.new("Toast")
	setmetatable(self, { __index = function(t, k)
		if Toast[k] then
			return Toast[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Toast"
	self.Text = options.Text or "Done!"
	self.Position = options.Position or "BottomCenter"
	self.Duration = options.Duration or 2
	self.Variant = options.Variant or "Dark"

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
	}

	self:Show()

	return self
end

function Toast:_variantColors(variant)
	local tokens = ThemeManager.GetTokens()
	local variants = {
		Dark = { Background = tokens.Elevated, Text = tokens.Text },
		Accent = { Background = tokens.Accent, Text = Color3.fromRGB(255, 255, 255) },
		Success = { Background = tokens.Success, Text = Color3.fromRGB(255, 255, 255) },
		Error = { Background = tokens.Error, Text = Color3.fromRGB(255, 255, 255) },
	}
	return variants[variant] or variants.Dark
end

function Toast:Show()
	local tokens = ThemeManager.GetTokens()
	local colors = self:_variantColors(self.Variant)

	local container = getContainer(self.Position)

	self.Frame = Instance.new("Frame")
	self.Frame.Name = "Toast"
	self.Frame.Size = UDim2.new(0, 0, 0, 0)
	self.Frame.AutomaticSize = Enum.AutomaticSize.XY
	self.Frame.BackgroundColor3 = colors.Background
	self.Frame.BackgroundTransparency = self.Variant == "Dark" and 0.06 or 0
	self.Frame.BorderSizePixel = 0
	self.Frame.ZIndex = 101
	self.Frame.Parent = container

	UIUtils.Corner(self.Frame, tokens.Corner)

	if self.Variant == "Dark" then
		UIUtils.Stroke(self.Frame, tokens.BorderLight, 1, 0.5)
	end

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.PaddingTop = UDim.new(0, 9)
	padding.PaddingBottom = UDim.new(0, 9)
	padding.Parent = self.Frame

	self.Label = Instance.new("TextLabel")
	self.Label.Name = "Text"
	self.Label.Size = UDim2.new(0, 0, 0, 0)
	self.Label.AutomaticSize = Enum.AutomaticSize.XY
	self.Label.BackgroundTransparency = 1
	self.Label.Font = tokens.FontBold
	self.Label.Text = self.Text
	self.Label.TextColor3 = colors.Text
	self.Label.TextSize = 13
	self.Label.ZIndex = 102
	self.Label.Parent = self.Frame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		local vc = self:_variantColors(self.Variant)
		self.Frame.BackgroundColor3 = vc.Background
		self.Label.Font = tk.FontBold
		self.Label.TextColor3 = vc.Text
	end))

	self.Frame.BackgroundTransparency = 1
	if self.Label then
		self.Label.TextTransparency = 1
	end

	Animator.Tween(self.Frame, { BackgroundTransparency = self.Variant == "Dark" and 0.06 or 0 }, 0.25, "Quart")
	Animator.Tween(self.Label, { TextTransparency = 0 }, 0.25, "Quart")

	Sound.Pop()

	task.delay(self.Duration, function()
		self:Hide()
	end)

	return self
end

function Toast:Hide()
	if self.Hidden then
		return self
	end
	self.Hidden = true

	if self.Frame and self.Frame.Parent then
		Animator.Tween(self.Frame, { BackgroundTransparency = 1 }, 0.2, "Quad")
		if self.Label then
			Animator.Tween(self.Label, { TextTransparency = 1 }, 0.2, "Quad")
		end

		task.delay(0.22, function()
			if self.Frame then
				self.Frame:Destroy()
			end
			self._maid:Destroy()
		end)
	end

	return self
end

function Toast:SetText(text)
	self.Text = text
	if self.Label then
		self.Label.Text = text
	end
	return self
end

function Toast:Destroy()
	self:Hide()
	self.Destroyed = true
end

return Toast
]]
__MODULES["Components.Tooltip"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")

local Tooltip = {}
Tooltip.__index = Tooltip
setmetatable(Tooltip, { __index = BaseComponent })

Tooltip.Active = nil

local function getRoot()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	if not ok or parent == nil then
		parent = PlayerGui
	end

	local existing = parent:FindFirstChild("NexusUI_Tooltips")
	if existing then
		return existing
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NexusUI_Tooltips"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 500
	screenGui.Parent = parent

	return screenGui
end

function Tooltip.new(options)
	options = options or {}

	local self = BaseComponent.new("Tooltip")
	setmetatable(self, { __index = function(t, k)
		if Tooltip[k] then
			return Tooltip[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Tooltip"
	self.Text = options.Text or "Tooltip"
	self.Target = options.Target
	self.Position = options.Position or "Top"
	self.Delay = options.Delay or 0.35

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
	}

	if self.Target then
		self:BindTo(self.Target)
	end

	return self
end

function Tooltip:_build()
	if self.Frame and self.Frame.Parent then
		return
	end

	local tokens = ThemeManager.GetTokens()

	self.Frame = Instance.new("Frame")
	self.Frame.Name = "Tooltip"
	self.Frame.AnchorPoint = Vector2.new(0.5, 1)
	self.Frame.Size = UDim2.new(0, 0, 0, 0)
	self.Frame.AutomaticSize = Enum.AutomaticSize.XY
	self.Frame.BackgroundColor3 = tokens.Elevated
	self.Frame.BackgroundTransparency = 0.04
	self.Frame.BorderSizePixel = 0
	self.Frame.ZIndex = 500
	self.Frame.Visible = false
	self.Frame.Parent = getRoot()

	UIUtils.Corner(self.Frame, tokens.CornerSmall)
	UIUtils.Stroke(self.Frame, tokens.BorderLight, 1, 0.5)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Frame.BackgroundColor3 = tk.Elevated
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.Parent = self.Frame

	self.Label = Instance.new("TextLabel")
	self.Label.Name = "Text"
	self.Label.Size = UDim2.new(0, 0, 0, 0)
	self.Label.AutomaticSize = Enum.AutomaticSize.XY
	self.Label.BackgroundTransparency = 1
	self.Label.Font = tokens.Font
	self.Label.Text = self.Text
	self.Label.TextColor3 = tokens.Text
	self.Label.TextSize = 12
	self.Label.TextWrapped = false
	self.Label.ZIndex = 501
	self.Label.Parent = self.Frame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Label.Font = tk.Font
		self.Label.TextColor3 = tk.Text
	end))
end

function Tooltip:SetText(text)
	self.Text = text
	if self.Label then
		self.Label.Text = text
	end
	return self
end

function Tooltip:Show()
	if Tooltip.Active and Tooltip.Active ~= self then
		Tooltip.Active:Hide()
	end

	self:_build()
	Tooltip.Active = self

	local tokens = ThemeManager.GetTokens()

	local targetFrame = self.Target
	if not targetFrame then
		return self
	end

	local mousePos = game:GetService("UserInputService"):GetMouseLocation()

	local posX = mousePos.X
	local posY = mousePos.Y

	if self.Position == "Top" then
		self.Frame.AnchorPoint = Vector2.new(0.5, 1)
		posY = posY - 12
	elseif self.Position == "Bottom" then
		self.Frame.AnchorPoint = Vector2.new(0.5, 0)
		posY = posY + 12
	elseif self.Position == "Left" then
		self.Frame.AnchorPoint = Vector2.new(1, 0.5)
		posX = posX - 12
	elseif self.Position == "Right" then
		self.Frame.AnchorPoint = Vector2.new(0, 0.5)
		posX = posX + 12
	end

	self.Frame.Position = UDim2.new(0, posX, 0, posY)
	self.Frame.Visible = true
	self.Frame.BackgroundTransparency = 1

	if self.Label then
		self.Label.TextTransparency = 1
		Animator.Tween(self.Label, { TextTransparency = 0 }, 0.18, "Quad")
	end

	Animator.Tween(self.Frame, { BackgroundTransparency = 0.04 }, 0.18, "Quad")

	return self
end

function Tooltip:Hide()
	if Tooltip.Active == self then
		Tooltip.Active = nil
	end

	if self.Frame and self.Frame.Parent then
		self.Frame.Visible = false
	end

	return self
end

function Tooltip:BindTo(target)
	self.Target = target

	if not target then
		return self
	end

	local showThread = nil

	target.MouseEnter:Connect(function()
		showThread = task.delay(self.Delay, function()
			self:Show()
		end)
	end)

	target.MouseLeave:Connect(function()
		if showThread then
			task.cancel(showThread)
			showThread = nil
		end
		self:Hide()
	end)

	target.MouseButton1Down:Connect(function()
		if showThread then
			task.cancel(showThread)
			showThread = nil
		end
		self:Hide()
	end)

	return self
end

function Tooltip:Destroy()
	if self.Destroyed then
		return
	end

	self:Hide()

	if self.Frame then
		self.Frame:Destroy()
		self.Frame = nil
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

Tooltip.HideAll = function()
	if Tooltip.Active then
		Tooltip.Active:Hide()
	end
end

return Tooltip
]]
__MODULES["Components.ContextMenu"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

local ContextMenu = {}
ContextMenu.__index = ContextMenu
setmetatable(ContextMenu, { __index = BaseComponent })

ContextMenu.Active = nil

local function getRoot()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	if not ok or parent == nil then
		parent = PlayerGui
	end

	local existing = parent:FindFirstChild("NexusUI_ContextMenu")
	if existing then
		return existing
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NexusUI_ContextMenu"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 400
	screenGui.Parent = parent

	return screenGui
end

function ContextMenu.new(options)
	options = options or {}

	local self = BaseComponent.new("ContextMenu")
	setmetatable(self, { __index = function(t, k)
		if ContextMenu[k] then
			return ContextMenu[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "ContextMenu"
	self.Items = options.Items or {}
	self.ItemHeight = options.ItemHeight or 30

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
	}

	return self
end

function ContextMenu:_build()
	if self.Frame and self.Frame.Parent then
		return
	end

	local tokens = ThemeManager.GetTokens()

	local totalHeight = 0
	for _, item in ipairs(self.Items) do
		if item.Divider then
			totalHeight = totalHeight + 9
		else
			totalHeight = totalHeight + self.ItemHeight + 2
		end
	end

	self.Frame = Instance.new("Frame")
	self.Frame.Name = "ContextMenu"
	self.Frame.Size = UDim2.new(0, 190, 0, totalHeight + 8)
	self.Frame.BackgroundColor3 = tokens.Elevated
	self.Frame.BackgroundTransparency = 0.03
	self.Frame.BorderSizePixel = 0
	self.Frame.ZIndex = 400
	self.Frame.Visible = false
	self.Frame.Parent = getRoot()

	UIUtils.Corner(self.Frame, tokens.Corner)
	UIUtils.Stroke(self.Frame, tokens.BorderLight, 1, 0.45)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Frame.BackgroundColor3 = tk.Elevated
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 4)
	padding.Parent = self.Frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 2)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Frame

	for index, item in ipairs(self.Items) do
		if item.Divider then
			local divider = Instance.new("Frame")
			divider.Name = "Divider"
			divider.Size = UDim2.new(1, 0, 0, 1)
			divider.BackgroundColor3 = tokens.Border
			divider.BackgroundTransparency = 0.5
			divider.BorderSizePixel = 0
			divider.LayoutOrder = index
			divider.ZIndex = 401
			divider.Parent = self.Frame

		elseif item.Text then
			local itemButton = Instance.new("TextButton")
			itemButton.Name = "Item_" .. item.Text
			itemButton.Size = UDim2.new(1, 0, 0, self.ItemHeight)
			itemButton.BackgroundColor3 = tokens.SurfaceLight
			itemButton.BackgroundTransparency = 1
			itemButton.BorderSizePixel = 0
			itemButton.AutoButtonColor = false
			itemButton.Font = tokens.Font
			itemButton.Text = item.Text
			itemButton.TextColor3 = item.Disabled and tokens.MutedText or tokens.Text
			itemButton.TextSize = 13
			itemButton.TextXAlignment = Enum.TextXAlignment.Left
			itemButton.LayoutOrder = index
			itemButton.ZIndex = 401
			itemButton.Parent = self.Frame

			UIUtils.Corner(itemButton, tokens.CornerSmall)

			local textPadding = Instance.new("UIPadding")
			textPadding.PaddingLeft = UDim.new(0, 10)
			textPadding.Parent = itemButton

			if not item.Disabled then
				itemButton.MouseEnter:Connect(function()
					Animator.Tween(itemButton, { BackgroundTransparency = 0.75 }, 0.1, "Quad")
				end)

				itemButton.MouseLeave:Connect(function()
					Animator.Tween(itemButton, { BackgroundTransparency = 1 }, 0.1, "Quad")
				end)

				itemButton.MouseButton1Click:Connect(function()
					Sound.Click()
					self:Close()
					if item.Callback then
						task.spawn(function()
							pcall(item.Callback, item)
						end)
					end
				end)
			end
		end
	end
end

function ContextMenu:Open(position)
	if ContextMenu.Active and ContextMenu.Active ~= self then
		ContextMenu.Active:Close()
	end

	self:_build()
	ContextMenu.Active = self

	local tokens = ThemeManager.GetTokens()

	local uis = game:GetService("UserInputService")
	local mousePos = position or uis:GetMouseLocation()

	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)

	local frameWidth = self.Frame.Size.X.Offset
	local frameHeight = self.Frame.Size.Y.Offset

	local posX = math.clamp(mousePos.X, 8, viewport.X - frameWidth - 8)
	local posY = math.clamp(mousePos.Y, 8, viewport.Y - frameHeight - 8)

	self.Frame.Position = UDim2.new(0, posX, 0, posY)
	self.Frame.Visible = true

	local scale = UIUtils.Scale(self.Frame, 0.85)
	self.Frame.BackgroundTransparency = 0.5

	Animator.Tween(scale, { Scale = 1 }, 0.18, "Back")
	Animator.Tween(self.Frame, { BackgroundTransparency = 0.03 }, 0.15, "Quad")

	self:_bindDismiss()

	Sound.Pop()

	return self
end

function ContextMenu:_bindDismiss()
	local uis = game:GetService("UserInputService")

	task.defer(function()
		local connection = uis.InputBegan:Connect(function(input, processed)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.Touch then

				local frame = self.Frame
				if not frame or not frame.Parent then
					connection:Disconnect()
					return
				end

				local absPos = frame.AbsolutePosition
				local absSize = frame.AbsoluteSize
				local pos = input.Position

				local inside = pos.X >= absPos.X and pos.X <= absPos.X + absSize.X
					and pos.Y >= absPos.Y and pos.Y <= absPos.Y + absSize.Y

				if not inside then
					self:Close()
					connection:Disconnect()
				end
			end
		end)

		self._maid:GiveTask(connection)
	end)
end

function ContextMenu:Close()
	if ContextMenu.Active == self then
		ContextMenu.Active = nil
	end

	if self.Frame and self.Frame.Parent then
		local scale = self.Frame:FindFirstChildOfClass("UIScale")
		if scale then
			Animator.Tween(scale, { Scale = 0.85 }, 0.12, "Quad")
		end
		Animator.Tween(self.Frame, { BackgroundTransparency = 0.5 }, 0.12, "Quad")

		task.delay(0.13, function()
			if self.Frame then
				self.Frame.Visible = false
			end
		end)
	end

	return self
end

function ContextMenu:SetItems(items)
	self.Items = items or {}

	if self.Frame then
		self.Frame:Destroy()
		self.Frame = nil
	end

	return self
end

function ContextMenu:Destroy()
	if self.Destroyed then
		return
	end

	self:Close()

	if self.Frame then
		self.Frame:Destroy()
		self.Frame = nil
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

ContextMenu.CloseAll = function()
	if ContextMenu.Active then
		ContextMenu.Active:Close()
	end
end

return ContextMenu
]]
__MODULES["Components.Modal"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")
local Button = __require("Components.Button")

local Modal = {}
Modal.__index = Modal
setmetatable(Modal, { __index = BaseComponent })

function Modal.new(options)
	options = options or {}

	local self = BaseComponent.new("Modal")
	setmetatable(self, { __index = function(t, k)
		if Modal[k] then
			return Modal[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "Modal"
	self.Title = options.Title or "Confirm"
	self.Message = options.Message or ""
	self.Size = options.Size or UDim2.fromOffset(400, 0)
	self.DismissOnBackdrop = options.DismissOnBackdrop ~= false

	self.Buttons = {}

	self.OnOpened = Signal.new()
	self.OnClosed = Signal.new()
	self.OnDismissed = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Opened = self.OnOpened,
		Closed = self.OnClosed,
		Dismissed = self.OnDismissed,
	}

	self:_build()

	return self
end

function Modal:_getRootParent()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	return ok and parent or PlayerGui
end

function Modal:_build()
	local tokens = ThemeManager.GetTokens()

	self.Root = Instance.new("ScreenGui")
	self.Root.Name = "NexusUI_Modal_" .. self.Name
	self.Root.ResetOnSpawn = false
	self.Root.IgnoreGuiInset = true
	self.Root.DisplayOrder = 300
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

	if self.DismissOnBackdrop then
		self.Backdrop.MouseButton1Click:Connect(function()
			self:Dismiss()
		end)
	end

	self.Container = Instance.new("Frame")
	self.Container.Name = "Modal"
	self.Container.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Container.Position = UDim2.new(0.5, 0, 0.5, 0)
	self.Container.Size = self.Size
	self.Container.AutomaticSize = Enum.AutomaticSize.Y
	self.Container.BackgroundColor3 = tokens.Background
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 2
	self.Container.Parent = self.Backdrop

	UIUtils.Corner(self.Container, tokens.CornerLarge)
	UIUtils.Stroke(self.Container, tokens.BorderLight, 1, 0.5)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Container.BackgroundColor3 = tk.Background
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.Parent = self.Container

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Container

	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Name = "Title"
	self.TitleLabel.Size = UDim2.new(1, 0, 0, 22)
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.Font = tokens.FontBold
	self.TitleLabel.Text = self.Title
	self.TitleLabel.TextColor3 = tokens.Text
	self.TitleLabel.TextSize = 17
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.LayoutOrder = 1
	self.TitleLabel.ZIndex = 3
	self.TitleLabel.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TitleLabel.Font = tk.FontBold
		self.TitleLabel.TextColor3 = tk.Text
	end))

	if self.Message ~= "" then
		self.MessageLabel = Instance.new("TextLabel")
		self.MessageLabel.Name = "Message"
		self.MessageLabel.Size = UDim2.new(1, 0, 0, 0)
		self.MessageLabel.AutomaticSize = Enum.AutomaticSize.Y
		self.MessageLabel.BackgroundTransparency = 1
		self.MessageLabel.Font = tokens.Font
		self.MessageLabel.Text = self.Message
		self.MessageLabel.TextColor3 = tokens.SecondaryText
		self.MessageLabel.TextSize = 13
		self.MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.MessageLabel.TextWrapped = true
		self.MessageLabel.LayoutOrder = 2
		self.MessageLabel.ZIndex = 3
		self.MessageLabel.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.MessageLabel.Font = tk.Font
			self.MessageLabel.TextColor3 = tk.SecondaryText
		end))
	end

	self.ButtonRow = Instance.new("Frame")
	self.ButtonRow.Name = "ButtonRow"
	self.ButtonRow.Size = UDim2.new(1, 0, 0, 36)
	self.ButtonRow.BackgroundTransparency = 1
	self.ButtonRow.LayoutOrder = 3
	self.ButtonRow.ZIndex = 3
	self.ButtonRow.Parent = self.Container

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.Padding = UDim.new(0, 8)
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonLayout.Parent = self.ButtonRow
end

function Modal:AddButton(options)
	options = options or {}

	local modalRef = self
	local button = Button.new({
		Name = options.Name or "Button",
		Text = options.Text or "Action",
		Variant = options.Variant or "Secondary",
		FullWidth = false,
		Callback = function()
			pcall(options.Callback, modalRef)
			if options.CloseOnClick ~= false then
				modalRef:Close()
			end
		end,
	}, self.ButtonRow)

	button.Container.Size = UDim2.new(0, math.max(90, #button.Text * 8 + 30), 0, 34)

	table.insert(self.Buttons, button)
	return button
end

function Modal:AddCloseButton(text, variant)
	return self:AddButton({
		Text = text or "Close",
		Variant = variant or "Secondary",
		Callback = function() end,
	})
end

function Modal:AddConfirmButton(text, callback)
	return self:AddButton({
		Text = text or "Confirm",
		Variant = "Primary",
		Callback = callback or function() end,
	})
end

function Modal:AddDangerButton(text, callback)
	return self:AddButton({
		Text = text or "Delete",
		Variant = "Danger",
		Callback = callback or function() end,
	})
end

function Modal:Open()
	if self.IsOpen then
		return self
	end

	self.IsOpen = true
	self.Root.Enabled = true

	local scale = UIUtils.Scale(self.Container, 0.9)
	self.Container.BackgroundTransparency = 0.5
	self.Backdrop.BackgroundTransparency = 1

	Animator.Tween(self.Backdrop, { BackgroundTransparency = 0.45 }, 0.25, "Quad")
	Animator.Tween(scale, { Scale = 1 }, 0.35, "Back")
	Animator.Tween(self.Container, { BackgroundTransparency = 0 }, 0.25, "Quart")

	Sound.Open()
	self.OnOpened:Fire()

	return self
end

function Modal:Close()
	if not self.IsOpen then
		return self
	end

	self.IsOpen = false

	Animator.Tween(self.Backdrop, { BackgroundTransparency = 1 }, 0.18, "Quad")
	Animator.Tween(self.Container, { BackgroundTransparency = 0.4 }, 0.18, "Quad")

	local scale = self.Container:FindFirstChildOfClass("UIScale")
	if scale then
		Animator.Tween(scale, { Scale = 0.92 }, 0.18, "Quart")
	end

	task.delay(0.2, function()
		if not self.IsOpen then
			self.Root.Enabled = false
		end
	end)

	Sound.Close()
	self.OnClosed:Fire()

	return self
end

function Modal:Dismiss()
	self:Close()
	self.OnDismissed:Fire()
	return self
end

function Modal:SetTitle(title)
	self.Title = title
	self.TitleLabel.Text = title
	return self
end

function Modal:SetMessage(message)
	self.Message = message
	if self.MessageLabel then
		self.MessageLabel.Text = message
	else
		local tokens = ThemeManager.GetTokens()

		self.MessageLabel = Instance.new("TextLabel")
		self.MessageLabel.Name = "Message"
		self.MessageLabel.Size = UDim2.new(1, 0, 0, 0)
		self.MessageLabel.AutomaticSize = Enum.AutomaticSize.Y
		self.MessageLabel.BackgroundTransparency = 1
		self.MessageLabel.Font = tokens.Font
		self.MessageLabel.Text = message
		self.MessageLabel.TextColor3 = tokens.SecondaryText
		self.MessageLabel.TextSize = 13
		self.MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.MessageLabel.TextWrapped = true
		self.MessageLabel.LayoutOrder = 2
		self.MessageLabel.ZIndex = 3
		self.MessageLabel.Parent = self.Container
	end
	return self
end

function Modal:Destroy()
	if self.Destroyed then
		return
	end

	self:Close()

	task.delay(0.25, function()
		for _, button in ipairs(self.Buttons) do
			pcall(function() button:Destroy() end)
		end
		self.Buttons = {}

		if self.Root then
			self.Root:Destroy()
		end

		if self._maid then
			self._maid:Destroy()
		end
	end)

	self.Destroyed = true
end

return Modal
]]
__MODULES["Components.Tab"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Icons = __require("Core.Icons")
local Sound = __require("Utilities.Sound")

local Tab = {}
Tab.__index = Tab
setmetatable(Tab, { __index = BaseComponent })

function Tab.new(options, window)
	options = options or {}

	local self = BaseComponent.new("Tab")
	setmetatable(self, { __index = function(t, k)
		if Tab[k] then
			return Tab[k]
		end
		return BaseComponent[k]
	end })

	self.Window = window
	self.Name = options.Name or "Tab"
	self.Icon = options.Icon
	self.Description = options.Description or ""
	self.Compact = false

	self.Sections = {}

	self.OnSelected = Signal.new()
	self.OnDeselected = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Selected = self.OnSelected,
		Deselected = self.OnDeselected,
	}

	self:_build()

	return self
end

function Tab:_build()
	local tokens = ThemeManager.GetTokens()

	self.Button = Instance.new("TextButton")
	self.Button.Name = "Tab_" .. self.Name
	self.Button.Size = UDim2.new(1, 0, 0, 36)
	self.Button.BackgroundColor3 = tokens.SurfaceLight
	self.Button.BackgroundTransparency = 1
	self.Button.BorderSizePixel = 0
	self.Button.AutoButtonColor = false
	self.Button.Text = ""
	self.Button.ZIndex = 6
	self.Button.Parent = self.Window.TabScroll

	UIUtils.Corner(self.Button, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Button.BackgroundColor3 = tk.SurfaceLight
	end))

	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0, 3, 0, 0)
	accentBar.Position = UDim2.new(0, 0, 0.5, 0)
	accentBar.AnchorPoint = Vector2.new(0, 0.5)
	accentBar.BackgroundColor3 = tokens.Accent
	accentBar.BackgroundTransparency = 0.15
	accentBar.BorderSizePixel = 0
	accentBar.ZIndex = 7
	accentBar.Parent = self.Button

	self._accentBar = accentBar

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		accentBar.BackgroundColor3 = tk.Accent
	end))

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, 0)
	content.Position = UDim2.new(0, 10, 0, 0)
	content.BackgroundTransparency = 1
	content.ZIndex = 7
	content.Parent = self.Button

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Horizontal
	contentLayout.Padding = UDim.new(0, 8)
	contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = content

	if self.Icon then
		self.IconImage = Instance.new("ImageLabel")
		self.IconImage.Name = "Icon"
		self.IconImage.BackgroundTransparency = 1
		self.IconImage.Image = self.Icon
		self.IconImage.Size = UDim2.new(0, 18, 0, 18)
		self.IconImage.ImageColor3 = tokens.SecondaryText
		self.IconImage.ScaleType = Enum.ScaleType.Fit
		self.IconImage.LayoutOrder = 1
		self.IconImage.ZIndex = 8
		self.IconImage.Parent = content

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.IconImage.ImageColor3 = self.Selected and tk.Accent or tk.SecondaryText
		end))
	end

	self.Label = Instance.new("TextLabel")
	self.Label.Name = "Label"
	self.Label.BackgroundTransparency = 1
	self.Label.Size = UDim2.new(1, 0, 1, 0)
	self.Label.Font = tokens.Font
	self.Label.Text = self.Name
	self.Label.TextColor3 = tokens.SecondaryText
	self.Label.TextSize = tokens.TextSize
	self.Label.TextXAlignment = Enum.TextXAlignment.Left
	self.Label.TextTruncate = Enum.TextTruncate.AtEnd
	self.Label.LayoutOrder = 2
	self.Label.ZIndex = 8
	self.Label.Parent = content

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Label.Font = tk.Font
		self.Label.TextSize = tk.TextSize
		self.Label.TextColor3 = self.Selected and tk.Text or tk.SecondaryText
	end))

	local badge = options.Badge
	if badge then
		local badgeFrame = Instance.new("Frame")
		badgeFrame.Name = "Badge"
		badgeFrame.Size = UDim2.new(0, 18, 0, 18)
		badgeFrame.BackgroundColor3 = tokens.Accent
		badgeFrame.BorderSizePixel = 0
		badgeFrame.LayoutOrder = 3
		badgeFrame.ZIndex = 8
		badgeFrame.Parent = content

		UIUtils.Corner(badgeFrame, tokens.CornerCircle)

		local badgeText = Instance.new("TextLabel")
		badgeText.Name = "Text"
		badgeText.Size = UDim2.new(1, 0, 1, 0)
		badgeText.BackgroundTransparency = 1
		badgeText.Font = tokens.FontBold
		badgeText.Text = tostring(badge)
		badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
		badgeText.TextSize = 10
		badgeText.ZIndex = 9
		badgeText.Parent = badgeFrame
	end

	local pageContainer = Instance.new("Frame")
	pageContainer.Name = "Page_" .. self.Name
	pageContainer.Size = UDim2.new(1, 0, 1, 0)
	pageContainer.BackgroundTransparency = 1
	pageContainer.BorderSizePixel = 0
	pageContainer.ZIndex = 4
	pageContainer.Visible = false
	pageContainer.Parent = self.Window.Content

	self.Page = pageContainer

	self.Scroll = Instance.new("ScrollingFrame")
	self.Scroll.Name = "Scroll"
	self.Scroll.Size = UDim2.new(1, -8, 1, -8)
	self.Scroll.Position = UDim2.new(0, 4, 0, 4)
	self.Scroll.BackgroundTransparency = 1
	self.Scroll.BorderSizePixel = 0
	self.Scroll.ScrollBarThickness = 3
	self.Scroll.ScrollBarImageColor3 = tokens.ScrollBars or tokens.Accent
	self.Scroll.ScrollBarImageTransparency = 0.35
	self.Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.Scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	self.Scroll.ZIndex = 4
	self.Scroll.Parent = pageContainer

	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingLeft = UDim.new(0, 6)
	scrollPadding.PaddingRight = UDim.new(0, 10)
	scrollPadding.PaddingTop = UDim.new(0, 6)
	scrollPadding.PaddingBottom = UDim.new(0, 6)
	scrollPadding.Parent = self.Scroll

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.FillDirection = Enum.FillDirection.Vertical
	scrollLayout.Padding = UDim.new(0, 10)
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Parent = self.Scroll

	self.Button.MouseEnter:Connect(function()
		if not self.Selected then
			Animator.Tween(self.Button, { BackgroundTransparency = 0.7 }, 0.15, "Quad")
			Animator.Tween(self.Label, { TextColor3 = ThemeManager.GetTokens().Text }, 0.15, "Quad")
		end
		Sound.Hover()
	end)

	self.Button.MouseLeave:Connect(function()
		if not self.Selected then
			Animator.Tween(self.Button, { BackgroundTransparency = 1 }, 0.15, "Quad")
			Animator.Tween(self.Label, { TextColor3 = ThemeManager.GetTokens().SecondaryText }, 0.15, "Quad")
		end
	end)

	self.Button.MouseButton1Click:Connect(function()
		self.Window:SelectTab(self)
	end)

	self:_applyCompact(self.Compact)
end

function Tab:_applyCompact(compact)
	self.Compact = compact

	if compact then
		self.Button.Size = UDim2.new(1, 0, 0, 40)
		self.Label.Visible = false
		self._accentBar.Size = UDim2.new(0, 0, 0, 0)
		if self.IconImage then
			self.IconImage.Size = UDim2.new(0, 22, 0, 22)
			self.IconImage.Position = UDim2.new(0.5, -11, 0.5, -11)
		end
		contentFix(self.Button, compact)
	else
		self.Button.Size = UDim2.new(1, 0, 0, 36)
		self.Label.Visible = true
		if self.IconImage then
			self.IconImage.Size = UDim2.new(0, 18, 0, 18)
			self.IconImage.Position = UDim2.new(0, 0, 0, 0)
		end
		contentFix(self.Button, compact)
	end
end

function contentFix(button, compact)
	local content = button:FindFirstChild("Content")
	if not content then
		return
	end
	local layout = content:FindFirstChildOfClass("UIListLayout")
	if not layout then
		return
	end

	if compact then
		content.Size = UDim2.new(1, 0, 1, 0)
		content.Position = UDim2.new(0, 0, 0, 0)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	else
		content.Size = UDim2.new(1, -20, 1, 0)
		content.Position = UDim2.new(0, 10, 0, 0)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	end
end

function Tab:SetCompact(compact)
	self:_applyCompact(compact)
	return self
end

function Tab:SetSelected(selected)
	self.Selected = selected
	local tokens = ThemeManager.GetTokens()

	if selected then
		Animator.Tween(self.Button, { BackgroundTransparency = 0.82 }, 0.2, "Quad")
		Animator.Tween(self.Label, { TextColor3 = tokens.Text }, 0.2, "Quad")
		Animator.Tween(self._accentBar, { Size = UDim2.new(0, 3, 0, 20) }, 0.25, "Back")

		if self.IconImage then
			Animator.Tween(self.IconImage, { ImageColor3 = tokens.Accent }, 0.2, "Quad")
		end

		self.OnSelected:Fire(self)
	else
		Animator.Tween(self.Button, { BackgroundTransparency = 1 }, 0.2, "Quad")
		Animator.Tween(self.Label, { TextColor3 = tokens.SecondaryText }, 0.2, "Quad")
		Animator.Tween(self._accentBar, { Size = UDim2.new(0, 3, 0, 0) }, 0.2, "Quad")

		if self.IconImage then
			Animator.Tween(self.IconImage, { ImageColor3 = tokens.SecondaryText }, 0.2, "Quad")
		end

		self.OnDeselected:Fire(self)
	end

	return self
end

function Tab:PlayOpenAnimation()
	local children = {}
	for _, child in ipairs(self.Scroll:GetChildren()) do
		if child:IsA("GuiObject") then
			table.insert(children, child)
		end
	end

	for i, child in ipairs(children) do
		local originalPos = child.Position
		child.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, originalPos.Y.Scale, originalPos.Y.Offset + 14)
		child.GroupTransparency = child.GroupTransparency

		task.delay((i - 1) * 0.03, function()
			Animator.Tween(child, { Position = originalPos }, 0.3, "Quart")
		end)
	end
end

function Tab:AddSection(options)
	options = options or {}

	local Section = __require("Components.Section")
	local section = Section.new(options, self)

	table.insert(self.Sections, section)
	return section
end

function Tab:SetName(name)
	self.Name = name
	self.Label.Text = name
	self.Button.Name = "Tab_" .. name
	return self
end

function Tab:SetIcon(icon)
	self.Icon = icon

	if icon then
		if not self.IconImage then
			self.IconImage = Instance.new("ImageLabel")
			self.IconImage.Name = "Icon"
			self.IconImage.BackgroundTransparency = 1
			self.IconImage.Size = UDim2.new(0, 18, 0, 18)
			self.IconImage.ImageColor3 = self.Selected and ThemeManager.GetTokens().Accent or ThemeManager.GetTokens().SecondaryText
			self.IconImage.ScaleType = Enum.ScaleType.Fit
			self.IconImage.LayoutOrder = 1
			self.IconImage.ZIndex = 8
			self.IconImage.Parent = self.Button:FindFirstChild("Content")
		end
		self.IconImage.Image = icon
	else
		if self.IconImage then
			self.IconImage:Destroy()
			self.IconImage = nil
		end
	end

	return self
end

function Tab:SetBadge(count)
	local badge = self.Button:FindFirstChild("Content") and self.Button.Content:FindFirstChild("Badge")

	if count == nil then
		if badge then
			badge:Destroy()
		end
		return self
	end

	if badge then
		badge.Text.Text = tostring(count)
	else
		local content = self.Button:FindFirstChild("Content")
		local tokens = ThemeManager.GetTokens()

		local badgeFrame = Instance.new("Frame")
		badgeFrame.Name = "Badge"
		badgeFrame.Size = UDim2.new(0, 18, 0, 18)
		badgeFrame.BackgroundColor3 = tokens.Accent
		badgeFrame.BorderSizePixel = 0
		badgeFrame.LayoutOrder = 3
		badgeFrame.ZIndex = 8
		badgeFrame.Parent = content

		UIUtils.Corner(badgeFrame, tokens.CornerCircle)

		local badgeText = Instance.new("TextLabel")
		badgeText.Name = "Text"
		badgeText.Size = UDim2.new(1, 0, 1, 0)
		badgeText.BackgroundTransparency = 1
		badgeText.Font = tokens.FontBold
		badgeText.Text = tostring(count)
		badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
		badgeText.TextSize = 10
		badgeText.ZIndex = 9
		badgeText.Parent = badgeFrame
	end

	return self
end

function Tab:Destroy()
	if self.Destroyed then
		return
	end

	for _, section in ipairs(self.Sections) do
		pcall(function() section:Destroy() end)
	end
	self.Sections = {}

	if self.Button then
		self.Button:Destroy()
	end
	if self.Page then
		self.Page:Destroy()
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return Tab
]]
__MODULES["Components.Section"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")

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
	local Button = __require("Components.Button")
	local button = Button.new(options, self.Body)
	button:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, button)
	return button
end

function Section:AddToggle(options)
	options = options or {}
	local Toggle = __require("Components.Toggle")
	local toggle = Toggle.new(options, self.Body)
	toggle:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, toggle)
	return toggle
end

function Section:AddCheckbox(options)
	options = options or {}
	local Checkbox = __require("Components.Checkbox")
	local checkbox = Checkbox.new(options, self.Body)
	checkbox:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, checkbox)
	return checkbox
end

function Section:AddSlider(options)
	options = options or {}
	local Slider = __require("Components.Slider")
	local slider = Slider.new(options, self.Body)
	slider:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, slider)
	return slider
end

function Section:AddDropdown(options)
	options = options or {}
	local Dropdown = __require("Components.Dropdown")
	local dropdown = Dropdown.new(options, self.Body)
	dropdown:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, dropdown)
	return dropdown
end

function Section:AddMultiDropdown(options)
	options = options or {}
	local MultiDropdown = __require("Components.MultiDropdown")
	local dropdown = MultiDropdown.new(options, self.Body)
	dropdown:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, dropdown)
	return dropdown
end

function Section:AddTextBox(options)
	options = options or {}
	local TextBox = __require("Components.TextBox")
	local textBox = TextBox.new(options, self.Body)
	textBox:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, textBox)
	return textBox
end

function Section:AddSearchBox(options)
	options = options or {}
	local SearchBox = __require("Components.SearchBox")
	local searchBox = SearchBox.new(options, self.Body)
	searchBox:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, searchBox)
	return searchBox
end

function Section:AddKeybind(options)
	options = options or {}
	local Keybind = __require("Components.Keybind")
	local keybind = Keybind.new(options, self.Body)
	keybind:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, keybind)
	return keybind
end

function Section:AddColorPicker(options)
	options = options or {}
	local ColorPicker = __require("Components.ColorPicker")
	local picker = ColorPicker.new(options, self.Body)
	picker:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, picker)
	return picker
end

function Section:AddLabel(options)
	options = options or {}
	local Label = __require("Components.Label")
	local label = Label.new(options, self.Body)
	label:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, label)
	return label
end

function Section:AddParagraph(options)
	options = options or {}
	local Paragraph = __require("Components.Paragraph")
	local paragraph = Paragraph.new(options, self.Body)
	paragraph:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, paragraph)
	return paragraph
end

function Section:AddDivider(options)
	options = options or {}
	local Divider = __require("Components.Divider")
	local divider = Divider.new(options, self.Body)
	divider:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, divider)
	return divider
end

function Section:AddBadge(options)
	options = options or {}
	local Badge = __require("Components.Badge")
	local badge = Badge.new(options, self.Body)
	badge:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, badge)
	return badge
end

function Section:AddCard(options)
	options = options or {}
	local Card = __require("Components.Card")
	local card = Card.new(options, self.Body)
	card:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, card)
	return card
end

function Section:AddImage(options)
	options = options or {}
	local Image = __require("Components.Image")
	local image = Image.new(options, self.Body)
	image:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, image)
	return image
end

function Section:AddProgressBar(options)
	options = options or {}
	local ProgressBar = __require("Components.ProgressBar")
	local progress = ProgressBar.new(options, self.Body)
	progress:SetLayoutOrder(#self.Elements + 1)
	table.insert(self.Elements, progress)
	return progress
end

function Section:AddLoadingIndicator(options)
	options = options or {}
	local LoadingIndicator = __require("Components.LoadingIndicator")
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
]]
__MODULES["Components.Window"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Device = __require("Core.Device")
local Icons = __require("Core.Icons")
local Sound = __require("Utilities.Sound")

local Window = {}
Window.__index = Window
setmetatable(Window, { __index = BaseComponent })

Window.ActiveWindows = {}

local CoreGui = game:GetService("CoreGui")
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local function getParent()
	local ok = pcall(function()
		local test = CoreGui:GetChildren()
		return test
	end)
	if ok then
		return CoreGui
	end
	return PlayerGui
end

function Window.new(options)
	options = options or {}

	local self = BaseComponent.new("Window")
	setmetatable(self, { __index = function(t, k)
		if Window[k] then
			return Window[k]
		end
		return BaseComponent[k]
	end })

	self.Name = options.Name or "NexusUI"
	self.Title = options.Title or options.Name or "Nexus"
	self.SubTitle = options.SubTitle or ""
	self.Size = options.Size or UDim2.fromOffset(880, 560)
	self.Position = options.Position or UDim2.new(0.5, 0, 0.5, 0)
	self.Closable = options.Closable ~= false
	self.Resizable = options.Resizable ~= false
	self.Draggable = options.Draggable ~= false
	self.ShowOnCreate = options.ShowOnCreate ~= false
	self.MobileMode = options.MobileMode or false
	self.ImageBackground = options.Background ~= false
	self.BackgroundId = options.BackgroundId or Icons.Assets.Background
	self.ToggleKeybind = options.ToggleKeybind or Enum.KeyCode.RightShift

	self.Tabs = {}
	self.ActiveTab = nil
	self.Opened = false

	self.OnOpened = Signal.new()
	self.OnClosed = Signal.new()
	self.OnTabChanged = Signal.new()
	self.OnThemeChanged = Signal.new()

	self._maid = Maid.new()
	self._signals = {
		Destroyed = self.OnClosed,
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
		Opened = self.OnOpened,
		Closed = self.OnClosed,
		TabChanged = self.OnTabChanged,
	}

	self._build()

	if self.ShowOnCreate then
		self:Open()
	end

	Window.ActiveWindows[self] = true

	return self
end

function Window:_build()
	local tokens = ThemeManager.GetTokens()
	local parent = getParent()

	self.Root = Instance.new("ScreenGui")
	self.Root.Name = self.Name .. "_NexusUI"
	self.Root.ResetOnSpawn = false
	self.Root.IgnoreGuiInset = true
	self.Root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self.Root.DisplayOrder = 100
	self.Root.Enabled = false
	self.Root.Parent = parent

	self.Overlay = Instance.new("Frame")
	self.Overlay.Name = "Overlay"
	self.Overlay.Size = UDim2.new(1, 0, 1, 0)
	self.Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.Overlay.BackgroundTransparency = 1
	self.Overlay.BorderSizePixel = 0
	self.Overlay.ZIndex = 1
	self.Overlay.Parent = self.Root

	self.Container = Instance.new("Frame")
	self.Container.Name = "Window"
	self.Container.Size = self.Size
	self.Container.Position = self.Position
	self.Container.AnchorPoint = Vector2.new(0.5, 0.5)
	self.Container.BackgroundColor3 = tokens.Background
	self.Container.BackgroundTransparency = tokens.WindowTransparency
	self.Container.BorderSizePixel = 0
	self.Container.ZIndex = 2
	self.Container.ClipsDescendants = true
	self.Container.Parent = self.Overlay

	UIUtils.Corner(self.Container, tokens.CornerLarge)
	UIUtils.Stroke(self.Container, tokens.BorderLight, 1, 0.5)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Container.BackgroundColor3 = tk.Background
		self.Container.BackgroundTransparency = tk.WindowTransparency
	end))

	if self.ImageBackground then
		self.Background = Instance.new("ImageLabel")
		self.Background.Name = "Background"
		self.Background.Image = self.BackgroundId
		self.Background.Size = UDim2.new(1, 0, 1, 0)
		self.Background.Position = UDim2.new(0, 0, 0, 0)
		self.Background.BackgroundTransparency = 1
		self.Background.ImageTransparency = 0.88
		self.Background.ImageColor3 = tokens.Accent
		self.Background.ScaleType = Enum.ScaleType.Crop
		self.Background.ZIndex = 3
		self.Background.Parent = self.Container

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.Background.ImageColor3 = tk.Accent
		end))
	end

	self:_buildTopbar()
	self:_buildSidebar()
	self:_buildContent()
	self:_buildDrag()
	self:_buildResize()
	self:_buildKeybind()

	Device.Changed:Connect(function()
		self:_applyResponsive()
	end)
end

function Window:_buildTopbar()
	local tokens = ThemeManager.GetTokens()

	self.Topbar = Instance.new("Frame")
	self.Topbar.Name = "Topbar"
	self.Topbar.Size = UDim2.new(1, 0, 0, 46)
	self.Topbar.BackgroundColor3 = tokens.Surface
	self.Topbar.BackgroundTransparency = 0.35
	self.Topbar.BorderSizePixel = 0
	self.Topbar.ZIndex = 5
	self.Topbar.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Topbar.BackgroundColor3 = tk.Surface
	end))

	local bottomLine = Instance.new("Frame")
	bottomLine.Name = "BottomLine"
	bottomLine.Size = UDim2.new(1, 0, 0, 1)
	bottomLine.Position = UDim2.new(0, 0, 1, -1)
	bottomLine.BackgroundColor3 = tokens.Border
	bottomLine.BackgroundTransparency = 0.4
	bottomLine.BorderSizePixel = 0
	bottomLine.ZIndex = 5
	bottomLine.Parent = self.Topbar

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		bottomLine.BackgroundColor3 = tk.Border
	end))

	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "IconFrame"
	iconFrame.Size = UDim2.new(0, 30, 0, 30)
	iconFrame.Position = UDim2.new(0, 10, 0.5, 0)
	iconFrame.AnchorPoint = Vector2.new(0, 0.5)
	iconFrame.BackgroundColor3 = tokens.Accent
	iconFrame.BackgroundTransparency = 0.88
	iconFrame.BorderSizePixel = 0
	iconFrame.ZIndex = 6
	iconFrame.Parent = self.Topbar

	UIUtils.Corner(iconFrame, tokens.CornerSmall)

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Image = Icons.Assets.Background
	icon.Size = UDim2.new(0, 18, 0, 18)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.ImageColor3 = tokens.Accent
	icon.ZIndex = 7
	icon.Parent = iconFrame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		icon.ImageColor3 = tk.Accent
	end))

	self.TitleLabel = Instance.new("TextLabel")
	self.TitleLabel.Name = "Title"
	self.TitleLabel.BackgroundTransparency = 1
	self.TitleLabel.Position = UDim2.new(0, 50, 0, 0)
	self.TitleLabel.Size = UDim2.new(0.5, -60, 1, 0)
	self.TitleLabel.Font = tokens.FontBold
	self.TitleLabel.Text = self.Title
	self.TitleLabel.TextColor3 = tokens.Text
	self.TitleLabel.TextSize = tokens.TitleSize
	self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	self.TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	self.TitleLabel.ZIndex = 6
	self.TitleLabel.Parent = self.Topbar

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.TitleLabel.Font = tk.FontBold
		self.TitleLabel.TextColor3 = tk.Text
		self.TitleLabel.TextSize = tk.TitleSize
	end))

	if self.SubTitle ~= "" then
		self.SubTitleLabel = Instance.new("TextLabel")
		self.SubTitleLabel.Name = "SubTitle"
		self.SubTitleLabel.BackgroundTransparency = 1
		self.SubTitleLabel.Position = UDim2.new(0, 52, 0, 24)
		self.SubTitleLabel.Size = UDim2.new(0.4, -60, 0, 14)
		self.SubTitleLabel.Font = tokens.Font
		self.SubTitleLabel.Text = self.SubTitle
		self.SubTitleLabel.TextColor3 = tokens.SecondaryText
		self.SubTitleLabel.TextSize = 11
		self.SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		self.SubTitleLabel.ZIndex = 6
		self.SubTitleLabel.Parent = self.Topbar

		self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
			self.SubTitleLabel.TextColor3 = tk.SecondaryText
		end))
	end

	self.ButtonRow = Instance.new("Frame")
	self.ButtonRow.Name = "ButtonRow"
	self.ButtonRow.AnchorPoint = Vector2.new(1, 0.5)
	self.ButtonRow.Position = UDim2.new(1, -10, 0.5, 0)
	self.ButtonRow.Size = UDim2.new(0, 0, 0, 28)
	self.ButtonRow.BackgroundTransparency = 1
	self.ButtonRow.ZIndex = 6
	self.ButtonRow.Parent = self.Topbar

	local buttonList = UIUtils.ListLayout(self.ButtonRow, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right)

	if self.Closable then
		self.CloseButton = self:_createTopbarButton("Close", "X", function()
			self:Close()
		end)
	end
end

function Window:_createTopbarButton(name, glyph, callback)
	local tokens = ThemeManager.GetTokens()

	local button = Instance.new("TextButton")
	button.Name = name .. "Button"
	button.Size = UDim2.new(0, 28, 0, 28)
	button.BackgroundColor3 = tokens.SurfaceLight
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Font = tokens.FontBold
	button.Text = glyph
	button.TextColor3 = tokens.SecondaryText
	button.TextSize = 14
	button.AutoButtonColor = false
	button.ZIndex = 7
	button.LayoutOrder = 1
	button.Parent = self.ButtonRow

	UIUtils.Corner(button, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		button.BackgroundColor3 = tk.SurfaceLight
		button.TextColor3 = tk.SecondaryText
	end))

	button.MouseEnter:Connect(function()
		Animator.Tween(button, { BackgroundTransparency = 0.5, TextColor3 = ThemeManager.GetTokens().Text }, 0.15, "Quad")
		Sound.Hover()
	end)

	button.MouseLeave:Connect(function()
		Animator.Tween(button, { BackgroundTransparency = 1, TextColor3 = ThemeManager.GetTokens().SecondaryText }, 0.15, "Quad")
	end)

	button.MouseButton1Click:Connect(function()
		Sound.Click()
		callback()
	end)

	return button
end

function Window:_buildSidebar()
	local tokens = ThemeManager.GetTokens()

	self.Sidebar = Instance.new("Frame")
	self.Sidebar.Name = "Sidebar"
	self.Sidebar.Size = UDim2.new(0, 190, 1, -46)
	self.Sidebar.Position = UDim2.new(0, 0, 0, 46)
	self.Sidebar.BackgroundColor3 = tokens.Surface
	self.Sidebar.BackgroundTransparency = 0.5
	self.Sidebar.BorderSizePixel = 0
	self.Sidebar.ZIndex = 4
	self.Sidebar.Parent = self.Container

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Sidebar.BackgroundColor3 = tk.Surface
	end))

	local sidebarLine = Instance.new("Frame")
	sidebarLine.Name = "Line"
	sidebarLine.Size = UDim2.new(0, 1, 1, 0)
	sidebarLine.Position = UDim2.new(1, -1, 0, 0)
	sidebarLine.BackgroundColor3 = tokens.Border
	sidebarLine.BackgroundTransparency = 0.5
	sidebarLine.BorderSizePixel = 0
	sidebarLine.ZIndex = 5
	sidebarLine.Parent = self.Sidebar

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		sidebarLine.BackgroundColor3 = tk.Border
	end))

	self.TabScroll = Instance.new("ScrollingFrame")
	self.TabScroll.Name = "TabScroll"
	self.TabScroll.Size = UDim2.new(1, 0, 1, -20)
	self.TabScroll.Position = UDim2.new(0, 0, 0, 10)
	self.TabScroll.BackgroundTransparency = 1
	self.TabScroll.BorderSizePixel = 0
	self.TabScroll.ScrollBarThickness = 2
	self.TabScroll.ScrollBarImageColor3 = tokens.Accent
	self.TabScroll.ScrollBarImageTransparency = 0.4
	self.TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self.TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	self.TabScroll.ZIndex = 5
	self.TabScroll.Parent = self.Sidebar

	local tabList = Instance.new("UIListLayout")
	tabList.FillDirection = Enum.FillDirection.Vertical
	tabList.Padding = UDim.new(0, 4)
	tabList.SortOrder = Enum.SortOrder.LayoutOrder
	tabList.Parent = self.TabScroll

	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingLeft = UDim.new(0, 8)
	tabPadding.PaddingRight = UDim.new(0, 8)
	tabPadding.Parent = self.TabScroll
end

function Window:_buildContent()
	local tokens = ThemeManager.GetTokens()

	self.Content = Instance.new("Frame")
	self.Content.Name = "Content"
	self.Content.Size = UDim2.new(1, -190, 1, -46)
	self.Content.Position = UDim2.new(0, 190, 0, 46)
	self.Content.BackgroundTransparency = 1
	self.Content.BorderSizePixel = 0
	self.Content.ZIndex = 4
	self.Content.ClipsDescendants = true
	self.Content.Parent = self.Container
end

function Window:_buildDrag()
	if not self.Draggable then
		return
	end

	local dragging = false
	local dragStart = nil
	local startPos = nil

	self.Topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = self.Container.Position

			local moveConnection
			local endConnection

			moveConnection = game:GetService("UserInputService").InputChanged:Connect(function(moveInput)
				if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement
					or moveInput.UserInputType == Enum.UserInputType.Touch) then
					local delta = moveInput.Position - dragStart
					self.Container.Position = UDim2.new(
						startPos.X.Scale,
						startPos.X.Offset + delta.X,
						startPos.Y.Scale,
						startPos.Y.Offset + delta.Y
					)
				end
			end)

			endConnection = game:GetService("UserInputService").InputEnded:Connect(function(endInput)
				if endInput.UserInputType == Enum.UserInputType.MouseButton1
					or endInput.UserInputType == Enum.UserInputType.Touch then
					dragging = false
					moveConnection:Disconnect()
					endConnection:Disconnect()
				end
			end)
		end
	end)
end

function Window:_buildResize()
	if not self.Resizable then
		return
	end

	local tokens = ThemeManager.GetTokens()

	local resizeHandle = Instance.new("Frame")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.new(0, 16, 0, 16)
	resizeHandle.Position = UDim2.new(1, -16, 1, -16)
	resizeHandle.BackgroundColor3 = tokens.Accent
	resizeHandle.BackgroundTransparency = 0.92
	resizeHandle.BorderSizePixel = 0
	resizeHandle.ZIndex = 10
	resizeHandle.Parent = self.Container

	UIUtils.Corner(resizeHandle, UDim.new(0, 4))

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		resizeHandle.BackgroundColor3 = tk.Accent
	end))

	local dragging = false
	local dragStart = nil
	local startSize = nil

	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startSize = self.Container.Size
		end
	end)

	local uis = game:GetService("UserInputService")

	uis.InputChanged:Connect(function(moveInput)
		if dragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement
			or moveInput.UserInputType == Enum.UserInputType.Touch) then
			local delta = moveInput.Position - dragStart
			local minSize = 560
			local newSize = UDim2.new(
				0,
				math.max(minSize, startSize.X.Offset + delta.X),
				0,
				math.max(400, startSize.Y.Offset + delta.Y)
			)
			self.Container.Size = newSize
			self.Size = newSize
		end
	end)

	uis.InputEnded:Connect(function(endInput)
		if endInput.UserInputType == Enum.UserInputType.MouseButton1
			or endInput.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

function Window:_buildKeybind()
	if not self.ToggleKeybind then
		return
	end

	local uis = game:GetService("UserInputService")
	self._maid:GiveTask(uis.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == self.ToggleKeybind then
			if self.Opened then
				self:Close()
			else
				self:Open()
			end
		end
	end))
end

function Window:_applyResponsive()
	if Device.IsHandheld() or self.MobileMode then
		self.Sidebar.Size = UDim2.new(0, 56, 1, -46)
		self.Content.Position = UDim2.new(0, 56, 0, 46)
		self.Content.Size = UDim2.new(1, -56, 1, -46)
		self._sidebarCompact = true

		for _, tab in ipairs(self.Tabs) do
			if tab.SetCompact then
				tab:SetCompact(true)
			end
		end
	else
		self.Sidebar.Size = UDim2.new(0, 190, 1, -46)
		self.Content.Position = UDim2.new(0, 190, 0, 46)
		self.Content.Size = UDim2.new(1, -190, 1, -46)
		self._sidebarCompact = false

		for _, tab in ipairs(self.Tabs) do
			if tab.SetCompact then
				tab:SetCompact(false)
			end
		end
	end
end

function Window:SetMobileMode(enabled)
	self.MobileMode = enabled
	self:_applyResponsive()
	return self
end

function Window:AddTab(options)
	options = options or {}

	local Tab = __require("Components.Tab")
	local tab = Tab.new(options, self)

	table.insert(self.Tabs, tab)

	if not self.ActiveTab then
		self.ActiveTab = tab
		tab:SetSelected(true)
	end

	tab.Instance.Visible = (tab == self.ActiveTab)

	return tab
end

function Window:SelectTab(tabOrName)
	local target = nil

	if type(tabOrName) == "string" then
		for _, tab in ipairs(self.Tabs) do
			if tab.Name == tabOrName then
				target = tab
				break
			end
		end
	else
		target = tabOrName
	end

	if not target or target == self.ActiveTab then
		return self
	end

	if self.ActiveTab then
		self.ActiveTab:SetSelected(false)
		self.ActiveTab.Instance.Visible = false
	end

	self.ActiveTab = target
	target:SetSelected(true)
	target.Instance.Visible = true

	if target.PlayOpenAnimation then
		target:PlayOpenAnimation()
	end

	Sound.Click()
	self.OnTabChanged:Fire(target)

	return self
end

function Window:Open()
	if self.Opened then
		return self
	end

	self.Opened = true
	self.Root.Enabled = true

	local tokens = ThemeManager.GetTokens()

	self.Container.Size = self.Size

	local scale = UIUtils.Scale(self.Container, 0.9)
	self.Container.BackgroundTransparency = 0.4
	self.Overlay.BackgroundTransparency = 1

	Animator.Tween(self.Overlay, { BackgroundTransparency = 0.35 }, 0.3, "Quad")
	Animator.Tween(scale, { Scale = 1 }, 0.45, "Back")
	Animator.Tween(self.Container, { BackgroundTransparency = tokens.WindowTransparency }, 0.35, "Quart")

	if self.Background then
		self.Background.ImageTransparency = 1
		Animator.Tween(self.Background, { ImageTransparency = 0.88 }, 0.5, "Quad")
	end

	Sound.Open()
	self.OnOpened:Fire()

	return self
end

function Window:Close()
	if not self.Opened then
		return self
	end

	self.Opened = false

	local scale = self.Container:FindFirstChildOfClass("UIScale") or UIUtils.Scale(self.Container, 1)
	Animator.Tween(self.Overlay, { BackgroundTransparency = 1 }, 0.2, "Quad")
	Animator.Tween(scale, { Scale = 0.92 }, 0.22, "Quart")
	Animator.Tween(self.Container, { BackgroundTransparency = 0.35 }, 0.2, "Quad")

	task.delay(0.22, function()
		if not self.Opened then
			self.Root.Enabled = false
		end
	end)

	Sound.Close()
	self.OnClosed:Fire()

	return self
end

function Window:Toggle()
	if self.Opened then
		return self:Close()
	end
	return self:Open()
end

function Window:SetTitle(title)
	self.Title = title
	self.TitleLabel.Text = title
	return self
end

function Window:SetSubTitle(subTitle)
	self.SubTitle = subTitle

	if subTitle == "" then
		if self.SubTitleLabel then
			self.SubTitleLabel:Destroy()
			self.SubTitleLabel = nil
		end
	else
		if self.SubTitleLabel then
			self.SubTitleLabel.Text = subTitle
		end
	end

	return self
end

function Window:SetBackgroundImage(assetId, transparency)
	self.BackgroundId = assetId or self.BackgroundId

	if not self.Background and self.ImageBackground then
		self.Background = Instance.new("ImageLabel")
		self.Background.Name = "Background"
		self.Background.Size = UDim2.new(1, 0, 1, 0)
		self.Background.BackgroundTransparency = 1
		self.Background.ScaleType = Enum.ScaleType.Crop
		self.Background.ZIndex = 3
		self.Background.Parent = self.Container
	end

	if self.Background then
		self.Background.Image = self.BackgroundId
		self.Background.ImageTransparency = transparency or 0.88
	end

	return self
end

function Window:Destroy()
	if self.Destroyed then
		return
	end

	Window.ActiveWindows[self] = nil

	if self.Root then
		self.Root:Destroy()
		self.Root = nil
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Tabs = {}
	self.Destroyed = true
end

return Window
]]
__MODULES["Components.QuickActions"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")
local Icons = __require("Core.Icons")

local QuickActions = {}
QuickActions.__index = QuickActions
setmetatable(QuickActions, { __index = BaseComponent })

function QuickActions.new(options, window)
	options = options or {}

	local self = BaseComponent.new("QuickActions")
	setmetatable(self, { __index = function(t, k)
		if QuickActions[k] then
			return QuickActions[k]
		end
		return BaseComponent[k]
	end })

	self.Window = window
	self.Name = options.Name or "QuickActions"
	self.Position = options.Position or "TopRight"
	self.Size = options.Size or 38
	self.Spacing = options.Spacing or 8
	self.Buttons = {}

	self._maid = Maid.new()
	self._signals = {
		Destroyed = Signal.new(),
		VisibleChanged = Signal.new(),
		ThemeChanged = Signal.new(),
		StateChanged = Signal.new(),
	}

	self:_build()

	return self
end

function QuickActions:_getRootParent()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	return ok and parent or PlayerGui
end

function QuickActions:_build()
	local tokens = ThemeManager.GetTokens()

	self.Root = Instance.new("ScreenGui")
	self.Root.Name = "NexusUI_QuickActions"
	self.Root.ResetOnSpawn = false
	self.Root.IgnoreGuiInset = true
	self.Root.DisplayOrder = 150
	self.Root.Parent = self:_getRootParent()

	self.Container = Instance.new("Frame")
	self.Container.Name = "QuickActions"
	self.Container.Size = UDim2.new(0, self.Size + 8, 0, 0)
	self.Container.AutomaticSize = Enum.AutomaticSize.Y
	self.Container.BackgroundTransparency = 1
	self.Container.ZIndex = 100

	local offset = 12

	if self.Position == "TopRight" then
		self.Container.AnchorPoint = Vector2.new(1, 0)
		self.Container.Position = UDim2.new(1, -offset, 0, offset)
	elseif self.Position == "TopLeft" then
		self.Container.AnchorPoint = Vector2.new(0, 0)
		self.Container.Position = UDim2.new(0, offset, 0, offset)
	elseif self.Position == "BottomRight" then
		self.Container.AnchorPoint = Vector2.new(1, 1)
		self.Container.Position = UDim2.new(1, -offset, 1, -offset)
	else
		self.Container.AnchorPoint = Vector2.new(0, 1)
		self.Container.Position = UDim2.new(0, offset, 1, -offset)
	end

	self.Container.Parent = self.Root

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, self.Spacing)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = self.Container

	self.DragHandle = Instance.new("Frame")
	self.DragHandle.Name = "DragHandle"
	self.DragHandle.Size = UDim2.new(0, self.Size, 0, 6)
	self.DragHandle.BackgroundColor3 = tokens.Border
	self.DragHandle.BackgroundTransparency = 0.5
	self.DragHandle.BorderSizePixel = 0
	self.DragHandle.LayoutOrder = 0
	self.DragHandle.ZIndex = 101
	self.DragHandle.Parent = self.Container

	UIUtils.Corner(self.DragHandle, tokens.CornerCircle)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.DragHandle.BackgroundColor3 = tk.Border
	end))

	self:_bindDrag()
end

function QuickActions:_bindDrag()
	local dragging = false
	local dragStart = nil
	local startPos = nil

	self.DragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = self.Container.Position
		end
	end)

	local uis = game:GetService("UserInputService")

	self._maid:GiveTask(uis.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			self.Container.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end))

	self._maid:GiveTask(uis.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

function QuickActions:AddButton(options)
	options = options or {}

	local tokens = ThemeManager.GetTokens()

	local buttonHolder = Instance.new("Frame")
	buttonHolder.Name = "ActionButton_" .. (options.Name or #self.Buttons + 1)
	buttonHolder.Size = UDim2.new(0, self.Size, 0, self.Size)
	buttonHolder.BackgroundColor3 = tokens.Surface
	buttonHolder.BackgroundTransparency = 0.12
	buttonHolder.BorderSizePixel = 0
	buttonHolder.LayoutOrder = #self.Buttons + 1
	buttonHolder.ZIndex = 101
	buttonHolder.Parent = self.Container

	UIUtils.Corner(buttonHolder, tokens.Corner)
	UIUtils.Stroke(buttonHolder, tokens.Border, 1, 0.65)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		buttonHolder.BackgroundColor3 = tk.Surface
	end))

	local button = Instance.new("TextButton")
	button.Name = "ClickTarget"
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.ZIndex = 102
	button.Parent = buttonHolder

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.Size = UDim2.new(0, self.Size * 0.55, 0, self.Size * 0.55)
	icon.BackgroundTransparency = 1
	icon.Image = options.Icon or Icons.Assets.Settings
	icon.ImageColor3 = tokens.Text
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 103
	icon.Parent = buttonHolder

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		icon.ImageColor3 = tk.Text
	end))

	local tooltipText = options.Tooltip
	if tooltipText then
		local Tooltip = __require("Components.Tooltip")
		Tooltip.new({
			Text = tooltipText,
			Target = button,
			Position = "Left",
		})
	end

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = buttonHolder

	button.MouseEnter:Connect(function()
		Animator.Tween(scale, { Scale = 1.08 }, 0.15, "Back")
		Animator.Tween(buttonHolder, { BackgroundTransparency = 0.02 }, 0.15, "Quad")
		Sound.Hover()
	end)

	button.MouseLeave:Connect(function()
		Animator.Tween(scale, { Scale = 1 }, 0.2, "Quad")
		Animator.Tween(buttonHolder, { BackgroundTransparency = 0.12 }, 0.2, "Quad")
	end)

	button.MouseButton1Click:Connect(function()
		Sound.Click()
		if options.Callback then
			pcall(options.Callback)
		end
	end)

	local handle = {
		Holder = buttonHolder,
		Button = button,
		Icon = icon,
		SetIcon = function(_, imageId)
			icon.Image = imageId
			return handle
		end,
		SetVisible = function(_, visible)
			buttonHolder.Visible = visible
			return handle
		end,
		Destroy = function()
			buttonHolder:Destroy()
		end,
	}

	table.insert(self.Buttons, handle)
	return handle
end

function QuickActions:AddWindowToggle(iconId, tooltip)
	return self:AddButton({
		Name = "WindowToggle",
		Icon = iconId or Icons.Assets.Settings,
		Tooltip = tooltip or "Toggle Window",
		Callback = function()
			if self.Window then
				self.Window:Toggle()
			end
		end,
	})
end

function QuickActions:AddProfileButton(callback, tooltip)
	return self:AddButton({
		Name = "Profile",
		Icon = Icons.Assets.User,
		Tooltip = tooltip or "Profile",
		Callback = callback or function() end,
	})
end

function QuickActions:AddYouTubeButton(url, tooltip)
	return self:AddButton({
		Name = "YouTube",
		Icon = Icons.Assets.YouTube,
		Tooltip = tooltip or "YouTube",
		Callback = function()
			if url then
				local Toast = __require("Components.Toast")
				Toast.new({ Text = "YouTube: " .. url, Duration = 3 })
			end
		end,
	})
end

function QuickActions:AddDiscordButton(copyText, tooltip)
	return self:AddButton({
		Name = "Discord",
		Icon = Icons.Assets.Discord,
		Tooltip = tooltip or "Copy Discord Invite",
		Callback = function()
			if copyText then
				pcall(function()
					setclipboard(copyText)
				end)

				local Toast = __require("Components.Toast")
				Toast.new({ Text = "Copied: " .. copyText, Duration = 2.5 })
			end
		end,
	})
end

function QuickActions:SetPosition(position)
	self.Position = position
	local offset = 12

	if position == "TopRight" then
		self.Container.AnchorPoint = Vector2.new(1, 0)
		self.Container.Position = UDim2.new(1, -offset, 0, offset)
	elseif position == "TopLeft" then
		self.Container.AnchorPoint = Vector2.new(0, 0)
		self.Container.Position = UDim2.new(0, offset, 0, offset)
	elseif position == "BottomRight" then
		self.Container.AnchorPoint = Vector2.new(1, 1)
		self.Container.Position = UDim2.new(1, -offset, 1, -offset)
	else
		self.Container.AnchorPoint = Vector2.new(0, 1)
		self.Container.Position = UDim2.new(0, offset, 1, -offset)
	end

	return self
end

function QuickActions:Destroy()
	if self.Destroyed then
		return
	end

	for _, button in ipairs(self.Buttons) do
		pcall(function() button:Destroy() end)
	end
	self.Buttons = {}

	if self.Root then
		self.Root:Destroy()
		self.Root = nil
	end

	if self._maid then
		self._maid:Destroy()
	end

	self.Destroyed = true
end

return QuickActions
]]
__MODULES["Services.NotificationSystem"] = [[local ThemeManager = __require("Theme.ThemeManager")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")
local Config = __require("Core.Config")

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
]]
__MODULES["Services.CommandPalette"] = [[local ThemeManager = __require("Theme.ThemeManager")
local Signal = __require("Core.Signal")

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

	local ThemeManager = __require("Theme.ThemeManager")
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
		UIUtils = __require("Utilities.UIUtils")
		Animator = __require("Animation.Animator")
		Sound = __require("Utilities.Sound")
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
]]
__MODULES["Services.Preset"] = [[local HttpService = game:GetService("HttpService")

local Preset = {}
Preset.__index = Preset

Preset.Presets = {}

function Preset:SavePreset(name)
	assert(type(name) == "string", "Preset name must be a string")

	local NexusUI = __require("init")
	local data = {
		Meta = {
			Name = name,
			SavedAt = os.time(),
			Version = "1.0.0",
		},
		Theme = {},
		Windows = {},
		States = {},
	}

	local ThemeManager = __require("Theme.ThemeManager")
	local themeName, themeTokens = ThemeManager.CurrentName, ThemeManager.Current

	for key, value in pairs(themeTokens) do
		local valueType = typeof(value)

		if valueType == "Color3" then
			data.Theme[key] = {
				Type = "Color3",
				R = value.R,
				G = value.G,
				B = value.B,
			}
		elseif valueType == "UDim" then
			data.Theme[key] = {
				Type = "UDim",
				Scale = value.Scale,
				Offset = value.Offset,
			}
		elseif type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
			data.Theme[key] = {
				Type = valueType,
				Value = value,
			}
		elseif valueType == "EnumItem" then
			data.Theme[key] = {
				Type = "EnumItem",
				EnumType = tostring(value.EnumType),
				Name = value.Name,
			}
		end
	end
	data.Theme.Name = themeName

	for _, window in ipairs(NexusUI:GetAllWindows()) do
		if not window.Destroyed then
			local windowData = {
				Name = window.Name,
				Title = window.Title,
				Opened = window.Opened,
				Position = {
					X = { Scale = window.Container.Position.X.Scale, Offset = window.Container.Position.X.Offset },
					Y = { Scale = window.Container.Position.Y.Scale, Offset = window.Container.Position.Y.Offset },
				},
				Size = {
					X = { Scale = window.Container.Size.X.Scale, Offset = window.Container.Size.X.Offset },
					Y = { Scale = window.Container.Size.Y.Scale, Offset = window.Container.Size.Y.Offset },
				},
				ActiveTab = window.ActiveTab and window.ActiveTab.Name or nil,
				Toggles = {},
				Sliders = {},
				Dropdowns = {},
				Checkboxes = {},
			}

			for _, tab in ipairs(window.Tabs) do
				for _, section in ipairs(tab.Sections) do
					for _, element in ipairs(section.Elements or {}) do
						if element.ClassName == "Toggle" then
							table.insert(windowData.Toggles, {
								Name = element.Name,
								Value = element.Value,
							})
						elseif element.ClassName == "Slider" then
							table.insert(windowData.Sliders, {
								Name = element.Name,
								Value = element.Value,
							})
						elseif element.ClassName == "Dropdown" then
							table.insert(windowData.Dropdowns, {
								Name = element.Name,
								Value = element.Value,
							})
						elseif element.ClassName == "Checkbox" then
							table.insert(windowData.Checkboxes, {
								Name = element.Name,
								Value = element.Value,
							})
						end
					end
				end
			end

			table.insert(data.Windows, windowData)
		end
	end

	Preset.Presets[name] = data
	return data
end

function Preset:LoadPreset(name)
	local data = Preset.Presets[name]
	if not data then
		warn("[NexusUI] Preset not found:", name)
		return false
	end

	local NexusUI = __require("init")
	local ThemeManager = __require("Theme.ThemeManager")

	if data.Theme and next(data.Theme) then
		if data.Theme.Name and ThemeManager.ListThemes and table.find(ThemeManager.ListThemes(), data.Theme.Name) then
			ThemeManager.SetTheme(data.Theme.Name)
		else
			local tokens = {}
			for key, serialized in pairs(data.Theme) do
				if type(serialized) == "table" and serialized.Type then
					if serialized.Type == "Color3" then
						tokens[key] = Color3.new(serialized.R, serialized.G, serialized.B)
					elseif serialized.Type == "UDim" then
						tokens[key] = UDim.new(serialized.Scale, serialized.Offset)
					elseif serialized.Type == "number" or serialized.Type == "string" or serialized.Type == "boolean" then
						tokens[key] = serialized.Value
					elseif serialized.Type == "EnumItem" and serialized.EnumType == "Enum.Font" then
						tokens[key] = Enum.Font[serialized.Name]
					end
				end
			end
			if next(tokens) then
				ThemeManager.SetTheme(tokens)
			end
		end
	end

	for _, windowData in ipairs(data.Windows or {}) do
		for _, window in ipairs(NexusUI:GetAllWindows()) do
			if window.Name == windowData.Name and not window.Destroyed then
				if windowData.Position then
					window.Container.Position = UDim2.new(
						windowData.Position.X.Scale,
						windowData.Position.X.Offset,
						windowData.Position.Y.Scale,
						windowData.Position.Y.Offset
					)
				end

				if windowData.Size then
					window.Container.Size = UDim2.new(
						windowData.Size.X.Scale,
						windowData.Size.X.Offset,
						windowData.Size.Y.Scale,
						windowData.Size.Y.Offset
					)
				end

				if windowData.ActiveTab then
					window:SelectTab(windowData.ActiveTab)
				end

				local function findElements(container, out)
					for _, tab in ipairs(window.Tabs) do
						for _, section in ipairs(tab.Sections) do
							for _, element in ipairs(section.Elements or {}) do
								table.insert(out, element)
							end
						end
					end
				end

				local elements = {}
				findElements(window, elements)

				local function applyValues(list, className)
					if not list then
						return
					end
					for _, saved in ipairs(list) do
						for _, element in ipairs(elements) do
							if element.ClassName == className and element.Name == saved.Name then
								if className == "Toggle" or className == "Checkbox" then
									element:SetValue(saved.Value, true)
								elseif className == "Slider" then
									element:SetValue(saved.Value, true)
								elseif className == "Dropdown" then
									element:Select(saved.Value)
								end
								break
							end
						end
					end
				end

				applyValues(windowData.Toggles, "Toggle")
				applyValues(windowData.Sliders, "Slider")
				applyValues(windowData.Dropdowns, "Dropdown")
				applyValues(windowData.Checkboxes, "Checkbox")
			end
		end
	end

	return true
end

function Preset:DeletePreset(name)
	Preset.Presets[name] = nil
	return true
end

function Preset:ListPresets()
	local names = {}
	for name in pairs(Preset.Presets) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function Preset:ExportPreset(name)
	local data = Preset.Presets[name]
	if not data then
		return nil
	end

	local success, json = pcall(function()
		return HttpService:JSONEncode(data)
	end)

	if success then
		return json
	end

	return nil
end

function Preset:ImportPreset(name, json)
	local success, data = pcall(function()
		return HttpService:JSONDecode(json)
	end)

	if success and type(data) == "table" then
		Preset.Presets[name] = data
		return true
	end

	return false
end

function Preset:GetPreset(name)
	return Preset.Presets[name]
end

return Preset
]]
__MODULES["Services.Debug"] = [[local Debug = {}
Debug.__index = Debug

Debug.Enabled = false
Debug.Frame = nil
Debug.Root = nil
Debug.Connection = nil
Debug.UpdateInterval = 0.5

function Debug:CountConnections()
	local ok, Signal = pcall(function()
		return __require("Core.Signal")
	end)

	if ok and Signal then
		return Signal.GlobalConnections or 0
	end

	return 0
end

function Debug:CountComponents()
	local ok, Component = pcall(function()
		return __require("Core.Component")
	end)

	if ok and Component and Component.Count then
		return Component.Count()
	end

	return 0
end

function Debug:CountTweens()
	local ok, Animator = pcall(function()
		return __require("Animation.Animator")
	end)

	if ok and Animator and Animator.ActiveCount then
		return Animator.ActiveCount()
	end

	return 0
end

function Debug:CountSprings()
	local ok, Spring = pcall(function()
		return __require("Animation.Spring")
	end)

	if ok and Spring and Spring.Stats then
		local stats = Spring.Stats()
		return stats.Active or 0
	end

	return 0
end

function Debug:CountWindows()
	local ok, NexusUI = pcall(function()
		return __require("init")
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
]]
__MODULES["Services.Fluent"] = [[local Fluent = {}
Fluent.__index = Fluent

local function wrap(obj, methodNames)
	for _, name in ipairs(methodNames) do
		local original = obj[name]
		if type(original) == "function" then
			obj[name] = function(self, ...)
				local result = original(self, ...)
				if result == self then
					return self
				end
				return result or self
			end
		end
	end
	return obj
end

function Fluent.Apply(target, methodNames)
	if type(methodNames) == "table" then
		return wrap(target, methodNames)
	end
	return target
end

Fluent.Methods = {
	Button = { "SetText", "SetIcon", "SetVariant", "SetFullWidth", "SetVisible", "SetEnabled", "SetSize", "SetPosition", "SetZIndex", "SetLayoutOrder" },
	Toggle = { "SetValue", "SetText", "SetVisible", "SetEnabled", "SetSize", "SetPosition" },
	Slider = { "SetValue", "SetText", "SetRange", "SetStep", "SetSuffix", "SetVisible", "SetEnabled" },
	Dropdown = { "SetOptions", "Select", "SetText", "SetVisible", "SetEnabled" },
	Checkbox = { "SetValue", "SetText", "SetVisible", "SetEnabled" },
	TextBox = { "SetText", "SetPlaceholder", "SetNumericOnly", "SetMaxLength", "SetVisible", "SetEnabled" },
	Keybind = { "SetValue", "SetText", "SetMode", "SetVisible", "SetEnabled" },
	ColorPicker = { "SetColor", "SetText", "SetVisible", "SetEnabled" },
	MultiDropdown = { "SetSelected", "SetOptions", "Clear", "SetText", "SetVisible", "SetEnabled" },
	Label = { "SetText", "SetTextColor", "SetTextSize", "SetAlignment", "SetVisible" },
	Paragraph = { "SetText", "SetTitle", "SetVisible" },
	ProgressBar = { "SetValue", "SetText", "SetRange", "Increment", "Reset", "Complete", "SetVisible" },
	Badge = { "SetText", "SetVariant", "SetVisible" },
	Card = { "SetTitle", "SetDescription", "SetImage", "SetVisible" },
	Image = { "SetImage", "SetCaption", "SetScaleType", "SetVisible" },
	SearchBox = { "SetText", "Clear", "SetPlaceholder", "SetVisible", "SetEnabled" },
	Section = { "SetName", "SetCollapsed", "SetVisible" },
	Tab = { "SetName", "SetIcon", "SetBadge", "SetCompact", "SetVisible" },
	Window = { "SetTitle", "SetSubTitle", "SetBackgroundImage", "SetMobileMode", "Open", "Close", "Toggle", "SelectTab" },
	Modal = { "SetTitle", "SetMessage", "Open", "Close", "Dismiss" },
	Tooltip = { "SetText", "Show", "Hide" },
	LoadingIndicator = { "SetText", "SetSpeed", "Stop", "Start", "SetVisible" },
	ContextMenu = { "SetItems", "Open", "Close" },
	Toast = { "SetText", "Hide" },
	QuickActions = { "SetPosition" },
}

return Fluent
]]
__MODULES["Services.Welcome"] = [[local ThemeManager = __require("Theme.ThemeManager")
local BaseComponent = __require("Components.BaseComponent")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")
local Icons = __require("Core.Icons")

local Welcome = {}
Welcome.__index = Welcome

Welcome.Shown = false

local function getRoot()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	if not ok or parent == nil then
		parent = PlayerGui
	end

	local existing = parent:FindFirstChild("NexusUI_Welcome")
	if existing then
		return existing
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NexusUI_Welcome"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 800
	screenGui.Parent = parent

	return screenGui
end

function Welcome.new(options)
	options = options or {}

	local self = setmetatable({}, Welcome)
	self.Title = options.Title or "NexusUI"
	self.SubTitle = options.SubTitle or "Premium Interface Framework"
	self.Version = options.Version or "1.0.0"
	self.Duration = options.Duration or 3
	self.OnFinished = Signal.new()

	self._maid = Maid.new()

	self:Show()

	return self
end

function Welcome:Show()
	if Welcome.Shown then
		return self
	end

	Welcome.Shown = true
	local tokens = ThemeManager.GetTokens()

	local root = getRoot()

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = tokens.Background
	backdrop.BackgroundTransparency = 0
	backdrop.BorderSizePixel = 0
	backdrop.ZIndex = 800
	backdrop.Parent = root

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		backdrop.BackgroundColor3 = tk.Background
	end))

	local bgImage = Instance.new("ImageLabel")
	bgImage.Name = "BackgroundImage"
	bgImage.Size = UDim2.new(1, 0, 1, 0)
	bgImage.BackgroundTransparency = 1
	bgImage.Image = Icons.Assets.Background
	bgImage.ImageColor3 = tokens.Accent
	bgImage.ImageTransparency = 0.93
	bgImage.ScaleType = Enum.ScaleType.Crop
	bgImage.ZIndex = 801
	bgImage.Parent = backdrop

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		bgImage.ImageColor3 = tk.Accent
	end))

	local logoFrame = Instance.new("Frame")
	logoFrame.Name = "Logo"
	logoFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	logoFrame.Position = UDim2.new(0.5, 0, 0.5, -20)
	logoFrame.Size = UDim2.new(0, 72, 0, 72)
	logoFrame.BackgroundColor3 = tokens.Accent
	logoFrame.BackgroundTransparency = 0.85
	logoFrame.BorderSizePixel = 0
	logoFrame.ZIndex = 802
	logoFrame.Parent = backdrop

	UIUtils.Corner(logoFrame, tokens.CornerLarge)
	UIUtils.Stroke(logoFrame, tokens.Accent, 1.5, 0.3)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		logoFrame.BackgroundColor3 = tk.Accent
	end))

	local logo = Instance.new("ImageLabel")
	logo.Name = "Icon"
	logo.Size = UDim2.new(0, 40, 0, 40)
	logo.Position = UDim2.new(0.5, 0, 0.5, 0)
	logo.AnchorPoint = Vector2.new(0.5, 0.5)
	logo.BackgroundTransparency = 1
	logo.Image = Icons.Assets.Background
	logo.ImageColor3 = tokens.Accent
	logo.ZIndex = 803
	logo.Parent = logoFrame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		logo.ImageColor3 = tk.Accent
	end))

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.AnchorPoint = Vector2.new(0.5, 0)
	titleLabel.Position = UDim2.new(0.5, 0, 0.5, 30)
	titleLabel.Size = UDim2.new(1, 0, 0, 32)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = tokens.FontBold
	titleLabel.Text = self.Title
	titleLabel.TextColor3 = tokens.Text
	titleLabel.TextSize = 28
	titleLabel.TextTransparency = 1
	titleLabel.ZIndex = 802
	titleLabel.Parent = backdrop

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		titleLabel.Font = tk.FontBold
		titleLabel.TextColor3 = tk.Text
	end))

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubTitle"
	subtitleLabel.AnchorPoint = Vector2.new(0.5, 0)
	subtitleLabel.Position = UDim2.new(0.5, 0, 0.5, 66)
	subtitleLabel.Size = UDim2.new(1, 0, 0, 18)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font = tokens.Font
	subtitleLabel.Text = self.SubTitle .. "  |  v" .. self.Version
	subtitleLabel.TextColor3 = tokens.SecondaryText
	subtitleLabel.TextSize = 14
	subtitleLabel.TextTransparency = 1
	subtitleLabel.ZIndex = 802
	subtitleLabel.Parent = backdrop

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		subtitleLabel.Font = tk.Font
		subtitleLabel.TextColor3 = tk.SecondaryText
	end))

	local scale = UIUtils.Scale(logoFrame, 0.5)

	Animator.Tween(scale, { Scale = 1 }, 0.5, "Back")
	Animator.Tween(logoFrame, { BackgroundTransparency = 0.85 }, 0.5, "Quart")

	task.delay(0.25, function()
		Animator.Tween(titleLabel, { TextTransparency = 0 }, 0.4, "Quart")
		Animator.Tween(subtitleLabel, { TextTransparency = 0 }, 0.4, "Quart")
	end)

	task.delay(self.Duration, function()
		Animator.Tween(titleLabel, { TextTransparency = 1 }, 0.3, "Quad")
		Animator.Tween(subtitleLabel, { TextTransparency = 1 }, 0.3, "Quad")
		Animator.Tween(logoFrame, { BackgroundTransparency = 1 }, 0.3, "Quad")
		Animator.Tween(bgImage, { ImageTransparency = 1 }, 0.3, "Quad")

		task.delay(0.35, function()
			backdrop:Destroy()
			Welcome.Shown = false
			self.OnFinished:Fire()
			self._maid:Destroy()
		end)
	end)

	return self
end

function Welcome:Destroy()
	if self._maid then
		self._maid:Destroy()
	end
	Welcome.Shown = false
end

return Welcome
]]
__MODULES["Services.KeySystem"] = [[local ThemeManager = __require("Theme.ThemeManager")
local Maid = __require("Core.Maid")
local Signal = __require("Core.Signal")
local UIUtils = __require("Utilities.UIUtils")
local Animator = __require("Animation.Animator")
local Sound = __require("Utilities.Sound")
local Icons = __require("Core.Icons")

local KeySystem = {}
KeySystem.__index = KeySystem

KeySystem.Shown = false

local function getRoot()
	local CoreGui = game:GetService("CoreGui")
	local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

	local ok, parent = pcall(function()
		return CoreGui
	end)

	if not ok or parent == nil then
		parent = PlayerGui
	end

	local existing = parent:FindFirstChild("NexusUI_KeySystem")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NexusUI_KeySystem"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 700
	screenGui.Parent = parent

	return screenGui
end

function KeySystem.new(options)
	options = options or {}

	local self = setmetatable({}, KeySystem)
	self.Title = options.Title or "Key Verification"
	self.SubTitle = options.SubTitle or "Enter your access key to continue"
	self.Icon = options.Icon or Icons.Assets.Settings
	self.Validate = options.Validate or function(key)
		return key == options.Key
	end
	self.OnValidated = options.OnValidated or function() end
	self.OnFailed = options.OnFailed or function() end
	self.MaxAttempts = options.MaxAttempts or 3
	self.SaveKey = options.SaveKey

	self.Attempts = 0
	self.OnAttempt = Signal.new()

	self._maid = Maid.new()

	self:Show()

	return self
end

function KeySystem:Show()
	local tokens = ThemeManager.GetTokens()

	local root = getRoot()

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = tokens.Background
	backdrop.BackgroundTransparency = 0
	backdrop.BorderSizePixel = 0
	backdrop.ZIndex = 700
	backdrop.Parent = root

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		backdrop.BackgroundColor3 = tk.Background
	end))

	local bgImage = Instance.new("ImageLabel")
	bgImage.Name = "BG"
	bgImage.Size = UDim2.new(1, 0, 1, 0)
	bgImage.BackgroundTransparency = 1
	bgImage.Image = Icons.Assets.Background
	bgImage.ImageColor3 = tokens.Accent
	bgImage.ImageTransparency = 0.92
	bgImage.ScaleType = Enum.ScaleType.Crop
	bgImage.ZIndex = 701
	bgImage.Parent = backdrop

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		bgImage.ImageColor3 = tk.Accent
	end))

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.Size = UDim2.new(0, 380, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = tokens.Surface
	card.BackgroundTransparency = 0.04
	card.BorderSizePixel = 0
	card.ZIndex = 702
	card.Parent = backdrop

	UIUtils.Corner(card, tokens.CornerLarge)
	UIUtils.Stroke(card, tokens.BorderLight, 1, 0.45)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		card.BackgroundColor3 = tk.Surface
	end))

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 22)
	padding.PaddingRight = UDim.new(0, 22)
	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 20)
	padding.Parent = card

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 12)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = card

	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "IconFrame"
	iconFrame.Size = UDim2.new(0, 56, 0, 56)
	iconFrame.BackgroundColor3 = tokens.Accent
	iconFrame.BackgroundTransparency = 0.85
	iconFrame.BorderSizePixel = 0
	iconFrame.LayoutOrder = 1
	iconFrame.ZIndex = 703
	iconFrame.Parent = card

	UIUtils.Corner(iconFrame, tokens.CornerLarge)

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 30, 0, 30)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = self.Icon
	icon.ImageColor3 = tokens.Accent
	icon.ZIndex = 704
	icon.Parent = iconFrame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		icon.ImageColor3 = tk.Accent
	end))

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 22)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = tokens.FontBold
	titleLabel.Text = self.Title
	titleLabel.TextColor3 = tokens.Text
	titleLabel.TextSize = 18
	titleLabel.LayoutOrder = 2
	titleLabel.ZIndex = 703
	titleLabel.Parent = card

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		titleLabel.Font = tk.FontBold
		titleLabel.TextColor3 = tk.Text
	end))

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubTitle"
	subtitleLabel.Size = UDim2.new(1, 0, 0, 16)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Font = tokens.Font
	subtitleLabel.Text = self.SubTitle
	subtitleLabel.TextColor3 = tokens.SecondaryText
	subtitleLabel.TextSize = 12
	subtitleLabel.LayoutOrder = 3
	subtitleLabel.ZIndex = 703
	subtitleLabel.Parent = card

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		subtitleLabel.Font = tk.Font
		subtitleLabel.TextColor3 = tk.SecondaryText
	end))

	local inputFrame = Instance.new("Frame")
	inputFrame.Name = "InputFrame"
	inputFrame.Size = UDim2.new(1, 0, 0, 40)
	inputFrame.BackgroundColor3 = tokens.Background
	inputFrame.BackgroundTransparency = 0.2
	inputFrame.BorderSizePixel = 0
	inputFrame.LayoutOrder = 4
	inputFrame.ZIndex = 703
	inputFrame.Parent = card

	UIUtils.Corner(inputFrame, tokens.CornerSmall)
	self.InputStroke = UIUtils.Stroke(inputFrame, tokens.Border, 1, 0.6)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		inputFrame.BackgroundColor3 = tk.Background
	end))

	self.Input = Instance.new("TextBox")
	self.Input.Name = "KeyInput"
	self.Input.Size = UDim2.new(1, -20, 1, 0)
	self.Input.Position = UDim2.new(0, 10, 0, 0)
	self.Input.BackgroundTransparency = 1
	self.Input.Font = tokens.Font
	self.Input.Text = ""
	self.Input.PlaceholderText = "Enter key..."
	self.Input.PlaceholderColor3 = tokens.MutedText
	self.Input.TextColor3 = tokens.Text
	self.Input.TextSize = 14
	self.Input.ClearTextOnFocus = false
	self.Input.ZIndex = 704
	self.Input.Parent = inputFrame

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.Input.Font = tk.Font
		self.Input.TextColor3 = tk.Text
		self.Input.PlaceholderColor3 = tk.MutedText
	end))

	self.SubmitButton = Instance.new("TextButton")
	self.SubmitButton.Name = "Submit"
	self.SubmitButton.Size = UDim2.new(1, 0, 0, 38)
	self.SubmitButton.BackgroundColor3 = tokens.Accent
	self.SubmitButton.BackgroundTransparency = 0
	self.SubmitButton.BorderSizePixel = 0
	self.SubmitButton.AutoButtonColor = false
	self.SubmitButton.Font = tokens.FontBold
	self.SubmitButton.Text = "Verify"
	self.SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	self.SubmitButton.TextSize = 14
	self.SubmitButton.LayoutOrder = 5
	self.SubmitButton.ZIndex = 703
	self.SubmitButton.Parent = card

	UIUtils.Corner(self.SubmitButton, tokens.CornerSmall)

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.SubmitButton.BackgroundColor3 = tk.Accent
		self.SubmitButton.Font = tk.FontBold
	end))

	self.StatusLabel = Instance.new("TextLabel")
	self.StatusLabel.Name = "Status"
	self.StatusLabel.Size = UDim2.new(1, 0, 0, 16)
	self.StatusLabel.BackgroundTransparency = 1
	self.StatusLabel.Font = tokens.Font
	self.StatusLabel.Text = ""
	self.StatusLabel.TextColor3 = tokens.Error
	self.StatusLabel.TextSize = 12
	self.StatusLabel.LayoutOrder = 6
	self.StatusLabel.ZIndex = 703
	self.StatusLabel.Parent = card

	self._maid:GiveTask(UIUtils.BindTheme(function(_, tk)
		self.StatusLabel.Font = tk.Font
	end))

	local scale = UIUtils.Scale(card, 0.9)
	Animator.Tween(scale, { Scale = 1 }, 0.4, "Back")
	Animator.Tween(card, { BackgroundTransparency = 0.04 }, 0.3, "Quart")

	self.SubmitButton.MouseEnter:Connect(function()
		Animator.Tween(self.SubmitButton, { BackgroundTransparency = 0.15 }, 0.15, "Quad")
	end)

	self.SubmitButton.MouseLeave:Connect(function()
		Animator.Tween(self.SubmitButton, { BackgroundTransparency = 0 }, 0.15, "Quad")
	end)

	local selfRef = self

	self.SubmitButton.MouseButton1Click:Connect(function()
		selfRef:_submit()
	end)

	self.Input.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			selfRef:_submit()
		end
	end)

	self.Input.Focused:Connect(function()
		Animator.Tween(self.InputStroke, { Color = ThemeManager.GetTokens().Accent, Transparency = 0.1 }, 0.18, "Quad")
	end)

	self.Card = card
	self.Backdrop = backdrop
	self.RootGui = root

	return self
end

function KeySystem:_submit()
	local key = self.Input.Text

	if key == "" then
		self.StatusLabel.Text = "Please enter a key"
		self.StatusLabel.TextColor3 = ThemeManager.GetTokens().Warning
		Sound.Error()
		return
	end

	self.Attempts = self.Attempts + 1
	self.OnAttempt:Fire(self.Attempts, self.MaxAttempts)

	local tokens = ThemeManager.GetTokens()
	self.SubmitButton.Text = "Verifying..."
	self.SubmitButton.BackgroundTransparency = 0.3

	task.wait(0.4)

	local success, result = pcall(self.Validate, key)

	self.SubmitButton.Text = "Verify"
	self.SubmitButton.BackgroundTransparency = 0

	if success and result then
		self.StatusLabel.Text = "Key verified!"
		self.StatusLabel.TextColor3 = tokens.Success
		Sound.Success()

		Animator.Tween(self.Card, { BackgroundTransparency = 0.6 }, 0.3, "Quad")
		task.delay(0.4, function()
			self:_close()
			pcall(self.OnValidated)
		end)
	else
		local remaining = self.MaxAttempts - self.Attempts
		self.StatusLabel.Text = remaining > 0 and ("Invalid key. Attempts remaining: " .. remaining) or "Too many attempts"
		self.StatusLabel.TextColor3 = tokens.Error
		Sound.Error()

		Animator.Tween(self.Card, { Position = self.Card.Position + UDim2.new(0, 8, 0, 0) }, 0.05, "Quad")
		task.delay(0.05, function()
			Animator.Tween(self.Card, { Position = self.Card.Position - UDim2.new(0, 16, 0, 0) }, 0.05, "Quad")
			task.delay(0.05, function()
				Animator.Tween(self.Card, { Position = self.Card.Position + UDim2.new(0, 8, 0, 0) }, 0.15, "Quad")
			end)
		end)

		if remaining <= 0 then
			task.delay(0.6, function()
				self:_close()
				pcall(self.OnFailed)
			end)
		end
	end
end

function KeySystem:_close()
	if self.Backdrop then
		Animator.Tween(self.Card, { BackgroundTransparency = 1 }, 0.25, "Quad")
		task.delay(0.3, function()
			if self.RootGui then
				self.RootGui:Destroy()
			end
			self._maid:Destroy()
			KeySystem.Shown = false
		end)
	end
end

function KeySystem:Destroy()
	if self.RootGui then
		self.RootGui:Destroy()
	end
	if self._maid then
		self._maid:Destroy()
	end
	KeySystem.Shown = false
end

return KeySystem
]]
__MODULES["Demo.Demo"] = [[local NexusUI = __require("")
local Icons = __require("Core.Icons")

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
			local Welcome = __require("Services.Welcome")
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
			local CommandPalette = __require("Services.CommandPalette")
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
			local Debug = __require("Services.Debug")
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
]]
__MODULES["init"] = [[local Config = __require("Core.Config")
local ThemeManager = __require("Theme.ThemeManager")

local NexusUI = {}

NexusUI.Version = "1.0.0"
NexusUI.Author = "NexusUI Team"
NexusUI.Repository = "https://github.com/NexusUI1"

NexusUI.Config = Config
NexusUI.Themes = ThemeManager
NexusUI._windows = {}
NexusUI._started = false

local function applyDefaultThemes()
	local DefaultTheme = __require("Theme.DefaultTheme")
	for name, tokens in pairs(DefaultTheme) do
		if type(tokens) == "table" and name ~= "Apply" and type(name) == "string" then
			ThemeManager.RegisterTheme(name, tokens)
		end
	end
end

function NexusUI:CreateWindow(options)
	options = options or {}

	local WindowModule = __require("Components.Window")
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
	local NotificationSystem = __require("Services.NotificationSystem")
	return NotificationSystem:Notify(options)
end

function NexusUI:Success(title, description, duration)
	local NotificationSystem = __require("Services.NotificationSystem")
	return NotificationSystem:Success(title, description, duration)
end

function NexusUI:Error(title, description, duration)
	local NotificationSystem = __require("Services.NotificationSystem")
	return NotificationSystem:Error(title, description, duration)
end

function NexusUI:Warning(title, description, duration)
	local NotificationSystem = __require("Services.NotificationSystem")
	return NotificationSystem:Warning(title, description, duration)
end

function NexusUI:Info(title, description, duration)
	local NotificationSystem = __require("Services.NotificationSystem")
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
	local Modal = __require("Components.Modal")
	return Modal.new(options)
end

function NexusUI:CreateDialog(title, message, onConfirm)
	local Modal = __require("Components.Modal")
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
	local Toast = __require("Components.Toast")
	return Toast.new({
		Text = text,
		Duration = (options and options.Duration) or 2,
		Position = (options and options.Position) or "BottomCenter",
		Variant = (options and options.Variant) or "Dark",
	})
end

function NexusUI:CreateContextMenu(items)
	local ContextMenu = __require("Components.ContextMenu")
	local menu = ContextMenu.new({ Items = items })
	menu:Open()
	return menu
end

function NexusUI:CreateTooltip(text, target)
	local Tooltip = __require("Components.Tooltip")
	return Tooltip.new({
		Text = text,
		Target = target,
	})
end

function NexusUI:CreateQuickActions(options)
	local QuickActions = __require("Components.QuickActions")
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

	local Device = __require("Core.Device")
	Device.Start()

	ThemeManager.SetTheme(Config.Theme or "Midnight")

	local NotificationSystem = __require("Services.NotificationSystem")
	NotificationSystem:GetContainer()

	return self
end

function NexusUI:LaunchDemo()
	if self._demoLaunched then
		return nil
	end

	self._demoLaunched = true

	local Demo = __require("Demo.Demo")
	return Demo:Run()
end

function NexusUI:Destroy()
	self:DestroyAllWindows()

	local NotificationSystem = __require("Services.NotificationSystem")
	NotificationSystem:Destroy()

	self._started = false
end

applyDefaultThemes()

return NexusUI
]]

local function __require(key)
	if __CACHE[key] then
		return __CACHE[key]
	end

	local source = __MODULES[key]
	if not source then
		error("[NexusUI] Module not found: " .. tostring(key), 2)
	end

	local fn, loadErr = loadstring(source, "=" .. key)
	if not fn then
		error("[NexusUI] Failed to load module " .. tostring(key) .. ": " .. tostring(loadErr), 2)
	end

	local module = fn()
	__CACHE[key] = module

	return module
end

local NexusUI = __require("init")

NexusUI.__require = __require

if getgenv then
	getgenv().NexusUI = NexusUI
elseif _G then
	_G.NexusUI = NexusUI
end

return NexusUI