local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local BaseComponent = require(script.Parent.BaseComponent)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)

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
