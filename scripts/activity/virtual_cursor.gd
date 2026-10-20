class_name VirtualCursor
extends Control
## Gamepad (and arrow-key) pointer for activity workspaces. The left stick
## moves a soft hand-cursor; the "grab" button presses and releases. It sends
## ordinary pointer events, so every primitive works without gamepad code.

const SPEED := 700.0

var active := false
var pointer := Vector2(640, 360)
var held := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	pointer = get_viewport_rect().size / 2.0


func _process(delta: float) -> void:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v.length() > 0.1:
		active = true
		move_to(pointer + v * SPEED * delta)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("grab"):
		active = true
		press()
		get_viewport().set_input_as_handled()
	elif event.is_action_released("grab"):
		release()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and not _is_ours(event):
		active = false # a real mouse/touch took over


func move_to(p: Vector2) -> void:
	var r := get_viewport_rect()
	var target := p.clamp(r.position, r.end)
	var ev := InputEventMouseMotion.new()
	ev.position = target
	ev.global_position = target
	ev.relative = target - pointer
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	ev.set_meta("virtual", true)
	pointer = target
	get_viewport().push_input(ev, true)


func press() -> void:
	held = true
	_button(true)


func release() -> void:
	if held:
		held = false
		_button(false)


func _button(pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = pointer
	ev.global_position = pointer
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	ev.set_meta("virtual", true)
	get_viewport().push_input(ev, true)


func _is_ours(event: InputEvent) -> bool:
	return event.has_meta("virtual")


func _draw() -> void:
	if not active:
		return
	var p := pointer - global_position
	draw_circle(p, 22.0 if held else 26.0, Color(1, 0.97, 0.85, 0.35))
	draw_arc(p, 22.0 if held else 26.0, 0, TAU, 32, Color("3b3430"), 3.0)
	draw_circle(p, 5.0, Color("3b3430"))
