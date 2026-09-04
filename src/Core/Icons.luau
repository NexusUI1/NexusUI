local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)

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
