local ThemeManager = require(script.Parent.ThemeManager)

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
	local ThemeManager = require(script.Parent.ThemeManager)
	for name, tokens in pairs(t or DefaultTheme) do
		if type(tokens) == "table" and name ~= "Apply" then
			ThemeManager.RegisterTheme(name, tokens)
		end
	end
end

return DefaultTheme
