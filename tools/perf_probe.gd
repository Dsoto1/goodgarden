extends Node
## Measures rendering cost at fixed viewpoints for each scenery tier, to keep
## the world within a modest tablet's budget.
##   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1280x800 res://tools/perf_probe.tscn
## Reports draw calls, visible objects and triangles per view (independent of
## the machine), plus frame time on this machine (only comparable between tiers).

const VIEWS := [
	["home", "home_spawn", Vector3(3.2, 0, -0.2)],
	["garden", "garden_miriam", Vector3(-2.2, 0, 0.2)],
	["village", "village_plaza", Vector3.ZERO],
	["river", "riverbank", Vector3.ZERO],
	["overlook", "village_overlook", Vector3.ZERO],
]
const FRAMES := 30

var main: Main


func _ready() -> void:
	Settings.persist = false
	SaveService.path = "user://perf_probe/save.json"
	SaveService.delete_save()
	print("tier    view       draws  shadow  objects  triangles    ms/frame")
	var tiers := ["high", "medium", "low"]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tiers="):
			tiers = arg.substr(8).split(",")
	for tier: String in tiers:
		Settings.set_value("scenery_quality", tier)
		main = load("res://scenes/main.tscn").instantiate()
		add_child(main)
		await _frames(5)
		main.start_new_game()
		await _frames(20)
		for view: Array in VIEWS:
			if main.world.anchor(view[1]) == null:
				continue
			var a := main.world.anchor(view[1])
			main.world.player.teleport(a.global_position + view[2], a.global_rotation.y)
			main.world.rig.snap()
			await _frames(20)
			var start := Time.get_ticks_usec()
			await _frames(FRAMES)
			var ms := (Time.get_ticks_usec() - start) / 1000.0 / FRAMES
			var vp := get_viewport().get_viewport_rid()
			var shadow := RenderingServer.viewport_get_render_info(vp, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
			var info := func(kind: int) -> int:
				return RenderingServer.get_rendering_info(kind)
			print("%-7s %-9s %6d %7d %8d %10d %11.1f" % [tier, view[0],
				info.call(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), shadow,
				info.call(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
				info.call(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), ms])
		main.queue_free()
		await _frames(5)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
