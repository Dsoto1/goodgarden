class_name Waterfall
extends RefCounted
## A waterfall where the river drops off the western plateau: a streaming
## sheet over the cliff, the upper river behind it, a foaming pool and soft
## mist below, framed by rocks. Positions come from Terrain's falls settings.


static func build(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Waterfall"
	parent.add_child(root)
	var x := Terrain.FALLS_X
	var z := Terrain.RIVER_Z
	var top := Terrain.FALLS_TOP - 0.3
	var bottom := Terrain.RIVER_LEVEL
	var width := 4.6
	# The sheet leans slightly out from the cliff face.
	var sheet := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(width, top - bottom + 0.6)
	sheet.mesh = quad
	sheet.material_override = Style.material("falls")
	sheet.position = Vector3(x + 0.4, (top + bottom) / 2.0, z)
	sheet.rotation = Vector3(0, PI / 2.0, 0.08)
	root.add_child(sheet)
	# Upper river running back along the plateau.
	var upper := MeshKit.box(root, Vector3(140, 0.06, 5.0), Vector3(x - 70.5, top, z), "water")
	upper.name = "UpperRiver"
	# Foam where the water lands.
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in 14:
		var p := Vector3(x + 1.6 + rng.randf_range(0, 2.6), bottom + 0.05, z + rng.randf_range(-2.4, 2.4))
		MeshKit.sphere(root, rng.randf_range(0.35, 0.7), p, "white", Vector3(1.0, 0.3, 1.0), 8, 4).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(_mist(Vector3(x + 2.2, bottom + 0.4, z)))
	# Rocks framing the lip and the pool.
	for r: Array in [[-0.6, -3.0, top - 0.6, 1.4], [-0.6, 3.1, top - 0.5, 1.2], [3.6, -3.4, bottom, 1.1], [4.2, 3.2, bottom, 0.9], [1.0, -3.8, bottom + 1.2, 1.3], [1.2, 3.9, bottom + 1.6, 1.0]]:
		Props.place(root, ["rock", "rock_b", "rock_c"][rng.randi() % 3], Vector3(x + r[0], r[2], z + r[1]), rng.randf() * TAU, r[3])
	return root


static func _mist(at: Vector3) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.position = at
	p.amount = maxi(6, int(24 * float(Quality.value("mist"))))
	p.lifetime = 3.0
	p.emitting = not Settings.get_value("reduced_motion")
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(1.0, 0.2, 2.2)
	pm.direction = Vector3(0.4, 1, 0)
	pm.spread = 30.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.7
	pm.gravity = Vector3(0, 0.05, 0)
	pm.scale_min = 0.8
	pm.scale_max = 1.6
	p.process_material = pm
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	puff.radial_segments = 8
	puff.rings = 4
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1, 0.22)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = m
	p.draw_pass_1 = puff
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p
