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
	_read: { [Enum.KeyCode]: boolean },
	_subscriptions: { [SubscriptionCallback]: SubscriptionCallback },
	_last_event_state: { EnumMap.InputCode }?,
}

local function input(option: InputKind, ...: EnumMap.InputCode): Input
	local self = {
		Kind = option,
		InputCodes = { ... },
		Operator = "ANY",
		Activator = "PRESSED",
		Type = "INPUT",
		_activated = false,
		_read = {},
		_subscriptions = {},
		_last_event_state = {},
	} :: Input

	-- TODO: prevent duplicates
	self.set = function(_, ...: EnumMap.InputCode)
		local prev = self.InputCodes
		self.InputCodes = { ... }
		for _, cb in self._subscriptions do
			cb(self.InputCodes, prev)
		end
		return self
	end

	self.add = function(_, ...: EnumMap.InputCode)
		local prev = table.clone(self.InputCodes)
		local changed = false
		for _, input_code in { ... } do
			if table.find(self.InputCodes, input_code) then
				continue
			end
			table.insert(self.InputCodes, input_code)
			changed = true
		end
		if changed then
			for _, cb in self._subscriptions do
				cb(self.InputCodes, prev)
			end
		end
		return self
	end

	-- TODO: must work for both kinds of InputCode (string and enum)
	self.remove = function(_, ...: EnumMap.InputCode)
		local prev = table.clone(self.InputCodes)
		local changed = false
		for _, input_code in { ... } do
			local index = table.find(self.InputCodes, input_code)
			if index then
				table.remove(self.InputCodes, index)
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
			local normalized = EnumMap.as_key_code(self.Kind, input_code)
			local input_event = map[normalized]
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
