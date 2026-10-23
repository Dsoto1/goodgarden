class_name Main
extends Node
## Top-level flow: title screen, starting or continuing a garden, ending the
## day, and the UI layers. Regions ask for things through the "main" group
## (request_rest, open_invitation, start_activity_here...) so world content
## never needs a direct reference to the UI.

var world: World
var hud: Hud
var title: TitleScreen

var _hud_root: Control
var _activity_root: Control
var _overlay_root: Control
var _fade: ColorRect
var _activity_focus: Variant = null # Vector3 or null
var _talk_target: Node3D
var _play_seconds := 0.0
var _rest_reminded := false
var _theme: Theme


func _ready() -> void:
	add_to_group("main")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_theme()
	Settings.changed.connect(func(key: String) -> void:
		if key in ["text_scale", "work_level"]:
			_apply_theme())
	_hud_root = _layer(1, Node.PROCESS_MODE_PAUSABLE)
	_activity_root = _layer(2, Node.PROCESS_MODE_PAUSABLE)
	_overlay_root = _layer(3, Node.PROCESS_MODE_ALWAYS)
	var fade_root := _layer(10, Node.PROCESS_MODE_ALWAYS)
	_fade = ColorRect.new()
	_fade.color = Color(0.06, 0.05, 0.04, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_root.add_child(_fade)
	ActivityRunner.host = _activity_root
	ActivityRunner.activity_started.connect(_on_activity_started)
	ActivityRunner.activity_finished.connect(_on_activity_finished)
	Dialogue.conversation_started.connect(_on_conversation_started)
	Dialogue.conversation_ended.connect(_on_conversation_ended)
	Interaction.interacted.connect(func(t: Interactable) -> void: _talk_target = t)
	show_title()


func _layer(index: int, mode: Node.ProcessMode) -> Control:
	var layer := CanvasLayer.new()
	layer.layer = index
	layer.process_mode = mode
	add_child(layer)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_to_group("ui_roots")
	root.theme = _theme
	return root


## Themes don't cross CanvasLayers, so every layer's root gets the theme.
func _apply_theme() -> void:
	_theme = UiStyle.build_theme(UiStyle.text_scale())
	for root in get_tree().get_nodes_in_group("ui_roots"):
		(root as Control).theme = _theme


# --- Title and game start -----------------------------------------------------

func show_title() -> void:
	_teardown_world()
	GameState.reset(GameState.Mode.TITLE)
	AudioService.set_ambience("outdoor", 1.0)
	title = TitleScreen.new()
	title.continue_pressed.connect(continue_game)
	title.new_pressed.connect(func() -> void:
		if SaveService.has_save():
			var c := ConfirmCard.new()
			_overlay_root.add_child(c)
			c.ask(tr("Start a brand new garden? Your old garden will be gone."), tr("Yes, start over"), tr("Go back"), start_new_game)
		else:
			start_new_game())
	title.settings_pressed.connect(open_settings)
	title.close_pressed.connect(quit_game)
	_overlay_root.add_child(title)


func start_new_game() -> void:
	SaveService.new_game()
	_enter_world()
	Days.start_day(1)
	SaveService.save_game()
	show_caption(tr("Day 1. Good morning! A letter is waiting for you by the door."), 6.0)


func continue_game() -> bool:
	if not SaveService.load_game():
		return false
	_enter_world()
	show_caption(tr("Welcome back. It's %s.") % Days.weekday_name())
	return true


func _enter_world() -> void:
	if is_instance_valid(title):
		title.queue_free()
	_teardown_world()
	world = World.new()
	world.name = "World"
	add_child(world)
	move_child(world, 0)
	hud = Hud.new()
	_hud_root.add_child(hud)
	_hud_root.add_child(DialogueBox.new())
	GameState.reset(GameState.Mode.EXPLORE)
	_play_seconds = 0.0
	_rest_reminded = false


func _teardown_world() -> void:
	if ActivityRunner.is_running():
		ActivityRunner.set_aside()
	if Dialogue.is_active():
		Dialogue.end()
	for c in _hud_root.get_children() if _hud_root else []:
		c.queue_free()
	if is_instance_valid(world):
		remove_child(world)
		world.free()
	world = null
	hud = null


func quit_to_title() -> void:
	SaveService.save_game()
	show_title()


## Saves (when a garden is open) and closes the game.
func quit_game() -> void:
	if world:
		SaveService.save_game()
	get_tree().quit()


## Whether the game can close itself: on a computer, yes; in a browser tab or
## on a phone or tablet the system closes apps, so there is no button for it.
static func can_close_itself() -> bool:
	return not (OS.has_feature("web") or OS.has_feature("ios") or OS.has_feature("android"))


# --- Requests from the world (via the "main" group) ----------------------------

func request_rest() -> void:
	# The bed reminds the child of anything still waiting today (the letter,
	# or jobs not yet done), but the choice stays theirs: "Keep working" is
	# the answer that starts selected, and "Rest anyway" is still there.
	var question := tr("Rest until morning?")
	var yes := tr("Yes, rest")
	var no := tr("Not yet")
	var left := TodaysWork.today().filter(func(j: Dictionary) -> bool: return not j["done"]).map(func(j: Dictionary) -> String: return tr(j["text"]))
	if Invitations.has_unread():
		question = tr("Today's letter is still waiting by the door. Rest anyway?")
		yes = tr("Rest anyway")
		no = tr("Read it first")
	elif not left.is_empty():
		var list: String = left[0] if left.size() == 1 else ", ".join(left.slice(0, left.size() - 1)) + " " + tr("and") + " " + left[left.size() - 1]
		question = tr("There is still a job to do: %s. Rest anyway?") % list if left.size() == 1 else tr("There are still jobs to do: %s. Rest anyway?") % list
		yes = tr("Rest anyway")
		no = tr("Keep working")
	var c := ConfirmCard.new()
	_overlay_root.add_child(c)
	c.ask(question, yes, no, rest_until_morning)


func rest_until_morning() -> void:
	GameState.push_mode(GameState.Mode.TRANSITION)
	await _fade_to(1.0)
	Days.end_day()
	world.move_player_to_anchor("home_spawn")
	SaveService.save_game()
	await get_tree().create_timer(0.4).timeout
	await _fade_to(0.0)
	GameState.pop_mode(GameState.Mode.TRANSITION)
	var line := tr("Good morning! It's %s.") % Days.weekday_name()
	if Days.is_sunday():
		line += " " + tr("Sunday is a day of rest. Listen: the chapel bells are ringing.")
	elif Days.weekday() == "saturday":
		line += " " + tr("Saturday is a free day. Play, explore, or do any work you like.")
	if Invitations.has_unread():
		line += " " + tr("A new letter is waiting by the door.")
	for place in newly_open_places():
		line += " " + tr("Something new: %s is open on the map!") % place
	show_caption(line, 6.0)


## Places in the wider world that opened this morning.
func newly_open_places() -> Array[String]:
	var out: Array[String] = []
	for entry: Dictionary in Content.get_world("regions").get("regions", []):
		if not World.is_open(entry):
			continue
		for c: Dictionary in entry["open_when"]:
			if int(c.get("day_at_least", -1)) == Days.current_day:
				out.append(tr(str(entry["name"])))
	return out


func open_invitation(invitation_id: String) -> void:
	if invitation_id.is_empty():
		return
	var card := InvitationCard.new()
	_overlay_root.add_child(card)
	card.show_invitation(invitation_id)


func reread_invitation() -> void:
	var id := Invitations.latest_read()
	if not id.is_empty():
		var card := InvitationCard.new()
		_overlay_root.add_child(card)
		card.show_invitation(id, false)


func start_activity_here(activity_id: String, focus: Vector3) -> void:
	if not ActivityRunner.can_start(activity_id):
		var def := Content.get_activity(activity_id)
		if def and not def.unavailable_text.is_empty():
			show_caption(tr(def.unavailable_text))
		return
	_activity_focus = focus
	ActivityRunner.start(activity_id)


func sit_quietly(focus: Vector3, distance := 3.2, pitch := 12.0, yaw := 0.0, on_stand := Callable()) -> void:
	# Deliberately unrecorded: quiet time is the child's own.
	GameState.push_mode(GameState.Mode.REFLECTION)
	world.rig.focus_on(focus, distance, pitch, yaw)
	var stand := UiStyle.button(tr("Stand up"), false, "up")
	stand.modulate.a = 0.75
	stand.grow_horizontal = Control.GROW_DIRECTION_BOTH
	stand.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_overlay_root.add_child(stand)
	stand.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 30)
	stand.pressed.connect(func() -> void:
		stand.queue_free()
		if on_stand.is_valid():
			on_stand.call()
		world.rig.release_focus()
		GameState.pop_mode(GameState.Mode.REFLECTION))
	stand.call_deferred("grab_focus")


func show_caption(text: String, seconds := 4.5) -> void:
	if hud:
		hud.show_caption(text, seconds)


## The chapel library's book shelf.
func open_library() -> void:
	var p := BookPanel.new()
	_overlay_root.add_child(p)
	p.show_shelf()


func open_journal() -> void:
	var p := JournalPanel.new()
	_overlay_root.add_child(p)
	p.show_journal()


func open_map() -> void:
	if Discovery.map_unlocked():
		var p := MapPanel.new()
		_overlay_root.add_child(p)
		p.show_map()


func travel_to(region_id: String) -> void:
	GameState.push_mode(GameState.Mode.TRANSITION)
	await _fade_to(1.0)
	world.travel_to(region_id)
	await _fade_to(0.0)
	GameState.pop_mode(GameState.Mode.TRANSITION)


func open_pause() -> void:
	var p := PauseMenu.new()
	_overlay_root.add_child(p)
	p.show_menu()


func open_settings() -> void:
	var p := SettingsPanel.new()
	_overlay_root.add_child(p)
	p.show_settings()


func open_parents() -> void:
	var p := ParentPanel.new()
	_overlay_root.add_child(p)
	p.show_gate()


func _unhandled_input(event: InputEvent) -> void:
	if world == null:
		return
	# Pause anywhere outside protected transitions.
	if event.is_action_pressed("pause") and GameState.mode() in [GameState.Mode.EXPLORE, GameState.Mode.ACTIVITY, GameState.Mode.REFLECTION, GameState.Mode.DIALOGUE]:
		open_pause()
		get_viewport().set_input_as_handled()
		return
	if not GameState.is_exploring():
		return
	if event.is_action_pressed("pause"):
		open_pause()
	elif event.is_action_pressed("journal"):
		open_journal()
	elif event.is_action_pressed("map"):
		open_map()
	else:
		return
	get_viewport().set_input_as_handled()


# --- Camera framing for conversations and activities --------------------------

func _on_conversation_started(_id: String) -> void:
	if world and is_instance_valid(_talk_target):
		var mid := (world.player.global_position + _talk_target.global_position) / 2.0
		world.rig.focus_on(mid + Vector3(0, 1.0, 0), 6.0, 32.0)


func _on_conversation_ended(_id: String) -> void:
	if world and not ActivityRunner.is_running():
		world.rig.release_focus()


func _on_activity_started(_def: ActivityDefinition) -> void:
	if world == null:
		return
	var focus: Vector3 = _activity_focus if _activity_focus != null else world.player.global_position + Vector3(0, 0.5, 0)
	if _activity_focus == null and is_instance_valid(_talk_target):
		# Started from conversation: frame the interactable nearest the speaker (e.g. the bean row).
		focus = _nearest_focus_point()
	world.rig.focus_on(focus, 4.0, 60.0)
	_activity_focus = focus


func _on_activity_finished(def: ActivityDefinition, completed: bool) -> void:
	if world == null:
		return
	# A solid sign the work is finished (practical work only: stories are not "done").
	if completed and not def.is_reflection():
		DoneSeal.show_for(_overlay_root, tr(def.title))
	if completed and _activity_focus != null:
		# Linger on the changed world for a moment before handing control back.
		GameState.push_mode(GameState.Mode.TRANSITION)
		world.rig.focus_on(_activity_focus, 6.0, 48.0)
		await get_tree().create_timer(2.2).timeout
		GameState.pop_mode(GameState.Mode.TRANSITION)
	if world:
		world.rig.release_focus()
	_activity_focus = null
	if hud:
		hud.refresh() # says "Today's work is done!" if that was the last job
	# The at-home idea is kept in the journal for a grown-up, not shown here: in
	# the moment it read like a new task ("set the table" right after setting it).


func _nearest_focus_point() -> Vector3:
	var best := world.player.global_position
	var best_d := INF
	for node in get_tree().get_nodes_in_group("activity_focus"):
		var d: float = node.global_position.distance_to(world.player.global_position)
		if d < best_d:
			best_d = d
			best = node.global_position
	return best


# --- Fades and gentle rest reminder ---------------------------------------------

func _fade_to(alpha: float) -> void:
	var seconds := 0.05 if Settings.get_value("reduced_motion") else 0.6
	var t := create_tween()
	t.tween_property(_fade, "color:a", alpha, seconds)
	await t.finished


func _process(delta: float) -> void:
	if world == null or not GameState.is_exploring():
		return
	_play_seconds += delta
	var minutes := int(Settings.get_value("session_minutes"))
	if minutes > 0 and not _rest_reminded and _play_seconds >= minutes * 60.0:
		_rest_reminded = true
		var c := ConfirmCard.new()
		_overlay_root.add_child(c)
		c.ask(tr("Good work today! Time to rest your eyes and play outside."), tr("Save and rest"), tr("Keep playing"), quit_to_title)
