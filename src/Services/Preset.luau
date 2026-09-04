local HttpService = game:GetService("HttpService")

local Preset = {}
Preset.__index = Preset

Preset.Presets = {}

function Preset:SavePreset(name)
	assert(type(name) == "string", "Preset name must be a string")

	local NexusUI = require(script.Parent.Parent.init)
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

	local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
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

	local NexusUI = require(script.Parent.Parent.init)
	local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)

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
