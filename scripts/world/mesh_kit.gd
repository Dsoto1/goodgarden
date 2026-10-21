class_name MeshKit
extends RefCounted
## Helpers that assemble the low-poly storybook world from primitive meshes.
##
## These are the placeholder "art kit" for the vertical slice: every piece is
## procedural, so the slice ships with no third-party assets. When CC0 packs
## (Quaternius/KayKit/Kenney) are imported, regions can swap these calls for
## instanced scenes without changing gameplay code.

const LAYER_GROUND := 1
const LAYER_OBSTACLE := 2
const LAYER_INTERACTABLE := 4
const LAYER_PLAYER := 8
const LAYER_TRIGGER := 16
## Characters block the avatar but are not baked into the navigation mesh.
const LAYER_CHARACTER := 32
## Invisible blockers (river banks, world edge): stop the avatar, but the
## camera's spring arm ignores them.
const LAYER_INVISIBLE := 64

static var _meshes := {}


static func box(parent: Node3D, size: Vector3, pos: Vector3, material: String, collide := false, rot_y := 0.0) -> MeshInstance3D:
	var key := "box%s" % size
	if not _meshes.has(key):
		var m := BoxMesh.new()
		m.size = size
		_meshes[key] = m
	var mi := _instance(parent, _meshes[key], pos, material, rot_y)
	if collide:
		solid(parent, size, pos, rot_y)
	return mi


static func cylinder(parent: Node3D, radius_top: float, radius_bottom: float, height: float, pos: Vector3, material: String, sides := 8, collide := false) -> MeshInstance3D:
	var key := "cyl%s_%s_%s_%d" % [radius_top, radius_bottom, height, sides]
	if not _meshes.has(key):
		var m := CylinderMesh.new()
		m.top_radius = radius_top
		m.bottom_radius = radius_bottom
		m.height = height
		m.radial_segments = sides
		m.rings = 1
		_meshes[key] = m
	var mi := _instance(parent, _meshes[key], pos, material)
	if collide:
		var r := maxf(radius_top, radius_bottom)
		solid(parent, Vector3(r * 1.6, height, r * 1.6), pos)
	return mi


static func sphere(parent: Node3D, radius: float, pos: Vector3, material: String, scale := Vector3.ONE, segments := 8, rings := 5) -> MeshInstance3D:
	var key := "sph%s_%d_%d" % [radius, segments, rings]
	if not _meshes.has(key):
		var m := SphereMesh.new()
		m.radius = radius
		m.height = radius * 2.0
		m.radial_segments = segments
		m.rings = rings
		_meshes[key] = m
	var mi := _instance(parent, _meshes[key], pos, material)
	mi.scale = scale
	return mi


## Gable roof: a triangular prism whose ridge runs along local Z.
static func roof(parent: Node3D, width: float, height: float, depth: float, pos: Vector3, material: String, rot_y := 0.0) -> MeshInstance3D:
	var key := "roof%s_%s_%s" % [width, height, depth]
	if not _meshes.has(key):
		var m := PrismMesh.new()
		m.size = Vector3(width, height, depth)
		_meshes[key] = m
	return _instance(parent, _meshes[key], pos, material, rot_y)


static func cone(parent: Node3D, radius: float, height: float, pos: Vector3, material: String, sides := 8) -> MeshInstance3D:
	return cylinder(parent, 0.001, radius, height, pos, material, sides)


## Invisible collider on the obstacle layer (or another layer, e.g. characters).
static func solid(parent: Node3D, size: Vector3, pos: Vector3, rot_y := 0.0, layer := LAYER_OBSTACLE) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	body.position = pos
	body.rotation.y = rot_y
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	parent.add_child(body)
	return body


static func tree(parent: Node3D, pos: Vector3, size := 1.0, kind := "round") -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	if kind == "pine":
		cylinder(root, 0.12 * size, 0.18 * size, 1.0 * size, Vector3(0, 0.5 * size, 0), "trunk", 6)
		cone(root, 1.1 * size, 1.6 * size, Vector3(0, 1.6 * size, 0), "pine", 7)
		cone(root, 0.8 * size, 1.3 * size, Vector3(0, 2.4 * size, 0), "pine", 7)
	else:
		var leaf := "leaf" if kind == "round" else kind
		cylinder(root, 0.14 * size, 0.2 * size, 1.4 * size, Vector3(0, 0.7 * size, 0), "trunk", 6)
		sphere(root, 1.0 * size, Vector3(0, 2.0 * size, 0), leaf, Vector3(1.0, 0.85, 1.0), 7, 4)
		sphere(root, 0.7 * size, Vector3(0.55 * size, 1.7 * size, 0.2 * size), "leaf_light", Vector3.ONE, 7, 4)
	solid(root, Vector3(0.5, 2.0, 0.5) * size, Vector3(0, 1.0 * size, 0))
	return root


## Post-and-rail fence from `a` to `b` (local to parent), with a collider.
static func fence(parent: Node3D, a: Vector3, b: Vector3, material := "wood_light") -> void:
	var span := b - a
	var length := span.length()
	var dir := span / length
	var yaw := atan2(dir.x, dir.z)
	var posts := maxi(1, ceili(length / 1.6))
	for i in posts + 1:
		box(parent, Vector3(0.14, 0.9, 0.14), a + dir * (length * i / posts) + Vector3(0, 0.45, 0), material)
	for h: float in [0.35, 0.72]:
		box(parent, Vector3(0.06, 0.08, length), a + span * 0.5 + Vector3(0, h, 0), material, false, yaw)
	solid(parent, Vector3(0.3, 1.2, length), a + span * 0.5 + Vector3(0, 0.6, 0), yaw)


## Flat walkable strip for paths (purely visual; the ground is walkable everywhere).
static func path(parent: Node3D, a: Vector3, b: Vector3, width := 1.6, material := "path") -> MeshInstance3D:
	var span := b - a
	var length := span.length()
	return box(parent, Vector3(width, 0.04, length + width * 0.5), a + span * 0.5 + Vector3(0, 0.02, 0), material, false, atan2(span.x, span.z))


static func flowers(parent: Node3D, center: Vector3, radius: float, count: int, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var colors := ["flower_pink", "flower_yellow", "flower_white", "flower_blue"]
	for i in count:
		var p := center + Vector3(rng.randf_range(-radius, radius), 0, rng.randf_range(-radius, radius))
		cylinder(parent, 0.02, 0.02, 0.3, p + Vector3(0, 0.15, 0), "leaf", 4)
		sphere(parent, 0.09, p + Vector3(0, 0.32, 0), colors[rng.randi() % colors.size()], Vector3.ONE, 6, 3)


static func _instance(parent: Node3D, mesh: Mesh, pos: Vector3, material: String, rot_y := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Palette.mat(material)
	mi.position = pos
	mi.rotation.y = rot_y
	parent.add_child(mi)
	return mi
