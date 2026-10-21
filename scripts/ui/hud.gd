class_name Hud
extends Control
## Exploration HUD, laid out like the mockup: the place name top-left, the
## day and today's invitation top-right, and Journal / Map / Settings tiles
## bottom-right. One contextual prompt sits at the bottom. No quest lists,
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
	invite.flat = true
	invite.focus_mode = Control.FOCUS_NONE
	invite.custom_minimum_size = Vector2(330, 0)
	invite.pressed.connect(_on_invitation_pressed)
	var card := _chip()
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
	col.add_child(heading)
	_invite_text = UiStyle.label("", "SmallLabel")
	_invite_text.custom_minimum_size.x = 250
	col.add_child(_invite_text)
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
	var settings := Icon.Tile.new("settings", tr("Settings"))
	settings.pressed.connect(func() -> void: get_tree().call_group("main", "open_pause"))
	_tiles.add_child(settings)
	_tiles.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 16)

	_prompt_panel = PanelContainer.new()
	_prompt_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(_prompt_panel)
	_prompt_button = UiStyle.button("", true)
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

	Interaction.focus_changed.connect(func(_t: Interactable) -> void: refresh())
	GameState.mode_changed.connect(func(_m: GameState.Mode) -> void: refresh())
	Discovery.discovered.connect(func(_id: String) -> void: refresh())
	Discovery.entered.connect(func(_id: String) -> void: refresh())
	Invitations.opened.connect(func(_id: String) -> void: refresh())
	Invitations.delivered.connect(func(_id: String) -> void: refresh())
	Days.day_started.connect(func(_d: int) -> void: refresh())
	Journal.changed.connect(refresh)
	refresh()


func _chip() -> PanelContainer:
	var p := PanelContainer.new()
	var box := UiStyle.card(UiStyle.PAPER, 12)
	box.border_color = UiStyle.PAPER_EDGE
	box.set_content_margin_all(10)
	box.content_margin_left = 16
	box.content_margin_right = 16
	p.add_theme_stylebox_override("panel", box)
	return p


func refresh() -> void:
	var exploring := GameState.is_exploring()
	for n: Control in [_place_chip, _right, _tiles]:
		n.visible = exploring
	_place.text = _place_name()
	_place_chip.visible = exploring and not _place.text.is_empty()
	_day.text = tr("Day %d  •  %s") % [Days.current_day, tr(Days.season())]
	_invite_text.text = _invitation_summary()
	_invite_glyph.kind = "letter" if Invitations.has_unread() else "seedling"
	_invite_glyph.queue_redraw()
	_map_tile.visible = Discovery.map_unlocked()
	var target := Interaction.focused
	_prompt_panel.visible = exploring and target != null
	if target:
		_prompt_button.text = tr(target.prompt)
	# Keep the prompt centered as its text changes width.
	_prompt_panel.reset_size()
	_prompt_panel.position = Vector2((size.x - _prompt_panel.size.x) / 2.0, size.y - _prompt_panel.size.y - 24)


func _place_name() -> String:
	for entry: Dictionary in Content.get_world("regions").get("regions", []):
		if entry["id"] == Discovery.current:
			return tr(str(entry.get("name", "")))
	return ""


func _invitation_summary() -> String:
	if Invitations.has_unread():
		return tr("A letter is waiting by the door at home.")
	var latest := Invitations.latest_read()
	var data := Content.get_invitation(latest)
	if not latest.is_empty() and Journal.has_entry("invitation", latest, Days.current_day):
		return tr(str(data.get("summary", "Read Miriam's letter again.")))
	return tr("A free day. Go wherever you like.")


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
