local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Maid = require(script.Parent.Maid)

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
