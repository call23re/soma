export type InputEventKind = "BEGAN" | "CHANGED" | "ENDED"
export type InputEvent = {
	KeyCode: Enum.KeyCode,
	InputObject: InputObject,
	Event: InputEventKind,
}

export type Operator = "ANY" | "ALL"

return {}
