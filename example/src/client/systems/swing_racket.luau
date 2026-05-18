local actions = require("../actions")
local keybinds = require("../keybinds")
local action = actions.Swing

return function()
	if not action:activated() then
		return
	end

	local shot = action:names()[1] or "FLAT"
	local swing_direction = if keybinds.LEFT:activated() then "LEFT_TO_RIGHT" else "RIGHT_TO_LEFT"
	print(`swinging {swing_direction}`)

	local hit = math.random() > 0.5
	if hit then
		print(`hit ball with {shot}`)
	end
end
