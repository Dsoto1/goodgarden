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
const MIN_CHECKS := 450

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
		test_match_to_outline_self_correction, test_story_handoff_and_put_away, test_parable_growth_and_put_away, test_chapel_library_books, test_calling_of_the_fishermen, test_sit_and_hold_rod, test_young_child_access, test_older_work_level, test_sequence_cards,
		test_observations_never_score_reflection, test_pointer_events_drag_pieces, test_props_catalog, test_recorded_sounds, test_animal_moments, test_large_text_fits,
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
	# Every working day asks for three jobs; the day of rest asks for none.
	for d in range(1, 15):
		var sunday := d % 7 == 0
		eq(TodaysWork.jobs(Content.get_invitation("inv_day_%03d" % d)).size(), 0 if sunday else 3, "day %d has %s" % [d, "no jobs (Sunday)" if sunday else "three jobs"])


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
	for id: String in ["mustard_seed", "leaven", "lost_sheep", "fishers", "five_thousand", "good_shepherd"]:
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
	eq(shelf.size(), 7, "seven materials on the Atrium shelf")
	story.queue_free()
	put_away.queue_free()


## The Calling of the Fishermen and the Feeding of the Five Thousand: every
## figure the story brings out can be returned to its own place in the box.
func test_calling_of_the_fishermen() -> void:
	for id: String in ["fishers", "five_thousand", "good_shepherd"]:
		_story_round_trip(id)
	var def := Content.get_activity("five_thousand")
	var story := _make_step("story_figures", def.steps[0])
	for i in def.steps[0]["segments"].size():
		story._next_segment()
	check(story.figures["baskets"].visible, "the twelve baskets are out at the end")
	var loaves: DragPiece = story.figures["loaves"]
	check(loaves.position.distance_to(loaves.home) < 1.0, "the loaves go back to the box when the baskets come out")
	story.queue_free()


func _story_round_trip(id: String) -> void:
	var def := Content.get_activity(id)
	var story := _make_step("story_figures", def.steps[0])
	for i in def.steps[0]["segments"].size():
		story._next_segment()
	story.put_away()
	var put_away := _make_step("match_to_outline", def.steps[1], {"pieces": story.handoff()})
	var done := []
	put_away.completed.connect(func(r: Dictionary) -> void: done.append(r))
	for slot in put_away.slots:
		for p in put_away.pieces:
			if p.kind == slot.accepts and p.placed_in == null:
				_drop(p, slot.center())
	eq(done.size(), 1, "%s: the figures all go back in the box" % id)
	story.queue_free()
	put_away.queue_free()


## Fishing: the child sits and holds a rod whose float rests on the water,
## and standing up puts it away.
func test_sit_and_hold_rod() -> void:
	var model := CharacterModel.new()
	add_child(model)
	model.build(Content.get_world("characters")["characters"]["player"]["look"])
	model.animate(0.1, 0.0)
	var standing := model._skeleton.get_bone_pose_position(BodyMesh.Bone.HIPS).y
	model.sit(0.44)
	var rod := FishingRod.create(-0.25)
	model.hold(rod)
	model.animate(0.1, 0.0)
	rod._process(0.1)
	check(model._skeleton.get_bone_pose_position(BodyMesh.Bone.HIPS).y < standing - 0.1, "sitting lowers the hips")
	check(absf(rod._float.global_position.y - (-0.25 + 0.02)) < 0.02, "the float rests on the water")
	check(rod.global_position.distance_to(model._r_hand.global_position) < 0.01, "the rod is in the child's hand")
	model.hold(null)
	model.sit(0.0)
	model.animate(0.1, 0.0)
	check(absf(model._skeleton.get_bone_pose_position(BodyMesh.Bone.HIPS).y - standing) < 0.05, "standing up again")
	model.queue_free()


## Help for a five-year-old who can't read yet: questions start on the safe
## answer and are read out with their choices, every button can be heard,
## small pieces are easy to pick up, and counting is spoken.
func test_young_child_access() -> void:
	var card := ConfirmCard.new()
	add_child(card)
	card.ask("Stop now?", "Yes, stop", "Keep going", func() -> void: pass)
	await frames(2)
	var focus := get_viewport().gui_get_focus_owner()
	check(focus is Button and (focus as Button).text == "Keep going", "a question starts on the safe answer")
	card.close()
	var box := DialogueBox.new()
	add_child(box)
	box._on_line({"name": "Miriam", "text": "Will you plant?", "choices": ["Yes, let's plant!", "Not yet."]})
	var spoken := box._spoken_line()
	check(spoken.contains("Yes, let's plant!") and spoken.contains("Not yet."), "the choices are read out with the question")
	box.queue_free()
	var b := UiStyle.button("Show me", false, "hint")
	add_child(b)
	await frames(2)
	check(b.has_meta(&"spoken_button"), "every button can be heard")
	eq(SpokenButton.words(b), "Show me", "a button is heard by its words")
	var tile := Icon.Tile.new("map", "Map")
	eq(SpokenButton.words(tile), "Map", "a picture tile is heard by its caption")
	tile.free()
	var helper: SpokenButton = b.get_children(true).filter(func(n: Node) -> bool: return n is SpokenButton)[0]
	b.button_down.emit()
	helper._process(2.0) # one very slow frame, as on a busy tablet
	check(not b.disabled, "a quick tap is still a tap on a slow frame")
	b.button_up.emit()
	b.button_down.emit()
	helper._held_since -= 700
	helper._process(0.016)
	check(b.disabled, "a long hold listens instead of pressing")
	b.queue_free()
	var seed := DragPiece.create("bean_seed", Vector2(30, 22))
	check(seed._has_point(Vector2(-14, 30)), "a small piece can be picked up from just beside it")
	check(not seed._has_point(Vector2(-40, 11)), "but not from far away")
	seed.free()
	var counter := PrimitiveRegistry.create("count_into_slots")
	eq(counter.count_word(4), "four", "counting is spoken in words")
	counter.free()
	# Manners: the child greets a grown-up, says goodbye, and answers politely.
	check(Dialogue.start("ruth"), "talk to Ruth")
	eq(Dialogue.current_line()["reply"], "Hello, Mrs. Ruth!", "the child greets Mrs. Ruth first")
	Dialogue.advance()
	eq(Dialogue.current_line()["reply"], "Goodbye, Mrs. Ruth!", "and says goodbye at the end")
	Dialogue.advance()
	check(Dialogue.start("ruth"), "talk to Ruth again")
	check(Dialogue.current_line()["reply"] != "Hello, Mrs. Ruth!", "only one hello a day")
	Dialogue.end()
	for f in ["miriam", "tobias"]:
		for node: Dictionary in Content.get_dialogue(f).get("nodes", {}).values():
			for c: Dictionary in node.get("choices", []):
				var t := str(c.get("text", ""))
				check(t.contains("please") or t.contains("thank you") or t.contains("glad"), "a polite answer: %s" % t)


## The work level for older children: the same activities, with bigger
## numbers and fewer helps, and each can still be finished.
func test_older_work_level() -> void:
	var younger := Content.get_activity("sheepfold_hay")
	check(younger.at_level("younger") == younger, "the younger level is the activity as written")
	var older := younger.at_level("older")
	eq(int(older.steps[0]["slots"]), 4, "older children share between four troughs")
	check(not older.steps[0].has("older") and younger.steps[0].has("older"), "the older settings are laid over a copy")
	for id: String in ["garden_water", "bakery_baskets", "sheepfold_hay"]:
		var cfg: Dictionary = Content.get_activity(id).at_level("older").steps[0]
		check(cfg.get("show_dimples", true) == false, "%s: no counting dots for older children" % id)
		var step := _make_step("count_into_slots", cfg)
		var k := 0
		for h: DropSlot in step.holes:
			for i in h.capacity:
				_drop(step.pieces[k], h.center())
				k += 1
		check(step.is_done, "%s can be finished at the older level" % id)
		step.queue_free()
	var mill := Content.get_activity("mill_flour").at_level("older")
	var sorter := _make_step("sort_into_bins", mill.steps[0])
	eq(sorter.bins.size(), 3, "older children sort grain, chaff and stones")
	var first: DragPiece = sorter.pieces[0]
	for b: DropSlot in sorter.bins:
		if b.accepts != first.kind:
			_drop(first, b.center())
			break
	check(first.placed_in == null, "a piece in the wrong bin goes back to the pile")
	for p: DragPiece in sorter.pieces:
		for b: DropSlot in sorter.bins:
			if b.accepts == p.kind and p.placed_in == null:
				_drop(p, b.center())
	check(sorter.is_done, "everything sorted")
	sorter.queue_free()
	var scale := _make_step("balance_scale", mill.steps[1])
	var big: Array = scale.pieces.filter(func(q: DragPiece) -> bool: return q.kind == "flour_scoop_big")
	var small: Array = scale.pieces.filter(func(q: DragPiece) -> bool: return q.kind == "flour_scoop")
	for q in big:
		_drop(q, scale.pan.center())
	check(not scale.is_done and scale.load_weight() == 8, "four big scoops outweigh a seven-dot stone")
	_drop(big[0], Vector2(820, 470))
	_drop(small[0], scale.pan.center())
	check(scale.is_done and scale.load_weight() == 7, "three big and one small balance it")
	scale.queue_free()
	var oven := _make_step("match_to_outline", Content.get_activity("oven_bake").at_level("older").steps[0])
	eq(oven.slots.size(), 8, "more loaves to fit for older children")
	oven.queue_free()


## Sequence cards: when every place is filled, cards out of order go back
## to the table and the rest stay; the right order completes the step.
func test_sequence_cards() -> void:
	var step := _make_step("sequence_cards", {"id": "grow", "cards": ["card_seed", "card_sprout", "card_sapling", "card_blossom", "card_apples"]})
	eq(step.places.size(), 5, "five numbered places")
	var by_order := {}
	for c: DragPiece in step.cards:
		by_order[int(c.get_meta(&"order"))] = c
	check(step.cards.map(func(c: DragPiece) -> int: return int(c.get_meta(&"order"))) != [0, 1, 2, 3, 4], "the cards start shuffled")
	# Swap the first two.
	var order := [1, 0, 2, 3, 4]
	for i in 5:
		_drop(by_order[order[i]], step.places[i].center())
	check(not step.is_done, "the wrong order doesn't complete")
	check(by_order[0].placed_in == null and by_order[1].placed_in == null, "the two out of order go back to the table")
	check(by_order[2].placed_in == step.places[2], "the ones in the right place stay")
	_drop(by_order[0], step.places[0].center())
	_drop(by_order[1], step.places[1].center())
	check(step.is_done, "the right order completes")
	step.queue_free()


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

func test_recorded_sounds() -> void:
	for sound: String in AudioService.FILES:
		var files: Array = AudioService.FILES[sound]
		eq(AudioService._recorded(sound).size(), files.size(), "every recording for '%s' loads" % sound)
	for sound: String in AudioService.LOOPS:
		var loops := AudioService._recorded(sound).all(func(st: AudioStream) -> bool: return st is AudioStreamOggVorbis and (st as AudioStreamOggVorbis).loop)
		check(loops, "'%s' repeats seamlessly" % sound)
	check(not AudioService.has_recording("complete") and AudioService._stream("complete") is AudioStreamWAV, "the finishing chime stays a gentle synthesized one")
	check(not AudioService.has_recording("chapel"), "the Chapel keeps its quiet synthesized pad")
	var parent := Node3D.new()
	add_child(parent)
	var river := SoundSpot.looping(parent, "river", Vector3.ZERO, 14.0)
	var sheep := SoundSpot.calling(parent, "sheep", Vector3.ZERO, 30.0, Vector2(7, 16))
	await frames(2)
	check(river.player.playing and river.player.stream != null, "the river plays as soon as it is placed")
	check(not sheep.is_looping() and sheep._wait > 0.0, "sheep call now and then, not all the time")
	parent.queue_free()


func test_animal_moments() -> void:
	var parent := Node3D.new()
	add_child(parent)
	# A lamb is an animated model that walks when its wanderer moves it.
	var lamb := Wanderer.new().setup(AnimalModel.make("lamb"), 1)
	lamb.speed = 0.4
	parent.add_child(lamb)
	var model := lamb.model as FarmAnimal
	check(model != null and model.kind == "lamb", "lambs are animated farm animals")
	for k: String in FarmAnimal.KINDS:
		var a := FarmAnimal.make(k)
		check(a.anim.has_animation(FarmAnimal.IDLE) and a.anim.has_animation(FarmAnimal.WALK) and a.anim.has_animation(FarmAnimal.JUMP), "the %s can stand, walk and hop" % k)
		a.free()
	lamb._wait = 0.0
	lamb._target = lamb.position + Vector3(2, 0, 0)
	await frames(3)
	eq(model.anim.current_animation, FarmAnimal.WALK, "the lamb's legs walk as it moves")
	# Stroking it: it stops, turns to the child, hops, and hearts float up.
	var stroke := AnimalMoments.strokable(lamb, "Stroke the lamb", ["The lamb hops."], "sheep")
	stroke.trigger()
	await frames(2)
	check(lamb._face_player > 0.0 and model.is_hopping(), "a stroked lamb stands still and hops for joy")
	eq(model.anim.current_animation, FarmAnimal.JUMP, "the hop is the model's own jump")
	check(lamb.find_children("Heart*", "", true, false).size() > 0, "hearts float up from the lamb")
	# Grain brings the hens to peck where it was scattered.
	var hens: Array[Wanderer] = []
	for i in 2:
		var hen := Wanderer.new().setup(AnimalModel.make("chicken"), 10 + i)
		hen.position = Vector3(4 + i, 0, 4)
		parent.add_child(hen)
		hens.append(hen)
	var bin := AnimalMoments.grain_bin(parent, Vector3(-2, 0, 0), Vector3(-2, 0, 2), hens)
	bin.trigger()
	await frames(2)
	var grain := parent.get_node("Grain") as Node3D
	check(grain.visible and grain.get_child_count() > 10, "grain lies on the ground")
	check(hens.all(func(h: Wanderer) -> bool: return h.is_visiting() and h.home.distance_to(grain.position) < 0.01), "the hens come to the grain")
	check(AudioService.world_stream("purr") != null, "the cat can purr")
	parent.queue_free()


func test_large_text_fits() -> void:
	Settings.set_value("work_level", "younger")
	Settings.set_value("text_scale", 1.0)
	check(UiStyle.text_scale() > 1.0, "younger children start with larger text")
	Settings.set_value("text_scale", 1.6)
	eq(UiStyle.text_scale(), UiStyle.MAX_TEXT, "but never larger than the largest setting")
	Settings.set_value("text_scale", 1.0)
	# A card taller than the screen scrolls, and its buttons stay in view.
	var panel := ModalPanel.new()
	add_child(panel)
	panel.open(600)
	for i in 30:
		panel.content.add_child(UiStyle.label("A long line of text, number %d." % i, "LetterLabel"))
	var ok := UiStyle.button("Close", true)
	panel.add_buttons([ok])
	await frames(3)
	var card := panel.content.get_parent() as Control
	check(panel.content.get_node_or_null("FitScroll") != null, "a tall card scrolls")
	check(card.get_combined_minimum_size().y <= panel.get_viewport_rect().size.y, "and fits on the screen")
	check(ok.get_parent().get_parent() == panel.content, "its buttons stay outside the scrolling part")
	panel.close()


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
	var sound_spots := world.find_children("*", "SoundSpot", true, false)
	check(sound_spots.size() >= 12, "the river, waterfall, fountain, sheep and hens can be heard (%d sound spots)" % sound_spots.size())
	check(sound_spots.any(func(sp: SoundSpot) -> bool: return sp.sound == "waterfall") and sound_spots.any(func(sp: SoundSpot) -> bool: return sp.sound == "hens"), "the waterfall and the hens have sounds")
	var kinds := {}
	for a in world.find_children("*", "FarmAnimal", true, false):
		kinds[(a as FarmAnimal).kind] = true
	eq(kinds.size(), FarmAnimal.KINDS.size(), "sheep, lambs, cows, the horse, pigs and the dog live in the valley and village")
	var strokable := world.find_children("*", "Interactable", true, false).filter(func(it: Interactable) -> bool: return it.get_parent() is Wanderer)
	check(strokable.size() >= 12, "the animals can be stroked (%d)" % strokable.size())
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
	var to_sheep := NavigationServer3D.map_get_path(world.get_world_3d().navigation_map, Vector3(6, 0, -20), Vector3(27.5, 0, -22.5), true)
	var sheep_end := to_sheep[to_sheep.size() - 1] if to_sheep.size() > 0 else Vector3.INF
	check(Vector2(sheep_end.x, sheep_end.z).distance_to(Vector2(27.5, -22.5)) < 0.5, "the child can walk through the open gate in among the sheep")

	# The camera keeps the child in view: the see-through hole is aimed at them,
	# and while walking somewhere the view knows where they're going.
	await frames(2)
	var aimed: Vector3 = world.rig.see_through_target
	var child_at := world.player.global_position
	check(Vector2(aimed.x, aimed.z).distance_to(Vector2(child_at.x, child_at.z)) < 0.6 and aimed.y > child_at.y, "the see-through is aimed at the child")
	check(world.player.walk_goal() == null, "standing still, no destination")

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
	check(not main.hud.todays_work_done(), "before planting, the note still asks for help")

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
	check(_find(main, DoneSeal) != null, "a clear Done seal shows the work is finished")
	var jobs := TodaysWork.today()
	eq(jobs.size(), 3, "day 1 has three jobs")
	check(jobs[0]["done"] and not jobs[1]["done"] and not jobs[2]["done"], "planting ticks off the first job")
	check(not main.hud.todays_work_done() and main.hud._invite_heading.text == "Today's jobs", "the corner note lists what is left")
	eq(main.hud._jobs_box.get_child_count(), 3, "one line per job")

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
	eq(world.player.surface(), "wood", "footsteps on the wooden floor at home")
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
	check(not main.hud.todays_work_done(), "two jobs done, one to go")
	# The third job: grain for the hens, by the coop at home.
	var grain := _interactable("Scatter grain for the hens")
	world.player.walk_to(grain.approach_point(world.player.global_position), grain)
	var walked := 0.0
	while WorldState.get_fact("home.hens_fed_day") == null and walked < 30.0:
		await get_tree().physics_frame
		walked += get_physics_process_delta_time()
	eq(int(WorldState.get_fact("home.hens_fed_day", 0)), 1, "the child walked to the coop and fed the hens")
	await frames(2)
	check(main.hud.todays_work_done() and main.hud._invite_heading.text == "Done today", "the note turns to Done once all three jobs are finished")
	check(main.hud._invite_text.text.contains("beans are planted"), "and thanks the child for the work")
	check(main.hud.caption_text().contains("hens come running"), "the hens' moment is told first")
	var waited := 0.0
	while not main.hud.caption_text().contains("Today's work is done") and waited < 14.0:
		await wait(0.5)
		waited += 0.5
	check(main.hud.caption_text().contains("Today's work is done"), "then it says the day's work is done")

	# 9-11. Chapel/Atrium: choose the Good Samaritan, listen, retell, put away.
	var shelf := _interactable("Choose The Good Samaritan")
	await _walk_and_use(world, shelf)
	check(Discovery.is_discovered("chapel"), "chapel discovered by walking there")
	eq(world.mood, "chapel", "chapel mood is active inside")
	eq(world.player.surface(), "stone", "footsteps on the Chapel's stone floor")
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
	var seal_before := _find(main, DoneSeal)
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
	check(seal_before == null and _find(main, DoneSeal) == null, "a story is never marked Done")

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

	# Days 4 to 7: watering the beans, feeding the lambs, the mill and the oven.
	await main.rest_until_morning()
	await frames(3)
	eq(Invitations.pending_id, "inv_day_004", "day 4: Miriam's letter about thirsty beans")
	var water := ActivityRunner.workspace if await _start_from("Water the beans") else null
	if water:
		var cups := water.current_step()
		for h in cups.holes.size():
			for i in 2:
				_drop(cups.pieces[h * 2 + i], cups.holes[h].center())
		check(cups.is_done, "every bean plant has two drops")
		await _finish_activity(water)
	eq(int(WorldState.get_fact("garden.watered", 0)), 4, "the beans were watered today")

	await main.rest_until_morning()
	await frames(3)
	eq(Invitations.pending_id, "inv_day_005", "day 5: Ruth's letter about the lambs")
	var ruth := _find_named(main.world, "Ruth") as Node3D
	var fold_spot := _find_named(main.world, "Anchor_sheepfold_ruth") as Node3D
	check(ruth != null and fold_spot != null and ruth.global_position.distance_to(fold_spot.global_position) < 1.0, "Mrs. Ruth waits at the sheepfold, as her letter says")
	var hay_ws := ActivityRunner.workspace if await _start_by_talking("ruth") else null
	if hay_ws:
		var hay := hay_ws.current_step()
		eq(hay.holes.size(), 3, "three troughs")
		for h in 3:
			for i in 3:
				_drop(hay.pieces[h * 3 + i], hay.holes[h].center())
		check(hay.is_done, "every trough has the same")
		await _finish_activity(hay_ws)
	eq(int(WorldState.get_fact("valley.lambs_fed", 0)), 5, "the lambs were fed today")
	var fed := _find_named(main.world, "FedLambs") as Node3D
	check(fed != null and fed.visible, "hay is in the troughs and the lambs are eating")

	await main.rest_until_morning()
	await frames(3)
	eq(Invitations.pending_id, "inv_day_006", "day 6: Tobias asks for flour")
	check(fed != null and not fed.visible, "the next day the troughs are empty again")
	var tobias := _find_named(main.world, "Tobias") as Node3D
	var mill_spot := _find_named(main.world, "Anchor_mill_tobias") as Node3D
	check(tobias != null and mill_spot != null and tobias.global_position.distance_to(mill_spot.global_position) < 1.0, "Mr. Tobias waits at the mill")
	check(ruth.global_position.distance_to(fold_spot.global_position) > 5.0, "and Mrs. Ruth is back home in the village")
	var mill := ActivityRunner.workspace if await _start_by_talking("tobias") else null
	if mill:
		var sorter := mill.current_step()
		for p: DragPiece in sorter.pieces:
			for b: DropSlot in sorter.bins:
				if b.accepts == p.kind:
					_drop(p, b.center())
		check(sorter.is_done, "the grain is sorted from the chaff")
		await wait(1.8)
		var scale := mill.current_step()
		check(scale != null and scale != sorter, "then the flour is weighed")
		if scale:
			var big: Array = scale.pieces.filter(func(q: DragPiece) -> bool: return q.kind == "flour_scoop_big")
			var small: Array = scale.pieces.filter(func(q: DragPiece) -> bool: return q.kind == "flour_scoop")
			for q in big:
				_drop(q, scale.pan.center())
			check(not scale.is_done and scale.load_weight() == 6, "three big scoops are too heavy")
			_drop(big[0], Vector2(820, 470)) # take one out
			check(scale.load_weight() == 4, "taking a scoop out makes it lighter")
			_drop(small[0], scale.pan.center())
			check(scale.is_done, "a little scoop makes the beam level")
		await _finish_activity(mill)
	eq(int(WorldState.get_fact("village.flour_day", 0)), 6, "there is flour for Monday")

	# Day 7 is Sunday: a day of rest, with the neighbours at the Chapel.
	await main.rest_until_morning()
	await frames(3)
	eq(Days.weekday(), "sunday", "the seventh day is a Sunday")
	check(main.hud._day.text.begins_with("Sunday"), "the corner says it is Sunday")
	check(main.hud.caption_text().contains("day of rest"), "the morning greeting says it is a day of rest")
	eq(Invitations.pending_id, "inv_day_007", "day 7: a letter about the day of rest")
	main.open_invitation(Invitations.pending_id)
	await frames(2)
	var sunday_letter := _find(main, InvitationCard) as InvitationCard
	if sunday_letter:
		sunday_letter.close()
	await frames(2)
	eq(TodaysWork.today().size(), 0, "Sunday has no jobs")
	check(not main.hud._jobs_box.visible and main.hud._invite_text.text.contains("day of rest"), "the corner note says Sunday is for rest")
	for npc: String in ["miriam", "tobias", "ruth"]:
		var at := _find_named(main.world, "Anchor_chapel_" + npc) as Node3D
		var who := (main.world.npcs[npc] if main.world.npcs.has(npc) else _find_named(main.world, npc.capitalize())) as Node3D
		check(at != null and who != null and who.global_position.distance_to(at.global_position) < 1.0, "%s is with the neighbours at the Chapel" % npc)
	check(Dialogue.start("miriam") and str(Dialogue.current_line()["text"]).contains("Sunday"), "Miss Miriam rests too")
	Dialogue.end()
	check(Dialogue.start("tobias") and str(Dialogue.current_line()["text"]).contains("No baking today"), "so does Mr. Tobias")
	Dialogue.end()
	check(AudioService.world_stream("bells") != null, "the chapel bells ring")

	# Week 2. Monday, day 8: baking the bread with Saturday's flour.
	await main.rest_until_morning()
	await frames(3)
	eq(Days.weekday(), "monday", "a new week begins on Monday")
	eq(Days.week(), 2, "week 2")
	eq(Invitations.pending_id, "inv_day_008", "day 8: baking day")
	var oven := ActivityRunner.workspace if await _start_from("Bake bread with Mr. Tobias") else null
	if oven:
		var load := oven.current_step()
		for slot: DropSlot in load.slots:
			for p: DragPiece in load.pieces:
				if p.kind == slot.accepts and p.placed_in == null:
					_drop(p, slot.center())
					break
		check(load.is_done, "every loaf is in its place in the oven")
		await _finish_activity(oven)
	eq(int(WorldState.get_fact("village.baked_day", 0)), 8, "the bread was baked today")
	var baking := _find_named(main.world, "BakingDay") as Node3D
	check(baking != null and baking.visible, "the oven glows and fresh loaves cool beside it")

	# Day 9: planting the orchard with Miss Miriam in the meadow.
	await main.rest_until_morning()
	await frames(3)
	eq(Invitations.pending_id, "inv_day_009", "day 9: Miss Miriam's letter about the apple trees")
	var miriam_now := main.world.npcs["miriam"] as Node3D
	var orchard_spot := _find_named(main.world, "Anchor_orchard_miriam") as Node3D
	check(orchard_spot != null and miriam_now.global_position.distance_to(orchard_spot.global_position) < 0.5, "Miss Miriam waits in the meadow")
	var orchard := ActivityRunner.workspace if await _start_by_talking("miriam") else null
	if orchard:
		var rope := orchard.current_step()
		var spots: Array[float] = rope.required_positions()
		for i in rope.markers.size():
			_drop(rope.markers[i], Vector2(spots[i], 300))
		check(rope.is_done, "three trees, one long stick apart")
		await wait(1.8)
		var seq := orchard.current_step()
		check(seq != null and seq != rope, "then the pictures of how a tree grows")
		if seq:
			for i in seq.places.size():
				for c: DragPiece in seq.cards:
					if int(c.get_meta(&"order")) == i:
						_drop(c, seq.places[i].center())
			check(seq.is_done, "the pictures are in order")
		await _finish_activity(orchard)
	eq(int(WorldState.get_fact("orchard.planted", 0)), 9, "the orchard is planted")
	var trees := _find_named(main.world, "Orchard") as Node3D
	check(trees != null and trees.get_child_count() > 0, "young apple trees stand in the meadow")

	# Day 10: the pond with Mrs. Ruth.
	await main.rest_until_morning()
	await frames(3)
	var pond_spot := _find_named(main.world, "Anchor_pond_ruth") as Node3D
	check(pond_spot != null and ruth.global_position.distance_to(pond_spot.global_position) < 1.0, "Mrs. Ruth waits by the pond")
	var pond := ActivityRunner.workspace if await _start_by_talking("ruth") else null
	if pond:
		var sorter2 := pond.current_step()
		for p: DragPiece in sorter2.pieces:
			for b: DropSlot in sorter2.bins:
				if b.accepts == sorter2.belongs_in(p):
					_drop(p, b.center())
		check(sorter2.is_done, "every creature sorted into its home")
		await _finish_activity(pond)
	eq(int(WorldState.get_fact("valley.pond_day", 0)), 10, "the pond creatures were sorted today")

	# Day 11: a thank-you card for Mrs. Ruth, given by the child.
	await main.rest_until_morning()
	await frames(3)
	main.open_invitation(Invitations.pending_id) # read Miss Miriam's letter first
	await frames(2)
	var day10_letter := _find(main, InvitationCard) as InvitationCard
	if day10_letter:
		day10_letter.close()
	await frames(2)
	check(not main.hud.todays_work_done(), "day 11 starts with the letter's request")
	var card_ws := ActivityRunner.workspace if await _start_by_talking("miriam") else null
	if card_ws:
		var deco := card_ws.current_step()
		for slot: DropSlot in deco.slots:
			for p: DragPiece in deco.pieces:
				if p.kind == slot.accepts and p.placed_in == null:
					_drop(p, slot.center())
					break
		check(deco.is_done, "every pressed flower in its place")
		await _finish_activity(card_ws)
	eq(str(WorldState.get_fact("npc.ruth.card", "")), "made", "the card is made")
	check(not main.hud.todays_work_done(), "making the card isn't the end: it still has to be given")
	WorldState.set_fact("home.hens_fed_day", Days.current_day)
	WorldState.set_fact("animals.cat.stroked_day", Days.current_day)
	check(not main.hud.todays_work_done(), "with the small jobs done, the card still has to be given")
	check(Dialogue.start("ruth"), "take the card to Mrs. Ruth")
	check(str(Dialogue.current_line()["reply"]).contains("This card is for you, Mrs. Ruth"), "the child gives the card with a kind word")
	Dialogue.advance()
	check(str(Dialogue.current_line()["text"]).contains("For me?"), "Mrs. Ruth is delighted")
	Dialogue.advance()
	eq(str(WorldState.get_fact("npc.ruth.card", "")), "given", "the card was given")
	check(main.hud.todays_work_done(), "once given, day 11 is done")

	# Friday and Saturday of week 2, then Sunday again; after the written
	# days, Sundays still rest, with the neighbours at the Chapel.
	await main.rest_until_morning()
	await frames(3)
	eq([Days.weekday(), Invitations.pending_id], ["friday", "inv_day_012"], "day 12 is Friday")
	await main.rest_until_morning()
	await main.rest_until_morning()
	await frames(3)
	eq([Days.weekday(), Invitations.pending_id], ["sunday", "inv_day_014"], "day 14 is a Sunday of rest")
	for i in 7:
		await main.rest_until_morning()
	await frames(3)
	eq(Days.current_day, 21, "a free Sunday past the written days")
	eq(Days.npc_anchor("tobias"), "chapel_tobias", "on every Sunday the neighbours gather at the Chapel")

	# The map: the real valley with a card for each place, travel from the
	# places the child has been, and a marker where the child is.
	main.open_map()
	await frames(3)
	var map := _find(main, MapPanel) as MapPanel
	check(map != null, "the map opens")
	check(not CameraRig.see_through_on, "seen from above, nothing is cut away")
	if map:
		var home_at := map.map_point(Vector3.ZERO)
		var village_at := map.map_point(Vector3(6, 0, -27))
		check(village_at.y < home_at.y, "the village is drawn north of home, across the river")
		var travel := map.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return (b as Button).text in ["Home", "Miss Miriam's Garden", "The Village", "The Chapel"])
		eq(travel.size(), Discovery.discovered_ids().filter(func(id: Variant) -> bool: return id in ["home", "garden", "village", "chapel"]).size(), "a travel card for each place the child has been")
		check(_find(map, MapPanel.YouAreHere) != null, "the map shows where the child is")
		map.close()
		await frames(2)
		check(CameraRig.see_through_on, "and the see-through returns after the map")
	# Save and stop through the real buttons, as a child or parent would.
	var day_before := Days.current_day
	main.open_pause()
	await frames(2)
	var pause := _find(main, PauseMenu) as PauseMenu
	check(pause != null, "the Pause tile opens the menu")
	if pause:
		var stop: Button = pause.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return (b as Button).text == "Save and stop playing")[0]
		stop.pressed.emit()
		await frames(2)
		var ask := _find(main, ConfirmCard) as ConfirmCard
		check(ask != null, "stopping asks first")
		if ask:
			var yes: Button = ask.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return (b as Button).text == "Yes, stop")[0]
			yes.pressed.emit()
			await frames(3)
	check(main.world == null, "Yes, stop saves and goes back to the title")
	check(SaveService.has_save(), "the garden was saved")
	check(main.continue_game() and Days.current_day == day_before, "and continues on the same day")
	await frames(3)
	main.quit_to_title()
	await frames(2)
	main.queue_free()
	await frames(2)


# --- Helpers -------------------------------------------------------------------

## Uses the interactable with this prompt and waits for its activity's first
## step, past the introduction. Returns false if it didn't start.
func _start_from(prompt: String) -> bool:
	var target := _interactable(prompt)
	check(target != null and target.is_available(), "\"%s\" is offered" % prompt)
	if target == null:
		return false
	target.trigger()
	await frames(3)
	check(ActivityRunner.is_running(), "\"%s\" starts its work" % prompt)
	if not ActivityRunner.is_running():
		return false
	await _play_intro(ActivityRunner.workspace)
	return ActivityRunner.workspace.current_step() != null


## Talks to a grown-up who offers work, says yes, and waits for the work's first step.
func _start_by_talking(dialogue_id: String) -> bool:
	check(Dialogue.start(dialogue_id), "talk to %s" % dialogue_id)
	var guard := 0
	while Dialogue.is_active() and Dialogue.current_line()["choices"].is_empty() and guard < 4:
		Dialogue.advance()
		guard += 1
	check(Dialogue.is_active() and Dialogue.current_line()["choices"].size() == 2, "%s politely asks for help" % dialogue_id)
	if guard == 0:
		check(str(Dialogue.current_line()["choices"][0]).begins_with("Hello!"), "the child greets %s before answering" % dialogue_id)
	Dialogue.choose(0)
	if Dialogue.is_active():
		eq(Dialogue.current_line()["reply"], "Let's begin!", "no goodbye when work together follows")
	Dialogue.advance()
	await frames(3)
	check(ActivityRunner.is_running(), "the work starts after saying yes")
	if not ActivityRunner.is_running():
		return false
	await _play_intro(ActivityRunner.workspace)
	return ActivityRunner.workspace.current_step() != null


func _finish_activity(ws: ActivityWorkspace) -> void:
	await wait(1.8)
	await _play_outro(ws)
	await wait(0.2)
	check(not ActivityRunner.is_running(), "the work is finished")


func _find_named(node: Node, node_name: String) -> Node:
	return node.find_child(node_name, true, false)


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
	check(world.player.walk_goal() != null, "walking to '%s', the camera knows where to" % target.prompt)
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
