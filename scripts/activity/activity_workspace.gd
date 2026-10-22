class_name ActivityWorkspace
extends Control
## The reusable close-up work surface every activity runs in.
##
## Shows the guide's words, the board for the current step and a few calm
## controls (Hear it, Show me, Start over, Finish later). Steps come from the
## activity definition and are created through PrimitiveRegistry, so the same
## workspace serves the garden row, the supper table and the Atrium.

signal finished(results: Dictionary)
signal observed(kind: String, data: Dictionary)

const SURFACES := {
	"soil_bed": {"kind": "soil", "base": Color("8a6446"), "edge": Color("6e4c34"), "grain": Color("7a573c")},
	"wood_table": {"kind": "wood", "base": Color("c39566"), "edge": Color("9c7049"), "grain": Color("b5875a")},
	"atrium_felt": {"kind": "felt", "base": Color("41577f"), "edge": Color("2f3f5e"), "grain": Color("4a6190")},
}

var definition: ActivityDefinition
var results: Dictionary = {}
var step: ActivityStep
var step_index := -1
## Gamepad pointer; idle until a stick or the grab button is used.
var cursor: VirtualCursor

var _board: Control
var _board_holder: Control
var _speaker: Label
var _prompt: Label
var _prompt_buttons: HBoxContainer
var _restart_button: Button
var _hint_button: Button
var _leave_button: Button
var _lines: Array = []
var _line_index := 0
var _after_lines: Callable
var _handed: Array[DragPiece] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_fit_board)


func run(def: ActivityDefinition) -> void:
	definition = def
	_build_layout()
	_fit_board()
	if not Settings.get_value("reduced_motion"):
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.4)
	_play_lines(def.intro, _next_step)


# --- Layout ---------------------------------------------------------------

func _build_layout() -> void:
	var reflective := definition.is_reflection()
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.07, 0.12, 0.55) if reflective else Color(0.1, 0.08, 0.05, 0.35)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 10)
	column.offset_left = 16
	column.offset_right = -16
	column.offset_top = 12
	column.offset_bottom = -12
	add_child(column)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.card(Color("2c3550") if reflective else Color("fbf5e8"), 14))
	card.custom_minimum_size.y = 110
	column.add_child(card)
	var card_row := HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 16)
	card.add_child(card_row)
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_row.add_child(text_col)
	var ink := Color("f3ead8") if reflective else Color("3b3430")
	_speaker = Label.new()
	_speaker.add_theme_color_override("font_color", Color(ink, 0.7))
	_speaker.theme_type_variation = "SmallLabel"
	text_col.add_child(_speaker)
	_prompt = Label.new()
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt.add_theme_color_override("font_color", ink)
	_prompt.theme_type_variation = "PromptLabel"
	_prompt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_col.add_child(_prompt)
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_child(right)
	var hear := UiStyle.button(tr("Hear it"), false, "speaker")
	hear.pressed.connect(_on_hear_pressed)
	right.add_child(hear)
	_prompt_buttons = HBoxContainer.new()
	_prompt_buttons.alignment = BoxContainer.ALIGNMENT_END
	_prompt_buttons.add_theme_constant_override("separation", 8)
	text_col.add_child(_prompt_buttons)

	_board_holder = Control.new()
	_board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board_holder.resized.connect(_fit_board)
	column.add_child(_board_holder)
	_board = Board.new()
	_board.surface = SURFACES.get(definition.surface, SURFACES["wood_table"])
	_board.size = ActivityStep.BOARD_SIZE
	_board_holder.add_child(_board)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	column.add_child(bar)
	var pause := UiStyle.button(tr("Pause"), false, "pause")
	pause.pressed.connect(func() -> void: get_tree().call_group("main", "open_pause"))
	bar.add_child(pause)
	_restart_button = UiStyle.button(tr("Start over"), false, "restart")
	_restart_button.pressed.connect(_on_restart_pressed)
	bar.add_child(_restart_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_hint_button = UiStyle.button(tr("Show me"), false, "hint")
	_hint_button.pressed.connect(_on_hint_pressed)
	bar.add_child(_hint_button)
	_leave_button = UiStyle.button(tr("Return to the shelf") if reflective else tr("Finish later"), false, "box" if reflective else "door")
	_leave_button.pressed.connect(_on_leave_pressed)
	bar.add_child(_leave_button)
	_update_controls()
	cursor = VirtualCursor.new()
	add_child(cursor)


func _fit_board() -> void:
	if _board == null or _board_holder == null:
		return
	var avail := _board_holder.size
	if avail.x < 10 or avail.y < 10:
		return
	var s := minf(avail.x / ActivityStep.BOARD_SIZE.x, avail.y / ActivityStep.BOARD_SIZE.y)
	_board.scale = Vector2(s, s)
	_board.position = (avail - ActivityStep.BOARD_SIZE * s) / 2.0
	if step:
		step.snap_tolerance = Settings.get_value("snap_tolerance") / s


func board_scale() -> float:
	return _board.scale.x if _board else 1.0


# --- Spoken lines (intro/outro) --------------------------------------------

func _play_lines(lines: Array, then: Callable) -> void:
	_lines = lines
	_line_index = 0
	_after_lines = then
	_show_line()


func _show_line() -> void:
	if _line_index >= _lines.size():
		_set_prompt_buttons([])
		_after_lines.call()
		return
	var line: Dictionary = _lines[_line_index]
	var speaker := str(line.get("speaker", ""))
	_speaker.text = Dialogue.character_name(speaker) if not speaker.is_empty() else ""
	_set_prompt(tr(str(line.get("text", ""))))
	var last := _line_index == _lines.size() - 1
	var label := str(line.get("button", "Begin" if last and step_index < 0 else ("Done" if last else "Next")))
	_set_prompt_buttons([{"label": tr(label), "primary": true, "icon": "up" if label == "Stand up" else "next", "callback": func() -> void:
		_line_index += 1
		_show_line()}])


# --- Steps -------------------------------------------------------------------

func _next_step() -> void:
	if is_instance_valid(step):
		_handed = step.handoff()
		for p in _handed:
			p.reparent(_board, false)
		step.queue_free()
		step = null
	step_index += 1
	if step_index >= definition.steps.size():
		_update_controls()
		_play_lines(definition.outro, func() -> void: finished.emit(results))
		return
	var cfg: Dictionary = definition.steps[step_index]
	step = PrimitiveRegistry.create(str(cfg["primitive"]))
	step.reduced_motion = Settings.get_value("reduced_motion")
	step.snap_tolerance = Settings.get_value("snap_tolerance") / board_scale()
	step.prompt_changed.connect(_set_prompt)
	step.actions_changed.connect(_set_prompt_buttons)
	step.observed.connect(func(kind: String, data: Dictionary) -> void: observed.emit(kind, data))
	step.completed.connect(_on_step_completed)
	_board.add_child(step)
	var ctx := results.duplicate()
	ctx["pieces"] = _handed
	_speaker.text = Dialogue.character_name(str(cfg.get("speaker", ""))) if cfg.has("speaker") else ""
	_set_prompt_buttons([])
	step.begin(cfg, ctx)
	_update_controls()


func _on_step_completed(result: Dictionary) -> void:
	results[str(definition.steps[step_index].get("id", step_index))] = result
	_update_controls()
	await get_tree().create_timer(1.4).timeout
	# Let the "well done" words finish before the next step speaks over them.
	var waited := 0.0
	while is_inside_tree() and AudioService.is_speaking() and waited < 8.0:
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
	if is_inside_tree():
		_next_step()


## Test/automation hook: the step currently on the board.
func current_step() -> ActivityStep:
	return step


## Test/automation hook: presses the main button on the prompt card
## (Next/Begin/Continue). Returns false when there is none.
func press_primary() -> bool:
	for i in range(_prompt_buttons.get_child_count() - 1, -1, -1):
		var b := _prompt_buttons.get_child(i) as Button
		if b and not b.is_queued_for_deletion():
			b.pressed.emit()
			return true
	return false


func prompt_text() -> String:
	return _prompt.text


func _update_controls() -> void:
	var active := step != null and not step.is_done
	_restart_button.visible = active and step.supports_reset()
	_hint_button.visible = active and step.supports_hint()


func _set_prompt(text: String) -> void:
	_prompt.text = text
	AudioService.narrate(text)


func _set_prompt_buttons(actions: Array) -> void:
	for c in _prompt_buttons.get_children():
		c.queue_free()
	for a: Dictionary in actions:
		var primary: bool = a.get("primary", false)
		var b := UiStyle.button(str(a.get("label", "")), primary, str(a.get("icon", "next" if primary else "")))
		b.pressed.connect(a["callback"])
		_prompt_buttons.add_child(b)
	if actions.size() > 0:
		(_prompt_buttons.get_child(_prompt_buttons.get_child_count() - 1) as Button).call_deferred("grab_focus")


# --- Controls ----------------------------------------------------------------

func _on_hear_pressed() -> void:
	observed.emit("read_aloud_requested", {})
	if not AudioService.narrate(_prompt.text, true):
		# No system voice: the caption is already on screen; make it a little more prominent.
		_prompt.modulate = Color(1.2, 1.2, 1.2)
		create_tween().tween_property(_prompt, "modulate", Color.WHITE, 0.6)


func _on_hint_pressed() -> void:
	if step and not step.is_done:
		observed.emit("help_requested", {"step": step.config.get("id", "")})
		step.show_hint()


func _on_restart_pressed() -> void:
	if step and not step.is_done:
		observed.emit("restarted", {"step": step.config.get("id", "")})
		step.reset_step()


## Leaving asks first, so a stray tap doesn't sweep the child's work away.
func _on_leave_pressed() -> void:
	var card := ConfirmCard.new()
	get_parent().add_child(card)
	var reflective := definition.is_reflection()
	var question := tr("Put the story away for now?") if reflective else tr("Stop for now? Next time, this work starts from the beginning.")
	card.ask(question, tr("Yes, stop"), tr("Keep going"), func() -> void:
		AudioService.stop_narration()
		ActivityRunner.set_aside())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		# Keyboard/gamepad: activate the focused prompt button.
		var f := get_viewport().gui_get_focus_owner()
		if f is Button:
			(f as Button).pressed.emit()
			get_viewport().set_input_as_handled()


## The work surface: a table, garden soil or Atrium felt.
class Board:
	extends Control
	var surface: Dictionary

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		clip_contents = false

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var base: Color = surface["base"]
		var grain: Color = surface["grain"]
		# A rounded frame with a soft shadow beneath it.
		draw_rect(r.grow(16), Color(0, 0, 0, 0.18))
		draw_rect(r.grow(10), surface["edge"])
		draw_rect(r.grow(10), Color(surface["edge"]).darkened(0.25), false, 3.0)
		draw_rect(r, base)
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		match str(surface.get("kind", "wood")):
			"soil":
				# Crumbly earth: lighter and darker specks, a few small stones.
				for i in 420:
					var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
					draw_circle(p, rng.randf_range(1.5, 4.0), base.darkened(0.18) if i % 3 else base.lightened(0.1))
				for i in 14:
					var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
					draw_circle(p, rng.randf_range(4.0, 7.0), Color("a49480"))
			"felt":
				# Soft felt: short fibres in slightly different blues.
				for i in 900:
					var p := Vector2(rng.randf() * size.x, rng.randf() * size.y)
					var d := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(3.0, 7.0)
					draw_line(p, p + d, grain if i % 2 else base.darkened(0.1), 1.0)
			_:
				# Planks: each a slightly different shade, with grain, seams and a knot or two.
				var plank := 112.0
				var y := 0.0
				var row := 0
				while y < size.y:
					var shade := base.lightened(0.04) if row % 2 else base.darkened(0.03)
					draw_rect(Rect2(0, y, size.x, plank), shade)
					for k in 4:
						var gy := y + 14.0 + k * 26.0 + rng.randf_range(-4.0, 4.0)
						var pts := PackedVector2Array()
						for x in range(0, int(size.x) + 40, 40):
							pts.append(Vector2(x, gy + sin(x * 0.012 + row + k) * 3.0))
						draw_polyline(pts, grain, 1.5, true)
					if row % 2 == 0:
						# A small knot, stretched along the grain.
						var knot := Vector2(rng.randf_range(80.0, size.x - 80.0), y + rng.randf_range(30.0, plank - 30.0))
						var k := PackedVector2Array()
						for i in 16:
							var a := TAU * i / 16.0
							k.append(knot + Vector2(cos(a) * 14.0, sin(a) * 4.0))
						draw_colored_polygon(k, grain.darkened(0.08))
					draw_line(Vector2(0, y), Vector2(size.x, y), base.darkened(0.25), 2.0)
					y += plank
					row += 1
		# Light falls from the top-left: a soft darkening toward the edges.
		for i in 6:
			draw_rect(Rect2(Vector2.ZERO, size).grow(-i * 6.0), Color(0, 0, 0, 0.025), false, 6.0)
