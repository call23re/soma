local soma = require("./soma")
local mouse, key, gamepad = soma.input.mouse, soma.input.key, soma.input.gamepad
local binding = soma.binding
local all = soma.operators.all

local LEFT = binding(mouse("LEFT"), gamepad("L1"))
local RIGHT = binding(mouse("RIGHT"), gamepad("R1"))

-- rebind a keybind by accessing it and calling set
-- e.g. keybinds.SHOTS.FLAT.Key:set(new_keybind)

return {
	LEFT = LEFT,
	RIGHT = RIGHT,
	SWING = binding(LEFT, RIGHT),
	SHOTS = {
		FLAT = {
			Key = key("F"),
			Gamepad = gamepad("A"),
		},
		TOP_SPIN = {
			Key = key("R"),
			Gamepad = gamepad("B"),
		},
		SLICE = {
			Key = key("Q"),
			Gamepad = gamepad("X"),
		},
		LOB = {
			Key = key("LEFT_SHIFT"),
			Gamepad = gamepad("Y"),
		},
		DROP = {
			Key = key("E"),
			Gamepad = all(gamepad("Y", "B")),
		},
	},
}
