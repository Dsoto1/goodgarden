class_name ParentPanel
extends ModalPanel
## Grown-ups' page behind a simple gate: what the child has been choosing and
## doing (never a score, never a judgement of faith or virtue), plus a few
## preferences. Everything stays on this device.

const GATES := [[7, 8], [6, 9], [8, 4], [9, 7], [12, 3]]

var _answer := 0


func show_gate() -> void:
	open(560)
	var q: Array = GATES[randi() % GATES.size()]
	_answer = q[0] * q[1]
	content.add_child(UiStyle.label(tr("For grown-ups"), "HeadingLabel"))
	content.add_child(UiStyle.label(tr("Please type the answer to continue: what is %d × %d?") % [q[0], q[1]]))
	var field := LineEdit.new()
	field.custom_minimum_size = Vector2(160, 56)
	field.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	content.add_child(field)
	var msg := UiStyle.label("", "SmallLabel")
	content.add_child(msg)
	var back := UiStyle.button(tr("Back"))
	back.pressed.connect(close)
	var go := UiStyle.button(tr("Continue"), true)
	var check := func(_t: String = "") -> void:
		if field.text.strip_edges() == str(_answer):
			_show_page()
		else:
			msg.text = tr("That isn't quite it.")
	go.pressed.connect(check)
	field.text_submitted.connect(check)
	add_buttons([back, go])
	field.call_deferred("grab_focus")


func _show_page() -> void:
	for c in content.get_children():
		c.queue_free()
	content.add_child(UiStyle.label(tr("What your child has been doing"), "HeadingLabel"))
	var notes := Observations.summarize()
	if notes.is_empty():
		notes.append(tr("Nothing yet. Observations appear here as your child works."))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 200
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for n in notes:
		list.add_child(UiStyle.label("• " + n, "SmallLabel"))
	content.add_child(UiStyle.label(tr("These are observations, not grades. Scripture and prayer are never scored; the game only notes that a material was chosen."), "SmallLabel"))
	var rw := CheckButton.new()
	rw.text = tr("Offer real-world invitations")
	rw.button_pressed = Settings.get_value("real_world_invitations")
	rw.toggled.connect(func(on: bool) -> void: Settings.set_value("real_world_invitations", on))
	content.add_child(rw)
	var row := HBoxContainer.new()
	content.add_child(row)
	var reminder := UiStyle.label(tr("Gentle rest reminder:"))
	reminder.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(reminder)
	var opt := OptionButton.new()
	for m: int in [0, 15, 30, 45]:
		opt.add_item(tr("Off") if m == 0 else tr("%d minutes") % m, m)
	opt.select(maxi(0, [0, 15, 30, 45].find(int(Settings.get_value("session_minutes")))))
	opt.item_selected.connect(func(i: int) -> void: Settings.set_value("session_minutes", opt.get_item_id(i)))
	row.add_child(opt)
	content.add_child(UiStyle.label(tr("All progress and observations are stored only on this device."), "SmallLabel"))
	var done := UiStyle.button(tr("Done"), true)
	done.pressed.connect(close)
	add_buttons([done])
