extends Node
## Renders a set of screenshots of the slice for visual review.
##   xvfb-run godot --path . --rendering-driver opengl3 res://tools/screenshot_tour.tscn -- --out=/abs/dir
## Not part of the game; uses the same calls as the end-to-end test.

var out_dir := "user://screenshots"
var main: Main


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	Settings.persist = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--text="):
			Settings.set_value("text_scale", float(arg.substr(7))) # check layouts with large text
	SaveService.path = "user://screenshot_tour/save.json"
	SaveService.delete_save()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _settle(10)
	await shot("01_title")
	main.start_new_game()
	await _settle(30)
	await shot("02_home_start")
	main.open_invitation(Invitations.pending_id)
	await _settle(10)
	await shot("03_letter")
	_close_modals()
	await _at("garden_miriam", Vector3(-2.2, 0, 0.2))
	await shot("04_garden_miriam")
	var miriam: NPC = main.world.npcs["miriam"]
	main.world.player.teleport(miriam.global_position + Vector3(-1.1, 0, 0.9), PI * 0.75)
	await _settle(10)
	main.world.rig.focus_on(miriam.global_position + Vector3(-0.55, 1.05, 0.4), 3.4, 10.0, -20.0)
	await _settle(90)
	await shot("04b_characters_closeup")
	main.world.rig.release_focus()
	await _at("garden_miriam", Vector3(-2.2, 0, 0.2))
	Dialogue.start("miriam")
	Dialogue.advance()
	await _settle(30)
	await shot("05_dialogue")
	Dialogue.choose(0)
	Dialogue.advance()
	await _settle(40)
	var ws := ActivityRunner.workspace
	ws.press_primary()
	await _settle(5)
	ws.press_primary()
	await _settle(10)
	var spacing := ws.current_step()
	var t: Array[float] = spacing.required_positions()
	for i in spacing.markers.size():
		_drop(spacing.markers[i], Vector2(t[i] + (50.0 if i == 2 else 0.0), 300))
	await _settle(10)
	await shot("06_spacing_check")
	_drop(spacing.markers[2], Vector2(t[2], 300))
	await get_tree().create_timer(1.6).timeout
	var sow := ws.current_step()
	for k in 7:
		_drop(sow.pieces[k], sow.holes[k / 3].center())
	await _settle(10)
	await shot("07_sowing")
	for k in range(7, 12):
		_drop(sow.pieces[k], sow.holes[k / 3].center())
	await get_tree().create_timer(1.6).timeout
	while ActivityRunner.is_running():
		ws.press_primary()
		await _settle(3)
	await get_tree().create_timer(0.8).timeout
	await shot("08_planted_row")
	await get_tree().create_timer(2.0).timeout
	await _at("home_spawn", Vector3(3.2, 0, -0.2))
	main.start_activity_here("home_set_table", Vector3(1.6, 0.8, -1.2))
	await _settle(30)
	ws = ActivityRunner.workspace
	ws.press_primary()
	await _settle(10)
	var m := ws.current_step()
	for i in 4:
		var slot: DropSlot = m.slots[i]
		for p: DragPiece in m.pieces:
			if p.placed_in == null and p.kind == slot.accepts:
				_drop(p, slot.center())
				break
	await _settle(10)
	await shot("09_table_setting")
	ActivityRunner.set_aside()
	await _settle(10)
	await _at("riverbank", Vector3.ZERO)
	await _settle(90)
	await shot("09b_bridge_waterfall")
	await _at("village_plaza", Vector3(0, 0, 0))
	await shot("10_village")
	main.world.rig.focus_on(main.world.player.global_position + Vector3(0, 1.0, -3.0), 5.0, 12.0)
	await _settle(90)
	await shot("10b_village_people")
	main.world.rig.release_focus()
	await _at("village_overlook", Vector3(0, 0, 0))
	await _settle(90)
	await shot("11_bellhaven_vista")
	await _at("chapel_door", Vector3(0, 0, 3.0))
	await _settle(30)
	await shot("11b_chapel_outside")
	await _at("home_door", Vector3(1.0, 0, 3.0))
	await _settle(30)
	await shot("11c_cottage_outside")
	await _at("chapel_door", Vector3(0, 0, -6.5))
	await _settle(120)
	await shot("12_atrium")
	main.start_activity_here("good_samaritan", Vector3(-9, 0.6, -26.4))
	await _settle(20)
	ws = ActivityRunner.workspace
	ws.press_primary()
	await _settle(10)
	for i in 6:
		ws.press_primary()
		await _settle(5)
	await _settle(40)
	await shot("13_story")
	ActivityRunner.set_aside()
	await _settle(10)
	await _at("home_door", Vector3(0, 0, 0))
	main.open_journal()
	await _settle(10)
	await shot("14_journal")
	_close_modals()
	main.open_settings()
	await _settle(10)
	await shot("14b_settings")
	_close_modals()
	main.open_parents()
	await _settle(5)
	var gate := _first(main, ParentPanel) as ParentPanel
	gate._show_page()
	await _settle(10)
	await shot("14c_grownups")
	_close_modals()
	main.open_map()
	await _settle(10)
	await shot("15_map")
	_close_modals()
	await main.rest_until_morning()
	await _at("garden_miriam", Vector3(1.5, 0, 0.8))
	await _settle(30)
	await shot("16_day2_sprouts")
	print("screenshots written to ", ProjectSettings.globalize_path(out_dir))
	get_tree().quit()


func _at(anchor_id: String, offset: Vector3) -> void:
	var a := main.world.anchor(anchor_id)
	main.world.player.teleport(a.global_position + offset, a.global_rotation.y)
	main.world.rig.snap()
	await _settle(20)


func _drop(piece: DragPiece, c: Vector2) -> void:
	piece.set_center(c)
	piece.grabbed.emit(piece)
	piece.set_center(c)
	piece.dropped.emit(piece)


func _close_modals() -> void:
	for layer in main.get_children():
		if layer is CanvasLayer:
			for root in layer.get_children():
				for c in root.get_children():
					if c is ModalPanel:
						c.close()


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = []
	for c in node.get_children():
		out.append(c)
		out.append_array(_all(c))
	return out


func _first(node: Node, type: Variant) -> Node:
	for c in _all(node):
		if is_instance_of(c, type):
			return c
	return null


func _settle(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
