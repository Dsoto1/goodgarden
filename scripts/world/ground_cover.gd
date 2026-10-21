class_name GroundCover
extends Node3D
## Lush ground: grass, clover and wildflower meadows scattered over the valley
## with MultiMesh instancing. Instances are grouped in chunks so the camera
## only draws nearby ones, and nothing grows in any region's clearings (paths,
## floors, beds, plaza). Meadows cluster by noise, the way real ones do.

const CHUNK := 10.0

## prop id, instances per 100 m², noise threshold (higher = patchier), scale range.
const LAYERS := [
	["grass_tuft", 140.0, 0.12, Vector2(0.65, 1.1)],
	["grass_wispy", 8.0, 0.4, Vector2(0.7, 1.1)],
	["clover", 6.0, 0.45, Vector2(0.7, 1.1)],
	["flower_a", 6.0, 0.55, Vector2(0.8, 1.2)],
	["flower_b", 2.0, 0.6, Vector2(0.8, 1.2)],
	["flowers_a", 0.4, 0.6, Vector2(0.7, 1.0)],
]

var instance_count := 0


func build(area: Rect2, clearings: Array[Dictionary], density: float, seed_value: int) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.045
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for layer: Array in LAYERS:
		var id: String = layer[0]
		var parts := _mesh_for(id)
		if parts.is_empty():
			continue
		var per_chunk := int(float(layer[1]) * density * CHUNK * CHUNK / 100.0)
		var x := area.position.x
		while x < area.end.x:
			var z := area.position.y
			while z < area.end.y:
				var transforms: Array[Transform3D] = []
				for i in per_chunk:
					var p := Vector2(x + rng.randf() * CHUNK, z + rng.randf() * CHUNK)
					# Meadows: accept more where the noise is high, fewer elsewhere.
					if (noise.get_noise_2dv(p) + 1.0) * 0.5 < float(layer[2]) * rng.randf_range(0.6, 1.4):
						continue
					if _cleared(p, clearings):
						continue
					var s := rng.randf_range(layer[3].x, layer[3].y)
					var place := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), Vector3(p.x, 0.0, p.y))
					transforms.append(place * (parts["local"] as Transform3D))
				if transforms.size() > 0:
					_add_chunk(parts["mesh"], transforms)
				z += CHUNK
			x += CHUNK


## Softens hard path edges with a fringe of tufts and the odd pebble.
func fringe_paths(clearings: Array[Dictionary], density: float, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var tuft := _mesh_for("grass_tuft")
	var pebble := _mesh_for("pebble")
	var tufts: Array[Transform3D] = []
	var pebbles: Array[Transform3D] = []
	for c in clearings:
		if not c.has("a"):
			continue
		var a: Vector2 = c["a"]
		var b: Vector2 = c["b"]
		var along := b - a
		var length := along.length()
		if length < 0.5:
			continue
		var dir := along / length
		var side := Vector2(-dir.y, dir.x)
		var half := float(c["width"]) * 0.5 - 0.2
		var step := 0.4 / density
		var t := 0.0
		while t < length:
			for s: float in [-1.0, 1.0]:
				var p := a + dir * (t + rng.randf_range(-0.15, 0.15)) + side * s * (half + rng.randf_range(-0.12, 0.25))
				if _cleared_except(p, clearings, c):
					continue
				var basis := Basis(Vector3.UP, rng.randf() * TAU)
				if rng.randf() < 0.05:
					pebbles.append(Transform3D(basis.scaled(Vector3.ONE * rng.randf_range(0.35, 0.6)), Vector3(p.x, 0.0, p.y)) * (pebble["local"] as Transform3D))
				else:
					tufts.append(Transform3D(basis.scaled(Vector3.ONE * rng.randf_range(0.6, 1.0)), Vector3(p.x, 0.0, p.y)) * (tuft["local"] as Transform3D))
			t += step
	_add_chunked(tuft["mesh"], tufts)
	_add_chunked(pebble["mesh"], pebbles)


static func _cleared_except(p: Vector2, clearings: Array[Dictionary], own: Dictionary) -> bool:
	for c in clearings:
		if c != own and _in_clearing(p, c):
			return true
	return false


## Splits instances into CHUNK-sized cells so each cell can be culled.
func _add_chunked(mesh: Mesh, transforms: Array[Transform3D]) -> void:
	var cells := {}
	for t in transforms:
		var key := Vector2i(floori(t.origin.x / CHUNK), floori(t.origin.z / CHUNK))
		if not cells.has(key):
			cells[key] = [] as Array[Transform3D]
		(cells[key] as Array[Transform3D]).append(t)
	for key: Vector2i in cells:
		_add_chunk(mesh, cells[key])


func _add_chunk(mesh: Mesh, transforms: Array[Transform3D]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_end = Quality.value("cover_range")
	add_child(mmi)
	instance_count += transforms.size()


## The prop's mesh with storybook materials baked onto its surfaces, so one
## MultiMesh can draw every surface (stems and petals) with the right look.
func _mesh_for(id: String) -> Dictionary:
	if not Props.has(id):
		return {}
	var probe := Props.place(self, id, Vector3.ZERO)
	var source: MeshInstance3D = probe.find_children("*", "MeshInstance3D", true, false)[0]
	var mesh := source.mesh.duplicate() as ArrayMesh
	for i in mesh.get_surface_count():
		mesh.surface_set_material(i, source.get_active_material(i))
	# Normalized scale/pivot from the catalog, as Props.place applied it.
	var result := {"mesh": mesh, "local": Props.relative_transform(source, probe)}
	probe.free()
	return result


static func _cleared(p: Vector2, clearings: Array[Dictionary]) -> bool:
	for c in clearings:
		if _in_clearing(p, c):
			return true
	return false


static func _in_clearing(p: Vector2, c: Dictionary) -> bool:
	if c.has("rect"):
		return (c["rect"] as Rect2).has_point(p)
	var a: Vector2 = c["a"]
	var b: Vector2 = c["b"]
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t) < float(c["width"]) * 0.5
