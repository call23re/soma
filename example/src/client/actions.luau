local soma = require("./soma")

local action, binding = soma.action, soma.binding
local key = soma.input.key
local all = soma.operators.all
local pressing = soma.activators.pressing

local contexts = require("./contexts")
local keybinds = require("./keybinds")

local swing, flat, top_spin, slice, lob, drop =
	keybinds.SWING,
	keybinds.SHOTS.FLAT,
	keybinds.SHOTS.TOP_SPIN,
	keybinds.SHOTS.SLICE,
	keybinds.SHOTS.LOB,
	keybinds.SHOTS.DROP

-- shots are activated via lmb/rmb + a modifier key OR by one of the gamepad action buttons
local shots = {
	binding(flat.Gamepad, all(binding(swing, pressing(flat.Key)))):named("FLAT"),
	binding(top_spin.Gamepad, all(binding(swing, pressing(top_spin.Key)))):named("TOP_SPIN"),
	binding(slice.Gamepad, all(binding(swing, pressing(slice.Key)))):named("SLICE"),
	binding(lob.Gamepad, all(binding(swing, pressing(lob.Key)))):named("LOB"),
	binding(drop.Gamepad, all(binding(swing, pressing(drop.Key)))):named("DROP"),
}

local actions = {
	Swing = action("Swing"):bind(swing, shots):cooldown(2 / 3):context(contexts.Match, contexts.Lobby),
	Dash = action("Dash"):bind(key("LEFT_SHIFT")):cooldown(1):context(contexts.Match),
}

return actions
