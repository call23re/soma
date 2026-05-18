local input = require("./input")
local binding = require("./binding")
local context = require("./context")
local types = require("./types")

export type ActionState = {
	read Pressed: { [Enum.KeyCode]: boolean },
	read Pressing: { [Enum.KeyCode]: boolean },
	read Released: { [Enum.KeyCode]: boolean },
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
}

type Private = {
	bindings: { binding.Binding },
	activated_bindings: { binding.Binding },
	contexts: { [context.Context]: boolean },
	cooldown_duration: number,
	elapsed: number,
	activated: boolean,
	pressed: { [Enum.KeyCode]: boolean },
	pressing: { [Enum.KeyCode]: boolean },
	released: { [Enum.KeyCode]: boolean },
	press_called: boolean,
	erase_press: boolean,
	last_action_event: ActionEvent?,
	subscriptions: { [SubscriptionCallback]: SubscriptionCallback },
	enabled: boolean,
}

local function action(name: string)
	local self = {
		Name = name,
	} :: Action

	local private = {
		bindings = {},
		activated_bindings = {},
		contexts = {},
		cooldown_duration = 0,
		elapsed = 0,
		activated = false,
		pressed = {},
		pressing = {},
		released = {},
		press_called = false,
		erase_press = true,
		last_action_event = nil,
		subscriptions = {},
		enabled = true,
	} :: Private

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
						table.insert(private.bindings, binding.as_binding(next_binding))
					end
				end
				continue
			elseif binding_option.Type == "BINDING" or binding_option.Type == "INPUT" then
				table.insert(private.bindings, binding.as_binding(binding_option))
			end
		end
		return self
	end

	self.unbind = function(_, bind: binding.Binding): Action
		local index = table.find(private.bindings, bind)
		if index then
			table.remove(private.bindings, index)
		end
		return self
	end

	self.context = function(_, ...: context.Context?): Action
		for _, next_context in { ... } do
			private.contexts[next_context] = true
		end
		return self
	end

	self.cooldown = function(_, cooldown: number): Action
		private.cooldown_duration = cooldown
		private.elapsed = cooldown
		return self
	end

	self.read = function()
		return table.freeze({
			Pressed = private.pressed,
			Pressing = private.pressing,
			Released = private.released,
		})
	end

	self.activated = function(): boolean
		return private.activated
	end

	self.bindings = function()
		return private.activated_bindings
	end

	self.names = function()
		local names = {}
		for _, active_binding in private.activated_bindings do
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
		private.enabled = true
		return self
	end

	self.disable = function(): Action
		private.enabled = false
		return self
	end

	self.press = function(): () -> ()
		private.press_called = true
		private.erase_press = false
		return function()
			private.erase_press = true
		end
	end

	self.press_once = function()
		private.press_called = true
		private.erase_press = true
	end

	self.subscribe = function(_, cb: SubscriptionCallback)
		private.subscriptions[cb] = cb
	end

	self.unsubscribe = function(_, cb: SubscriptionCallback)
		if private.subscriptions[cb] then
			private.subscriptions[cb] = nil
		end
	end

	self.update = function(map: { [Enum.KeyCode]: types.InputEvent }, dt: number)
		table.clear(private.activated_bindings)
		table.clear(private.pressed)
		table.clear(private.pressing)
		private.activated = private.press_called

		if private.erase_press then
			private.press_called = false
		end

		if not private.enabled then
			return
		end

		local any_contexts_enabled = false
		for next_context in private.contexts do
			if next_context.Enabled then
				any_contexts_enabled = true
			end
		end
		if not any_contexts_enabled then
			return
		end

		private.elapsed += dt or 0
		if private.elapsed < private.cooldown_duration then
			if private.last_action_event and private.last_action_event.Active ~= private.activated then
				for _, subscription in private.subscriptions do
					subscription({ Active = false, ActionState = self:read() }, private.last_action_event)
				end
			end
			return
		end

		local activated = private.activated
		for _, bind in private.bindings do
			local matches, any_match = bind:matches(map)
			if any_match then
				table.insert(private.activated_bindings, bind)
				activated = true
			end
			for match in matches do
				local input_event = map[match]
				if input_event.Event == "BEGAN" then
					private.pressed[match] = true
				elseif input_event.Event == "CHANGED" then
					private.pressing[match] = true
				elseif input_event.Event == "ENDED" then
					private.released[match] = true
				end
				-- TODO: handle delta
			end
		end

		if activated then
			private.elapsed = 0
		end

		if private.activated ~= activated then
			local action_event = { Active = false, ActionState = self:read() }
			for _, subscription in private.subscriptions do
				subscription(action_event, private.last_action_event)
			end
			private.last_action_event = action_event
		end

		private.activated = activated
	end

	return self
end

return action
