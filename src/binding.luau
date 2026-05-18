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
	activated: (Binding) -> boolean,
	read: (Binding) -> { [Enum.KeyCode]: boolean },
	subscribe: (Binding, SubscriptionCallback) -> (),
	unsubscribe: (Binding, SubscriptionCallback) -> (),
	clone: (Binding) -> Binding,
	_activated: boolean,
	_read: { [Enum.KeyCode]: boolean },
	_subscriptions: { [SubscriptionCallback]: SubscriptionCallback },
	_last_event_state: { map.InputCode }?,
}

local function binding(...: Binding | input.Input): Binding
	local self = {
		Inputs = { ... },
		Type = "BINDING",
		Operator = "ANY",
		_activated = false,
		_read = {},
		_subscriptions = {},
		_last_event_state = {},
	} :: Binding

	self.named = function(_, name: string)
		self.Name = name
		return self
	end

	self.matches = function(
		_,
		map: { [Enum.KeyCode]: types.InputEvent }
	): ({ [Enum.KeyCode]: boolean }, boolean, boolean)
		local matches, any_match, all_match = {}, false, true
		for _, next_input in self.Inputs do
			local matches_res, any_match_res, all_match_res = next_input:matches(map)
			if (any_match_res and next_input.Operator == "ANY") or (all_match_res and next_input.Operator == "ALL") then
				any_match = true
			else
				all_match = false
			end
			for match in matches_res do
				matches[match] = true
			end
		end
		self._activated = if self.Operator == "ANY" then any_match else all_match
		self._read = matches
		return matches, any_match, if not any_match then false else all_match
	end

	self.activated = function()
		return self._activated
	end

	self.read = function()
		return self._read
	end

	self.subscribe = function(_, cb: SubscriptionCallback)
		self._subscriptions[cb] = cb
	end

	self.unsubscribe = function(_, cb: SubscriptionCallback)
		if self._subscriptions[cb] then
			self._subscriptions[cb] = nil
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

	return self :: Binding
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
