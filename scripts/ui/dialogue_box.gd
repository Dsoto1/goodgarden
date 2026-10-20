class_name DialogueBox
extends Control
## Conversation panel at the bottom of the screen. Shows who is speaking, the
## line, and either a Next button or the child's choices.

var _panel: PanelContainer
var _name: Label
var _text: Label
var _choices: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 24
	_panel.offset_right = -24
	_panel.offset_bottom = -20
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.gui_input.connect(_on_panel_input)
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	_panel.add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	_name = UiStyle.label("", "HeadingLabel")
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_name)
	var hear := UiStyle.button(tr("Hear it"))
	hear.focus_mode = Control.FOCUS_NONE
	hear.pressed.connect(func() -> void:
		Observations.record("read_aloud_requested", "", {"dialogue": Dialogue.active_id})
		AudioService.narrate(_text.text, true))
	top.add_child(hear)
	_text = UiStyle.label("", "PromptLabel")
	col.add_child(_text)
	_choices = HBoxContainer.new()
	_choices.alignment = BoxContainer.ALIGNMENT_END
	_choices.add_theme_constant_override("separation", 12)
	col.add_child(_choices)
	visible = false
	Dialogue.line_shown.connect(_on_line)
	Dialogue.conversation_ended.connect(func(_id: String) -> void:
		visible = false
		AudioService.stop_narration())


func _on_line(line: Dictionary) -> void:
	visible = true
	_name.text = line["name"]
	_text.text = line["text"]
	AudioService.narrate(line["text"])
	for c in _choices.get_children():
		c.queue_free()
	var choices: Array = line["choices"]
	if choices.is_empty():
		var next := UiStyle.button(tr("Next"), true)
		next.pressed.connect(Dialogue.advance)
		_choices.add_child(next)
		next.call_deferred("grab_focus")
	else:
		for i in choices.size():
			var b := UiStyle.button(choices[i], i == 0)
			b.pressed.connect(Dialogue.choose.bind(i))
			_choices.add_child(b)
			if i == 0:
				b.call_deferred("grab_focus")


func _on_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Dialogue.advance()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("interact"):
		var f := get_viewport().gui_get_focus_owner()
		if f is Button and _choices.is_ancestor_of(f):
			(f as Button).pressed.emit()
		else:
			Dialogue.advance()
		get_viewport().set_input_as_handled()
