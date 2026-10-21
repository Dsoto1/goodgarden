extends Node
## Headless test suite. Run:
##   godot --headless --path . res://tests/test_runner.tscn
## Exits with code 0 when every test passes, 1 otherwise.
##
## Unit tests cover world facts, conditions, saves and each activity
## primitive; the end-to-end test plays the vertical slice's required flow
## (letter -> Miriam -> planting -> table -> Atrium -> rest -> save/reload)
## through the same calls real input uses.

const SAVE_PATH := "user://test_saves/test_garden.json"
## Raise this as tests are added; fewer checks means some never ran.
const MIN_CHECKS := 300

var _failures := 0
var _checks := 0
var _current := ""


func _ready() -> void:
	Settings.persist = false
	Settings.set_value("reduced_motion", true) # tweens become instant
	SaveService.path = SAVE_PATH
	SaveService.delete_save()
	var tests := [
		test_content_is_valid, test_validator_catches_errors, test_conditions_and_tokens,
		test_save_round_trip_and_migration, test_space_along_line, test_count_into_slots,
		test_match_to_outline_self_correction, test_story_handoff_and_put_away, test_parable_growth_and_put_away, test_chapel_library_books,
		test_observations_never_score_reflection, test_pointer_events_drag_pieces, test_props_catalog,
		test_scenery_quality_and_batching, test_vertical_slice_end_to_end,
	]
	for t: Callable in tests:
		_current = t.get_method()
		SaveService.new_game()
		await t.call()
	SaveService.delete_save()
	# A script that fails to compile makes its checks vanish rather than fail.
	check(_checks >= MIN_CHECKS, "at least %d checks ran (did a script fail to compile?)" % MIN_CHECKS)
	print("\n%d checks, %d failure(s)" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("FAIL [%s] %s" % [_current, what])


func eq(a: Variant, b: Variant, what: String) -> void:
	check(a == b, "%s (got %s, expected %s)" % [what, a, b])


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func frames(n := 2) -> void:
	for i in n:
		await get_tree().process_frame


# --- Unit tests -----------------------------------------------------------------

func test_content_is_valid() -> void:
	var errors := ContentValidator.new().run()
	for e in errors:
		printerr("  content: ", e)
	eq(errors.size(), 0, "authored content has no validation errors")


func test_validator_catches_errors() -> void:
	var bad := ActivityDefinition.from_dict({"id": "bad", "steps": [{"id": "a", "primitive": "juggle"}, {"id": "a", "primitive": "story_figures"}], "replay": "sometimes"})
	var errors := bad.validate()
	check(errors.size() >= 3, "unknown primitive, duplicate step id and bad replay are reported (%s)" % [errors])


func test_conditions_and_tokens() -> void:
	Days.current_day = 3
	WorldState.set_fact("garden.bed_1", {"crop": "beans"})
	WorldState.set_fact("home.table_set_day", 3)
	check(WorldState.matches([{"fact": "garden.bed_1", "exists": true}]), "exists")
	check(WorldState.matches([{"fact": "home.table_set_day", "is_today": true}]), "is_today")
	check(not WorldState.matches([{"not": {"fact": "home.table_set_day", "is_today": true}}]), "not")
	check(WorldState.matches([{"any": [{"day": 1}, {"day_at_least": 2}]}]), "any/day_at_least")
	WorldState.apply_effects([{"op": "set", "fact": "x", "value": {"d": "$day", "n": "$s.count"}}, {"op": "increment", "fact": "y"}, {"op": "increment", "fact": "y"}], {"day": 3, "s.count": 4})
	eq(WorldState.get_fact("x"), {"d": 3, "n": 4}, "tokens resolve inside values")
	eq(WorldState.get_fact("y"), 2, "increment")


func test_save_round_trip_and_migration() -> void:
	Days.current_day = 2
	WorldState.set_fact("garden.bed_1", {"crop": "beans", "planted_day": 1})
	Journal.add("work", "I planted beans.", "garden_bean_row")
	Discovery.discover("garden")
	Invitations.deliver("inv_day_002")
	check(SaveService.save_game(), "save succeeds")
	SaveService.new_game()
	check(not WorldState.has_fact("garden.bed_1"), "new game clears facts")
	check(SaveService.load_game(), "load succeeds")
	eq(Days.current_day, 2, "day restored")
	eq(int(WorldState.get_fact("garden.bed_1")["planted_day"]), 1, "fact restored")
	eq(Journal.entries().size(), 1, "journal restored")
	check(Discovery.is_discovered("garden"), "discovery restored")
	Discovery.enter("home")
	Discovery.enter("river", false)
	eq(Discovery.current, "river", "a small place labels the HUD while inside it")
	check(not Discovery.is_discovered("river"), "small places are not map destinations")
	Discovery.leave("river")
	eq(Discovery.current, "home", "leaving a place falls back to the region around it")
	eq(Invitations.pending_id, "inv_day_002", "unread letter restored")
	var old := {"schema_version": 0, "flags": {"home.table_set_day": 1}, "days": {"current_day": 1}}
	var migrated := SaveService.migrate(old)
	eq(migrated.get("schema_version"), SaveService.SCHEMA_VERSION, "migrated to current schema")
	check(migrated.get("world", {}).has("home.table_set_day"), "v0 flags moved to world facts")
	check(SaveService.migrate({"schema_version": 99}).is_empty(), "saves from the future are refused, not corrupted")


func _make_step(primitive: String, cfg: Dictionary, ctx := {}) -> ActivityStep:
	var step := PrimitiveRegistry.create(primitive)
	step.reduced_motion = true
	add_child(step)
	step.begin(cfg, ctx)
	return step


func _drop(piece: DragPiece, center: Vector2) -> void:
	piece.set_center(center)
	piece.grabbed.emit(piece)
	piece.set_center(center)
	piece.dropped.emit(piece)


func test_space_along_line() -> void:
	var step := _make_step("space_along_line", {"id": "s", "markers": 3, "stick_length": 170, "tolerance": 20})
	var result := []
	step.completed.connect(func(r: Dictionary) -> void: result.append(r))
	var corrections := []
	step.observed.connect(func(k: String, _d: Dictionary) -> void: corrections.append(k))
	var targets: Array[float] = step.required_positions()
	_drop(step.markers[0], Vector2(targets[0], 300))
	_drop(step.markers[1], Vector2(targets[0] + 60, 300)) # crowded
	_drop(step.markers[2], Vector2(targets[2], 300))
	check(result.is_empty(), "crowded spacing does not complete")
	check(step._gap_state.has(-1), "crowded gap is detected")
	_drop(step.markers[1], Vector2(targets[1] + 8, 300)) # within tolerance
	eq(result.size(), 1, "correct spacing completes")
	check(corrections.has("self_correction"), "fixing a gap is observed as a self-correction")
	if result.size() > 0:
		eq(result[0]["count"], 3, "result count")
		eq(result[0]["positions"].size(), 3, "result positions")
	step.queue_free()


func test_count_into_slots() -> void:
	var step := _make_step("count_into_slots", {"id": "c", "slots": 2, "per_slot": 3, "spare": 2})
	var result := []
	step.completed.connect(func(r: Dictionary) -> void: result.append(r))
	eq(step.pieces.size(), 8, "supply is holes x per_slot + spare")
	var holes: Array[DropSlot] = step.holes
	for i in 3:
		_drop(step.pieces[i], holes[0].center())
	_drop(step.pieces[3], holes[0].center()) # overfill: rolls back
	eq(holes[0].contents.size(), 3, "a full hole refuses a fourth seed")
	check(step.pieces[3].placed_in == null, "the extra seed is not placed")
	for i in range(3, 6):
		_drop(step.pieces[i], holes[1].center())
	eq(result.size(), 1, "all holes filled completes the step")
	if result.size() > 0:
		eq(result[0], {"slots": 2, "per_slot": 3, "pieces": 6}, "result")
	step.queue_free()


func test_match_to_outline_self_correction() -> void:
	var step := _make_step("match_to_outline", {"id": "m", "slots": [{"kind": "plate", "pos": [200, 150]}, {"kind": "fork", "pos": [400, 150]}]})
	var events := []
	step.observed.connect(func(k: String, _d: Dictionary) -> void: events.append(k))
	var done := []
	step.completed.connect(func(r: Dictionary) -> void: done.append(r))
	var plate: DragPiece
	var fork: DragPiece
	for p in step.pieces:
		if p.kind == "plate":
			plate = p
		else:
			fork = p
	_drop(fork, step.slots[0].center())
	check(fork.placed_in == null, "a fork does not settle on a plate outline")
	check(events.has("mismatch"), "mismatch observed")
	_drop(fork, step.slots[1].center())
	check(events.has("self_correction"), "placing it correctly afterwards is a self-correction")
	_drop(plate, step.slots[0].center())
	eq(done.size(), 1, "all pieces placed completes")
	step.queue_free()


func test_story_handoff_and_put_away() -> void:
	var def := Content.get_activity("good_samaritan")
	var story := _make_step("story_figures", def.steps[0])
	var finished := []
	story.completed.connect(func(r: Dictionary) -> void: finished.append(r))
	for i in def.steps[0]["segments"].size():
		story._next_segment()
	for i in def.steps[0]["wonderings"].size():
		story._wonder += 1
		story._show_wondering()
	check(story._phase == story.Phase.RETELL, "story reaches free retelling")
	story.put_away()
	eq(finished.size(), 1, "putting away ends the story step")
	var pieces := story.handoff()
	eq(pieces.size(), 6, "all six figures are handed to the put-away step")
	var put_away := _make_step("match_to_outline", def.steps[1], {"pieces": pieces})
	var done := []
	put_away.completed.connect(func(r: Dictionary) -> void: done.append(r))
	for slot in put_away.slots:
		for p in put_away.pieces:
			if p.kind == slot.accepts:
				_drop(p, slot.center())
	eq(done.size(), 1, "every figure returned to its compartment")
	story.queue_free()
	put_away.queue_free()


## The Mustard Seed: the seed gives way to the sprout and the grown plant,
## and figures the story set back in the box count as already put away.
func test_parable_growth_and_put_away() -> void:
	for id: String in ["mustard_seed", "leaven", "lost_sheep"]:
		check(Content.get_activity(id) != null, "%s is authored" % id)
	var def := Content.get_activity("mustard_seed")
	var opening := PrimitiveRegistry.create("story_figures")
	opening.reduced_motion = true
	add_child(opening)
	var seen := []
	opening.prompt_changed.connect(func(t: String) -> void: seen.append(t))
	opening.begin(def.steps[0], {})
	check(not seen.is_empty() and str(seen.back()).begins_with("Jesus wanted"), "a story opens with its first line showing, not an empty prompt")
	opening.queue_free()
	var story := _make_step("story_figures", def.steps[0])
	for i in def.steps[0]["segments"].size():
		story._next_segment()
	var seed: DragPiece = story.figures["seed"]
	check(seed.position.distance_to(seed.home) < 1.0, "the seed returns to the box when the sprout appears")
	check(story.figures["bush"].visible and story.figures["bird_a"].visible, "the grown plant and the birds are out")
	story.put_away()
	var put_away := _make_step("match_to_outline", def.steps[1], {"pieces": story.handoff()})
	var resting: Array = put_away.slots.filter(func(sl: DropSlot) -> bool: return not sl.contents.is_empty())
	eq(resting.size(), 2, "the seed and sprout are already in their places")
	var done := []
	put_away.completed.connect(func(r: Dictionary) -> void: done.append(r))
	for slot in put_away.slots:
		for p in put_away.pieces:
			if p.kind == slot.accepts and p.placed_in == null:
				_drop(p, slot.center())
	eq(done.size(), 1, "the rest go back and the material is put away")
	var shelf: Array = Content.get_world("atrium_shelf").get("items", [])
	eq(shelf.size(), 4, "four materials on the Atrium shelf")
	story.queue_free()
	put_away.queue_free()


## The chapel library: every book has pages, and the reader turns them
## without running past either end.
func test_chapel_library_books() -> void:
	var books: Array = Content.get_world("library").get("books", [])
	check(books.size() >= 3, "the library has books")
	for b: Dictionary in books:
		check(not str(b.get("title", "")).is_empty() and b.get("pages", []).size() > 0, "%s has a title and pages" % b.get("id", "?"))
	var panel := BookPanel.new()
	add_child(panel)
	panel.show_shelf()
	panel.open_book(books[0])
	eq(panel.page(), 0, "a book opens at its first page")
	panel.turn(-1)
	eq(panel.page(), 0, "no page before the first")
	for i in 20:
		panel.turn(1)
	eq(panel.page(), panel.page_count() - 1, "no page after the last")
	panel.close()
	await frames(2)
	var names := {}
	for place: Dictionary in Content.get_world("regions").get("places", []):
		names[place["id"]] = place["name"]
	for id: String in ["chapel_hall", "atrium", "library"]:
		check(names.has(id), "the chapel's %s has a name for the HUD" % id)


func test_observations_never_score_reflection() -> void:
	Observations.record("activity_started", "good_samaritan")
	Observations.record("retold", "good_samaritan", {"seconds": 150})
	Observations.record("activity_completed", "good_samaritan", {"seconds": 400})
	var text := "\n".join(Observations.summarize())
	check(text.contains("chosen 1 time"), "reports that the material was chosen")
	check(not text.contains("completed"), "does not report Scripture work as completion")
	check(not text.contains("%"), "no percentages")


## Real pointer events (as sent by mouse, touch emulation and the gamepad
## cursor) pick up a piece and drop it on its outline.
func test_pointer_events_drag_pieces() -> void:
	var main: Main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await frames()
	main.start_new_game()
	await frames(3)
	check(ActivityRunner.start("home_set_table"), "table setting starts")
	var ws := ActivityRunner.workspace
	await _play_intro(ws)
	await frames(2)
	var step := ws.current_step()
	var slot: DropSlot = step.slots[2]
	var piece: DragPiece
	for p: DragPiece in step.pieces:
		if p.kind == slot.accepts:
			piece = p
	var to_screen := func(c: CanvasItem, local: Vector2) -> Vector2: return c.get_global_transform_with_canvas() * local
	var cursor := ws.cursor
	cursor.move_to(to_screen.call(step, piece.center()))
	cursor.press()
	await frames()
	check(piece.dragging, "virtual cursor press grabs the piece")
	var dest: Vector2 = to_screen.call(step, slot.center())
	for i in 6:
		cursor.move_to(cursor.pointer.lerp(dest, 0.5 if i < 5 else 1.0))
		await frames(1)
	cursor.release()
	await frames()
	check(piece.placed_in == slot, "dropped on its outline through real input events")
	ActivityRunner.set_aside()
	main.quit_to_title()
	await frames(2)
	main.queue_free()
	await frames(2)


## Every catalogued third-party prop loads and lands at a sensible game size.
func test_props_catalog() -> void:
	var holder := Node3D.new()
	add_child(holder)
	for id: String in Props.catalog()["props"]:
		var prop := Props.place(holder, id, Vector3.ZERO)
		check(prop != null, "prop '%s' instantiates" % id)
		if prop:
			var size := Props.bounds(prop).size
			check(size.length() > 0.05 and maxf(size.x, maxf(size.y, size.z)) < 60.0, "prop '%s' has a sensible size %s" % [id, size])
	holder.queue_free()
	await frames()


# --- End to end -------------------------------------------------------------------

func test_scenery_quality_and_batching() -> void:
	Settings.set_value("scenery_quality", "auto")
	Settings.apply_stored({"lush_detail": false})
	eq(Settings.get_value("scenery_quality"), "low", "the old 'less detail' switch becomes the Light tier")
	eq(Quality.tier(), "low", "an explicit tier is used as chosen")
	Settings.set_value("scenery_quality", "auto")
	check(Quality.tier() in ["high", "medium"], "auto picks a tier for the device")
	for tier: String in Quality.TIERS:
		eq(Quality.TIERS[tier].keys(), Quality.TIERS["high"].keys(), "tier %s sets every option" % tier)
	# Two flat-coloured boxes merge into one mesh that keeps their colours;
	# a live container is left alone.
	var root := Node3D.new()
	add_child(root)
	MeshKit.box(root, Vector3.ONE, Vector3(0, 0, 0), "wood")
	MeshKit.box(root, Vector3.ONE, Vector3(2, 0, 0), "stone")
	var live := Node3D.new()
	StaticBatch.mark_live(live)
	root.add_child(live)
	var kept := MeshKit.box(live, Vector3.ONE, Vector3(4, 0, 0), "wood")
	var merged := StaticBatch.merge(root, INF)
	eq(merged, 2, "static boxes merged")
	check(kept.mesh != null, "live nodes are not merged")
	var batches: Array[MeshInstance3D] = []
	for c in root.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			batches.append(c)
	var colors := {}
	for b in batches:
		var arrays := b.mesh.surface_get_arrays(0)
		for c: Color in arrays[Mesh.ARRAY_COLOR]:
			colors[c.to_html()] = true
	check(colors.size() >= 2, "merged mesh keeps each piece's colour")
	root.queue_free()


func test_vertical_slice_end_to_end() -> void:
	var main: Main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await frames()
	main.start_new_game()
	await frames(3)
	var world := main.world
	check(world != null, "world built")
	eq(GameState.mode(), GameState.Mode.EXPLORE, "exploring after start")
	eq(Days.current_day, 1, "day 1")
	check(Invitations.has_unread(), "day 1 letter waiting")
	check(world.player.global_position.distance_to(world.anchor("home_spawn").global_position) < 0.5, "child begins at home")
	# The river winds, but the only ways over it are the bridge and the stepping stones.
	for route: Array in [[Vector3(-3, 0, -6), Vector3(-3, 0, -22)], [Vector3(-14, 0, -6), Vector3(-14, 0, -23)], [Vector3(20, 0, -7), Vector3(20, 0, -21)]]:
		var crossing := NavigationServer3D.map_get_path(world.get_world_3d().navigation_map, route[0], route[1], true)
		var wet := 0
		for p: Vector3 in crossing:
			var on_bridge := p.x > 3.5 and p.x < 7.5
			var on_stones := absf(p.x - ValleyRegion.FORD_X) < 1.5
			if Terrain.river_bank_distance(p.x, p.z) < -0.5 and not on_bridge and not on_stones:
				wet += 1
		check(crossing.size() > 1 and wet == 0, "the river is crossed only by the bridge or the stepping stones")

	# 1-2. Read the invitation at home.
	var letter := _interactable("Read the letter")
	check(letter != null and letter.is_available(), "letter is available at home")
	await _walk_and_use(world, letter)
	var card := _find(main, InvitationCard) as InvitationCard
	check(card != null, "invitation card opened")
	if card:
		card.close()
	await frames()
	check(not Invitations.has_unread(), "letter read")
	check(Journal.has_entry("invitation", "inv_day_001"), "letter kept in the journal")

	# 3-5. Walk to the garden, talk to Miriam, accept.
	var miriam: NPC = world.npcs["miriam"]
	check(miriam.visible, "Miriam is in the garden today")
	await _walk_and_use(world, miriam.talk)
	check(Discovery.is_discovered("garden"), "garden discovered by walking there")
	check(Dialogue.is_active(), "conversation started")
	Dialogue.advance() # "You found my letter."
	check(Dialogue.current_line()["choices"].size() == 2, "Miriam offers a choice")
	Dialogue.choose(0)
	Dialogue.advance()
	await frames(3)
	check(ActivityRunner.is_running(), "planting activity started from conversation")
	eq(GameState.mode(), GameState.Mode.ACTIVITY, "activity mode")

	# 6. Tactile seed spacing and counting with self-correction.
	var ws := ActivityRunner.workspace
	await _play_intro(ws)
	var spacing := ws.current_step()
	var targets: Array[float] = spacing.required_positions()
	for i in spacing.markers.size():
		var x := targets[i] + (45.0 if i == 1 else 0.0) # one peg a little too far first
		_drop(spacing.markers[i], Vector2(x, 300))
	check(not spacing.is_done, "uneven spacing waits for the child")
	_drop(spacing.markers[1], Vector2(targets[1], 300))
	check(spacing.is_done, "spacing completes once corrected")
	await wait(1.6)
	var sowing := ws.current_step()
	check(sowing != null and sowing != spacing, "moved on to sowing")
	var k := 0
	for hole: DropSlot in sowing.holes:
		for n in 3:
			_drop(sowing.pieces[k], hole.center())
			k += 1
	check(sowing.is_done, "every hole has three seeds")
	await wait(1.6)
	await _play_outro(ws)
	await wait(0.2)
	check(not ActivityRunner.is_running(), "activity finished")

	# 7. The world shows the planted bed.
	var bed: Variant = WorldState.get_fact("garden.bed_1")
	check(bed is Dictionary, "garden.bed_1 fact written")
	if bed is Dictionary:
		eq(bed["holes"], 4, "four holes")
		eq(bed["seeds_per_hole"], 3, "three seeds each")
		eq(bed["planted_day"], 1, "planted on day 1")
	var garden: Node = world.regions["garden"]
	check(not garden._bed_1_ready.visible, "raked-and-ready look replaced")
	await frames()
	check(garden._bed_1_plants.get_child_count() > 0, "planted mounds visible")
	check(Journal.has_entry("real_world", "rw_seed_look"), "optional real-world invitation offered")
	await wait(2.6)
	eq(GameState.mode(), GameState.Mode.EXPLORE, "free exploration resumes")

	# Second activity: practical life at home, reusing the framework.
	var table := _interactable("Set the table")
	await _walk_and_use(world, table)
	check(ActivityRunner.is_running() and ActivityRunner.current.id == "home_set_table", "table setting started")
	ws = ActivityRunner.workspace
	await _play_intro(ws)
	var matching := ws.current_step()
	for slot: DropSlot in matching.slots:
		for p: DragPiece in matching.pieces:
			if p.placed_in == null and p.kind == slot.accepts:
				_drop(p, slot.center())
				break
	check(matching.is_done, "table set")
	await wait(1.6)
	await _play_outro(ws)
	await wait(2.8)
	check(world.regions["home"]._table_settings.visible, "table stays set in the world")
	check(not table.is_available(), "table cannot be set twice in a day")

	# 9-11. Chapel/Atrium: choose the Good Samaritan, listen, retell, put away.
	var shelf := _interactable("Choose The Good Samaritan")
	await _walk_and_use(world, shelf)
	check(Discovery.is_discovered("chapel"), "chapel discovered by walking there")
	eq(world.mood, "chapel", "chapel mood is active inside")
	eq(AudioService.current_ambience(), "chapel", "chapel has its own soundscape")
	check(ActivityRunner.is_running(), "presentation started")
	eq(GameState.mode(), GameState.Mode.REFLECTION, "reflection mode, not task mode")
	ws = ActivityRunner.workspace
	check(not ws._hint_button.visible and not ws._restart_button.visible, "no hints or restart in the presentation")
	await _play_intro(ws)
	# Story segments, wonderings, then free retelling: press the primary button through them.
	var story := ws.current_step()
	var guard := 0
	while story._phase != story.Phase.RETELL and guard < 40:
		ws.press_primary()
		await frames()
		guard += 1
	check(story._phase == story.Phase.RETELL, "reached retelling")
	story.put_away()
	await wait(1.6)
	var put_away := ws.current_step()
	for slot: DropSlot in put_away.slots:
		for p: DragPiece in put_away.pieces:
			if p.kind == slot.accepts:
				_drop(p, slot.center())
	check(put_away.is_done, "materials returned to the box")
	await wait(1.6)
	await _play_outro(ws)
	await wait(2.8)
	eq(WorldState.get_fact("chapel.good_samaritan.visits"), 1, "visit remembered without a score")

	# 12. Save, quit, reload: world state remains.
	var player_pos := world.player.global_position
	main.quit_to_title()
	await frames(3)
	check(main.world == null, "back at the title")
	SaveService.new_game() # make sure nothing survives in memory
	check(main.continue_game(), "continue from save")
	await frames(3)
	world = main.world
	bed = WorldState.get_fact("garden.bed_1")
	check(bed is Dictionary and int(bed["holes"]) == 4, "bean row persisted across reload")
	check(world.regions["home"]._table_settings.visible, "set table persisted across reload")
	check(world.player.global_position.distance_to(player_pos) < 0.5, "child is where they left off")
	check(Journal.entries().size() >= 5, "journal persisted")
	check(Discovery.is_discovered("chapel"), "discoveries persisted")

	# Rest until morning: the beans sprout on day 2.
	await main.rest_until_morning()
	await frames(3)
	eq(Days.current_day, 2, "day 2 after resting")
	eq(GardenRegion.growth_stage(WorldState.get_fact("garden.bed_1")), 1, "beans have sprouted")
	check(Invitations.has_unread(), "day 2 letter delivered")
	check(not world.regions["home"]._table_settings.visible and world.regions["home"]._vase.visible, "table cleared but a vase remembers the work")
	check(_interactable("Set the table").is_available(), "table can be set again on a new day")
	check(Dialogue.start("miriam") and Dialogue.current_line()["text"].contains("green loops"), "Miriam remembers and comments on the sprouts")
	Dialogue.end()

	# Day 3: Tobias's letter, and filling the neighbors' bread baskets.
	await main.rest_until_morning()
	await frames(3)
	eq(Days.current_day, 3, "day 3 after resting")
	eq(Invitations.pending_id, "inv_day_003", "Tobias's letter delivered")
	check(Dialogue.start("miriam") and Dialogue.current_line()["text"].contains("first leaves"), "Miriam notices the beans have grown and points to Tobias")
	Dialogue.end()
	check(Dialogue.start("tobias"), "talk to Tobias")
	if Dialogue.current_line()["choices"].is_empty():
		Dialogue.advance()
	eq(Dialogue.current_line()["choices"].size(), 2, "Tobias asks for help with the bread")
	Dialogue.choose(0)
	Dialogue.advance()
	await frames(3)
	check(ActivityRunner.is_running(), "bread activity started from conversation")
	if ActivityRunner.is_running():
		ws = ActivityRunner.workspace
		await _play_intro(ws)
		var fill := ws.current_step()
		check(fill != null, "basket step begins after Tobias's introduction")
		if fill == null:
			return
		var baskets: Array[DropSlot] = fill.holes
		eq(baskets.size(), 3, "three neighbors' baskets")
		var roll := 0
		for b in baskets.size():
			for i in [2, 4, 3][b]:
				_drop(fill.pieces[roll], baskets[b].center())
				roll += 1
			if b == 0:
				_drop(fill.pieces[roll], baskets[0].center()) # one too many: it goes back
				check(fill.pieces[roll].placed_in == null, "a full basket refuses an extra roll")
		check(fill.is_done, "every basket has its number of rolls")
		await wait(1.6)
		await _play_outro(ws)
		await wait(0.2)
	check(not ActivityRunner.is_running(), "bread activity finished")
	eq(int(WorldState.get_fact("village.bread_day", 0)), 3, "the bread was delivered today")
	check(Dialogue.start("ruth") and Dialogue.current_line()["text"].contains("bread basket"), "Ruth thanks the child for the bread")
	Dialogue.end()
	main.quit_to_title()
	await frames(2)
	main.queue_free()
	await frames(2)


# --- Helpers -------------------------------------------------------------------

func _interactable(prompt: String) -> Interactable:
	return _search(get_tree().root, prompt)


func _search(node: Node, prompt: String) -> Interactable:
	if node is Interactable and (node as Interactable).prompt == prompt:
		return node
	for c in node.get_children():
		var found := _search(c, prompt)
		if found:
			return found
	return null


func _find(node: Node, type: Variant) -> Node:
	for c in node.get_children():
		if is_instance_of(c, type):
			return c
		var found := _find(c, type)
		if found:
			return found
	return null


## Uses tap-to-walk, like a child tapping the object, and waits to arrive.
## The avatar walks the whole route on the navigation mesh (doors, gates, bridge).
func _walk_and_use(world: World, target: Interactable) -> void:
	if target == null:
		check(false, "interactable exists")
		return
	world.player.walk_to(target.approach_point(world.player.global_position), target)
	var t := 0.0
	while GameState.is_exploring() and t < 30.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	check(not GameState.is_exploring(), "walked to and used '%s' (%.1fs)" % [target.prompt, t])


func _play_intro(ws: ActivityWorkspace) -> void:
	var guard := 0
	while ws.current_step() == null and guard < 10:
		ws.press_primary()
		await frames()
		guard += 1


func _play_outro(ws: ActivityWorkspace) -> void:
	var guard := 0
	while ActivityRunner.is_running() and guard < 10:
		ws.press_primary()
		await frames()
		guard += 1
