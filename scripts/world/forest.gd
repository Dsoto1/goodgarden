class_name Forest
extends Node3D
## Distant forests on the hills around the valley, like the mockup's wooded
## slopes: thousands of cheap low-poly trees drawn with MultiMesh (two draw
## calls per chunk), tinted per instance so the canopy isn't one flat green.
## Near the play area the detailed Quaternius trees take over.

const CHUNK := 40.0

var tree_count := 0


func build(seed_value: int, density: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var clumps := FastNoiseLite.new()
	clumps.seed = seed_value
	clumps.frequency = 0.02
	var pine := _pine_mesh()
	var round_tree := _round_mesh()
	var cells := {}
	var attempts := int(9000 * density)
	for i in attempts:
		var p := Vector2(rng.randf_range(-300, 300), rng.randf_range(-300, 300))
		var d := Terrain.outside(p.x, p.y)
		if d < 3.0 or d > 260.0:
			continue
		var h := Terrain.height(p.x, p.y)
		if h > 70.0: # above the tree line
			continue
		if (clumps.get_noise_2dv(p) + 1.0) * 0.5 < 0.35 + rng.randf() * 0.25:
			continue
		if _in_city_view(p) or absf(p.y - Terrain.RIVER_Z) < 9.0:
			continue
		var s := rng.randf_range(0.9, 1.5) * (1.0 + clampf(d / 120.0, 0.0, 1.5))
		var t := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), Vector3(p.x, h - 0.3, p.y))
		var green := Color.from_hsv(rng.randf_range(0.24, 0.34), rng.randf_range(0.55, 0.82), rng.randf_range(0.3, 0.58))
		var kind := 0 if (h > 25.0 or rng.randf() < 0.45) else 1
		var key := Vector3i(floori(p.x / CHUNK), floori(p.y / CHUNK), kind)
		if not cells.has(key):
			cells[key] = {"t": [] as Array[Transform3D], "c": [] as Array[Color]}
		cells[key]["t"].append(t)
		cells[key]["c"].append(green)
	for key: Vector3i in cells:
		_add(pine if key.z == 0 else round_tree, cells[key]["t"], cells[key]["c"])


## Keeps the sightline from the overlook to Bellhaven open.
static func _in_city_view(p: Vector2) -> bool:
	if p.y > Terrain.FLOOR.position.y or p.y < Terrain.BELLHAVEN.y + 30.0:
		return false
	var t := clampf((-p.y - 46.0) / 130.0, 0.0, 1.0)
	return absf(p.x - lerpf(6.0, Terrain.BELLHAVEN.x, t)) < lerpf(10.0, 30.0, t)


func _add(mesh: Mesh, transforms: Array[Transform3D], colors: Array[Color]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	# Distant forests are too far for crisp shadows; skipping them saves a lot.
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	tree_count += transforms.size()


## Two stacked cones on a short trunk. Leaves take the instance colour.
static func _pine_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cone(st, 0.18, 1.2, 0.0, Color("6b4a32"), 6)
	_cone(st, 1.5, 2.6, 0.9, Color.WHITE, 7)
	_cone(st, 1.1, 2.2, 2.2, Color.WHITE, 7)
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, Style.material("solid", {"use_vertex_color": true, "wrap": 0.4, "saturation": 1.0}))
	return mesh


## A lumpy round canopy (three low-poly blobs) on a trunk.
static func _round_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_cone(st, 0.22, 1.6, 0.0, Color("6b4a32"), 6)
	for blob: Array in [[Vector3(0, 2.4, 0), 1.6], [Vector3(0.8, 2.0, 0.3), 1.1], [Vector3(-0.7, 2.1, -0.4), 1.15]]:
		_blob(st, blob[0], blob[1])
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, Style.material("solid", {"use_vertex_color": true, "wrap": 0.5, "saturation": 1.0}))
	return mesh


static func _cone(st: SurfaceTool, radius: float, height: float, base: float, color: Color, sides: int) -> void:
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		st.set_color(color)
		st.add_vertex(Vector3(cos(a0) * radius, base, sin(a0) * radius))
		st.add_vertex(Vector3(0, base + height, 0))
		st.add_vertex(Vector3(cos(a1) * radius, base, sin(a1) * radius))


static func _blob(st: SurfaceTool, center: Vector3, r: float) -> void:
	var rings := 4
	var sides := 7
	for j in rings:
		for i in sides:
			var pts: Array[Vector3] = []
			for k: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i, j + 1), Vector2i(i + 1, j + 1)]:
				var lat := PI * k.y / rings - PI / 2.0
				var lon := TAU * k.x / sides
				pts.append(center + Vector3(cos(lat) * cos(lon), sin(lat) * 0.85, cos(lat) * sin(lon)) * r)
			st.set_color(Color.WHITE)
			st.add_vertex(pts[0])
			st.add_vertex(pts[2])
			st.add_vertex(pts[1])
			st.add_vertex(pts[1])
			st.add_vertex(pts[2])
			st.add_vertex(pts[3])
