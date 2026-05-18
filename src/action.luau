local input = require("./input")
local binding = require("./binding")
local context = require("./context")
local types = require("./types")

export type ActionState = {
	read Pressed: { [Enum.KeyCode]: boolean },
	read Pressing: { [Enum.KeyCode]: boolean },
	read Released: { [Enum.KeyCode]: boolean },
	read LookDelta: Vector2,
}

export type ActionEvent = {
	Active: boolean,
	ActionState: ActionState,
}

export type SubscriptionCallback = (cur: ActionEvent, prev: ActionEvent?) -> ()

export type Action = {
	Name: string?,
	bind: (Action, ...(input.Input | binding.Binding | { input.Input | binding.Binding })) -> Action,
	unbind: (Action, binding.Binding) -> Action,
	context: (Action, ...context.Context?) -> Action,
	cooldown: (Action, number) -> Action,
	read: (Action) -> ActionState,
	activated: (Action) -> boolean,
	bindings: (Action) -> { binding.Binding },
	names: (Action) -> { string },
	named: (Action, string) -> Action,
	enable: (Action) -> Action,
	disable: (Action) -> Action,
	press: (Action) -> () -> (),
	press_once: (Action) -> (),
	subscribe: (Action, SubscriptionCallback) -> (),
	unsubscribe: (Action, SubscriptionCallback) -> (),
	update: (queue: { [Enum.KeyCode]: types.InputEvent }, delta: number) -> (),
	_bindings: { binding.Binding },
	_activated_bindings: { binding.Binding },
	_contexts: { [context.Context]: boolean },
	_cooldown_duration: number,
	_elapsed: number,
	_activated: boolean,
	_pressed: { [Enum.KeyCode]: boolean },
	_pressing: { [Enum.KeyCode]: boolean },
	_released: { [Enum.KeyCode]: boolean },
	_look_delta: Vector2,
	_press_called: boolean,
	_erase_press: boolean,
	_last_action_event: ActionEvent?,
	_subscriptions: { [SubscriptionCallback]: SubscriptionCallback },
	_enabled: boolean,
}

local function action(name: string)
	local self = {
		Name = name,
		_bindings = {},
		_activated_bindings = {},
		_contexts = {},
		_cooldown_duration = 0,
		_elapsed = 0,
		_activated = false,
		_pressed = {},
		_pressing = {},
		_released = {},
		_look_delta = Vector2.zero,
		_press_called = false,
		_erase_press = true,
		_last_action_event = nil,
		_subscriptions = {},
		_enabled = true,
	} :: Action

	self.bind = function(_, ...: input.Input | binding.Binding | { input.Input | binding.Binding }): Action
		for _, binding_option in { ... } do
			if typeof(binding_option) ~= "table" then
				continue
			end
			-- TODO: this cast is misleading
			binding_option = binding_option :: input.Input | binding.Binding

			if binding_option.Type == nil then
				for _, next_binding: input.Input in binding_option do
					if next_binding.Type == "BINDING" or next_binding.Type == "INPUT" then
						table.insert(self._bindings, binding.as_binding(next_binding))
					end
				end
				continue
			elseif binding_option.Type == "BINDING" or binding_option.Type == "INPUT" then
				table.insert(self._bindings, binding.as_binding(binding_option))
			end
		end
		return self
	end

	self.unbind = function(_, bind: binding.Binding): Action
		local index = table.find(self._bindings, bind)
		if index then
			table.remove(self._bindings, index)
		end
		return self
	end

	self.context = function(_, ...: context.Context?): Action
		for _, next_context in { ... } do
			self._contexts[next_context] = true
		end
		return self
	end

	self.cooldown = function(_, cooldown: number): Action
		self._cooldown_duration = cooldown
		self._elapsed = cooldown
		return self
	end

	self.read = function()
		return table.freeze({
			Pressed = self._pressed,
			Pressing = self._pressing,
			Released = self._released,
			LookDelta = self._look_delta,
		})
	end

	self.activated = function(): boolean
		return self._activated
	end

	self.bindings = function()
		return self._activated_bindings
	end

	self.names = function()
		local names = {}
		for _, active_binding in self._activated_bindings do
			if active_binding.Name then
				table.insert(names, active_binding.Name)
			end
		end
		return names
	end

	self.named = function(_, name: string)
		self.Name = name
		return self
	end

	self.enable = function(): Action
		self._enabled = true
		return self
	end

	self.disable = function(): Action
		self._enabled = false
		return self
	end

	self.press = function(): () -> ()
		self._press_called = true
		self._erase_press = false
		return function()
			self._erase_press = true
		end
	end

	self.press_once = function()
		self._press_called = true
		self._erase_press = true
	end

	self.subscribe = function(_, cb: SubscriptionCallback)
		self._subscriptions[cb] = cb
	end

	self.unsubscribe = function(_, cb: SubscriptionCallback)
		if self._subscriptions[cb] then
			self._subscriptions[cb] = nil
		end
	end

	self.update = function(map: { [Enum.KeyCode]: types.InputEvent }, dt: number)
		table.clear(self._activated_bindings)
		table.clear(self._pressed)
		table.clear(self._pressing)
		self._activated = self._press_called

		if self._erase_press then
			self._press_called = false
		end

		if not self._enabled then
			return
		end

		local any_contexts_enabled = false
		for next_context in self._contexts do
			if next_context.Enabled then
				any_contexts_enabled = true
			end
		end
		if not any_contexts_enabled then
			return
		end

		self._elapsed += dt or 0
		if self._elapsed < self._cooldown_duration then
			if self._last_action_event and self._last_action_event.Active ~= self._activated then
				for _, subscription in self._subscriptions do
					subscription({ Active = false, ActionState = self:read() }, self._last_action_event)
				end
			end
			return
		end

		local activated = self._activated
		for _, bind in self._bindings do
			local matches, any_match = bind:matches(map)
			if any_match then
				table.insert(self._activated_bindings, bind)
				activated = true
			end
			for match in matches do
				local input_event = map[match]
				if input_event.Event == "BEGAN" then
					self._pressed[match] = true
				elseif input_event.Event == "CHANGED" then
					self._pressing[match] = true
				elseif input_event.Event == "ENDED" then
					self._released[match] = true
				end
				-- TODO: handle delta
			end
		end

		if activated then
			self._elapsed = 0
		end

		if self._activated ~= activated then
			local action_event = { Active = false, ActionState = self:read() }
			for _, subscription in self._subscriptions do
				subscription(action_event, self._last_action_event)
			end
			self._last_action_event = action_event
		end

		self._activated = activated
	end

	return self
end

return action
