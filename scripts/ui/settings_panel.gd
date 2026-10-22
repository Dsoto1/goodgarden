class_name SettingsPanel
extends ModalPanel
## Comfort and accessibility settings the child or a grown-up can change.


func show_settings() -> void:
	open(620)
	content.add_child(UiStyle.label(tr("Settings"), "HeadingLabel"))
	_slider(tr("Text size"), "text_scale", 1.0, 1.6, 0.1)
	var read := _toggle(tr("Read words aloud"), "read_aloud")
	if not AudioService.can_narrate():
		read.text += " " + tr("(no voice found on this device; words stay on screen)")
	_toggle(tr("Less motion"), "reduced_motion")
	var easy := CheckButton.new()
	easy.text = tr("Easier dragging (pieces snap from farther away)")
	easy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART # long words wrap at large text sizes
	easy.button_pressed = Settings.get_value("snap_tolerance") > 60.0
	easy.toggled.connect(func(on: bool) -> void: Settings.set_value("snap_tolerance", 90.0 if on else 56.0))
	content.add_child(easy)
	_choice(tr("Scenery"), "scenery_quality", [["auto", tr("Automatic")], ["high", tr("Full")], ["medium", tr("Balanced")], ["low", tr("Light (older tablets)")]])
	content.add_child(UiStyle.label(tr("Grass and trees change the next time the world loads."), "SmallLabel"))
	_slider(tr("All sound"), "volume_master", 0.0, 1.0, 0.05)
	_slider(tr("Nature and music"), "volume_ambience", 0.0, 1.0, 0.05)
	_slider(tr("Little sounds"), "volume_effects", 0.0, 1.0, 0.05)
	_slider(tr("Reading voice"), "volume_voice", 0.0, 1.0, 0.05)
	var done := UiStyle.button(tr("Done"), true)
	done.pressed.connect(close)
	add_buttons([done])


func _toggle(text: String, key: String) -> CheckButton:
	var c := CheckButton.new()
	c.text = text
	c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	c.button_pressed = Settings.get_value(key)
	c.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	content.add_child(c)
	return c


## A row of options for a setting with a few named values: [value, label] pairs.
func _choice(text: String, key: String, options: Array) -> void:
	var row := HBoxContainer.new()
	content.add_child(row)
	var l := UiStyle.label(text)
	l.custom_minimum_size.x = 220
	row.add_child(l)
	var pick := OptionButton.new()
	pick.custom_minimum_size.y = 44
	pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in options.size():
		pick.add_item(options[i][1], i)
		if options[i][0] == Settings.get_value(key):
			pick.select(i)
	pick.item_selected.connect(func(i: int) -> void: Settings.set_value(key, options[i][0]))
	row.add_child(pick)


func _slider(text: String, key: String, lo: float, hi: float, step: float) -> void:
	var row := HBoxContainer.new()
	content.add_child(row)
	var l := UiStyle.label(text)
	l.custom_minimum_size.x = 220
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = Settings.get_value(key)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size.y = 44
	s.drag_ended.connect(func(_changed: bool) -> void: Settings.set_value(key, s.value))
	s.value_changed.connect(func(v: float) -> void:
		if key != "text_scale":
			Settings.set_value(key, v))
	row.add_child(s)
