class_name StoneBridge
extends RefCounted
## A humped stone arch bridge built as one masonry mesh: cobbled deck,
## spandrel walls, an arch with a darker voussoir ring, parapets with cap
## stones and corner pillars. The deck is walkable (it has its own sloped
## collider); parapets stop the child but not the camera.
##
## Built in local space with the bridge running along Z, centred on the river.

const LENGTH := 7.8 # along the crossing
const WIDTH := 3.2
const DECK_END := 0.1 # clearly above the paths (0.03) that run onto it
const DECK_PEAK := 0.95
const SPAN := 5.2 # arch opening along Z
const SPRING := -0.6 # where the arch meets the water
const CROWN := 0.6 # arch apex height
const PARAPET := 0.55
const SAMPLES := 40


static func deck_y(z: float) -> float:
	return DECK_END + (DECK_PEAK - DECK_END) * pow(cos(clampf(z / (LENGTH / 2.0), -1.0, 1.0) * PI / 2.0), 1.3)


static func arch_y(z: float) -> float:
	var t := z / (SPAN / 2.0)
	if absf(t) >= 1.0:
		return -1.0
	return SPRING + (CROWN - SPRING) * sqrt(1.0 - t * t)


static func build(parent: Node3D, at: Vector3, yaw := 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "StoneBridge"
	root.position = at
	root.rotation.y = yaw
	parent.add_child(root)
	var stone := SurfaceTool.new()
	stone.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring := SurfaceTool.new()
	ring.begin(Mesh.PRIMITIVE_TRIANGLES)
	var deck := SurfaceTool.new()
	deck.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_w := WIDTH / 2.0
	var inner := half_w - 0.3
	var zs := PackedFloat32Array()
	for i in SAMPLES + 1:
		zs.append(-LENGTH / 2.0 + LENGTH * i / SAMPLES)
	for i in SAMPLES:
		var z0 := zs[i]
		var z1 := zs[i + 1]
		var d0 := deck_y(z0)
		var d1 := deck_y(z1)
		var b0 := arch_y(z0) if arch_y(z0) > -1.0 else -0.8
		var b1 := arch_y(z1) if arch_y(z1) > -1.0 else -0.8
		for side: float in [-1.0, 1.0]:
			var x := side * half_w
			var n := Vector3(side, 0, 0)
			# Outer wall: from the arch (or footing) up to the parapet top.
			_quad(stone, Vector3(x, b0, z0), Vector3(x, b1, z1), Vector3(x, d1 + PARAPET, z1), Vector3(x, d0 + PARAPET, z0), n)
			# Parapet inner face and top.
			var xi := side * inner
			_quad(stone, Vector3(xi, d0, z0), Vector3(xi, d1, z1), Vector3(xi, d1 + PARAPET, z1), Vector3(xi, d0 + PARAPET, z0), -n)
			_quad(ring, Vector3(xi - side * 0.04, d0 + PARAPET, z0), Vector3(xi - side * 0.04, d1 + PARAPET, z1), Vector3(x + side * 0.05, d1 + PARAPET, z1), Vector3(x + side * 0.05, d0 + PARAPET, z0), Vector3.UP)
			# Voussoir ring: a darker band of wedge stones around the arch.
			if arch_y(z0) > -1.0 and arch_y(z1) > -1.0:
				var xr := x + side * 0.08 # well proud of the wall, or the two flicker
				_quad(ring, Vector3(xr, b0, z0), Vector3(xr, b1, z1), Vector3(xr, b1 + 0.3, z1), Vector3(xr, b0 + 0.3, z0), n)
		# Cobbled deck between the parapets.
		_quad(deck, Vector3(-inner, d0, z0), Vector3(inner, d0, z0), Vector3(inner, d1, z1), Vector3(-inner, d1, z1), Vector3.UP)
		# Arch underside.
		if arch_y(z0) > -1.0 and arch_y(z1) > -1.0:
			_quad(stone, Vector3(-half_w, b0, z0), Vector3(half_w, b0, z0), Vector3(half_w, b1, z1), Vector3(-half_w, b1, z1), Vector3(0, -1, -z0 * 0.2).normalized())
	for side: float in [-1.0, 1.0]:
		var z := side * LENGTH / 2.0
		_quad(stone, Vector3(-half_w, -0.8, z), Vector3(half_w, -0.8, z), Vector3(half_w, deck_y(z), z), Vector3(-half_w, deck_y(z), z), Vector3(0, 0, side))
	var mesh := ArrayMesh.new()
	for pair: Array in [[stone, "stone"], [ring, "stone_dark"], [deck, "cobble"]]:
		var st: SurfaceTool = pair[0]
		st.generate_normals()
		st.commit(mesh)
		mesh.surface_set_material(mesh.get_surface_count() - 1, Palette.mat(pair[1]))
	var mi := MeshInstance3D.new()
	mi.name = "Masonry"
	mi.mesh = mesh
	root.add_child(mi)
	# Corner pillars with caps.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			# Pillars stand proud of the parapet on both faces: flush faces of two
			# stone colours flickered against each other.
			var p := Vector3(sx * (half_w - 0.08), 0, sz * (LENGTH / 2.0 - 0.15))
			MeshKit.box(root, Vector3(0.6, deck_y(p.z) + PARAPET + 0.35, 0.5), p + Vector3(0, (deck_y(p.z) + PARAPET + 0.35) / 2.0, 0), "stone_dark")
			MeshKit.box(root, Vector3(0.72, 0.12, 0.62), p + Vector3(0, deck_y(p.z) + PARAPET + 0.41, 0), "stone")
	_colliders(root, inner)
	return root


## Walkable deck (sloped, on the ground layer so taps and navigation use it)
## and parapets on the invisible layer (they stop the avatar, not the camera).
static func _colliders(root: Node3D, inner: float) -> void:
	var faces := PackedVector3Array()
	for i in SAMPLES:
		var z0 := -LENGTH / 2.0 + LENGTH * i / SAMPLES
		var z1 := -LENGTH / 2.0 + LENGTH * (i + 1) / SAMPLES
		var a := Vector3(-inner, deck_y(z0), z0)
		var b := Vector3(inner, deck_y(z0), z0)
		var c := Vector3(inner, deck_y(z1), z1)
		var d := Vector3(-inner, deck_y(z1), z1)
		# Both windings: the navmesh baker only keeps upward-facing triangles,
		# and which winding counts as "up" differs between physics and baking.
		faces.append_array([a, c, b, a, d, c, a, b, c, a, c, d])
	# The deck ends sit a little above the paths. A short ramp from the ground
	# up to each end lets the avatar walk on, instead of catching on the lip.
	for end: float in [-1.0, 1.0]:
		var z_deck := end * LENGTH / 2.0
		var z_ground := end * (LENGTH / 2.0 + 0.7)
		var a := Vector3(-inner, deck_y(z_deck), z_deck)
		var b := Vector3(inner, deck_y(z_deck), z_deck)
		var c := Vector3(inner, -0.05, z_ground)
		var d := Vector3(-inner, -0.05, z_ground)
		faces.append_array([a, c, b, a, d, c, a, b, c, a, c, d])
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var deck_body := StaticBody3D.new()
	deck_body.collision_layer = MeshKit.LAYER_GROUND
	deck_body.collision_mask = 0
	var cs := CollisionShape3D.new()
	cs.shape = shape
	deck_body.add_child(cs)
	root.add_child(deck_body)
	for side: float in [-1.0, 1.0]:
		MeshKit.solid(root, Vector3(0.3, 3.0, LENGTH), Vector3(side * (inner + 0.15), 1.0, 0), 0.0, MeshKit.LAYER_INVISIBLE)


## Quad wound so its front faces along `normal`.
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	for tri: Array in [[a, b, c], [a, c, d]]:
		var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0])
		var order: Array = [tri[0], tri[2], tri[1]] if n.dot(normal) > 0.0 else tri
		for v: Vector3 in order:
			st.add_vertex(v)
