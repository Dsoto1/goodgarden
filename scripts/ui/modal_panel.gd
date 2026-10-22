class_name ModalPanel
extends Control
## Base for full-screen cards (letter, journal, map, menus). Pushes the MENU
## mode while open so the avatar and camera wait, and closes on Pause/Back.

signal closed

var content: VBoxContainer
var _mode_pushed := false
var _button_rows: Array[Control] = []


func open(width := 680.0, fill := UiStyle.PAPER) -> VBoxContainer:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	content = UiStyle.modal(self, width, fill)
	GameState.push_mode(GameState.Mode.MENU)
	_mode_pushed = true
	AudioService.play("page")
	_fit_to_screen.call_deferred()
	return content


## With large text a card can be taller than the screen. Then everything but
## its buttons scrolls, so "Keep it", "Close" and the like stay in view.
func _fit_to_screen() -> void:
	if not is_inside_tree() or content == null:
		return
	var card := content.get_parent() as Control
	var room := get_viewport_rect().size.y - 24.0
	if card.get_combined_minimum_size().y <= room:
		return
	var scroll := ScrollContainer.new()
	scroll.name = "FitScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", content.get_theme_constant("separation"))
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inner)
	for c in content.get_children():
		if not c in _button_rows:
			content.remove_child(c)
			inner.add_child(c)
	content.add_child(scroll)
	content.move_child(scroll, 0)
	scroll.custom_minimum_size.y = maxf(room - card.get_combined_minimum_size().y, 120.0)


func close() -> void:
	if _mode_pushed:
		_mode_pushed = false
		GameState.pop_mode(GameState.Mode.MENU)
	AudioService.stop_narration()
	closed.emit()
	queue_free()


## Adds a row of buttons; the one at `focus_index` (default: the last) starts selected.
func add_buttons(buttons: Array, focus_index := -1) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	_button_rows.append(row)
	for b: Button in buttons:
		row.add_child(b)
	if buttons.size() > 0:
		(buttons[focus_index] as Button).call_deferred("grab_focus")
	return row


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
