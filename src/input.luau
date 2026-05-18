local EnumMap = require("./enum_map")
local types = require("./types")

export type InputKind = "Key" | "Gamepad" | "Mouse" | "Touch"
export type Activator = "PRESSING" | "PRESSED" | "RELEASED" | "NONE"
export type SubscriptionCallback = (cur: { EnumMap.InputCode }, prev: { EnumMap.InputCode }?) -> ()
export type Input = {
	Kind: InputKind,
	InputCodes: { EnumMap.InputCode },
	Operator: types.Operator,
	Activator: Activator,
	Type: "INPUT",
	set: (Input, ...EnumMap.InputCode) -> Input,
	add: (Input, ...EnumMap.InputCode) -> Input,
	remove: (Input, ...EnumMap.InputCode) -> Input,
	matches: (Input, { [Enum.KeyCode]: types.InputEvent }) -> ({ [Enum.KeyCode]: boolean }, boolean, boolean),
	activated: (Input) -> boolean,
	read: (Input) -> { [Enum.KeyCode]: boolean },
	subscribe: (Input, SubscriptionCallback) -> (),
	unsubscribe: (Input, SubscriptionCallback) -> (),
	clone: (Input) -> Input,
	_activated: boolean,
	_input_code_map: { [EnumMap.InputCode]: boolean },
	_read: { [Enum.KeyCode]: boolean },
	_subscriptions: { [SubscriptionCallback]: SubscriptionCallback },
	_last_event_state: { EnumMap.InputCode }?,
}

local function input(option: InputKind, ...: EnumMap.InputCode): Input
	local self = {
		Kind = option,
		InputCodes = {},
		Operator = "ANY",
		Activator = "PRESSED",
		Type = "INPUT",
		_activated = false,
		_input_code_map = {},
		_read = {},
		_subscriptions = {},
		_last_event_state = {},
	} :: Input

	for _, input_code in { ... } do
		input_code = EnumMap.normalize(input_code)
		if not self._input_code_map[input_code] then
			table.insert(self.InputCodes, input_code)
			self._input_code_map[input_code] = true
		end
	end

	self.set = function(_, ...: EnumMap.InputCode)
		local prev_input_codes = table.clone(self.InputCodes)
		self.InputCodes = {}
		self._input_code_map = {}
		for _, input_code in { ... } do
			input_code = EnumMap.normalize(input_code)
			if not self._input_code_map[input_code] then
				table.insert(self.InputCodes, input_code)
				self._input_code_map[input_code] = true
			end
		end
		for _, cb in self._subscriptions do
			cb(self.InputCodes, prev_input_codes)
		end
		return self
	end

	self.add = function(_, ...: EnumMap.InputCode)
		local prev = table.clone(self.InputCodes)
		local changed = false
		local new_input_code_map = {}
		local new_input_code_list = { ... }
		for _, input_code in { ... } do
			input_code = EnumMap.normalize(input_code)
			if new_input_code_map[input_code] then
				continue
			end
			new_input_code_map[input_code] = true
			table.insert(new_input_code_list, input_code)
			changed = true
		end
		if changed then
			self.InputCodes = new_input_code_list
			self._input_code_map = new_input_code_map
			for _, cb in self._subscriptions do
				cb(self.InputCodes, prev)
			end
		end
		return self
	end

	self.remove = function(_, ...: EnumMap.InputCode)
		local prev = table.clone(self.InputCodes)
		local changed = false
		for _, input_code in { ... } do
			input_code = EnumMap.normalize(input_code)
			if self._input_code_map[input_code] then
				self._input_code_map[input_code] = nil
				table.remove(self.InputCodes, table.find(self.InputCodes, input_code))
				changed = true
			end
		end
		if changed then
			for _, cb in self._subscriptions do
				cb(self.InputCodes, prev)
			end
		end
		return self
	end

	self.matches = function(_, map: { [Enum.KeyCode]: types.InputEvent })
		local matches, any_match, all_match = {}, false, true

		for _, input_code in self.InputCodes do
			local key_code = EnumMap.as_key_code(self.Kind, input_code)
			local input_event = map[key_code]
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

		if self.Activator == "NONE" and not any_match then
			any_match = true
			all_match = true
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
		local copy = input(self.Kind, table.unpack(self.InputCodes))
		copy.Operator = self.Operator
		copy.Activator = self.Activator
		return copy
	end

	return self
end

local function mouse(...: EnumMap.InputCode)
	return input("Mouse", ...)
end

local function key(...: EnumMap.InputCode)
	return input("Key", ...)
end

local function gamepad(...: EnumMap.InputCode)
	return input("Gamepad", ...)
end

return {
	mouse = mouse,
	key = key,
	gamepad = gamepad,
}
