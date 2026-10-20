extends Node
## Registers input actions in code so keyboard, gamepad and pointer bindings
## live in one readable place instead of serialized events in project.godot.
## Touch and mouse are handled as pointer input by the player and UI directly.

const KEYS := {
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
	"journal": [KEY_J],
	"map": [KEY_M],
	"pause": [KEY_ESCAPE, KEY_P],
	"grab": [KEY_G],
}

const JOY_BUTTONS := {
	"interact": [JOY_BUTTON_A],
	"journal": [JOY_BUTTON_Y],
	"map": [JOY_BUTTON_BACK],
	"pause": [JOY_BUTTON_START],
	"grab": [JOY_BUTTON_X],
	"move_up": [JOY_BUTTON_DPAD_UP],
	"move_down": [JOY_BUTTON_DPAD_DOWN],
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
}

const JOY_AXES := {
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
}


func _enter_tree() -> void:
	for action: String in KEYS:
		_ensure(action)
		for keycode: int in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)
	for action: String in JOY_BUTTONS:
		_ensure(action)
		for button: int in JOY_BUTTONS[action]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = button
			InputMap.action_add_event(action, ev)
	for action: String in JOY_AXES:
		var ev := InputEventJoypadMotion.new()
		ev.axis = JOY_AXES[action][0]
		ev.axis_value = JOY_AXES[action][1]
		InputMap.action_add_event(action, ev)


func _ensure(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)
