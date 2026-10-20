class_name ValleyRegion
extends Region
## The shared valley floor: ground, river and bridge, the roads that connect
## the places, a meadow with sheep, and the trees that frame the playable area.

const BOUNDS := Rect2(-30, -46, 64, 59) # x, z, width, depth of the walkable area


func build() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = MeshKit.LAYER_GROUND
	ground.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1, 400)
	shape.shape = box
	shape.position.y = -0.5
	ground.add_child(shape)
	add_child(ground)
	MeshKit.box(self, Vector3(400, 0.1, 400), Vector3(0, -0.05, 0), "grass")
	_patches()

	# River with a single bridge crossing.
	MeshKit.box(self, Vector3(200, 0.06, 4), Vector3(0, 0.0, -14), "water")
	for z: float in [-16.2, -11.8]:
		MeshKit.box(self, Vector3(200, 0.08, 0.5), Vector3(0, 0.01, z), "soil")
	MeshKit.solid(self, Vector3(96, 2, 4.2), Vector3(-44.0, 1, -14))
	MeshKit.solid(self, Vector3(96, 2, 4.2), Vector3(55.0, 1, -14))
	MeshKit.box(self, Vector3(3.0, 0.14, 6.6), Vector3(5.5, 0.07, -14), "wood")
	for i in 9:
		MeshKit.box(self, Vector3(3.0, 0.02, 0.06), Vector3(5.5, 0.15, -17 + i * 0.75), "wood_dark")
	MeshKit.fence(self, Vector3(4.0, 0, -17.2), Vector3(4.0, 0, -10.8), "wood")
	MeshKit.fence(self, Vector3(7.0, 0, -17.2), Vector3(7.0, 0, -10.8), "wood")

	# Roads.
	MeshKit.path(self, Vector3(0, 0, 4.4), Vector3(5.5, 0, 4.4))
	MeshKit.path(self, Vector3(5.5, 0, 6), Vector3(5.5, 0, -11))
	MeshKit.path(self, Vector3(5.5, 0, 3), Vector3(8, 0, 3))
	MeshKit.path(self, Vector3(5.5, 0, -17), Vector3(6, 0, -21.5))
	MeshKit.path(self, Vector3(5.5, 0, -21), Vector3(-9, 0, -21))

	# Meadow with sheep east of the village.
	for i in 3:
		var sheep := Wanderer.new().setup(AnimalModel.make("sheep"), 80 + i)
		sheep.position = Vector3(22 + i * 1.5, 0, -24 + i)
		sheep.radius = 4.0
		sheep.speed = 0.3
		sheep.pause_range = Vector2(4, 10)
		add_child(sheep)

	_trees()
	_boundary()


func _patches() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 70:
		var p := Vector3(rng.randf_range(-36, 40), 0.0, rng.randf_range(-50, 18))
		if absf(p.z + 14) < 3.5:
			continue
		MeshKit.sphere(self, rng.randf_range(0.8, 2.2), p, "grass_dark", Vector3(1.0, 0.03, rng.randf_range(0.6, 1.2)), 7, 2)
	# Undergrowth: bushes, ferns, grass and wildflowers, kept off paths and buildings.
	var cover := ["bush", "bush_flowers", "fern", "grass_tuft", "grass_wispy", "grass_wispy", "flowers_a", "flowers_b", "clover", "plant"]
	for i in 90:
		var p := Vector3(rng.randf_range(-28, 32), 0, rng.randf_range(-44, 12))
		if _near_built(p) or _on_path(p):
			continue
		Props.place(self, cover[rng.randi() % cover.size()], p, rng.randf() * TAU, rng.randf_range(0.8, 1.2))


func _trees() -> void:
	var spots := [
		[-12, 4, 1.0, "tree_a"], [-15, -4, 1.0, "grove_b_small"], [-20, 8, 1.1, "tree_b"], [-18, -9, 1.0, "grove_a_small"],
		[12, 11, 1.0, "tree_a"], [20, 11, 1.0, "grove_b_small"], [25, -1, 1.1, "tree_b"], [26, -8, 1.0, "grove_a_medium"],
		[-4, -8, 0.9, "tree_a"], [-15, -18, 1.0, "grove_b_medium"], [17, -19, 1.0, "tree_b"], [24, -33, 1.0, "grove_a_small"],
		[-21, -31, 1.0, "grove_b_medium"], [-23, -40, 1.0, "tree_a"], [-16, -37, 1.1, "tree_b"], [-4, -35, 1.0, "grove_a_small"],
		[17, -36, 1.0, "tree_a"], [-25, -2, 1.0, "grove_a_medium"], [29, -15, 1.0, "tree_b"], [-1, -18.5, 0.8, "tree_a"],
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for s: Array in spots:
		Props.place(self, s[3], Vector3(s[0], 0, s[1]), rng.randf() * TAU, s[2])
	# A few old twisted trees as landmarks the child can steer by.
	Props.place(self, "twisted_tree", Vector3(-17, 0, -21), 0.6)
	Props.place(self, "twisted_tree_b", Vector3(-10, 0, 8), 2.4)
	Props.place(self, "twisted_tree", Vector3(20, 0, -40), 4.0, 0.9)
	for m: Array in [[-16, -19], [-15.2, -20.4], [-9, 9.5], [-11, 6.8]]:
		Props.place(self, "mushroom", Vector3(m[0], 0, m[1]), rng.randf() * TAU)
	# Working buildings and fields that make the valley feel lived in.
	Props.place(self, "windmill", Vector3(28, 0, -29), -0.4)
	Props.place(self, "watermill", Vector3(-11, 0, -10.2), PI)
	Props.place(self, "grain_field", Vector3(25, 0, 6), 0.3)
	Props.place(self, "grain_field", Vector3(29, 0, 0), -0.2)
	var rocks := ["rock", "rock_b", "rock_c"]
	for r: Array in [[-7, 9], [14, -9], [-19, -24], [20, -12], [-26, 6], [2, -42]]:
		Props.place(self, rocks[rng.randi() % 3], Vector3(r[0], 0, r[1]), rng.randf() * TAU, rng.randf_range(0.7, 1.2))
	for i in 12:
		Props.place(self, "pebble", Vector3(rng.randf_range(-25, 30), 0, -11.6 - rng.randf() * 0.4 if i % 2 == 0 else -16.4 + rng.randf() * 0.4), rng.randf() * TAU)
	for i in 5:
		Props.place(self, "waterlily", Vector3(-20 + i * 9.0 + rng.randf_range(-2, 2), 0.04, -14 + rng.randf_range(-1.2, 1.2)), rng.randf() * TAU)
		Props.place(self, "waterplant", Vector3(-17 + i * 9.0, 0.0, -12.0 + (i % 2) * -4.0), rng.randf() * TAU)
	for c: Array in [[-40, 34, -110, "cloud_big"], [10, 40, -150, "cloud_small"], [60, 30, -120, "cloud_big"], [-80, 38, -160, "cloud_small"]]:
		Props.place(self, c[3], Vector3(c[0], c[1], c[2]), 0.0, 2.5)


func _boundary() -> void:
	var b := BOUNDS
	MeshKit.solid(self, Vector3(1, 6, b.size.y), Vector3(b.position.x, 3, b.position.y + b.size.y / 2.0))
	MeshKit.solid(self, Vector3(1, 6, b.size.y), Vector3(b.end.x, 3, b.position.y + b.size.y / 2.0))
	MeshKit.solid(self, Vector3(b.size.x, 6, 1), Vector3(b.position.x + b.size.x / 2.0, 3, b.end.y))
	MeshKit.solid(self, Vector3(b.size.x, 6, 1), Vector3(b.position.x + b.size.x / 2.0, 3, b.position.y))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var groves := ["grove_a_medium", "grove_b_medium", "grove_a_small", "grove_b_small"]
	var x := b.position.x
	while x <= b.end.x:
		Props.place(self, groves[rng.randi() % 4], Vector3(x + rng.randf_range(-1, 1), 0, b.end.y + 2.5 + rng.randf_range(0, 2)), rng.randf() * TAU)
		# Keep the north edge low so the overlook can see Bellhaven.
		if x < -6 or x > 22:
			Props.place(self, groves[rng.randi() % 4], Vector3(x + rng.randf_range(-1, 1), 0, b.position.y - 2.5 - rng.randf_range(0, 2)), rng.randf() * TAU)
		else:
			Props.place(self, "fence_stone", Vector3(x, 0, b.position.y - 0.8), PI / 2.0, 1.0).scale.z = 3.5 / 1.6
		x += 4.0
	var z := b.position.y
	while z <= b.end.y:
		for side_x: float in [b.position.x - 2.5, b.end.x + 2.5]:
			Props.place(self, groves[rng.randi() % 4], Vector3(side_x + rng.randf_range(-1, 1), 0, z + rng.randf_range(-1, 1)), rng.randf() * TAU)
		z += 4.0
	# Rolling hills beyond the edges for silhouette. (The hex pack's hills and
	# mountains are map tiles with cliff sides, which read as mesas at this scale.)
	for h: Array in [[-60, -10, 30], [-55, -60, 25], [70, -20, 28], [60, -70, 22], [-10, 50, 30], [40, 45, 26], [-45, 30, 22]]:
		MeshKit.sphere(self, float(h[2]), Vector3(h[0], -float(h[2]) * 0.55, h[1]), "grass_dark", Vector3(1.6, 1.0, 1.0), 10, 5)


## Roughly the road network, so undergrowth never sits on a path.
static func _on_path(p: Vector3) -> bool:
	var roads := [Rect2(-1, 3.4, 7.5, 2), Rect2(4.5, -21, 2, 27), Rect2(-10, -22, 16, 2), Rect2(5, -46, 2, 26)]
	for r: Rect2 in roads:
		if r.grow(0.8).has_point(Vector2(p.x, p.z)):
			return true
	return false


static func _near_built(p: Vector3) -> bool:
	var areas := [Rect2(-6, -4, 12, 14), Rect2(7, -3, 14, 12), Rect2(-5, -38, 24, 20), Rect2(-15, -34, 12, 16), Rect2(3.5, -20, 4, 28)]
	for r: Rect2 in areas:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return absf(p.z + 14) < 3.0
