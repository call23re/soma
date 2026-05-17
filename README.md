## Soma
Soma is an experimental, compositional input library made to be used with an ECS. It is currently just a prototype, and it's missing a number of important features.

## Usage

First define your actions.

```luau
-- contexts.luau
local contexts = {
	Lobby = context("LOBBY"):enable(),
	Match = context("MATCH"),
}
return contexts

-- actions.luau
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
	Swing = action("Swing"):bind(swing, shots):cooldown(2/3):context(contexts.Match, contexts.Lobby),
	Dash = action("Dash"):bind(key("LEFT_SHIFT")):cooldown(1):context(contexts.Match),
}

return actions

-- keybinds.luau
local LEFT = binding(mouse("LEFT"), gamepad("L1"))
local RIGHT = binding(mouse("RIGHT"), gamepad("R1"))

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
```

Then query for them.

```luau
-- swing_racket.luau
local action = require("actions").Swing
-- for every frame...
if not action:activated() then return end
local shot = action:names()[1] or "FLAT"
local swing_direction = if keybinds.LEFT:activated() then "LEFT_TO_RIGHT" else "RIGHT_TO_LEFT"
```

Or modify them.

```luau
type Keybinds = {
	[string]: {
		Kind: "Key" | "Gamepad",
		Keys: { Enum.KeyCode }
	}
}

keybinds_remote.OnClientEvent:Connect(function(new_keybinds: Keybinds)
	for shot_name, new_key in new_keybinds do
		keybinds.SHOTS[shot_name][new_key.Kind]:set(table.unpack(new_key.Keys))
	end
end)
```

And, finally, update them.

```luau
local soma = require("soma")

RunService.Heartbeat:Connect(function(dt)
	soma.update(dt)
end)
```