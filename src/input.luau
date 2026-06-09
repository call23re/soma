local map = require("./map")
local types = require("./types")

export type InputKind = "Key" | "Gamepad" | "Mouse" | "Touch"
export type Activator = "PRESSING" | "PRESSED" | "RELEASED" | "NONE"

export type SubscriptionCallback = (cur: { map.InputCode }, prev: { map.InputCode }?) -> ()

export type Input = {
	Kind: InputKind,
	InputCodes: { map.InputCode },
	Operator: types.Operator,
	Activator: Activator,
	Type: "INPUT",
	set: (Input, ...map.InputCode) -> Input,
	add: (Input, ...map.InputCode) -> Input,
	remove: (Input, ...map.InputCode) -> Input,
	matches: (Input, { [Enum.KeyCode]: types.InputEvent }) -> ({ [Enum.KeyCode]: boolean }, boolean, boolean),
	press: (Input) -> () -> (),
	press_once: (Input) -> (),
	activated: (Input) -> boolean,
	read: (Input) -> { [Enum.KeyCode]: boolean },
	subscribe: (Input, SubscriptionCallback) -> (),
	unsubscribe: (Input, SubscriptionCallback) -> (),
	clone: (Input) -> Input,
}

type Private = {
	activated: boolean,
	press_called: boolean,
	erase_press: boolean,
	input_code_map: { [map.InputCode]: boolean },
	read: { [Enum.KeyCode]: boolean },
	subscriptions: { [SubscriptionCallback]: SubscriptionCallback },
	last_event_state: { map.InputCode }?,
}

local function input(option: InputKind, ...: map.InputCode): Input
	local self = {
		Kind = option,
		InputCodes = {},
		Operator = "ANY",
		Activator = "PRESSED",
		Type = "INPUT",
	} :: Input

	local private = {
		activated = false,
		press_called = false,
		erase_press = true,
		input_code_map = {},
		read = {},
		subscriptions = {},
		last_event_state = {},
	} :: Private

	for _, input_code in { ... } do
		input_code = map.normalize(input_code)
		if not private.input_code_map[input_code] then
			table.insert(self.InputCodes, input_code)
			private.input_code_map[input_code] = true
		end
	end

	self.set = function(_, ...: map.InputCode)
		local prev_input_codes = table.clone(self.InputCodes)

		self.InputCodes = {}
		private.input_code_map = {}

		for _, input_code in { ... } do
			input_code = map.normalize(input_code)
			if not private.input_code_map[input_code] then
				table.insert(self.InputCodes, input_code)
				private.input_code_map[input_code] = true
			end
		end

		for _, cb in private.subscriptions do
			cb(self.InputCodes, prev_input_codes)
		end

		return self
	end

	self.add = function(_, ...: map.InputCode)
		local prev = table.clone(self.InputCodes)
		local changed = false

		local new_input_code_map = table.clone(private.input_code_map)
		local new_input_code_list = table.clone(self.InputCodes)

		for _, input_code in { ... } do
			input_code = map.normalize(input_code)
			if new_input_code_map[input_code] then
				continue
			end
			new_input_code_map[input_code] = true
			table.insert(new_input_code_list, input_code)
			changed = true
		end

		if changed then
			self.InputCodes = new_input_code_list
			private.input_code_map = new_input_code_map
			for _, cb in private.subscriptions do
				cb(self.InputCodes, prev)
			end
		end

		return self
	end

	self.remove = function(_, ...: map.InputCode)
		local prev = table.clone(self.InputCodes)
		local changed = false

		for _, input_code in { ... } do
			input_code = map.normalize(input_code)
			if private.input_code_map[input_code] then
				private.input_code_map[input_code] = nil
				table.remove(self.InputCodes, table.find(self.InputCodes, input_code))
				changed = true
			end
		end

		if changed then
			for _, cb in private.subscriptions do
				cb(self.InputCodes, prev)
			end
		end

		return self
	end

	self.matches = function(_, key_map: { [Enum.KeyCode]: types.InputEvent })
		local matches, any_match, all_match = {}, false, true

		for _, input_code in self.InputCodes do
			local key_code = map.as_key_code(self.Kind, input_code)
			local input_event = key_map[key_code]
			if input_event then
				if
					(input_event.Event == "BEGAN" and self.Activator == "PRESSED")
					or ((input_event.Event == "BEGAN" or input_event.Event == "CHANGED") and self.Activator == "PRESSING")
					or (input_event.Event == "ENDED" and self.Activator == "RELEASED")
				then
					any_match = true
					matches[input_event.KeyCode] = true
				end
			else
				all_match = false
			end
		end

		if (self.Activator == "NONE" and not any_match) or private.press_called then
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
		local copy = input(self.Kind, table.unpack(self.InputCodes))
		copy.Operator = self.Operator
		copy.Activator = self.Activator
		return copy
	end

	return self
end

local function mouse(...: map.InputCode)
	return input("Mouse", ...)
end

local function key(...: map.InputCode)
	return input("Key", ...)
end

local function gamepad(...: map.InputCode)
	return input("Gamepad", ...)
end

return {
	mouse = mouse,
	key = key,
	gamepad = gamepad,
}
