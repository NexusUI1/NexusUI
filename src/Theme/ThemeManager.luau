local ThemeManager = {}
ThemeManager.__index = ThemeManager

local Tokens = require(script.Parent.DefaultTheme)

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
