local ThemeManager = require(script.Parent.Parent.Theme.ThemeManager)
local Maid = require(script.Parent.Parent.Core.Maid)
local Signal = require(script.Parent.Parent.Core.Signal)
local UIUtils = require(script.Parent.Parent.Utilities.UIUtils)
local Animator = require(script.Parent.Parent.Animation.Animator)

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
