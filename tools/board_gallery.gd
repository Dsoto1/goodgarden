extends Node
## Renders each hands-on board on its own, half done, without loading the 3D
## world: a quick way to review the look of the work surfaces.
##   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1280x800 res://tools/board_gallery.tscn -- --out=/abs/dir [--only=id,id] [--older] [--text=1.6]

var out := "user://board_gallery"


func _ready() -> void:
	Settings.persist = false
	var bg := ColorRect.new()
	bg.color = Color("6f9a52")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	layer.layer = -1
	layer.add_child(bg)
	add_child(layer)
	await get_tree().process_frame
	SaveService.new_game()
	Days.current_day = 11
	WorldState.set_fact("garden.bed_1", {"holes": 4, "planted_day": 1})
	WorldState.set_fact("village.flour_day", 6)
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
		elif a.begins_with("--out="):
			out = a.substr(6)
		elif a == "--older":
			Settings.set_value("work_level", "older")
		elif a.begins_with("--text="):
			Settings.set_value("text_scale", float(a.substr(7)))
	get_tree().root.theme = UiStyle.build_theme(UiStyle.text_scale())
	DirAccess.make_dir_recursive_absolute(out)
	for id: String in ["home_eggs", "garden_weed", "village_pantry", "garden_flower_border", "garden_measure_again", "grove_leaves", "grove_trail_signs", "grove_acorns", "grove_stone_path", "grove_bird_feeders", "home_pour_water", "market_buy", "garden_look_closely", "garden_measure", "market_labels", "home_animal_signs", "garden_bean_row", "garden_water", "bakery_baskets", "home_set_table", "sheepfold_hay", "mill_flour", "oven_bake", "good_shepherd", "orchard_plant", "pond_creatures", "thank_you_card"]:
		if not only.is_empty() and not only.split(",").has(id):
			continue
		if not ActivityRunner.start(id):
			push_error("could not start " + id)
			continue
		var ws := ActivityRunner.workspace
		for i in 6:
			await _settle(4)
			if ws.current_step() == null:
				ws.press_primary()
		await _settle(10)
		var step := ws.current_step()
		_fill(step, 0.5)
		await _settle(40)
		await shot(id)
		if id == "mill_flour":
			_fill(step, 1.0)
			await _settle(150)
			var scale_step := ws.current_step()
			for q: DragPiece in scale_step.pieces:
				if q.kind == "flour_scoop_big" and scale_step.load_weight() < scale_step._weight - 1:
					_place(q, scale_step.pan.center())
			await _settle(60)
			await shot("mill_scale")
		if id == "orchard_plant":
			step.finish()
			await _settle(40)
			_fill(ws.current_step(), 0.5)
			await _settle(40)
			await shot("orchard_sequence")
		ActivityRunner.set_aside()
		await _settle(5)
	get_tree().quit()


## Puts about `part` of the pieces where they belong.
func _fill(step: ActivityStep, part: float) -> void:
	if step.get("unit") != null:
		# A pattern carried on partway along the row.
		for i in int(step.places.size() * part + 0.5):
			if step.places[i].contents.is_empty():
				for p: DragPiece in step.pieces:
					if p.kind == step.kind_at(i) and p.placed_in == null:
						_place(p, step.places[i].center())
						break
	elif step.get("glasses") != null:
		for i in int(step.glasses.size() * part + 0.5):
			step.levels[i] = step.lines[i]
		step.levels[step.glasses.size() - 1] = step.lines[step.glasses.size() - 1] * 0.5
		step.queue_redraw()
	elif step.get("dish") != null:
		for k in 2:
			_place(step.coins[k], step.dish.center())
	elif step.get("lens") != null:
		step.lens.position = step.PICTURE.position + step.LADYBIRD - Vector2(step.LENS_R + 10, step.LENS_R + 10)
	elif step.get("columns") != null:
		# Plants partly measured: the first stacks built.
		var free: Array = step.blocks.duplicate()
		for i in int(step.columns.size() * part + 0.5):
			var col: DropSlot = step.columns[i]
			for n in col.capacity:
				_place(free.pop_back(), col.center())
	elif step.get("labels") != null and step.get("places") != null:
		for i in int(step.places.size() * part + 0.5):
			for l: DragPiece in step.labels:
				if l.kind == step.places[i].accepts and l.placed_in == null:
					_place(l, step.places[i].center())
					break
	elif step.get("tiles") != null:
		# A word built partly: its first letters in place.
		for i in int(step.slots.size() * part + 0.5):
			for t: DragPiece in step.tiles:
				if t.kind == step.slots[i].accepts and t.placed_in == null:
					_place(t, step.slots[i].center())
					break
	elif step.get("holes") != null:
		var k := 0
		var total := 0
		for h: DropSlot in step.holes:
			total += h.capacity
		for h: DropSlot in step.holes:
			for i in h.capacity:
				if k < int(total * part):
					_place(step.pieces[k], h.center())
				k += 1
	elif step.get("bins") != null:
		for i in int(step.pieces.size() * part):
			var p: DragPiece = step.pieces[i]
			for b: DropSlot in step.bins:
				if b.accepts == step.belongs_in(p):
					_place(p, b.center())
	elif step.get("slots") != null and step.get("pieces") != null:
		for i in int(step.slots.size() * part):
			var slot: DropSlot = step.slots[i]
			for p: DragPiece in step.pieces:
				if p.kind == slot.accepts and p.placed_in == null:
					_place(p, slot.center())
					break
	elif step.get("places") != null:
		for i in int(step.places.size() * part):
			var place: DropSlot = step.places[i]
			for p: DragPiece in step.cards:
				if p.get_meta(&"order") == i and p.placed_in == null:
					_place(p, place.center())
					break
	elif step.get("markers") != null:
		for i in 2:
			_place(step.markers[i], Vector2(110 + 170 * (i + 1), 300))
	elif step.get("figures") != null:
		for i in 3:
			step._next_segment()


func _place(p: DragPiece, c: Vector2) -> void:
	p.set_center(c)
	p.grabbed.emit(p)
	p.set_center(c)
	p.dropped.emit(p)


func _settle(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out.path_join(n + ".png"))
