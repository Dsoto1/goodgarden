extends Region
## The village: a market square around a fountain, with stalls, the bakery,
## the workshop and houses around its edge, neighbours about their day, and
## the north road to an overlook where Bellhaven can be seen.

## The market square: an even octagon of cobbles (corner radius, metres).
const SQUARE_RADIUS := 7.4
## Stalls in two tidy rows facing each other across the fountain:
## [position, awning, goods on the counter].
const STALLS := [
	[Vector3(-4.6, 0, -2.3), "awning_blue", ["bread"]],
	[Vector3(-4.6, 0, 2.3), "awning_red", ["crate_carrots", "crate_lettuce"]],
	[Vector3(4.6, 0, -2.3), "awning_green", ["crate_carrots", "crate_open"]],
	[Vector3(4.6, 0, 2.3), "awning_red", ["crate_lettuce", "crate_carrots"]],
]

var _pantry_labels: Node3D # labels on Mrs. Ruth's pantry shelf, once made
var _ruth_window: Node3D # Mrs. Ruth's mended window, once mended
var _broken_window: Node3D # the empty window frame waiting at the workshop
var _shape_boxes: Node3D # the sorted shape boxes on the workbench
var _egg_trays: Node3D # Mrs. Ruth's eggs for sale, from the market week
var _cart: Node3D # the cart packed for Bellhaven, until it goes
var _tables: Node3D # the long table and benches for the Harvest Supper
var _table_pattern: Node3D # the pattern painted along the table's edge
var _place_settings: Node3D
var _feast: Node3D # food on the table, from the pies
var _flags_up: Node3D # the harvest bunting the child made, across the square
var _sam: Node3D # Mrs. Ruth's grandson, come from Bellhaven for the supper

## The long table for the Harvest Supper, north of the fountain.
const LONG_TABLE := Vector3(0, 0, -4.6)

## The workshop's jobs, by the day each is first offered.
const WORKSHOP_JOBS := [[29, "workshop_shapes"], [30, "workshop_window"], [31, "workshop_order"], [32, "workshop_planks"], [33, "workshop_birdhouse"]]
## Mr. Tobias's market-week jobs at the bread stall.
const BREAD_STALL_JOBS := [[37, "market_scales"], [39, "market_count_coins"], [40, "market_stall_day"]]
var _stall_labels: Node3D # the labels the child made for Tobias's stall
var _baking: Node3D # the fire and fresh loaves, on baking day
## Villagers by id: [wanderer, home position, home radius, current anchor id].
var _villagers := {}


func build() -> void:
	# The market square: an even octagon of cobbles with the fountain at its
	# heart, stalls in two rows facing each other across it, and the south side
	# open to the road from the bridge.
	var square := square_outline()
	_square(square)
	_fountain(Vector3(0, 0, 0))
	SoundSpot.looping(self, "fountain", Vector3(0, 1.0, 0), 13.0, -6.0)
	SoundSpot.calling(self, "hens", Vector3(14.3, 0.4, 9.8), 18.0, Vector2(9, 20), -8.0)
	Props.place(self, "well", Vector3(6.4, 0, 6.0), -0.6, 0.85)
	for i in STALLS.size():
		var at: Vector3 = STALLS[i][0]
		var side := signf(at.x)
		# West stalls face east, east stalls face west: both toward the fountain.
		_stall(at, -side * PI / 2.0, STALLS[i][1], STALLS[i][2])
		# Spare stock stacked neatly behind each stall, on the cobbles.
		Props.place(self, ["barrel", "crate", "barrel", "crate"][i], at + Vector3(side * 1.05, 0, -0.45), 0.0)
		Props.place(self, "sack", at + Vector3(side * 1.05, 0, 0.45), side * 0.3)
		# Where a neighbour stands to mind the stall, at its fountain side.
		if i == 3:
			add_anchor("egg_stall_ruth", at + Vector3(0.6, 0, 1.7), PI / 2.0) # behind her egg table
		else:
			add_anchor(["bread_stall_tobias", "veg_stall", "market_miriam"][i], at + Vector3(-side * 1.2, 0, 1.3 * (1 if at.z > 0 else -1)), side * PI / 2.0)
	_market_week()
	# Benches sit along the square's outer edge, each turned to face the
	# fountain: either side of the road in from the bridge, on the south-east
	# side, and by the north road. The middle of the square stays open.
	var inset := SQUARE_RADIUS * cos(PI / 8.0) - 0.6
	for b: Array in [[2.3, 90.0], [-1.5, 90.0], [0.0, 45.0], [2.2, -90.0]]:
		var a := deg_to_rad(b[1])
		var along := Vector2(-sin(a), cos(a)) * float(b[0])
		var at := Vector2(cos(a), sin(a)) * inset + along
		_bench(Vector3(at.x, 0, at.y), atan2(cos(a), sin(a)))
	# A lantern at every other corner.
	for k in [1, 3, 5, 7]:
		var corner: Vector2 = square[k]
		_lantern(Vector3(corner.x, 0, corner.y) * 0.92)

	_building("market", Vector3(-7.5, 0, -12.5), 0.0, "Bakery", 3.2)
	# Tobias's work outside the bakery: the kneading trough, and the
	# neighbours' bread baskets waiting on a plank table.
	CraftedProps.kneading_trough(self, Vector3(-9.6, 0, -9.4), 0.0)
	# The domed bread oven stands beside the bakery, with wood stacked for the fire.
	Props.place(self, "bread_oven", Vector3(-3.5, 0, -12.2), -0.25)
	_baking_day(Vector3(-3.5, 0, -12.2))
	CraftedProps.woodpile(self, Vector3(-1.9, 0, -12.9), PI / 2.0 - 0.25)
	var table := Vector3(-4.7, 0, -9.7)
	add_activity_focus(table + Vector3(0, 0.7, 0))
	MeshKit.box(self, Vector3(1.9, 0.06, 0.6), table + Vector3(0, 0.62, 0), "wood", false, -0.2)
	for x: float in [-0.75, 0.75]:
		MeshKit.box(self, Vector3(0.08, 0.6, 0.5), table + Vector3(0, 0.3, 0) + Vector3(x, 0, 0).rotated(Vector3.UP, -0.2), "wood_dark", false, -0.2)
	MeshKit.solid(self, Vector3(1.9, 0.7, 0.6), table + Vector3(0, 0.35, 0), -0.2)
	for i in 3:
		CraftedProps.bread_basket(self, table + Vector3(0, 0.65, 0) + Vector3(-0.62 + i * 0.62, 0, 0).rotated(Vector3.UP, -0.2), i * 0.9).scale = Vector3.ONE * 0.62
	# Buildings stand back from the square, so there is a little stroll to each door.
	_building("workshop", Vector3(8.0, 0, -13.0), 0.0, "Workshop", 3.6)
	# Houses close round the square at easy angles, as in a village that grew.
	_building("house_yellow", Vector3(-12.4, 0, -0.3), PI / 2.0 - 0.1, "")
	_building("house_blue", Vector3(13.0, 0, -0.8), -PI / 2.0 + 0.08, "")
	_building("house_tall_red", Vector3(-13.4, 0, -10.6), PI / 4.0 + 0.1, "")
	_building("house_yellow", Vector3(13.8, 0, -10.6), -PI / 4.0, "")
	# Two cottages: one by the lane to the sheepfold, one by the river path.
	var east_cottage := CraftedProps.cottage(self, Vector3(11.6, 0, 6.8), -PI / 2.0 - 0.12, 2, Vector2(3.4, 4.0), "roof_red")
	add_clearing(east_cottage.position, Vector2(5.2, 5.2))
	# North of the river path to the Chapel (which runs at about z 7 here), so
	# the path stays open.
	var west_cottage := CraftedProps.cottage(self, Vector3(-14.0, 0, 4.2), PI / 2.0 + 0.08, 5, Vector2(3.2, 3.2), "roof_thatch")
	add_clearing(west_cottage.position, Vector2(4.6, 4.6))
	_bunting(Vector3(-3.0, 3.7, -9.4), Vector3(4.2, 3.7, -9.8))
	for p: Array in [[-9.4, 3.4], [9.0, -4.6], [-10.6, -4.4], [9.6, -7.4]]:
		_planter(Vector3(p[0], 0, p[1]))
	Props.place(self, "lumber", Vector3(12.0, 0, -5.4), 0.4, 0.8)
	Props.place(self, "wheelbarrow", Vector3(13.0, 0, -6.2), 2.2)
	Props.place(self, "bucket", Vector3(5.6, 0, 6.8))
	Props.place(self, "tree_a", Vector3(-17.2, 0, 2.6), 0.5)
	Props.place(self, "tree_b", Vector3(16.4, 0, 9.4), 1.2)
	_village_life()
	for f: Array in [[-7.4, 8.4, "flowers_a"], [8.4, 9.0, "flowers_b"], [-3.2, 8.9, "bush_flowers"], [3.4, 9.0, "flowers_a"]]:
		Props.place(self, f[2], Vector3(f[0], 0, f[1]), f[0])

	# Short paths from the square to every door.
	for door: Array in [
		[Vector3(-4.9, 0, -6.0), Vector3(-6.4, 0, -8.2), Vector3(-7.4, 0, -10.3)], # bakery
		[Vector3(5.0, 0, -6.4), Vector3(6.8, 0, -8.2), Vector3(8.0, 0, -10.1)], # workshop
		[Vector3(-7.6, 0, -0.2), Vector3(-9.0, 0, -0.5), Vector3(-10.4, 0, -0.4)], # yellow house
		[Vector3(7.4, 0, -0.6), Vector3(9.4, 0, -0.9), Vector3(11.1, 0, -0.8)], # blue house
		[Vector3(-7.4, 0, -3.4), Vector3(-9.4, 0, -5.8), Vector3(-11.0, 0, -7.8), Vector3(-11.8, 0, -9.0)], # tall red house
		[Vector3(7.2, 0, -3.4), Vector3(9.4, 0, -5.8), Vector3(11.4, 0, -7.8), Vector3(12.4, 0, -9.2)], # corner house
		[Vector3(6.6, 0, 4.0), Vector3(8.2, 0, 5.8), Vector3(9.4, 0, 6.6)], # east cottage
		[Vector3(-5.6, 0, 5.6), Vector3(-9.0, 0, 5.0), Vector3(-11.8, 0, 4.8)], # west cottage
	]:
		path(door, 1.3)

	# North road between the bakery and workshop to the overlook.
	path([Vector3(0.2, 0, -6.6), Vector3(0.3, 0, -10.5), Vector3(-0.2, 0, -13.0), Vector3(0, 0, -15.2)], 2.0, "cobble")
	MeshKit.box(self, Vector3(12, 0.7, 0.6), Vector3(0, 0.35, -17.2), "stone", true)
	add_clearing(Vector3(0, 0, -15.6), Vector2(8, 2.6))
	MeshKit.box(self, Vector3(1.6, 0.45, 0.5), Vector3(-2.5, 0.22, -15.8), "wood", true)
	var sign_post := MeshKit.box(self, Vector3(0.12, 1.8, 0.12), Vector3(2.0, 0.9, -14.2), "wood")
	sign_post.name = "SignPost"
	MeshKit.box(self, Vector3(1.4, 0.4, 0.08), Vector3(2.5, 1.55, -14.2), "wood_light")
	var label := Label3D.new()
	label.text = tr("To Bellhaven")
	label.font_size = 48
	label.pixel_size = 0.005
	label.modulate = Color("3b3430")
	label.outline_size = 0
	label.position = Vector3(2.5, 1.55, -14.14)
	add_child(label)
	add_camera_zone(Vector3(0, 1, -14.5), Vector3(11, 3, 4.5), {"pitch": 9.0, "distance": 7.0, "height": 1.8, "fov": 52.0})
	add_anchor("village_overlook", Vector3(0, 0, -14.5), 0.0)

	_villager("tobias", World.look_for("tobias"), Vector3(-8.4, 0, -8.2), 1.2)
	_villager("ruth", World.look_for("ruth"), Vector3(7.0, 0, 5.2), 0.8)
	_villager("amos", World.look_for("amos"), Vector3(10.0, 0, -8.6), 0.8)
	_harvest_square()
	_workshop_yard(Vector3(10.8, 0, -9.9))
	_pantry_shelf(Vector3(8.7, 0, 4.3))
	# Neighbours going about their day (ambient, no conversation yet).
	var folk: Array = Content.get_world("characters").get("villagers", [])
	var spots := [Vector3(-3.6, 0, 5.6), Vector3(3.8, 0, -5.2), Vector3(-3.4, 0, -5.8), Vector3(1.6, 0, 6.2), Vector3(7.2, 0, 0.8)]
	for i in folk.size():
		var w := Wanderer.new().setup(CharacterModel.new().build(folk[i]), 300 + i)
		w.position = spots[i % spots.size()]
		w.radius = 3.0
		w.speed = 0.55
		w.pause_range = Vector2(2, 6)
		add_child(w)
		MeshKit.solid(w, Vector3(0.5, 1.6, 0.5), Vector3(0, 0.8, 0), 0.0, MeshKit.LAYER_CHARACTER)
	for i in 4:
		var bird := Wanderer.new().setup(AnimalModel.make("bird"), 60 + i)
		bird.gait = "hop"
		bird.speed = 0.6
		bird.radius = 3.0
		bird.position = Vector3(-3 + i * 2.0, 0, 2.4 - (i % 2) * 4.8)
		add_child(bird)

	add_anchor("village_plaza", Vector3(0, 0, 7.0), 0.0)
	add_discovery_zone(Vector3(0, 1, -3), Vector3(36, 3, 28))


## Cobbles laid in the square's outline, edged with a kerb of larger stones.
## The square's corners, an even octagon with flat sides facing the four roads.
static func square_outline() -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for k in 8:
		var a := PI / 8.0 + k * PI / 4.0
		pts.append(Vector2(cos(a), sin(a)) * SQUARE_RADIUS)
	return pts


func _square(outline: Array[Vector2]) -> void:
	var pts := PackedVector2Array(outline)
	var tris := Geometry2D.triangulate_polygon(pts)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in tris.size():
		var q := pts[tris[i]]
		st.set_uv(q / 4.0)
		# Above the paths (laid at 0.03) that run into it, so where they meet the
		# square covers them instead of flickering against them.
		st.add_vertex(Vector3(q.x, 0.055, q.y))
	MeshKit._instance(self, st.commit(), Vector3.ZERO, "cobble")
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var n := int(a.distance_to(b) / 0.5)
		for k in n:
			var q := a.lerp(b, (k + 0.5) / n)
			MeshKit.box(self, Vector3(0.46, 0.08, 0.3), Vector3(q.x, 0.04, q.y), "stone", false, atan2(b.x - a.x, b.y - a.y) + PI / 2.0)
	var box := Rect2(pts[0], Vector2.ZERO)
	for q in pts:
		box = box.expand(q)
	add_clearing(Vector3(box.get_center().x, 0, box.get_center().y), box.size)


## The small things that make it lived in, as in the concept art: a washing
## line and hens behind the east cottage, a cat by the fountain, barrels and
## pots by the doors, a hand cart, and low stone walls along the road in.
func _village_life() -> void:
	CraftedProps.clothesline(self, Vector3(14.6, 0, 4.8), Vector3(14.6, 0, 8.6))
	for i in 3:
		var hen := Wanderer.new().setup(AnimalModel.make("chicken"), 70 + i)
		hen.gait = "hop"
		hen.speed = 0.35
		hen.radius = 1.4
		hen.position = Vector3(14.0 + i * 0.5, 0, 10.0 - i * 0.4)
		add_child(hen)
	var cat := Wanderer.new().setup(AnimalModel.make("cat"), 77)
	cat.speed = 0.3
	cat.radius = 2.0
	cat.pause_range = Vector2(6, 14)
	cat.position = Vector3(2.4, 0, -4.4)
	add_child(cat)
	AnimalMoments.pettable(cat, "Pet the cat", ["The cat purrs and rubs against your hand.", "Purr, purr. The cat stays to be petted."], "purr")
	# The village dog, a friendly pug who potters about the square.
	var dog := Wanderer.new().setup(AnimalModel.make("dog"), 78)
	dog.speed = 0.5
	dog.radius = 2.4
	dog.pause_range = Vector2(3, 8)
	dog.position = Vector3(-1.0, 0, 5.6)
	add_child(dog)
	AnimalMoments.pettable(dog, "Pet the dog", ["The little dog wags its tail and hops about.", "The dog sits for a pat, then hops with joy."], "dog", -10.0)
	for b: Array in [[Vector3(-10.6, 0, 1.8), "barrel"], [Vector3(11.4, 0, 1.6), "barrel"], [Vector3(9.9, 0, 5.4), "crate"], [Vector3(-16.0, 0, 2.2), "barrel"]]:
		Props.place(self, b[1], b[0], b[0].x)
	for f: Array in [[Vector3(9.8, 0, 7.9), "flower_pink"], [Vector3(-12.1, 0, 2.5), "flower_yellow"], [Vector3(-10.2, 0, -1.6), "flower_white"]]:
		CraftedProps.flower_pot(self, f[0], f[1])
	CraftedProps.hand_cart(self, Vector3(8.8, 0, -8.6), 0.6)
	# Low dry-stone walls either side of the road up from the bridge.
	CraftedProps.stone_wall(self, Vector3(-2.6, 0, 8.0), Vector3(-2.9, 0, 10.6), 1)
	CraftedProps.stone_wall(self, Vector3(2.0, 0, 8.2), Vector3(2.4, 0, 10.8), 2)


func _bench(at: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = yaw
	add_child(root)
	MeshKit.box(root, Vector3(1.6, 0.08, 0.45), Vector3(0, 0.45, 0), "wood", false)
	MeshKit.box(root, Vector3(1.6, 0.4, 0.07), Vector3(0, 0.7, 0.2), "wood", false)
	for x: float in [-0.65, 0.65]:
		MeshKit.box(root, Vector3(0.08, 0.45, 0.4), Vector3(x, 0.22, 0), "wood_dark")
	MeshKit.solid(root, Vector3(1.6, 0.9, 0.5), Vector3(0, 0.45, 0.05))


## A KayKit building with an optional painted sign over its front.
func _building(prop: String, at: Vector3, rot: float, sign_text: String, sign_height := 3.0) -> void:
	var b := Props.place(self, prop, at, rot)
	var box := Props.bounds(b)
	var span := maxf(box.size.x, box.size.z) + 0.6
	add_clearing(at, Vector2(span, span))
	if sign_text.is_empty():
		return
	var front := Props.bounds(b).end.z + 0.08
	var board := MeshKit.box(b, Vector3(1.9, 0.45, 0.05), Vector3(0, sign_height, front), "wood_light")
	board.name = "SignBoard"
	var l := Label3D.new()
	l.text = tr(sign_text)
	l.font_size = 56
	l.pixel_size = 0.006
	l.modulate = Color("3b3430")
	l.position = Vector3(0, sign_height, front + 0.04)
	b.add_child(l)


## Tiered stone fountain, the heart of the plaza.
func _fountain(at: Vector3) -> void:
	MeshKit.cylinder(self, 1.7, 1.8, 0.55, at + Vector3(0, 0.27, 0), "stone", 16, true)
	# Water surfaces sit a little above the stone they rest in (basin top 0.545,
	# bowl top 1.73), never level with or inside it.
	var pool := MeshKit.cylinder(self, 1.5, 1.5, 0.03, at + Vector3(0, 0.565, 0), "water", 16)
	pool.material_override = Palette.mat("water")
	MeshKit.cylinder(self, 0.25, 0.32, 1.3, at + Vector3(0, 1.0, 0), "stone", 10)
	MeshKit.cylinder(self, 0.75, 0.5, 0.22, at + Vector3(0, 1.62, 0), "stone", 12)
	MeshKit.cylinder(self, 0.65, 0.65, 0.03, at + Vector3(0, 1.75, 0), "water", 12)
	MeshKit.cylinder(self, 0.1, 0.14, 0.6, at + Vector3(0, 1.98, 0), "stone", 8)
	MeshKit.sphere(self, 0.16, at + Vector3(0, 2.36, 0), "stone", Vector3.ONE, 8, 4)
	var spray := GPUParticles3D.new()
	spray.amount = 40
	spray.lifetime = 0.9
	spray.position = at + Vector3(0, 2.4, 0)
	spray.emitting = not Settings.get_value("reduced_motion")
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 35.0
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 1.6
	pm.gravity = Vector3(0, -6, 0)
	spray.process_material = pm
	var drop := SphereMesh.new()
	drop.radius = 0.035
	drop.height = 0.07
	drop.radial_segments = 6
	drop.rings = 3
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.85, 0.94, 1.0, 0.8)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = dm
	spray.draw_pass_1 = drop
	spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(spray)


## Market stall: counter, produce, and a striped awning.
func _stall(at: Vector3, rot: float, awning: String, goods: Array) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = rot
	add_child(root)
	MeshKit.box(root, Vector3(1.8, 0.8, 0.7), Vector3(0, 0.4, 0), "wood", true)
	for x: float in [-0.85, 0.85]:
		MeshKit.box(root, Vector3(0.08, 2.2, 0.08), Vector3(x, 1.1, -0.35), "wood_dark")
		MeshKit.box(root, Vector3(0.08, 1.8, 0.08), Vector3(x, 0.9, 0.55), "wood_dark")
	var canopy := MeshKit.box(root, Vector3(2.1, 0.06, 1.3), Vector3(0, 2.0, 0.1), awning)
	canopy.rotation.x = -0.32
	MeshKit.box(root, Vector3(2.1, 0.22, 0.04), Vector3(0, 1.72, 0.72), awning)
	if goods == ["bread"]:
		CraftedProps.bread_stall_goods(root, Vector3(0, 0.8, 0.05)) # Tobias's bread
		_stall_labels = Node3D.new()
		_stall_labels.name = "StallLabels"
		root.add_child(_stall_labels)
		# From Thursday of the first week the child can label what's on it.
		var label := Interactable.create(root, Vector3(0, 0, 1.2), "Label the market stall", func() -> void:
			get_tree().call_group("main", "start_activity_here", "market_labels", root.global_position + Vector3(0, 1.0, 0)), 0.7, 1.6)
		label.conditions = [{"day_at_least": 4}, {"fact": "village.stall_labels", "exists": false}]
		# From the second week the child can shop here, counting out coins.
		var shop := Interactable.create(root, Vector3(0.7, 0, 1.2), "Buy food for supper", func() -> void:
			get_tree().call_group("main", "start_activity_here", "market_buy", root.global_position + Vector3(0, 1.0, 0)), 0.7, 1.6)
		shop.conditions = [{"day_at_least": 8}, {"not": {"fact": "home.bought_day", "is_today": true}}]
		# In the market week Mr. Tobias has work here: weighing, counting, minding.
		var help := Interactable.create(root, Vector3(-0.7, 0, 1.2), "Help at the bread stall", func() -> void:
			_start_job(BREAD_STALL_JOBS, root.global_position + Vector3(0, 1.0, 0), tr("Mr. Tobias has everything in hand today.")), 0.7, 1.6)
		help.conditions = [{"day_at_least": 37}]
		return
	for i in goods.size():
		Props.place(root, goods[i], Vector3(-0.45 + i * 0.9, 0.8, 0.05), 0.0, 0.75)


## Little card labels hung on the front of Tobias's stall, one under each
## thing the child labelled ("bun", "jam", ...).
func _sync_stall_labels() -> void:
	if _stall_labels == null:
		return
	var made: Variant = WorldState.get_fact("village.stall_labels", [])
	var spots := {"bun": -0.58, "jam": -0.2, "egg": 0.2, "nut": 0.55}
	for word: String in spots:
		var have := _stall_labels.get_node_or_null("Label_" + word)
		var want: bool = made is Array and word in made
		if want and have == null:
			var tag := Node3D.new()
			tag.name = "Label_" + word
			tag.position = Vector3(spots[word], 0.66, 0.37)
			_stall_labels.add_child(tag)
			MeshKit.box(tag, Vector3(0.32, 0.13, 0.01), Vector3.ZERO, "cloth_cream")
			var text := Label3D.new()
			text.text = word
			text.font = UiStyle.font()
			text.font_size = 64
			text.pixel_size = 0.0026
			text.modulate = Color("3b3430")
			text.outline_size = 0
			text.position = Vector3(0, 0, 0.008)
			tag.add_child(text)
		elif not want and have:
			have.free()


func _lantern(at: Vector3) -> void:
	MeshKit.box(self, Vector3(0.1, 2.4, 0.1), at + Vector3(0, 1.2, 0), "wood_dark")
	MeshKit.box(self, Vector3(0.4, 0.06, 0.06), at + Vector3(0.15, 2.35, 0), "wood_dark")
	MeshKit.box(self, Vector3(0.2, 0.28, 0.2), at + Vector3(0.3, 2.12, 0), "lantern")
	MeshKit.box(self, Vector3(0.24, 0.04, 0.24), at + Vector3(0.3, 2.28, 0), "dark")


## A string of little coloured flags between two points.
func _bunting(a: Vector3, b: Vector3) -> void:
	var span := b - a
	var count := int(span.length() / 0.45)
	var colors := ["awning_red", "flower_yellow", "awning_blue", "cloth_cream", "awning_green"]
	var yaw := atan2(span.x, span.z)
	MeshKit.box(self, Vector3(0.02, 0.02, span.length()), a + span * 0.5 + Vector3(0, -0.18, 0), "wood_dark", false, yaw)
	for i in count:
		var t := (i + 0.5) / count
		var sag := sin(t * PI) * 0.35
		var flag := MeshKit.roof(self, 0.3, 0.32, 0.02, a + span * t + Vector3(0, -sag - 0.34, 0), colors[i % colors.size()], yaw + PI / 2.0)
		flag.rotation.z = PI


func _planter(at: Vector3) -> void:
	MeshKit.box(self, Vector3(1.0, 0.45, 0.5), at + Vector3(0, 0.22, 0), "wood")
	MeshKit.box(self, Vector3(0.9, 0.05, 0.42), at + Vector3(0, 0.44, 0), "soil")
	Props.place(self, "flowers_a", at + Vector3(-0.22, 0.44, 0), 0.4, 0.55)
	Props.place(self, "flowers_b", at + Vector3(0.24, 0.44, 0), 1.3, 0.5)


func _villager(id: String, look: Dictionary, at: Vector3, wander_radius: float) -> void:
	var w := Wanderer.new().setup(CharacterModel.new().build(look), id.hash())
	w.name = id.capitalize()
	w.position = at
	w.radius = wander_radius
	w.speed = 0.6
	w.pause_range = Vector2(3, 7)
	w.talk_dialogue_id = id
	add_child(w)
	_villagers[id] = [w, at, wander_radius, ""]
	MeshKit.solid(w, Vector3(0.5, 1.6, 0.5), Vector3(0, 0.8, 0), 0.0, MeshKit.LAYER_CHARACTER)
	var talk := Interactable.create(w, Vector3.ZERO, "Talk to %s" % Dialogue.character_name(id), func() -> void: Dialogue.start(id), 0.7, 1.95 * float(look.get("height", 1.0)))
	talk.reach = 2.2


func sync_with_world() -> void:
	_sync_stall_labels()
	if _pantry_labels:
		_pantry_labels.visible = WorldState.has_fact("village.pantry_labels")
	if _tables:
		_sync_harvest()
	if _ruth_window:
		_ruth_window.visible = WorldState.has_fact("workshop.window")
		_broken_window.visible = Days.current_day >= 30 and not WorldState.has_fact("workshop.window")
		_shape_boxes.visible = WorldState.has_fact("workshop.shapes_day")
		_egg_trays.visible = Days.current_day >= 36
	# On some days a neighbour waits somewhere else (Mrs. Ruth at the
	# sheepfold, Mr. Tobias at the mill), as the day's "npcs" anchors say.
	for id: String in _villagers:
		var v: Array = _villagers[id]
		var anchor_id := Days.npc_anchor(id)
		if anchor_id == v[3]:
			continue
		var w: Wanderer = v[0]
		var a := _find_anchor(anchor_id)
		if a == null and not anchor_id.is_empty():
			continue # that place isn't built yet; try again on the next sync
		v[3] = anchor_id
		if a:
			w.relocate(a.global_position, 0.4, a.global_rotation.y)
		else:
			w.relocate(to_global(v[1]), v[2])
	if _baking:
		var baked: Variant = WorldState.get_fact("village.baked_day")
		_baking.visible = baked != null and int(baked) == Days.current_day


## Mrs. Ruth's pantry shelf by her cottage door: a pot, a pan, a cup and a
## lid. From the third week the child makes labels for it; once made, little
## cream labels hang along the shelf's edge.
func _pantry_shelf(at: Vector3) -> void:
	var r := Node3D.new()
	r.name = "PantryShelf"
	r.position = at
	r.rotation.y = -0.6
	add_child(r)
	for x: float in [-0.55, 0.55]:
		MeshKit.box(r, Vector3(0.08, 1.4, 0.36), Vector3(x, 0.7, 0), "wood_dark")
	for y: float in [0.45, 0.95, 1.38]:
		MeshKit.box(r, Vector3(1.18, 0.05, 0.38), Vector3(0, y, 0), "wood")
	MeshKit.solid(r, Vector3(1.2, 1.4, 0.4), Vector3(0, 0.7, 0))
	MeshKit.cylinder(r, 0.13, 0.11, 0.2, Vector3(-0.3, 0.58, 0), "stone_dark", 10)
	MeshKit.cylinder(r, 0.14, 0.14, 0.04, Vector3(0.28, 0.5, 0), "stone_dark", 10)
	MeshKit.cylinder(r, 0.05, 0.04, 0.1, Vector3(-0.28, 1.03, 0), "cloth_cream", 8)
	MeshKit.cylinder(r, 0.12, 0.12, 0.02, Vector3(0.28, 0.99, 0), "stone_dark", 10)
	_pantry_labels = Node3D.new()
	_pantry_labels.name = "PantryLabels"
	StaticBatch.mark_live(_pantry_labels)
	r.add_child(_pantry_labels)
	for k in 4:
		MeshKit.box(_pantry_labels, Vector3(0.16, 0.07, 0.01), Vector3(-0.3 + (k % 2) * 0.58, 0.4 + (k / 2) * 0.5, 0.2), "cloth_cream")
	var use := Interactable.create(r, Vector3(0, 0, 0.8), "Help Mrs. Ruth label her pantry", func() -> void:
		get_tree().call_group("main", "start_activity_here", "village_pantry", r.global_position + Vector3(0, 0.9, 0)), 0.7, 1.7)
	use.conditions = [{"day_at_least": 17}, {"fact": "village.pantry_labels", "exists": false}]


## Mr. Amos's yard beside the workshop: a workbench where the child helps
## with the week's jobs, an empty window frame waiting for its panes, and,
## once sorted, little boxes of wooden shapes.
func _workshop_yard(at: Vector3) -> void:
	MeshKit.box(self, Vector3(1.8, 0.08, 0.7), at + Vector3(0, 0.8, 0), "wood_light")
	for x: float in [-0.8, 0.8]:
		for z: float in [-0.28, 0.28]:
			MeshKit.box(self, Vector3(0.08, 0.8, 0.08), at + Vector3(x, 0.4, z), "wood_dark")
	MeshKit.solid(self, Vector3(1.8, 0.9, 0.7), at + Vector3(0, 0.45, 0))
	# Tools on the bench: a saw and a mallet.
	MeshKit.box(self, Vector3(0.5, 0.01, 0.12), at + Vector3(-0.45, 0.85, 0.1), "stone_dark").rotation.y = 0.3
	MeshKit.box(self, Vector3(0.12, 0.03, 0.2), at + Vector3(-0.1, 0.85, 0.15), "wood_dark").rotation.y = 0.3
	MeshKit.cylinder(self, 0.06, 0.06, 0.16, at + Vector3(0.5, 0.92, -0.12), "wood", 8).rotation.z = PI / 2.0
	CraftedProps.woodpile(self, at + Vector3(1.6, 0, -0.6), 0.2)
	_shape_boxes = group_node("ShapeBoxes")
	for k in 3:
		var colour: String = ["cloth_blue", "cloth_red", "cloth_gold"][k]
		MeshKit.box(_shape_boxes, Vector3(0.22, 0.1, 0.18), at + Vector3(0.1 + k * 0.26, 0.89, 0.15), "wood")
		MeshKit.box(_shape_boxes, Vector3(0.16, 0.04, 0.12), at + Vector3(0.1 + k * 0.26, 0.95, 0.15), colour)
	_broken_window = group_node("BrokenWindow")
	var frame := at + Vector3(-1.4, 0, 0.3)
	for side: float in [-0.4, 0.4]:
		MeshKit.box(_broken_window, Vector3(0.08, 1.0, 0.06), frame + Vector3(side, 0.55, 0), "wood")
	for y: float in [0.06, 1.04]:
		MeshKit.box(_broken_window, Vector3(0.88, 0.08, 0.06), frame + Vector3(0, y, 0), "wood")
	var work := Interactable.create(self, at + Vector3(0, 0, 0.9), "Work with Mr. Amos", func() -> void:
		_start_job(WORKSHOP_JOBS, position + at + Vector3(0, 0.9, 0), tr("The workbench is tidy. Mr. Amos has no job for you just now.")), 0.7, 1.4)
	work.conditions = [{"day_at_least": 29}]
	add_activity_focus(at + Vector3(0, 0.9, 0))
	add_clearing(at, Vector2(4.0, 2.4))
	# Mrs. Ruth's mended window, its coloured panes in a new frame, by her door.
	_ruth_window = group_node("RuthWindow")
	# Leaning against the wall by the pantry shelf, waiting to be fitted.
	var win := Vector3(9.75, 0, 3.75)
	var leaning := Node3D.new()
	leaning.position = win
	leaning.rotation = Vector3(-0.22, -0.6, 0)
	_ruth_window.add_child(leaning)
	MeshKit.box(leaning, Vector3(0.9, 1.0, 0.06), Vector3(0, 0.5, 0), "wood")
	for k in 6:
		var pane: String = ["cloth_blue", "cloth_gold", "cloth_red", "cloth_green", "cloth_blue", "cloth_gold"][k]
		MeshKit.box(leaning, Vector3(0.24, 0.26, 0.02), Vector3(-0.28 + (k % 3) * 0.28, 0.35 + (k / 3) * 0.3, 0.035), pane)


## Weeks 7-12 in the village: the cart packed for Bellhaven on the north
## road, then the Harvest Supper taking shape in the square: the long table
## and benches the child helped build, their painted edge, the bunting, the
## place settings, the food, and finally everyone together.
func _harvest_square() -> void:
	_cart = group_node("BellhavenCart")
	var cart := CraftedProps.hand_cart(_cart, Vector3(1.4, 0, -13.4), 0.2)
	for k in 5:
		MeshKit.box(cart, Vector3(0.3, 0.22, 0.3), Vector3(-0.3 + (k % 3) * 0.3, 0.7, -0.3 + (k / 3) * 0.5), "cloth_tan" if k % 2 == 0 else "wood_light")
	_tables = group_node("SupperTables")
	var t := LONG_TABLE
	MeshKit.box(_tables, Vector3(5.0, 0.08, 1.0), t + Vector3(0, 0.76, 0), "wood_light")
	for x: float in [-2.3, 0.0, 2.3]:
		for z: float in [-0.4, 0.4]:
			MeshKit.box(_tables, Vector3(0.08, 0.76, 0.08), t + Vector3(x, 0.38, z), "wood_dark")
	for z: float in [-0.95, 0.95]:
		MeshKit.box(_tables, Vector3(4.8, 0.06, 0.34), t + Vector3(0, 0.45, z), "wood")
		for x: float in [-2.1, 2.1]:
			MeshKit.box(_tables, Vector3(0.08, 0.45, 0.28), t + Vector3(x, 0.22, z), "wood_dark")
	MeshKit.solid(_tables, Vector3(5.0, 0.9, 2.3), t + Vector3(0, 0.45, 0))
	_table_pattern = group_node("TablePattern")
	_place_settings = group_node("PlaceSettings")
	for k in 8:
		var x := -2.0 + (k % 4) * 1.33
		var z := -0.3 if k < 4 else 0.3
		MeshKit.cylinder(_place_settings, 0.15, 0.15, 0.02, t + Vector3(x, 0.81, z), "cloth_cream", 12)
		MeshKit.cylinder(_place_settings, 0.04, 0.035, 0.1, t + Vector3(x + 0.22, 0.85, z), "cloth_blue", 8)
	_feast = group_node("Feast")
	for k in 3:
		var at := t + Vector3(-1.6 + k * 1.6, 0.8, 0)
		MeshKit.cylinder(_feast, 0.2, 0.16, 0.08, at + Vector3(0, 0.04, 0), "wood_light", 10)
		MeshKit.sphere(_feast, 0.16, at + Vector3(0, 0.1, 0), ["cloth_gold", "leaf", "cloth_red"][k], Vector3(1, 0.5, 1), 8, 3)
	for k in 2:
		MeshKit.sphere(_feast, 0.14, t + Vector3(-0.8 + k * 1.6, 0.86, 0.05), "cloth_gold", Vector3(1.4, 0.7, 1), 8, 3)
	_flags_up = group_node("Bunting")
	var poles := [Vector3(-5.4, 0, -5.4), Vector3(5.4, 0, 5.4), Vector3(5.4, 0, -5.4), Vector3(-5.4, 0, 5.4)]
	for p: Vector3 in poles:
		MeshKit.cylinder(_flags_up, 0.05, 0.06, 3.6, p + Vector3(0, 1.8, 0), "wood_dark", 6)
	for pair: Array in [[0, 1], [2, 3]]:
		var a: Vector3 = poles[pair[0]] + Vector3(0, 3.5, 0)
		var b: Vector3 = poles[pair[1]] + Vector3(0, 3.5, 0)
		for k in 22:
			var f := (k + 0.5) / 22.0
			var at := a.lerp(b, f) - Vector3(0, sin(f * PI) * 0.9, 0)
			var flag := MeshKit.box(_flags_up, Vector3(0.22, 0.26, 0.01), at - Vector3(0, 0.14, 0), "cloth_red")
			flag.rotation.y = atan2(b.x - a.x, b.z - a.z) + PI / 2.0
			flag.set_meta(&"index", k)
	_sam = group_node("Sam")
	var sam := CharacterModel.new().build({"skin": "skin_3", "hair": "hair_black", "hair_style": "short", "shirt": "cloth_green", "pants": "cloth_brown", "height": 0.98})
	sam.position = t + Vector3(0, 0, 1.45)
	_sam.add_child(sam)
	for id: String in ["miriam", "ruth", "tobias", "amos"]:
		var i := ["miriam", "ruth", "tobias", "amos"].find(id)
		var side := 1.0 if i < 2 else -1.0
		add_anchor("supper_" + id, t + Vector3(-1.5 + (i % 2) * 3.0, 0, side * 1.45), 0.0 if side > 0 else PI)


func _sync_harvest() -> void:
	_cart.visible = WorldState.has_fact("community.cart_packed") and not WorldState.has_fact("community.cart_sent")
	_tables.visible = WorldState.has_fact("project.tables")
	_place_settings.visible = WorldState.has_fact("harvest.table_set")
	_feast.visible = WorldState.has_fact("harvest.pies")
	_sam.visible = WorldState.has_fact("harvest.invitations") and Days.current_day >= 82
	var flags: Variant = WorldState.get_fact("harvest.bunting")
	_flags_up.visible = flags is Array
	if flags is Array and not (flags as Array).is_empty():
		var colours := {"flag_red": "cloth_red", "flag_yellow": "cloth_gold", "flag_blue": "cloth_blue", "flag_green": "cloth_green"}
		for c in _flags_up.get_children():
			if c.has_meta(&"index"):
				var m := c as MeshInstance3D
				m.material_override = Palette.mat(str(colours.get(str(flags[int(c.get_meta(&"index")) % flags.size()]), "cloth_red")))
	# The pattern the child painted, in little squares along the table's edge.
	var painted: Variant = WorldState.get_fact("project.painted")
	if painted is Array and _table_pattern.get_child_count() == 0 and not (painted as Array).is_empty():
		var shades := {"shape_circle": "cloth_gold", "shape_square": "cloth_blue", "shape_triangle": "cloth_red"}
		for k in 16:
			MeshKit.box(_table_pattern, Vector3(0.16, 0.06, 0.01), LONG_TABLE + Vector3(-2.3 + k * 0.307, 0.74, 0.51), str(shades.get(str(painted[k % painted.size()]), "cloth_red")))
	_table_pattern.visible = _tables.visible


## Today's job from a neighbour's list ([[first day, activity], ...]): the
## day's own job if it is one of them, or else the latest one offered so
## far that can be done again.
func _start_job(jobs: Array, focus: Vector3, none_text: String) -> void:
	var primary := str(Days.definition().get("primary_activity", ""))
	var pick := ""
	for j: Array in jobs:
		if str(j[1]) == primary and ActivityRunner.can_start(primary):
			pick = primary
	if pick.is_empty():
		for j: Array in jobs:
			if Days.current_day >= int(j[0]) and ActivityRunner.can_start(str(j[1])):
				pick = str(j[1])
	if pick.is_empty():
		get_tree().call_group("main", "show_caption", none_text)
		return
	get_tree().call_group("main", "start_activity_here", pick, focus)


## The market week (from day 36): Mrs. Ruth sells eggs at the east stall,
## and Miss Miriam does her shopping at the vegetable stall.
func _market_week() -> void:
	# Mrs. Ruth's own little egg table, beside the east stall.
	var eggs_at: Vector3 = STALLS[3][0] + Vector3(-0.2, 0, 1.7)
	_egg_trays = group_node("EggTrays")
	MeshKit.box(_egg_trays, Vector3(1.2, 0.06, 0.6), eggs_at + Vector3(0, 0.7, 0), "wood_light")
	for x: float in [-0.5, 0.5]:
		MeshKit.box(_egg_trays, Vector3(0.07, 0.7, 0.5), eggs_at + Vector3(x, 0.35, 0), "wood_dark")
	for k in 3:
		var tray := eggs_at + Vector3(-0.38 + k * 0.38, 0.73, 0)
		MeshKit.box(_egg_trays, Vector3(0.3, 0.05, 0.36), tray + Vector3(0, 0.025, 0), "wood")
		for e in 4:
			MeshKit.sphere(_egg_trays, 0.05, tray + Vector3(-0.07 + (e % 2) * 0.14, 0.1, -0.08 + (e / 2) * 0.16), "cloth_cream", Vector3(1, 1.3, 1), 6, 3)
	var sign := Label3D.new()
	sign.text = tr("Eggs")
	sign.font = UiStyle.font()
	sign.font_size = 72
	sign.pixel_size = 0.005
	sign.modulate = Color("8a2f26")
	sign.outline_size = 0
	sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sign.position = eggs_at + Vector3(0, 1.15, 0)
	_egg_trays.add_child(sign)
	var sell := Interactable.create(self, eggs_at + Vector3(-0.9, 0, 0), "Help Mrs. Ruth sell eggs", func() -> void:
		get_tree().call_group("main", "start_activity_here", "market_sell_eggs", position + eggs_at + Vector3(0, 0.9, 0)), 0.7, 1.4)
	sell.conditions = [{"day_at_least": 36}, {"not": {"fact": "market.eggs_day", "is_today": true}}]
	var veg_at: Vector3 = STALLS[2][0]
	var shop := Interactable.create(self, veg_at + Vector3(-1.3, 0, -0.2), "Do Miss Miriam's shopping", func() -> void:
		get_tree().call_group("main", "start_activity_here", "market_list", position + veg_at + Vector3(0, 1.0, 0)), 0.7, 1.6)
	shop.conditions = [{"day_at_least": 38}, {"not": {"fact": "market.list_day", "is_today": true}}]


func _find_anchor(anchor_id: String) -> Node3D:
	if anchor_id.is_empty():
		return null
	for a in get_tree().get_nodes_in_group("anchors"):
		if a.name == "Anchor_%s" % anchor_id:
			return a
	return null


## From day 9, the day after the mill (once there is flour), the oven is
## where the bread is baked. On baking day a fire glows in its mouth and
## fresh loaves cool beside it.
func _baking_day(oven: Vector3) -> void:
	var bake := Interactable.create(self, oven + Vector3(-0.3, 0, 1.4), "Bake bread with Mr. Tobias", func() -> void:
		get_tree().call_group("main", "start_activity_here", "oven_bake", position + oven + Vector3(0, 0.8, 0.4)), 0.7, 1.7)
	bake.conditions = [{"day_at_least": 9}, {"fact": "village.flour_day", "exists": true}]
	add_activity_focus(oven + Vector3(0, 0.8, 0.4))
	_baking = group_node("BakingDay")
	var glow := OmniLight3D.new()
	glow.light_color = Color("ff9a3c")
	glow.light_energy = 1.6
	glow.omni_range = 2.6
	glow.position = oven + Vector3(0, 0.75, 0.5)
	_baking.add_child(glow)
	MeshKit.sphere(_baking, 0.18, oven + Vector3(-0.12, 0.62, 0.32), "flower_yellow", Vector3(1.3, 0.6, 0.8), 8, 4)
	MeshKit.sphere(_baking, 0.12, oven + Vector3(0.1, 0.6, 0.34), "roof_red", Vector3(1.2, 0.7, 0.8), 8, 4)
	# A board of fresh loaves cooling on a crate beside the oven.
	var board := oven + Vector3(1.25, 0, 0.9)
	MeshKit.box(_baking, Vector3(0.6, 0.5, 0.45), board + Vector3(0, 0.25, 0), "wood_dark")
	MeshKit.box(_baking, Vector3(0.7, 0.04, 0.5), board + Vector3(0, 0.52, 0), "wood_light")
	for k in 3:
		MeshKit.sphere(_baking, 0.12, board + Vector3(-0.2 + k * 0.2, 0.6, 0), "roof_thatch", Vector3(1.1, 0.7, 1.0), 8, 4)
