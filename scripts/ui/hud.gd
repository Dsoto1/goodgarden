class_name Hud
extends Control
## Exploration HUD, laid out like the mockup: the place name top-left, the
## day and today's invitation top-right, and Journal / Map / Settings tiles
## bottom-right. The invitation lists the day's three jobs with soft ticks
## (no counts or rewards). One contextual prompt sits at the bottom. No
## currencies, meters or badges. The prompt is itself a button, so touch
## players can tap it instead of walking right up to things.

var _prompt_panel: PanelContainer
var _prompt_button: Button
var _place: Label
var _place_chip: PanelContainer
var _day: Label
var _invite_text: Label
var _invite_glyph: Icon.Glyph
var _right: VBoxContainer
var _tiles: HBoxContainer
var _map_tile: Button
var _caption: PanelContainer
var _caption_label: Label
var _caption_timer: SceneTreeTimer
var _invite: Button
var _invite_heading: Label
var _invite_card: PanelContainer
var _jobs_box: VBoxContainer
var _jobs_key := ""
## Whether today's jobs were all done at the last refresh, so finishing the
## last one (by any route) is announced once.
var _was_done := false
var _announce_done := false
var _spoken_target: Interactable
var _spoken_places := {}


func _ready() -> void:
	add_to_group("hud")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_place_chip = _chip()
	add_child(_place_chip)
	_place = UiStyle.label("", "HeadingLabel")
	_place.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place_chip.add_child(_place)
	_place_chip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 16)

	_right = VBoxContainer.new()
	_right.add_theme_constant_override("separation", 8)
	_right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(_right)
	var day_chip := _chip()
	day_chip.size_flags_horizontal = Control.SIZE_SHRINK_END
	var day_row := HBoxContainer.new()
	day_row.add_child(Icon.Glyph.new("sun", 28))
	_day = UiStyle.label("", "")
	_day.autowrap_mode = TextServer.AUTOWRAP_OFF
	day_row.add_child(_day)
	day_chip.add_child(day_row)
	_right.add_child(day_chip)
	var invite := Button.new()
	_invite = invite
	invite.flat = true
	invite.focus_mode = Control.FOCUS_NONE
	invite.custom_minimum_size = Vector2(380, 0)
	invite.pressed.connect(_on_invitation_pressed)
	var card := _chip()
	_invite_card = card
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_invite_glyph = Icon.Glyph.new("letter", 40)
	row.add_child(_invite_glyph)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var heading := UiStyle.label(tr("Today's Invitation"), "SmallLabel")
	heading.add_theme_color_override("font_color", Color("7a4a26"))
	_invite_heading = heading
	col.add_child(heading)
	_invite_text = UiStyle.label("", "SmallLabel")
	_invite_text.custom_minimum_size.x = 250
	col.add_child(_invite_text)
	_jobs_box = VBoxContainer.new()
	_jobs_box.add_theme_constant_override("separation", 2)
	_jobs_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_jobs_box)
	row.add_child(col)
	card.add_child(row)
	invite.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	invite.resized.connect(func() -> void: invite.custom_minimum_size.y = card.get_combined_minimum_size().y)
	_right.add_child(invite)
	_right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)

	_tiles = HBoxContainer.new()
	_tiles.add_theme_constant_override("separation", 10)
	_tiles.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_tiles.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_tiles)
	var journal := Icon.Tile.new("journal", tr("Journal"))
	journal.pressed.connect(func() -> void: get_tree().call_group("main", "open_journal"))
	_tiles.add_child(journal)
	_map_tile = Icon.Tile.new("map", tr("Map"))
	_map_tile.pressed.connect(func() -> void: get_tree().call_group("main", "open_map"))
	_tiles.add_child(_map_tile)
	# Opens the pause menu (keep playing, settings, grown-ups, save and stop).
	var settings := Icon.Tile.new("pause", tr("Pause"))
	settings.pressed.connect(func() -> void: get_tree().call_group("main", "open_pause"))
	_tiles.add_child(settings)
	_tiles.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)

	_prompt_panel = PanelContainer.new()
	_prompt_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(_prompt_panel)
	_prompt_button = UiStyle.button("", true, "hand")
	_prompt_button.focus_mode = Control.FOCUS_NONE
	_prompt_button.pressed.connect(func() -> void: Interaction.interact_focused())
	_prompt_panel.add_child(_prompt_button)

	_caption = PanelContainer.new()
	_caption.custom_minimum_size.x = 520
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.visible = false
	add_child(_caption)
	_caption_label = UiStyle.label("")
	_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_label.custom_minimum_size.x = 480 # autowrap needs a width to measure height
	_caption.add_child(_caption_label)

	Interaction.focus_changed.connect(func(t: Interactable) -> void:
		refresh()
		_speak_prompt_soon(t))
	GameState.mode_changed.connect(func(_m: GameState.Mode) -> void: refresh())
	Discovery.discovered.connect(func(_id: String) -> void: refresh())
	Discovery.entered.connect(func(id: String) -> void:
		refresh()
		_speak_place(id))
	Invitations.opened.connect(func(_id: String) -> void: refresh())
	Invitations.delivered.connect(func(_id: String) -> void: refresh())
	Days.day_started.connect(func(_d: int) -> void:
		_spoken_places.clear()
		_was_done = false
		_announce_done = false
		refresh())
	AudioService.narration_unavailable.connect(func() -> void:
		show_caption(tr("This device has no reading voice, so words can't be read aloud. A grown-up can add a voice in the device's settings."), 9.0))
	Journal.changed.connect(refresh)
	ActivityRunner.activity_finished.connect(func(_def: ActivityDefinition, _completed: bool) -> void: refresh())
	WorldState.fact_changed.connect(func(_key: String, _value: Variant) -> void: refresh())
	refresh()


func _chip() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _chip_box())
	return p


func _chip_box(fill := UiStyle.PAPER, edge := UiStyle.PAPER_EDGE) -> StyleBoxFlat:
	var box := UiStyle.card(fill, 12)
	box.border_color = edge
	box.set_content_margin_all(10)
	box.content_margin_left = 16
	box.content_margin_right = 16
	return box


func refresh() -> void:
	var exploring := GameState.is_exploring()
	for n: Control in [_place_chip, _right, _tiles]:
		n.visible = exploring
	_place.text = _place_name()
	_place_chip.visible = exploring and not _place.text.is_empty()
	_day.text = tr("Day %d  •  %s") % [Days.current_day, tr(Days.season())]
	_invite_text.text = _invitation_summary()
	# Once the day's work is done, the note says so plainly: a green tick and a
	# thank-you, never the old request.
	var done := todays_work_done()
	var jobs := TodaysWork.today()
	var listing := not jobs.is_empty() and not done
	_invite_text.visible = not listing
	_show_jobs(jobs if listing else [])
	_invite_glyph.kind = "letter" if Invitations.has_unread() else ("yes" if done else "seedling")
	_invite_glyph.queue_redraw()
	_invite_heading.text = tr("Done today") if done else (tr("Today's jobs") if listing else tr("Today's Invitation"))
	_invite_card.add_theme_stylebox_override("panel", _chip_box(Color("e4efd3"), Color("6f9a52")) if done else _chip_box())
	var spoken := _invite_heading.text + ". "
	if listing:
		for j: Dictionary in jobs:
			spoken += tr(j["text"]) + (" " + tr("(done)") if j["done"] else "") + ". "
	else:
		spoken += _invite_text.text
	_invite.set_meta(&"spoken", spoken)
	# Finishing the last job, however it happened, is said once, after any
	# activity has handed control back.
	if done and not _was_done:
		_announce_done = true
	_was_done = done
	if _announce_done and exploring:
		_announce_done = false
		_say_day_done()
	_map_tile.visible = Discovery.map_unlocked()
	var target := Interaction.focused
	_prompt_panel.visible = exploring and target != null
	if target:
		_prompt_button.text = tr(target.prompt)
	# Keep the prompt centered as its text changes width.
	_prompt_panel.reset_size()
	_prompt_panel.position = Vector2((size.x - _prompt_panel.size.x) / 2.0, size.y - _prompt_panel.size.y - 24)


## Says what the prompt button will do once the child has paused by something,
## so a child who can't read knows what is in reach.
func _speak_prompt_soon(target: Interactable) -> void:
	if target == null or target == _spoken_target:
		if target == null:
			_spoken_target = null
		return
	await get_tree().create_timer(0.6).timeout
	if Interaction.focused == target and GameState.is_exploring() and is_instance_valid(target):
		_spoken_target = target
		AudioService.narrate(tr(target.prompt))


## Names a place the first time the child walks into it each day.
func _speak_place(id: String) -> void:
	if _spoken_places.has(id) or not GameState.is_exploring():
		return
	_spoken_places[id] = true
	var place := _place_name()
	if not place.is_empty() and not AudioService.is_speaking():
		AudioService.narrate(place)


func _place_name() -> String:
	var world := Content.get_world("regions")
	for entry: Dictionary in world.get("regions", []) + world.get("places", []):
		if entry["id"] == Discovery.current:
			return tr(str(entry.get("name", "")))
	return ""


func _invitation_summary() -> String:
	if Invitations.has_unread():
		return tr("A letter is waiting by the door at home.")
	var latest := Invitations.latest_read()
	var data := Content.get_invitation(latest)
	if not latest.is_empty() and Journal.has_entry("invitation", latest, Days.current_day):
		if todays_work_done():
			# Say what comes next, so a finished day never leaves the child wondering.
			return tr(str(data.get("done", "All done. Thank you for helping!"))) + "\n" + tr("When you're ready, rest in your bed at home for a new day.")
		return tr(str(data.get("summary", "Read your letter again.")))
	return tr("A free day. Go wherever you like.")


## True once every job today's letter asked for has been finished today.
func todays_work_done() -> bool:
	return TodaysWork.all_done()


## Waits for whatever the last job said (a lamb's hop, the hens' grain) to
## be read, then says the day's work is done.
func _say_day_done() -> void:
	await get_tree().process_frame
	var guard := 0.0
	while _caption.visible and guard < 12.0:
		await get_tree().create_timer(0.25).timeout
		guard += 0.25
	show_caption(tr("Today's work is done! You can explore, visit the Chapel, or go home and rest in your bed to start a new day."), 8.0)


## One line per job: an empty ring, or a green tick once it is done.
func _show_jobs(jobs: Array) -> void:
	var key := str(jobs)
	if key == _jobs_key:
		return
	_jobs_key = key
	for c in _jobs_box.get_children():
		c.queue_free()
	_jobs_box.visible = not jobs.is_empty()
	for j: Dictionary in jobs:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(Icon.Glyph.new("yes" if j["done"] else "todo", 24))
		var l := UiStyle.label(tr(j["text"]), "SmallLabel")
		l.custom_minimum_size.x = 270
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if j["done"]:
			l.add_theme_color_override("font_color", Color("6b7f5a"))
		row.add_child(l)
		_jobs_box.add_child(row)



func _on_invitation_pressed() -> void:
	if Invitations.has_unread():
		show_caption(tr("Your letter is waiting on the stand by the cottage door."))
	else:
		get_tree().call_group("main", "reread_invitation")


## Softer HUD in the Chapel.
func set_quiet(quiet: bool) -> void:
	var a := 0.45 if quiet else 1.0
	for n: Control in [_right, _tiles, _place_chip]:
		create_tween().tween_property(n, "modulate:a", a, 0.8)


func show_caption(text: String, seconds := 4.5) -> void:
	_caption_label.text = text
	_caption.visible = true
	_caption.size = Vector2.ZERO
	_caption.reset_size()
	_caption.position = Vector2((size.x - _caption.size.x) / 2.0, size.y - _caption.size.y - 110)
	AudioService.narrate(text)
	# Long enough to listen to as well as read.
	seconds = maxf(seconds, 1.5 + text.split(" ").size() * 0.4)
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
