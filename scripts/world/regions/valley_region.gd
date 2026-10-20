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
	for i in 40:
		var p := Vector3(rng.randf_range(-28, 32), 0, rng.randf_range(-44, 12))
		if _near_built(p):
			continue
		MeshKit.sphere(self, 0.35, p + Vector3(0, 0.15, 0), "leaf_light", Vector3(1.0, 0.7, 1.0), 6, 3)


func _trees() -> void:
	var spots := [
		[-12, 4, 1.1, "round"], [-15, -4, 1.3, "pine"], [-20, 8, 1.0, "round"], [-18, -9, 1.2, "leaf_light"],
		[12, 11, 1.0, "round"], [20, 11, 1.2, "pine"], [25, -1, 1.1, "round"], [26, -8, 1.3, "pine"],
		[-4, -8, 0.9, "round"], [-15, -18, 1.1, "pine"], [17, -19, 1.0, "leaf_autumn"], [24, -33, 1.2, "round"],
		[-21, -31, 1.3, "pine"], [-23, -40, 1.1, "round"], [-16, -37, 1.0, "leaf_light"], [-4, -35, 1.2, "pine"],
		[17, -36, 1.1, "round"], [-25, -2, 1.2, "round"], [29, -15, 1.0, "pine"], [-1, -18.5, 0.8, "leaf_light"],
	]
	for s: Array in spots:
		MeshKit.tree(self, Vector3(s[0], 0, s[1]), s[2], s[3])


func _boundary() -> void:
	var b := BOUNDS
	MeshKit.solid(self, Vector3(1, 6, b.size.y), Vector3(b.position.x, 3, b.position.y + b.size.y / 2.0))
	MeshKit.solid(self, Vector3(1, 6, b.size.y), Vector3(b.end.x, 3, b.position.y + b.size.y / 2.0))
	MeshKit.solid(self, Vector3(b.size.x, 6, 1), Vector3(b.position.x + b.size.x / 2.0, 3, b.end.y))
	MeshKit.solid(self, Vector3(b.size.x, 6, 1), Vector3(b.position.x + b.size.x / 2.0, 3, b.position.y))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var x := b.position.x
	while x <= b.end.x:
		MeshKit.tree(self, Vector3(x + rng.randf_range(-1, 1), 0, b.end.y + 2 + rng.randf_range(0, 3)), rng.randf_range(1.0, 1.5), "pine")
		# Keep the north edge low so the overlook can see Bellhaven.
		if x < -6 or x > 22:
			MeshKit.tree(self, Vector3(x + rng.randf_range(-1, 1), 0, b.position.y - 2 - rng.randf_range(0, 3)), rng.randf_range(1.0, 1.5), "pine")
		else:
			MeshKit.sphere(self, 0.9, Vector3(x, 0.3, b.position.y - 1.5), "leaf", Vector3(1.4, 0.7, 1.0), 7, 3)
		x += 3.5
	var z := b.position.y
	while z <= b.end.y:
		for side_x: float in [b.position.x - 2.5, b.end.x + 2.5]:
			MeshKit.tree(self, Vector3(side_x + rng.randf_range(-1, 1), 0, z + rng.randf_range(-1, 1)), rng.randf_range(1.0, 1.6), "pine" if rng.randf() < 0.6 else "round")
		z += 3.5
	# Rolling hills beyond the edges for silhouette.
	for h: Array in [[-60, -10, 30], [-55, -60, 25], [70, -20, 28], [60, -70, 22], [-10, 50, 30], [40, 45, 26], [-45, 30, 22]]:
		MeshKit.sphere(self, float(h[2]), Vector3(h[0], -float(h[2]) * 0.55, h[1]), "grass_dark", Vector3(1.6, 1.0, 1.0), 10, 5)


static func _near_built(p: Vector3) -> bool:
	var areas := [Rect2(-6, -4, 12, 14), Rect2(7, -3, 14, 12), Rect2(-5, -38, 24, 20), Rect2(-15, -34, 12, 16), Rect2(3.5, -20, 4, 28)]
	for r: Rect2 in areas:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return absf(p.z + 14) < 3.0
