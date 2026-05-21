local UserInputService = game:GetService("UserInputService")

local context = require("@self/context")
local action = require("@self/action")
local binding = require("@self/binding")
local input = require("@self/input")
local activators = require("@self/activators")
local operators = require("@self/operators")
local types = require("@self/types")

local actions = {}
local input_map: { [Enum.KeyCode]: types.InputEvent } = {}

local function get_keycode(InputObject: InputObject): Enum.KeyCode?
	const valid = {
		[Enum.UserInputType.Keyboard] = true,
		[Enum.UserInputType.Gamepad1] = true,
		[Enum.UserInputType.Gamepad2] = true,
		[Enum.UserInputType.Gamepad3] = true,
		[Enum.UserInputType.Gamepad4] = true,
		[Enum.UserInputType.Gamepad5] = true,
		[Enum.UserInputType.Gamepad6] = true,
		[Enum.UserInputType.Gamepad7] = true,
		[Enum.UserInputType.Gamepad8] = true,
	}
	if valid[InputObject.UserInputType] then
		return InputObject.KeyCode
	elseif InputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		return Enum.KeyCode.MouseLeftButton
	elseif InputObject.UserInputType == Enum.UserInputType.MouseButton2 then
		return Enum.KeyCode.MouseRightButton
	elseif InputObject.UserInputType == Enum.UserInputType.MouseButton3 then
		return Enum.KeyCode.MouseMiddleButton
	elseif InputObject.UserInputType == Enum.UserInputType.MouseMovement then
		return Enum.KeyCode.MouseDelta
	elseif InputObject.UserInputType == Enum.UserInputType.MouseWheel then
		return Enum.KeyCode.MouseWheel
	end
	return nil
end

UserInputService.InputBegan:Connect(function(InputObject, sunk)
	if sunk then
		return
	end

	local key_code = get_keycode(InputObject)
	if key_code then
		input_map[key_code] = {
			KeyCode = key_code,
			InputObject = InputObject,
			Event = "BEGAN",
		}
	end
end)

UserInputService.InputChanged:Connect(function(InputObject, sunk)
	local key_code = get_keycode(InputObject)
	if key_code then
		input_map[key_code] = {
			KeyCode = key_code,
			InputObject = InputObject,
			Event = "CHANGED",
		}
	end
end)

UserInputService.InputEnded:Connect(function(InputObject, sunk)
	local key_code = get_keycode(InputObject)
	if key_code then
		input_map[key_code] = {
			KeyCode = key_code,
			InputObject = InputObject,
			Event = "ENDED",
		}
	end
end)

local function make_action(name: string)
	local new_action = action(name)
	table.insert(actions, new_action)
	return new_action
end

local function update(dt)
	for _, action in actions do
		action.update(input_map, dt)
	end
	for key, value in input_map do
		if value.Event == "ENDED" then
			input_map[key] = nil
		elseif value.Event == "BEGAN" then
			value.Event = "HELD"
		end
	end
end

return {
	update = update,
	context = context,
	action = make_action,
	binding = binding.binding,
	input = input,
	activators = activators,
	operators = operators,
}
