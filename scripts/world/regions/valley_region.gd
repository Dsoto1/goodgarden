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
	var land := MeshInstance3D.new()
	land.name = "Landscape"
	land.mesh = Terrain.build_mesh()
	land.material_override = Style.material("ground", {"wrap": 0.3})
	add_child(land)
	_patches()

	# River with a single bridge crossing.
	add_clearing(Vector3(0, 0, -14), Vector2(400, 8.4))
	# River surface in its carved channel; it begins at the waterfall to the west.
	var river_len := 200.0 - Terrain.FALLS_X
	MeshKit.box(self, Vector3(river_len, 0.06, 7.0), Vector3(Terrain.FALLS_X + river_len / 2.0 + 0.5, Terrain.RIVER_LEVEL, -14), "water")
	Waterfall.build(self)
	MeshKit.solid(self, Vector3(96, 2, 4.2), Vector3(-44.0, 1, -14), 0.0, MeshKit.LAYER_INVISIBLE)
	MeshKit.solid(self, Vector3(96, 2, 4.2), Vector3(55.0, 1, -14), 0.0, MeshKit.LAYER_INVISIBLE)
	StoneBridge.build(self, Vector3(5.5, 0, -14))
	# A riverbank seat east of the bridge, where the view turns west along the
	# river: the arch in front, the waterfall far off.
	MeshKit.box(self, Vector3(1.6, 0.45, 0.5), Vector3(11.5, 0.22, -9.4), "wood", true)
	for i in 3:
		Props.place(self, "stepping_stone" if i % 2 == 0 else "stepping_stone_b", Vector3(7.4 + i * 1.2, 0.0, -9.6 + (i % 2) * 0.3), i * 0.9)
	add_clearing(Vector3(9.6, 0, -9.6), Vector2(5.2, 2.0))
	add_anchor("riverbank", Vector3(10.6, 0, -9.0), PI / 2.0)
	add_place_zone("river", Vector3(7.0, 1, -12.5), Vector3(16, 3, 9))
	add_camera_zone(Vector3(10.5, 1, -9.4), Vector3(5.0, 3, 3.0), {"yaw": 76.0, "pitch": 11.0, "distance": 8.5, "height": 1.5, "fov": 54.0})

	# Roads.
	road(Vector3(0, 0, 4.4), Vector3(5.5, 0, 4.4))
	road(Vector3(5.5, 0, 6), Vector3(5.5, 0, -11))
	road(Vector3(5.5, 0, 3), Vector3(8, 0, 3))
	road(Vector3(5.5, 0, -17), Vector3(6, 0, -19.2))
	road(Vector3(2.0, 0, -19.4), Vector3(-15.0, 0, -19.4))

	# Meadow with sheep east of the village, in a fold whose gate faces the village.
	_sheepfold(Rect2(23.0, -26.2, 7.0, 7.4))
	CraftedProps.water_trough(self, Vector3(28.4, 0, -20.0))
	CraftedProps.hay_bale(self, Vector3(31.6, 0, -21.4), 0.3)
	CraftedProps.hay_bale(self, Vector3(31.9, 0, -19.6), -0.2)
	CraftedProps.haystack(self, Vector3(32.4, 0, -25.6))
	# Life along the road and river.
	CraftedProps.hand_cart(self, Vector3(7.6, 0, -6.4), 0.25)
	CraftedProps.jetty(self, Vector3(15.2, 0, -10.2), 0.0, 3.0)
	CraftedProps.rowboat(self, Vector3(16.9, Terrain.RIVER_LEVEL - 0.05, -12.3), 1.45)
	CraftedProps.signpost(self, Vector3(6.9, 0, 5.8), [["Village", 0.0], ["Home", PI / 2.0], ["Garden", -PI / 2.0]])
	CraftedProps.signpost(self, Vector3(3.2, 0, -18.6), [["Village", -0.3], ["Chapel", PI / 2.0], ["Home", PI]])
	for i in 3:
		var sheep := Wanderer.new().setup(AnimalModel.make("sheep"), 80 + i)
		sheep.position = Vector3(25 + i * 1.3, 0, -23.5 + i)
		sheep.radius = 2.2
		sheep.speed = 0.3
		sheep.pause_range = Vector2(4, 10)
		add_child(sheep)

	_trees()
	_boundary()


## A wooden fold around the sheep, with the gate in the west side.
func _sheepfold(r: Rect2) -> void:
	var nw := Vector3(r.position.x, 0, r.position.y)
	var ne := Vector3(r.end.x, 0, r.position.y)
	var se := Vector3(r.end.x, 0, r.end.y)
	var sw := Vector3(r.position.x, 0, r.end.y)
	var mid := (r.position.y + r.end.y) / 2.0
	Props.fence(self, "fence_wood", nw, ne)
	Props.fence(self, "fence_wood", ne, se)
	Props.fence(self, "fence_wood", se, sw)
	Props.fence(self, "fence_wood", sw, Vector3(r.position.x, 0, mid + 0.95))
	Props.fence(self, "fence_wood", Vector3(r.position.x, 0, mid - 0.95), nw)
	CraftedProps.fold_gate(self, Vector3(r.position.x, 0, mid), PI / 2.0)


func _patches() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
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
		[-4, -8, 0.9, "tree_a"], [-26, -21, 1.0, "grove_b_medium"], [19, -17.5, 1.0, "tree_b"], [24, -33, 1.0, "grove_a_small"],
		[-24, -31, 1.0, "grove_b_medium"], [-23, -40, 1.0, "tree_a"], [-16, -37, 1.1, "tree_b"], [-9, -41, 1.0, "grove_a_small"],
		[22, -40, 1.0, "tree_a"], [-25, -2, 1.0, "grove_a_medium"], [29, -15, 1.0, "tree_b"],
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for s: Array in spots:
		Props.place(self, s[3], Vector3(s[0], 0, s[1]), rng.randf() * TAU, s[2])
	# A few old twisted trees as landmarks the child can steer by.
	Props.place(self, "twisted_tree", Vector3(-24, 0, -24), 0.6)
	Props.place(self, "twisted_tree_b", Vector3(-10, 0, 8), 2.4)
	Props.place(self, "twisted_tree", Vector3(25, 0, -42), 4.0, 0.9)
	for m: Array in [[-23, -22], [-22.2, -23.4], [-9, 9.5], [-11, 6.8]]:
		Props.place(self, "mushroom", Vector3(m[0], 0, m[1]), rng.randf() * TAU)
	# Working buildings and fields that make the valley feel lived in.
	Props.place(self, "windmill", Vector3(28, 0, -29), -0.4)
	Props.place(self, "watermill", Vector3(-21, 0, -10.4), PI)
	Props.place(self, "grain_field", Vector3(25, 0, 6), 0.3)
	Props.place(self, "grain_field", Vector3(29, 0, 0), -0.2)
	var rocks := ["rock", "rock_b", "rock_c"]
	for r: Array in [[-7, 9], [17, -6], [-25, -28], [20, -11], [-26, 6], [2, -45]]:
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
	var edge := MeshKit.LAYER_INVISIBLE
	MeshKit.solid(self, Vector3(1, 6, b.size.y), Vector3(b.position.x, 3, b.position.y + b.size.y / 2.0), 0.0, edge)
	MeshKit.solid(self, Vector3(1, 6, b.size.y), Vector3(b.end.x, 3, b.position.y + b.size.y / 2.0), 0.0, edge)
	MeshKit.solid(self, Vector3(b.size.x, 6, 1), Vector3(b.position.x + b.size.x / 2.0, 3, b.end.y), 0.0, edge)
	MeshKit.solid(self, Vector3(b.size.x, 6, 1), Vector3(b.position.x + b.size.x / 2.0, 3, b.position.y), 0.0, edge)
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
			if absf(z - Terrain.RIVER_Z) < 7.0:
				continue # the river runs out through here
			Props.place(self, groves[rng.randi() % 4], Vector3(side_x + rng.randf_range(-1, 1), 0, z + rng.randf_range(-1, 1)), rng.randf() * TAU)
		z += 4.0
	# Hills and mountains beyond the edges come from Terrain (see World).


## Roughly the road network, so undergrowth never sits on a path.
static func _on_path(p: Vector3) -> bool:
	var roads := [Rect2(-1, 3.4, 7.5, 2), Rect2(4.5, -21, 2, 27), Rect2(-16, -20.4, 19, 2), Rect2(5, -46, 2, 26)]
	for r: Rect2 in roads:
		if r.grow(0.8).has_point(Vector2(p.x, p.z)):
			return true
	return false


static func _near_built(p: Vector3) -> bool:
	var areas := [Rect2(-6, -4, 12, 14), Rect2(7, -3, 14, 12), Rect2(-9, -46, 32, 30), Rect2(-22, -34, 12, 16), Rect2(3.5, -20, 4, 28)]
	for r: Rect2 in areas:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return absf(p.z + 14) < 3.0
