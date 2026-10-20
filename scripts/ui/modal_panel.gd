class_name ModalPanel
extends Control
## Base for full-screen cards (letter, journal, map, menus). Pushes the MENU
## mode while open so the avatar and camera wait, and closes on Pause/Back.

signal closed

var content: VBoxContainer
var _mode_pushed := false


func open(width := 680.0, fill := UiStyle.PAPER) -> VBoxContainer:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	content = UiStyle.modal(self, width, fill)
	GameState.push_mode(GameState.Mode.MENU)
	_mode_pushed = true
	AudioService.play("page")
	return content


func close() -> void:
	if _mode_pushed:
		_mode_pushed = false
		GameState.pop_mode(GameState.Mode.MENU)
	AudioService.stop_narration()
	closed.emit()
	queue_free()


func add_buttons(buttons: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	for b: Button in buttons:
		row.add_child(b)
	if buttons.size() > 0:
		(buttons.back() as Button).call_deferred("grab_focus")
	return row


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
