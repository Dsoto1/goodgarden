class_name Hud
extends Control
## Exploration HUD: one contextual prompt and a few quiet buttons. No quest
## list, currencies, meters or badges. The prompt is itself a button, so
## touch players can tap it instead of walking right up to things.

var _prompt_panel: PanelContainer
var _prompt_button: Button
var _letter_button: Button
var _map_button: Button
var _buttons: VBoxContainer
var _caption: PanelContainer
var _caption_label: Label
var _caption_timer: SceneTreeTimer


func _ready() -> void:
	add_to_group("hud")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_buttons = VBoxContainer.new()
	_buttons.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_buttons.position = Vector2(-16, 16)
	_buttons.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_buttons.add_theme_constant_override("separation", 10)
	add_child(_buttons)
	var journal := UiStyle.button(tr("Journal"))
	journal.pressed.connect(func() -> void: get_tree().call_group("main", "open_journal"))
	_buttons.add_child(journal)
	_letter_button = UiStyle.button(tr("Letter"))
	_letter_button.pressed.connect(func() -> void: get_tree().call_group("main", "reread_invitation"))
	_buttons.add_child(_letter_button)
	_map_button = UiStyle.button(tr("Map"))
	_map_button.pressed.connect(func() -> void: get_tree().call_group("main", "open_map"))
	_buttons.add_child(_map_button)
	var pause := UiStyle.button(tr("Pause"))
	pause.pressed.connect(func() -> void: get_tree().call_group("main", "open_pause"))
	_buttons.add_child(pause)

	_prompt_panel = PanelContainer.new()
	_prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt_panel.position.y = -24
	_prompt_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(_prompt_panel)
	_prompt_button = UiStyle.button("", true)
	_prompt_button.focus_mode = Control.FOCUS_NONE
	_prompt_button.pressed.connect(func() -> void: Interaction.interact_focused())
	_prompt_panel.add_child(_prompt_button)

	_caption = PanelContainer.new()
	_caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_caption.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_caption.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_caption.position.y = -110
	_caption.custom_minimum_size.x = 520
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.visible = false
	add_child(_caption)
	_caption_label = UiStyle.label("")
	_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_child(_caption_label)

	Interaction.focus_changed.connect(func(_t: Interactable) -> void: refresh())
	GameState.mode_changed.connect(func(_m: GameState.Mode) -> void: refresh())
	Discovery.discovered.connect(func(_id: String) -> void: refresh())
	Journal.changed.connect(refresh)
	refresh()


func refresh() -> void:
	var exploring := GameState.is_exploring()
	_buttons.visible = exploring
	var target := Interaction.focused
	_prompt_panel.visible = exploring and target != null
	if target:
		_prompt_button.text = tr(target.prompt)
	_letter_button.visible = not Invitations.latest_read().is_empty()
	_map_button.visible = Discovery.map_unlocked()
	# Keep the prompt centered as its text changes width.
	_prompt_panel.reset_size()
	_prompt_panel.position.x = (size.x - _prompt_panel.size.x) / 2.0
	_prompt_panel.position.y = size.y - _prompt_panel.size.y - 24


## Softer HUD in the Chapel.
func set_quiet(quiet: bool) -> void:
	var a := 0.45 if quiet else 1.0
	create_tween().tween_property(_buttons, "modulate:a", a, 0.8)


func show_caption(text: String, seconds := 4.5) -> void:
	_caption_label.text = text
	_caption.visible = true
	_caption.reset_size()
	_caption.position = Vector2((size.x - _caption.size.x) / 2.0, size.y - _caption.size.y - 110)
	AudioService.narrate(text)
	_caption_timer = get_tree().create_timer(seconds)
	var this_timer := _caption_timer
	this_timer.timeout.connect(func() -> void:
		if _caption_timer == this_timer:
			_caption.visible = false)


func caption_text() -> String:
	return _caption_label.text if _caption.visible else ""


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _prompt_panel:
		refresh()
