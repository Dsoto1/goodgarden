class_name JournalPanel
extends ModalPanel
## The child's journal: one page per day with the letter received, the work
## done, and any optional real-world invitations. Nothing here is graded.

var _day := 1
var _page: VBoxContainer
var _heading: Label
var _prev: Button
var _next: Button


func show_journal() -> void:
	open(720, Color("fbf3dc"))
	var top := HBoxContainer.new()
	content.add_child(top)
	_prev = UiStyle.button(tr("Earlier"), false, "back")
	_prev.pressed.connect(func() -> void: _turn(-1))
	top.add_child(_prev)
	_heading = UiStyle.label("", "HeadingLabel")
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_heading)
	_next = UiStyle.button(tr("Later"), false, "next")
	_next.pressed.connect(func() -> void: _turn(1))
	top.add_child(_next)
	var hear := UiStyle.button(tr("Hear it"), false, "speaker")
	hear.focus_mode = Control.FOCUS_NONE
	hear.pressed.connect(func() -> void: AudioService.narrate(_spoken_page(), true))
	top.add_child(hear)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 360
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override("separation", 14)
	scroll.add_child(_page)
	var done := UiStyle.button(tr("Close the journal"), true, "yes")
	done.pressed.connect(close)
	add_buttons([done])
	_day = Days.current_day
	_render()
	AudioService.narrate(_spoken_page())


func _turn(delta: int) -> void:
	var days := Journal.days_with_entries()
	if not days.has(Days.current_day):
		days.append(Days.current_day)
	days.sort()
	var i := clampi(days.find(_day) + delta, 0, days.size() - 1)
	_day = days[i]
	AudioService.play("page")
	_render()
	AudioService.narrate(_spoken_page())


## Everything on the page, in order, for reading aloud.
func _spoken_page() -> String:
	var parts: Array[String] = [_heading.text + "."]
	var entries := Journal.entries_for_day(_day)
	if entries.is_empty():
		parts.append(tr("This page is waiting for today's work."))
	for e in entries:
		match e["kind"]:
			"invitation":
				parts.append(_letter_heading(e) + " " + str(e["text"]))
			"work":
				parts.append(str(e["text"]))
			"real_world":
				parts.append(tr("Something to try at home:") + " " + str(e["text"]))
	return " ".join(parts)


## "A letter from Miss Miriam:", naming whoever wrote it.
func _letter_heading(e: Dictionary) -> String:
	var sender := str(Content.get_invitation(str(e.get("ref", ""))).get("from", "miriam"))
	return tr("A letter from %s:") % Dialogue.character_name(sender)


func _render() -> void:
	for c in _page.get_children():
		c.queue_free()
	_heading.text = tr("Day %d") % _day
	var days := Journal.days_with_entries()
	_prev.disabled = days.is_empty() or days[0] >= _day
	_next.disabled = _day >= Days.current_day
	var entries := Journal.entries_for_day(_day)
	if entries.is_empty():
		_page.add_child(UiStyle.label(tr("This page is waiting for today's work.")))
	for e in entries:
		match e["kind"]:
			"invitation":
				_page.add_child(UiStyle.label(_letter_heading(e), "SmallLabel"))
				var l := UiStyle.label(e["text"])
				l.add_theme_color_override("font_color", Color("5a4636"))
				_page.add_child(l)
			"work":
				_page.add_child(UiStyle.label("• " + e["text"]))
			"real_world":
				_add_real_world(e)


func _add_real_world(e: Dictionary) -> void:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiStyle.card(Color("eef3e2"), 12))
	_page.add_child(box)
	var col := VBoxContainer.new()
	box.add_child(col)
	col.add_child(UiStyle.label(tr("Something to try at home:"), "SmallLabel"))
	col.add_child(UiStyle.label(e["text"]))
	if Content.get_real_world(e["ref"]).get("checkable", true):
		var tried := CheckButton.new()
		tried.text = tr("We tried it")
		tried.button_pressed = e.get("tried", false)
		tried.toggled.connect(func(on: bool) -> void: Journal.mark_tried(e, on))
		col.add_child(tried)
