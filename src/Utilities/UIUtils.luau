local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)

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
