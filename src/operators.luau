local input = require("./input")
local binding = require("./binding")

local function all(this_input: input.Input | binding.Binding)
	this_input.Operator = "ALL"
	return this_input
end

local function any(this_input: input.Input | binding.Binding)
	this_input.Operator = "ANY"
	return this_input
end

return {
	all = all,
	any = any,
}
