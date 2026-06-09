local input = require("./input")
local types = require("./types")
local map = require("./map")

export type SubscriptionCallback = (cur: { map.InputCode }, prev: { map.InputCode }?) -> ()

export type Binding = {
	Inputs: { input.Input },
	Name: string?,
	Type: "BINDING",
	Operator: types.Operator,
	named: (Binding, string) -> Binding,
	matches: (Binding, { [Enum.KeyCode]: types.InputEvent }) -> ({ [Enum.KeyCode]: boolean }, boolean, boolean),
	press: (Binding) -> () -> (),
	press_once: (Binding) -> (),
	activated: (Binding) -> boolean,
	read: (Binding) -> { [Enum.KeyCode]: boolean },
	subscribe: (Binding, SubscriptionCallback) -> (),
	unsubscribe: (Binding, SubscriptionCallback) -> (),
	clone: (Binding) -> Binding,
}

type Private = {
	activated: boolean,
	press_called: boolean,
	erase_press: boolean,
	read: { [Enum.KeyCode]: boolean },
	subscriptions: { [SubscriptionCallback]: SubscriptionCallback },
	last_event_state: { map.InputCode }?,
}

local function binding(...: Binding | input.Input): Binding
	local self = {
		Name = nil,
		Inputs = { ... },
		Type = "BINDING",
		Operator = "ANY",
	} :: Binding

	local private = {
		activated = false,
		press_called = false,
		erase_press = true,
		read = {},
		subscriptions = {},
		last_event_state = {},
	} :: Private

	self.named = function(_, name)
		self.Name = name
		return self
	end

	self.matches = function(_, key_map)
		local matches, any_match, all_match = {}, false, true

		for _, next_input in self.Inputs do
			local matches_res, any_match_res, all_match_res = next_input:matches(key_map)

			if (any_match_res and next_input.Operator == "ANY") or (all_match_res and next_input.Operator == "ALL") then
				any_match = true
			else
				all_match = false
			end

			for match in matches_res do
				matches[match] = true
			end
		end

		if private.press_called then
			any_match = true
			all_match = true
		end

		if private.erase_press then
			private.press_called = false
		end

		private.activated = if self.Operator == "ANY" then any_match else all_match
		private.read = matches

		return matches, any_match, if not any_match then false else all_match
	end

	self.press = function()
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

	self.activated = function()
		return private.activated
	end

	self.read = function()
		return private.read
	end

	self.subscribe = function(_, cb)
		private.subscriptions[cb] = cb
	end

	self.unsubscribe = function(_, cb)
		if private.subscriptions[cb] then
			private.subscriptions[cb] = nil
		end
	end

	self.clone = function()
		local copy = binding()
		copy.Operator = self.Operator
		for _, input in self.Inputs do
			table.insert(copy.Inputs, input:clone())
		end
		return copy
	end

	return self
end

local function as_binding(input_option: input.Input | Binding): Binding
	if input_option.Type == "BINDING" then
		return input_option
	end
	return binding(input_option)
end

return {
	binding = binding,
	as_binding = as_binding,
}
