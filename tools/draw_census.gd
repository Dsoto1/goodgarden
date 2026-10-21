extends Node
## Counts mesh instances and surfaces (draw calls before culling) by where
## they live in the world, to find what to batch.
##   godot --headless --path . res://tools/draw_census.tscn

func _ready() -> void:
	Settings.persist = false
	SaveService.path = "user://draw_census/save.json"
	SaveService.delete_save()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tier="):
			Settings.set_value("scenery_quality", arg.substr(7))
	var main: Main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	main.start_new_game()
	for i in 5:
		await get_tree().process_frame
	var cam: Camera3D = null
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--at="):
			var a := main.world.anchor(arg.substr(5))
			main.world.player.teleport(a.global_position, a.global_rotation.y)
			main.world.rig.snap()
			for i in 5:
				await get_tree().process_frame
			cam = get_viewport().get_camera_3d()
	var tally := {}
	for n in main.world.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree() or (g is MeshInstance3D and (g as MeshInstance3D).mesh == null):
			continue
		if cam and not _seen(g, cam):
			continue
		var key := _category(g, main.world)
		var surfaces := 1
		if g is MeshInstance3D and (g as MeshInstance3D).mesh:
			surfaces = (g as MeshInstance3D).mesh.get_surface_count()
		elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh.mesh:
			surfaces = (g as MultiMeshInstance3D).multimesh.mesh.get_surface_count()
		var t: Array = tally.get(key, [0, 0, 0, 0])
		t[0] += 1
		t[1] += surfaces
		t[2] += surfaces if g.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else 0
		t[3] += _triangles(g)
		tally[key] = t
	if OS.get_cmdline_user_args().has("--why"):
		var why := {}
		for n in main.world.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi.mesh == null or not mi.is_visible_in_tree() or mi.name == "Batched":
				continue
			var m: Material = mi.material_override if mi.material_override else mi.mesh.surface_get_material(0)
			var sh := ""
			if m is ShaderMaterial:
				sh = (m as ShaderMaterial).shader.resource_path.get_file()
			var k := "%s %s %s" % [mi.mesh.resource_path.get_file() if mi.mesh.resource_path else mi.mesh.get_class(), sh, _live(mi)]
			why[k] = why.get(k, 0) + 1
			if OS.get_cmdline_user_args().has("--names") and _live(mi) == "" and mi.mesh is ArrayMesh and not mi.mesh.resource_path:
				print("   ", mi.get_path(), " ", mi.mesh.get_surface_count(), " ", mi.material_override)
		for k: String in why:
			if why[k] > 3:
				print("%5d  %s" % [why[k], k])
	var keys := tally.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return tally[a][1] > tally[b][1])
	print("category                         instances surfaces shadow_surfaces triangles")
	for k: String in keys:
		print("%-32s %9d %8d %8d %9d" % [k, tally[k][0], tally[k][1], tally[k][2], tally[k][3]])
	get_tree().quit()


func _category(g: Node, world: Node) -> String:
	var path: Array[String] = []
	var n := g.get_parent()
	while n and n != world:
		path.push_front(str(n.name))
		n = n.get_parent()
	var head := path[0] if path.size() > 0 else "world"
	if g.get_parent() is BoneAttachment3D or g.get_parent() is Skeleton3D or "Skeleton" in path:
		return head + "/character"
	if path.size() > 1 and str(path[1]).begins_with("@"):
		return head + "/" + str(g.get_class())
	return head + "/" + (path[1] if path.size() > 1 else str(g.get_class()))


func _live(n: Node) -> String:
	var mi := n as MeshInstance3D
	if mi.visibility_range_end > 0.0:
		return "range"
	if mi.top_level:
		return "top_level"
	while n and not n is Region:
		if n.has_meta(StaticBatch.LIVE_META):
			return "live:" + str(n.name)
		if n.get_script() != null:
			return "script:" + str(n.get_script().resource_path.get_file())
		n = n.get_parent()
	return "" if n else "outside"


func _seen(g: GeometryInstance3D, cam: Camera3D) -> bool:
	var box := g.global_transform * g.get_aabb()
	if g.visibility_range_end > 0.0 and cam.global_position.distance_to(box.get_center()) > g.visibility_range_end:
		return false
	for plane in cam.get_frustum():
		var corner := box.position
		# The box corner farthest along the plane normal decides.
		if plane.normal.x > 0: corner.x += box.size.x
		if plane.normal.y > 0: corner.y += box.size.y
		if plane.normal.z > 0: corner.z += box.size.z
		if plane.is_point_over(corner) and plane.distance_to(corner) > 0.0:
			pass
	for plane in cam.get_frustum():
		var inside := false
		for i in 8:
			if not plane.is_point_over(box.get_endpoint(i)):
				inside = true
				break
		if not inside:
			return false
	return true


func _triangles(g: GeometryInstance3D) -> int:
	var mesh: Mesh = null
	var copies := 1
	if g is MeshInstance3D:
		mesh = (g as MeshInstance3D).mesh
	elif g is MultiMeshInstance3D:
		mesh = (g as MultiMeshInstance3D).multimesh.mesh
		copies = (g as MultiMeshInstance3D).multimesh.instance_count
	if mesh == null:
		return 0
	var tris := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var idx: Variant = arrays[Mesh.ARRAY_INDEX]
		tris += ((idx as PackedInt32Array).size() if idx != null else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return tris * copies
