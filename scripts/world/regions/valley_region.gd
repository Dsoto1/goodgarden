class_name ValleyRegion
extends Region
## The shared valley floor: ground, river and bridge, the roads that connect
## the places, a meadow with sheep, and the trees that frame the playable area.

## Where stepping stones cross the river, between the mill and the bridge.
const FORD_X := -12.5

const BOUNDS := Rect2(-36, -46, 70, 59) # x, z, width, depth of the walkable area
## Feeding troughs along the sheepfold's north fence.
const TROUGHS := [Vector3(25.8, 0, -25.2), Vector3(27.6, 0, -25.2), Vector3(29.4, 0, -25.2)]

var _fed: Node3D # hay in the troughs and lambs eating, on a day they are fed
var _flour: Node3D # flour sacks by the mill, once flour has been made
var _orchard: Node3D # the young apple trees, once planted
var _saplings: Node3D # the bundle of saplings waiting to be planted

## The orchard row and the pond, in the meadow west of home.
const ORCHARD := [Vector3(-18.5, 0, 2.0), Vector3(-15.5, 0, 2.0), Vector3(-12.5, 0, 2.0)]
const POND := Vector3(-25.0, 0, 7.0)


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

	# The river winds through the valley from the waterfall in the west, with
	# a single bridge crossing.
	_river()
	_ford()
	_reeds_on_bends()
	_fishing_spot()
	Waterfall.build(self)
	StoneBridge.build(self, Vector3(5.5, 0, -14))
	# A riverbank seat east of the bridge, where the view turns west along the
	# river: the arch in front, the waterfall far off.
	MeshKit.box(self, Vector3(1.6, 0.45, 0.5), Vector3(11.5, 0.22, -9.4), "wood", true)
	for i in 3:
		var sx := 7.4 + i * 1.2
		var sz := -9.3 + (i % 2) * 0.3
		Props.place(self, "stepping_stone" if i % 2 == 0 else "stepping_stone_b", Vector3(sx, Terrain.height(sx, sz), sz), i * 0.9)
	add_clearing(Vector3(9.6, 0, -9.6), Vector2(5.2, 2.0))
	add_anchor("riverbank", Vector3(10.6, 0, -9.0), PI / 2.0)
	add_place_zone("river", Vector3(7.0, 1, -12.5), Vector3(16, 3, 9))
	add_camera_zone(Vector3(10.5, 1, -9.4), Vector3(5.0, 3, 3.0), {"yaw": 76.0, "pitch": 11.0, "distance": 8.5, "height": 1.5, "fov": 54.0})

	# Roads.
	# Paths that wander a little, the way feet wear them, and run right up to
	# the doors: home to the lane, the lane down to the bridge, over the river
	# into the square, and along the bank to the chapel.
	path([Vector3(0.0, 0, 3.9), Vector3(0.6, 0, 5.0), Vector3(2.8, 0, 5.5), Vector3(4.9, 0, 5.0), Vector3(5.7, 0, 4.0)], 1.5)
	path([Vector3(5.6, 0, 5.4), Vector3(5.8, 0, 2.6), Vector3(5.3, 0, -1.8), Vector3(5.9, 0, -6.2), Vector3(5.5, 0, -9.6), Vector3(5.5, 0, -10.9)], 1.7)
	path([Vector3(5.5, 0, -18.1), Vector3(5.8, 0, -19.6)], 2.0)
	var bank_path: Array = []
	for p: Vector3 in [Vector3(0.6, 0, -21.4), Vector3(-2.5, 0, -20.2), Vector3(-6.5, 0, -19.6), Vector3(-10.5, 0, -19.8), Vector3(-14.5, 0, -20.3), Vector3(-18.5, 0, -21.4), Vector3(-21.6, 0, -22.2)]:
		var north_bank := Terrain.river_z(p.x) - Terrain.river_half_width(p.x, true)
		bank_path.append(Vector3(p.x, 0, minf(p.z, north_bank - 2.2)))
	path(bank_path, 1.6)

	# Meadow with sheep east of the village, in a fold whose gate faces the village.
	_paddock(Rect2(24.0, -26.2, 7.0, 7.4), "w")
	CraftedProps.water_trough(self, Vector3(29.4, 0, -20.0))
	for i in 2:
		var lamb := Wanderer.new().setup(AnimalModel.make("lamb"), 90 + i)
		lamb.position = Vector3(26.8 + i * 1.2, 0, -22.6 - i * 0.8)
		lamb.radius = 1.8
		lamb.speed = 0.4
		lamb.pause_range = Vector2(2, 6)
		add_child(lamb)
		AnimalMoments.strokable(lamb, "Stroke the lamb", ["The lamb nuzzles your hand and gives a little hop.", "Soft, curly wool! The lamb hops for joy."], "sheep")
	CraftedProps.hay_bale(self, Vector3(32.6, 0, -21.4), 0.3)
	_lamb_troughs()
	_orchard_and_pond()
	# A path from the village square out to the sheepfold gate.
	path([Vector3(14.6, 0, -24.6), Vector3(17.6, 0, -23.4), Vector3(20.8, 0, -22.9), Vector3(23.4, 0, -22.5)], 1.3)
	CraftedProps.hay_bale(self, Vector3(32.9, 0, -19.6), -0.2)
	CraftedProps.haystack(self, Vector3(33.4, 0, -25.6))
	# Life along the road and river.
	CraftedProps.hand_cart(self, Vector3(7.6, 0, -6.4), 0.25)
	var shore := func(x: float) -> float:
		return Terrain.river_z(x) + Terrain.river_half_width(x, false)
	CraftedProps.jetty(self, Vector3(15.2, 0, shore.call(15.2) + 0.2), 0.0, 3.0)
	CraftedProps.rowboat(self, Vector3(16.9, Terrain.RIVER_LEVEL - 0.05, shore.call(16.9) - 1.9), 1.45)
	CraftedProps.creel_and_rope(self, Vector3(15.0, 0.21, shore.call(15.2) - 1.8), 0.4)
	CraftedProps.net_rack(self, Vector3(17.8, 0, shore.call(17.8) + 1.7), -0.15)
	CraftedProps.signpost(self, Vector3(6.9, 0, 5.8), [["Village", 0.0], ["Home", PI / 2.0], ["Garden", -PI / 2.0]])
	CraftedProps.signpost(self, Vector3(3.2, 0, -18.6), [["Village", -0.3], ["Chapel", PI / 2.0], ["Home", PI]])
	for i in 3:
		var sheep := Wanderer.new().setup(AnimalModel.make("sheep"), 80 + i)
		sheep.position = Vector3(26 + i * 1.3, 0, -23.5 + i)
		sheep.radius = 2.2
		sheep.speed = 0.3
		sheep.pause_range = Vector2(4, 10)
		add_child(sheep)
		AnimalMoments.strokable(sheep, "Stroke the sheep", ["The sheep stands still and lets you stroke its thick wool."], "sheep")
	_farm_animals()

	_trees()
	_boundary()
	_sounds()


## Water and animals you can hear: the river grows louder as you near it, the
## waterfall roars softly in the west, and the sheep call from their fold.
func _sounds() -> void:
	for x: float in [-46.0, -34.0, -22.0, -12.5, -2.0, 5.5, 14.0, 24.0, 35.0]:
		SoundSpot.looping(self, "river", Vector3(x, Terrain.RIVER_LEVEL + 0.3, Terrain.river_z(x)), 14.0, 0.0)
	SoundSpot.looping(self, "waterfall", Vector3(Terrain.FALLS_X + 2.5, Terrain.RIVER_LEVEL + 1.0, Terrain.river_z(Terrain.FALLS_X)), 42.0, 0.0)
	SoundSpot.calling(self, "sheep", Vector3(27.5, 0.6, -22.5), 30.0, Vector2(7, 16), -6.0)


## From day 5 the hay bale starts the feeding; on a day the lambs are fed,
## hay fills the troughs and the lambs come to eat.
func _lamb_troughs() -> void:
	for t: Vector3 in TROUGHS:
		MeshKit.box(self, Vector3(1.3, 0.12, 0.5), t + Vector3(0, 0.34, 0), "wood_dark")
		for side: float in [-1.0, 1.0]:
			MeshKit.box(self, Vector3(1.3, 0.22, 0.06), t + Vector3(0, 0.45, side * 0.24), "wood")
			MeshKit.box(self, Vector3(0.08, 0.34, 0.08), t + Vector3(side * 0.55, 0.17, 0), "wood_dark")
	_fed = group_node("FedLambs")
	for i in TROUGHS.size():
		var t: Vector3 = TROUGHS[i]
		# Loose straw heaped in the trough.
		for k in 9:
			var straw := MeshKit.box(_fed, Vector3(0.5, 0.04, 0.05), t + Vector3(-0.42 + (k % 5) * 0.21, 0.47 + (k / 5) * 0.04, -0.12 + (k % 3) * 0.12), "roof_thatch")
			straw.rotation = Vector3(0, 0.4 * ((k * 7) % 5 - 2), 0.15 * ((k * 3) % 3 - 1))
		var lamb := AnimalModel.make("lamb")
		lamb.position = t + Vector3(0.15, 0, 1.15)
		lamb.rotation.y = PI + (i - 1) * 0.3
		_fed.add_child(lamb)
	var feed := Interactable.create(self, Vector3(32.0, 0, -21.4), "Feed the lambs", func() -> void:
		get_tree().call_group("main", "start_activity_here", "sheepfold_hay", position + TROUGHS[1] + Vector3(0, 0.5, 0)), 0.7, 1.4)
	feed.conditions = [{"day_at_least": 5}]
	add_anchor("sheepfold_ruth", Vector3(32.2, 0, -23.0), PI / 2.0)
	add_activity_focus(TROUGHS[1] + Vector3(0, 0.5, 0))


## The meadow west of home: from day 8 a bundle of young apple trees waits to
## be planted in a row; once planted they grow, and blossom after two days.
## The pond is always there; from day 9 the child can look in it with Mrs. Ruth.
func _orchard_and_pond() -> void:
	_orchard = group_node("Orchard")
	_saplings = group_node("Saplings")
	for k in 3:
		var stick := MeshKit.cylinder(_saplings, 0.025, 0.04, 1.3, Vector3(-10.9 + k * 0.12, 0.6, 3.8), "trunk", 5)
		stick.rotation.z = -0.35 + k * 0.08
		MeshKit.sphere(_saplings, 0.18, Vector3(-11.1 + k * 0.12, 1.2, 3.8), "leaf_light", Vector3(1, 0.8, 1), 6, 3)
	MeshKit.box(_saplings, Vector3(0.5, 0.25, 0.4), Vector3(-10.8, 0.12, 3.8), "cloth_tan")
	var plant := Interactable.create(self, Vector3(-10.6, 0, 4.6), "Plant the apple trees", func() -> void:
		get_tree().call_group("main", "start_activity_here", "orchard_plant", position + ORCHARD[1] + Vector3(0, 0.6, 0)), 0.7, 1.4)
	plant.conditions = [{"day_at_least": 8}, {"fact": "orchard.planted", "exists": false}]
	add_anchor("orchard_miriam", Vector3(-10.2, 0, 6.2), -PI / 2.0)
	add_activity_focus(ORCHARD[1] + Vector3(0, 0.6, 0))
	add_clearing(ORCHARD[1], Vector2(9.0, 3.0))
	CraftedProps.pond(self, POND, Vector2(3.8, 2.8), 12)
	add_clearing(POND, Vector2(9.4, 7.0))
	var look := Interactable.create(self, POND + Vector3(4.4, 0, 0.8), "Look in the pond", func() -> void:
		get_tree().call_group("main", "start_activity_here", "pond_creatures", position + POND + Vector3(0, 0.4, 0)), 0.8, 1.4)
	look.conditions = [{"day_at_least": 9}]
	add_anchor("pond_ruth", POND + Vector3(4.8, 0, -0.6), -PI / 2.0)
	add_activity_focus(POND + Vector3(0, 0.4, 0))
	# A path from home's door west past the orchard to the pond.
	path([Vector3(-1.2, 0, 4.6), Vector3(-4.6, 0, 6.4), Vector3(-9.0, 0, 6.2), Vector3(-13.5, 0, 4.8), Vector3(-17.5, 0, 5.0), Vector3(-20.4, 0, 6.6)], 1.3)


func _sync_orchard() -> void:
	for c in _orchard.get_children():
		c.queue_free()
	var planted: Variant = WorldState.get_fact("orchard.planted")
	_saplings.visible = planted == null
	if planted == null:
		return
	var age := Days.current_day - int(planted)
	for i in ORCHARD.size():
		var at: Vector3 = ORCHARD[i]
		var h := 1.4 if age < 2 else 1.8
		MeshKit.cylinder(_orchard, 0.05, 0.08, h, at + Vector3(0, h / 2.0, 0), "trunk", 6)
		MeshKit.box(_orchard, Vector3(0.05, 1.3, 0.05), at + Vector3(0.18, 0.65, 0), "wood_light")
		var crown := 0.5 if age < 2 else 0.7
		var top := at + Vector3(0, h + 0.2, 0)
		MeshKit.sphere(_orchard, crown, top, "leaf", Vector3(1, 0.85, 1), 8, 5)
		# A second, smaller lump so the crown isn't a perfect ball.
		MeshKit.sphere(_orchard, crown * 0.6, top + Vector3(crown * 0.45, crown * 0.3, -crown * 0.25), "leaf", Vector3.ONE, 7, 4)
		MeshKit.sphere(_orchard, 0.4, at + Vector3(0, 0.03, 0), "soil_dark", Vector3(1, 0.06, 1), 8, 2)
		if age >= 2:
			# Spring blossom, dotted over the outside of the crown.
			for k in 24:
				var a := TAU * k / 24.0 * 5.0 + i
				var up := lerpf(-0.2, 0.85, fmod(k * 0.618, 1.0))
				var dir := Vector3(cos(a) * sqrt(1.0 - up * up), up, sin(a) * sqrt(1.0 - up * up))
				MeshKit.sphere(_orchard, 0.075, top + dir * Vector3(crown, crown * 0.85, crown) * 0.98, "flower_pink", Vector3.ONE, 6, 3)


func sync_with_world() -> void:
	if _orchard:
		_sync_orchard()
	if _fed:
		var fed: Variant = WorldState.get_fact("valley.lambs_fed")
		_fed.visible = fed != null and int(fed) == Days.current_day
	if _flour:
		_flour.visible = WorldState.get_fact("village.flour_day") != null


## A wooden fence around `r` (x, z, width, depth) with an open gate in the
## middle of one side: "n", "s", "e" or "w".
func _paddock(r: Rect2, gate: String) -> void:
	var corners := [Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y), Vector3(r.end.x, 0, r.end.y), Vector3(r.position.x, 0, r.end.y)]
	for i in 4:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		if "nesw"[i] != gate:
			Props.fence(self, "fence_wood", a, b)
			continue
		# Leave a gap for the gate, which stands open so the child can go in.
		var mid := (a + b) / 2.0
		var along := (b - a).normalized()
		Props.fence(self, "fence_wood", a, mid - along * 0.95)
		Props.fence(self, "fence_wood", mid + along * 0.95, b)
		CraftedProps.fold_gate(self, mid, {"n": PI, "e": -PI / 2.0, "s": 0.0, "w": PI / 2.0}[gate], true)


## Cows in a pasture past the windmill, the horse in a paddock west of the
## mill, and pigs in their sty beside it. Each can be stroked.
func _farm_animals() -> void:
	_paddock(Rect2(26.5, -38.6, 7.0, 5.0), "s")
	for i in 2:
		var cow := Wanderer.new().setup(AnimalModel.make("cow"), 110 + i)
		cow.position = Vector3(28.4 + i * 2.8, 0, -36.8 + i * 1.4)
		cow.radius = 1.5
		cow.speed = 0.35
		cow.pause_range = Vector2(6, 14)
		add_child(cow)
		AnimalMoments.strokable(cow, "Stroke the cow", ["The cow is warm and calm. She turns her big eyes to you."], "cow")
	CraftedProps.hay_bale(self, Vector3(32.4, 0, -37.6), 0.4)
	CraftedProps.water_trough(self, Vector3(27.6, 0, -37.9))
	SoundSpot.calling(self, "cow", Vector3(30.0, 1.0, -36.0), 30.0, Vector2(18, 40), -8.0)

	_paddock(Rect2(-32.0, -8.6, 6.0, 4.8), "e")
	var horse := Wanderer.new().setup(AnimalModel.make("horse"), 120)
	horse.position = Vector3(-29.0, 0, -6.2)
	horse.radius = 1.6
	horse.speed = 0.5
	horse.pause_range = Vector2(5, 12)
	add_child(horse)
	AnimalMoments.strokable(horse, "Stroke the horse", ["The horse lowers its head so you can stroke its soft nose."], "horse")
	CraftedProps.hay_bale(self, Vector3(-31.0, 0, -7.6), 0.2)

	_paddock(Rect2(-32.0, -1.4, 4.4, 3.6), "e")
	# A wallow of mud, which pigs love: it keeps them cool.
	MeshKit.sphere(self, 1.0, Vector3(-30.6, 0.0, 0.6), "soil_dark", Vector3(1.2, 0.08, 0.8), 10, 3)
	for i in 2:
		var pig := Wanderer.new().setup(AnimalModel.make("pig"), 130 + i)
		pig.position = Vector3(-30.8 + i * 1.4, 0, 0.0 + i * 0.8)
		pig.radius = 1.0
		pig.speed = 0.3
		pig.pause_range = Vector2(3, 9)
		add_child(pig)
		AnimalMoments.strokable(pig, "Scratch the pig's back", ["The pig gives a happy grunt and leans on you."], "pig")
	SoundSpot.calling(self, "pig", Vector3(-30.0, 0.6, 0.4), 22.0, Vector2(12, 28), -8.0)


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
		[-15.5, 15.5, 1.0, "tree_a"], [-15, -4, 1.0, "grove_b_small"], [-31.5, 10.5, 1.1, "tree_b"], [-16, -5, 1.0, "grove_a_small"],
		[12, 11, 1.0, "tree_a"], [20, 11, 1.0, "grove_b_small"], [25, -1, 1.1, "tree_b"], [26, -8, 1.0, "grove_a_medium"],
		[-4, -8, 0.9, "tree_a"], [-34, -23, 1.0, "grove_b_medium"], [19, -17.5, 1.0, "tree_b"], [24, -33, 1.0, "grove_a_small"],
		[-33, -31, 1.0, "grove_b_medium"], [-23, -40, 1.0, "tree_a"], [-16, -37, 1.1, "tree_b"], [-12, -45, 1.0, "grove_a_small"],
		[26, -43, 1.0, "tree_a"], [-22, 2.5, 1.0, "grove_a_medium"], [29, -15, 1.0, "tree_b"],
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for s: Array in spots:
		var at := Vector3(s[0], 0, s[1])
		# Keep every tree on dry ground, whichever way the river bends.
		if Terrain.river_bank_distance(at.x, at.z) < 1.8:
			var c := Terrain.river_z(at.x)
			var north := at.z < c
			at.z = c + (Terrain.river_half_width(at.x, north) + 2.4) * (-1.0 if north else 1.0)
		Props.place(self, s[3], at, rng.randf() * TAU, s[2])
	# A few old twisted trees as landmarks the child can steer by.
	Props.place(self, "twisted_tree", Vector3(-33, 0, -25), 0.6)
	# South of the orchard, so it never stands between the camera and the work.
	Props.place(self, "twisted_tree_b", Vector3(-7, 0, 14), 2.4)
	Props.place(self, "twisted_tree", Vector3(25, 0, -42), 4.0, 0.9)
	for m: Array in [[-34.6, -21.4], [-35.2, -22.6], [-6, 15.4], [-8.2, 13.1]]:
		Props.place(self, "mushroom", Vector3(m[0], 0, m[1]), rng.randf() * TAU)
	# Working buildings and fields that make the valley feel lived in.
	Props.place(self, "windmill", Vector3(28, 0, -29), -0.4)
	var mill_at := Vector3(-21, 0, Terrain.river_z(-21) + Terrain.river_half_width(-21, false) + 0.1)
	Props.place(self, "watermill", mill_at, PI)
	# From day 6 the mill takes grain to clean and flour to weigh; sacks of
	# flour wait by its door once it has been made.
	var mill := Interactable.create(self, mill_at + Vector3(2.4, 0, 3.2), "Help at the mill", func() -> void:
		get_tree().call_group("main", "start_activity_here", "mill_flour", position + mill_at + Vector3(0, 1.2, 1.5)), 0.8, 1.8)
	mill.conditions = [{"day_at_least": 6}]
	add_anchor("mill_tobias", mill_at + Vector3(3.6, 0, 3.6), PI * 0.75)
	add_activity_focus(mill_at + Vector3(0, 1.2, 1.5))
	# From the lane by home, along the south bank to the ford, and on to the mill.
	var ford_south := Terrain.river_z(FORD_X) + Terrain.river_half_width(FORD_X, false) + 0.6
	path([Vector3(5.0, 0, -6.4), Vector3(1.0, 0, -6.0), Vector3(-3.0, 0, -6.2), Vector3(-7.0, 0, -7.0), Vector3(-10.4, 0, ford_south + 0.9),
		Vector3(FORD_X, 0, ford_south + 0.2), Vector3(-15.2, 0, ford_south + 1.2), Vector3(-18.0, 0, mill_at.z + 3.6), Vector3(mill_at.x + 2.4, 0, mill_at.z + 3.6)], 1.3)
	_flour = group_node("FlourSacks")
	for k in 3:
		Props.place(_flour, "sack", mill_at + Vector3(3.3 + k * 0.55, 0, 2.6 + (k % 2) * 0.3), k * 0.7)
	CraftedProps.grain_field(self, Vector3(25.5, 0, 6.5), Vector2(7.0, 4.4), 0.25, 3)
	CraftedProps.grain_field(self, Vector3(29.5, 0, -0.5), Vector2(6.0, 4.4), -0.2, 4)
	var rocks := ["rock", "rock_b", "rock_c"]
	for r: Array in [[-7, 9], [17, -6], [-25, -28], [22, -8.5], [-31, 1.5], [2, -45]]:
		Props.place(self, rocks[rng.randi() % 3], Vector3(r[0], Terrain.height(r[0], r[1]), r[1]), rng.randf() * TAU, rng.randf_range(0.7, 1.2))
	# Pebbles at the water's edge, lilies in the slow water, reeds on the banks.
	for i in 14:
		var x := rng.randf_range(-30, 34)
		if absf(x - 5.5) < 3.0:
			continue
		var north := i % 2 == 1
		var edge := Terrain.river_half_width(x, north) - 0.25 - rng.randf() * 0.4
		var pz := Terrain.river_z(x) + (-edge if north else edge)
		Props.place(self, "pebble", Vector3(x, maxf(Terrain.height(x, pz), Terrain.RIVER_LEVEL - 0.06), pz), rng.randf() * TAU)
	for i in 6:
		var x := -24 + i * 9.0 + rng.randf_range(-2, 2)
		if absf(x - 5.5) < 4.0:
			x += 6.0
		Props.place(self, "waterlily", Vector3(x, Terrain.RIVER_LEVEL + 0.01, Terrain.river_z(x) + rng.randf_range(-1.2, 1.2)), rng.randf() * TAU)

	for c: Array in [[-40, 34, -110, "cloud_big"], [10, 40, -150, "cloud_small"], [60, 30, -120, "cloud_big"], [-80, 38, -160, "cloud_small"]]:
		Props.place(self, c[3], Vector3(c[0], c[1], c[2]), 0.0, 2.5)


## The river's water surface follows its winding course, a little wider
## than the channel so the carved banks frame it. Invisible walls along each
## side keep the avatar on dry land (the bridge is the way across), and
## ground cover keeps off the water.
func _river() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var prev_n := Vector3.ZERO
	var prev_s := Vector3.ZERO
	var x := Terrain.FALLS_X + 0.5
	while x <= 200.0:
		var c := Terrain.river_z(x)
		var n := Vector3(x, Terrain.RIVER_LEVEL, c - Terrain.river_half_width(x, true) - 0.6)
		var s := Vector3(x, Terrain.RIVER_LEVEL, c + Terrain.river_half_width(x, false) + 0.6)
		if x > Terrain.FALLS_X + 0.5:
			PathKit._tri(st, prev_n, n, prev_s)
			PathKit._tri(st, n, s, prev_s)
		prev_n = n
		prev_s = s
		x += 1.0 if absf(x) < 90.0 else 4.0
	var water := MeshInstance3D.new()
	water.name = "River"
	water.mesh = st.commit()
	water.material_override = Palette.mat("water")
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)
	# Walls a little inside each bank, in short pieces that turn with the river,
	# stopping exactly at the bridge's ends (x 4 to 7) and at the stepping
	# stones, the two ways across.
	for span: Vector2 in [Vector2(Terrain.FALLS_X, FORD_X - 1.0), Vector2(FORD_X + 1.0, 4.0), Vector2(7.0, 150.0)]:
		x = span.x
		while x < span.y - 0.01:
			var piece := minf(3.0, span.y - x)
			var mid := x + piece / 2.0
			var c := Terrain.river_z(mid)
			var heading := atan2(Terrain.river_z(x + piece) - Terrain.river_z(x), piece)
			var half := minf(Terrain.river_half_width(mid, true), Terrain.river_half_width(mid, false)) - 1.3
			MeshKit.solid(self, Vector3(piece + 0.2, 2, half * 2.0), Vector3(mid, 1, c), -heading, MeshKit.LAYER_INVISIBLE)
			add_clearing(Vector3(mid, 0, c), Vector2(piece + 0.2, 2.0 * (half + 1.3) + 1.2))
			x += piece


## A quiet fishing spot on the north bank west of the chapel, reached by a
## path from the chapel porch. Sitting to fish is like sitting quietly in the
## chapel: the view settles on the float, and nothing is counted.
## The child sits on the crate and takes up the rod; standing puts it back.
func _sit_and_fish(spot: Node3D, bob: Vector3) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var resting := spot.get_node("RestingRod") as Node3D
	var seat := spot.global_transform * Vector3(0.1, 0, 0.62)
	player.teleport(seat, spot.global_rotation.y)
	player.model.sit(0.44)
	player.model.hold(FishingRod.create(Terrain.RIVER_LEVEL))
	resting.visible = false
	get_tree().call_group("main", "sit_quietly", bob + Vector3(0, 0.4, 0), 5.0, 16.0, 200.0, func() -> void:
		player.model.sit(0.0)
		player.model.hold(null)
		resting.visible = true)


func _fishing_spot() -> void:
	var x := -32.5
	var bank := Terrain.river_z(x) - Terrain.river_half_width(x, true)
	var at := Vector3(x, 0, bank - 0.15)
	var spot := CraftedProps.fishing_spot(self, at, PI, Terrain.RIVER_LEVEL)
	var bob: Vector3 = spot.transform * (spot.get_meta("float") as Vector3)
	var fish := Interactable.create(self, at + Vector3(0.1, 0, -0.55), "Sit and fish", _sit_and_fish.bind(spot, bob), 0.5, 1.2)
	fish.reach = 1.6
	path([Vector3(-21.8, 0, -22.4), Vector3(-25.5, 0, -22.6), Vector3(-29.0, 0, -21.6), Vector3(-31.6, 0, bank - 1.4)], 1.3)
	add_clearing(at + Vector3(0, 0, -0.6), Vector2(3.2, 2.6))
	add_place_zone("fishing_spot", at + Vector3(0, 1, -0.8), Vector3(5, 3, 4))


## Stepping stones across a narrow bend: flat rocks just above the water,
## close enough for small legs, from one bank to the other.
func _ford() -> void:
	var c := Terrain.river_z(FORD_X)
	var south := c + Terrain.river_half_width(FORD_X, false) + 0.3
	var north := c - Terrain.river_half_width(FORD_X, true) - 0.3
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var z := south
	var i := 0
	while z >= north:
		var at := Vector3(FORD_X + (0.18 if i % 2 == 0 else -0.18) + rng.randf_range(-0.08, 0.08), Terrain.RIVER_LEVEL + 0.12, z)
		# On the banks a stone sits on the ground rather than at water level.
		at.y = maxf(at.y, Terrain.height(at.x, at.z) - 0.02)
		CraftedProps.stepping_stone(self, at, 60 + i)
		z -= 0.78
		i += 1
	add_clearing(Vector3(FORD_X, 0, c), Vector2(2.4, south - north + 1.0))


## Reeds gather on the inside of each bend, where the water slows, with a
## lily or two in the calm water beside them.
func _reeds_on_bends() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 47
	var keep_clear := [5.5, FORD_X, 15.2, -21.0, Terrain.FALLS_X]
	var bend := func(x: float) -> float:
		return Terrain.river_z(x + 1.0) - 2.0 * Terrain.river_z(x) + Terrain.river_z(x - 1.0)
	var x := Terrain.FALLS_X + 4.0
	while x < 70.0:
		var k: float = bend.call(x)
		var is_apex := absf(k) > 0.035 and absf(k) >= absf(bend.call(x - 1.0)) and absf(k) >= absf(bend.call(x + 1.0))
		var near_thing := false
		for t: float in keep_clear:
			if absf(x - t) < 3.5:
				near_thing = true
		if is_apex and not near_thing:
			# The river curves toward the side its centre of curvature lies on.
			var inner_south := k > 0.0
			for j in 3:
				var rx := x + (j - 1) * rng.randf_range(0.9, 1.4)
				var c := Terrain.river_z(rx)
				var edge := Terrain.river_half_width(rx, not inner_south) - 0.15
				var rz := c + (edge if inner_south else -edge)
				CraftedProps.reeds(self, Vector3(rx, Terrain.height(rx, rz), rz), int(rx * 13.0) + j, rng.randf_range(0.7, 1.1))
			var lx := x + rng.randf_range(-1.0, 1.0)
			var lc := Terrain.river_z(lx)
			var lily_off := Terrain.river_half_width(lx, not inner_south) - 1.1
			Props.place(self, "waterlily", Vector3(lx, Terrain.RIVER_LEVEL + 0.01, lc + (lily_off if inner_south else -lily_off)), rng.randf() * TAU)
			x += 4.0
		x += 1.0


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
			if absf(z - Terrain.river_z(side_x)) < 7.0:
				continue # the river runs out through here
			Props.place(self, groves[rng.randi() % 4], Vector3(side_x + rng.randf_range(-1, 1), 0, z + rng.randf_range(-1, 1)), rng.randf() * TAU)
		z += 4.0
	# Hills and mountains beyond the edges come from Terrain (see World).


## Roughly the road network, so undergrowth never sits on a path.
static func _on_path(p: Vector3) -> bool:
	var roads := [Rect2(-1, 3.4, 7.5, 2.4), Rect2(4.0, -21, 2.9, 27), Rect2(-22, -23.0, 25, 4.0), Rect2(-32, -23.5, 11, 3.5), Rect2(5, -46, 2, 26),
		Rect2(-30, 0, 30, 11),
		Rect2(14, -25.5, 10, 3.6), Rect2(-12.5, -8, 18, 2.6), Rect2(-21, -11, 9, 4)]
	for r: Rect2 in roads:
		if r.grow(0.8).has_point(Vector2(p.x, p.z)):
			return true
	return false


static func _near_built(p: Vector3) -> bool:
	var areas := [Rect2(-6, -4, 12, 14), Rect2(7, -3, 14, 12), Rect2(-13, -48, 40, 34), Rect2(-30, -35, 17, 16), Rect2(-35, -22, 6, 4.5), Rect2(3.5, -20, 4, 28)]
	for r: Rect2 in areas:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return absf(p.z + 14) < 3.0
