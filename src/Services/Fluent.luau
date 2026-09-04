local Fluent = {}
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
