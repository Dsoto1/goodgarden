class_name Props
extends RefCounted
## Places imported (third-party) props by catalog id, normalized by
## res://assets/props.json: scale, pivot offset, facing and collision live in
## data, so swapping a model never touches region code.

const CATALOG := "res://assets/props.json"

static var _catalog: Dictionary
static var _scenes := {}


static func catalog() -> Dictionary:
	if _catalog.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
		_catalog = parsed if parsed is Dictionary else {"packs": {}, "props": {}}
	return _catalog


static func has(id: String) -> bool:
	return catalog()["props"].has(id)


static func scene_path(id: String) -> String:
	var p: Dictionary = catalog()["props"][id]
	return str(catalog()["packs"][p["pack"]]) + str(p["model"]) + str(p.get("ext", ".gltf"))


## Instances prop `id` at `pos` (parent-local), turned `rot_y` radians.
## `scale_mul` enlarges or shrinks it relative to its normalized size.
static func place(parent: Node3D, id: String, pos: Vector3, rot_y := 0.0, scale_mul := 1.0) -> Node3D:
	if not has(id):
		push_error("Props: unknown prop '%s'" % id)
		return null
	var p: Dictionary = catalog()["props"][id]
	var path := scene_path(id)
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var root := Node3D.new()
	root.name = id.to_pascal_case()
	root.position = pos
	root.rotation.y = rot_y
	parent.add_child(root)
	var model: Node3D = (_scenes[path] as PackedScene).instantiate()
	var s := float(p.get("scale", 1.0)) * scale_mul
	model.scale = Vector3.ONE * s
	model.position = _vec3(p.get("offset", [0, 0, 0])) * s
	root.add_child(model)
	Style.apply(model, grade_for(id), float(p.get("sway", 0.0)), id)
	# Small things (flowers, pebbles, crates) skip the shadow pass on lighter tiers.
	var small: bool = not Quality.value("small_shadows") and bounds(root).size.y < 1.0
	if p.get("shadow", true) == false or small:
		for mi in model.find_children("*", "GeometryInstance3D", true, false):
			(mi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if p.get("collide", false):
		var box := bounds(root)
		var f := float(p.get("footprint", 0.9))
		var size := Vector3(box.size.x * f, box.size.y, box.size.z * f)
		MeshKit.solid(root, size, box.get_center())
	return root


## Colour grade for a prop: its pack's grade, overridden by the prop's own.
static func grade_for(id: String) -> Dictionary:
	var p: Dictionary = catalog()["props"][id]
	var g: Dictionary = catalog().get("grades", {}).get(p["pack"], {}).duplicate()
	for key: String in ["saturation", "tint", "wrap", "rim_strength", "up_normals", "root_shade"]:
		if p.has(key):
			g[key] = p[key]
	return g


## Places a row of fence panels from a to b using the prop's "length".
static func fence(parent: Node3D, id: String, a: Vector3, b: Vector3) -> void:
	var p: Dictionary = catalog()["props"][id]
	var span := b - a
	var length := span.length()
	var panel := float(p.get("length", 1.6))
	var count := maxi(1, roundi(length / panel))
	var yaw := atan2(span.x, span.z)
	for i in count:
		var piece := place(parent, id, a + span * ((i + 0.5) / count), yaw)
		piece.scale.z = length / count / panel # stretch along the run only
	MeshKit.solid(parent, Vector3(0.3, 1.2, length), a + span * 0.5 + Vector3(0, 0.6, 0), yaw)


## Bounds of every mesh under `node`, in `node`'s local space.
static func bounds(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var b := relative_transform(m, node) * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


static func relative_transform(n: Node3D, ancestor: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur != ancestor and cur is Node3D:
		t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t



static func _vec3(v: Variant) -> Vector3:
	if v is Array and v.size() >= 3:
		return Vector3(float(v[0]), float(v[1]), float(v[2]))
	return Vector3.ZERO
