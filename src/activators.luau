local input = require("./input")

local function pressing(this_input: input.Input)
	this_input.Activator = "PRESSING"
	return this_input
end

local function pressed(this_input: input.Input)
	this_input.Activator = "PRESSED"
	return this_input
end

local function released(this_input: input.Input)
	this_input.Activator = "RELEASED"
	return this_input
end

local function none(this_input: input.Input)
	this_input.Activator = "NONE"
	return this_input
end

return {
	pressing = pressing,
	pressed = pressed,
	released = released,
	none = none,
}
