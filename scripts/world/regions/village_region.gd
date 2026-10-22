extends Region
## The village: a market square around a fountain, with stalls, the bakery,
## the workshop and houses around its edge, neighbours about their day, and
## the north road to an overlook where Bellhaven can be seen.

## The market square's outline (x, z), irregular like a real village's.
const SQUARE: Array[Vector2] = [
	Vector2(-6.9, -5.4), Vector2(-2.6, -6.6), Vector2(2.9, -6.8), Vector2(6.8, -5.0), Vector2(7.6, -1.0),
	Vector2(7.0, 3.4), Vector2(4.8, 6.2), Vector2(1.6, 7.0), Vector2(-2.2, 6.6), Vector2(-5.4, 5.6),
	Vector2(-7.4, 2.4), Vector2(-7.8, -1.8),
]

var _baking: Node3D # the fire and fresh loaves, on baking day
## Villagers by id: [wanderer, home position, home radius, current anchor id].
var _villagers := {}


func build() -> void:
	# The market square, like the concept art's: cobbles in an uneven shape
	# rather than a circle, the fountain at its heart, stalls gathered close
	# round it, and the south side open to the road from the bridge.
	_square(SQUARE)
	_fountain(Vector3(0, 0, 0))
	SoundSpot.looping(self, "fountain", Vector3(0, 1.0, 0), 13.0, -6.0)
	SoundSpot.calling(self, "hens", Vector3(14.3, 0.4, 9.8), 18.0, Vector2(9, 20), -8.0)
	Props.place(self, "well", Vector3(6.4, 0, 6.0), -0.6, 0.85)
	var stalls := [
		[Vector3(-4.2, 0, 2.7), "awning_red", ["crate_carrots", "crate_lettuce"]],
		[Vector3(-4.6, 0, -2.4), "awning_blue", ["bread"]],
		[Vector3(4.5, 0, -2.6), "awning_green", ["crate_carrots", "crate_open"]],
		[Vector3(3.9, 0, 3.1), "awning_red", ["crate_lettuce", "crate_carrots"]],
	]
	var stock := ["barrel", "crate", "sack", "barrel"]
	for i in stalls.size():
		var at: Vector3 = stalls[i][0]
		_stall(at, atan2(-at.x, -at.z), stalls[i][1], stalls[i][2])
		# Spare stock stacked behind each stall.
		Props.place(self, stock[i], at * 1.36, i * 0.8)
		Props.place(self, "sack", at * 1.34 + Vector3(0.7, 0, 0.4).rotated(Vector3.UP, i * 1.6), i * 1.1)
	for b: Array in [[Vector3(-1.9, 0, -3.6), 0.55], [Vector3(2.2, 0, 4.0), PI + 0.55]]:
		_bench(b[0], b[1])
	# Lanterns stand at the square's corners, not in a perfect ring.
	for k in [0, 2, 3, 5, 8, 10]:
		var corner: Vector2 = SQUARE[k]
		_lantern(Vector3(corner.x, 0, corner.y) * 0.94)

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
	var west_cottage := CraftedProps.cottage(self, Vector3(-12.2, 0, 8.4), PI + 0.1, 5, Vector2(3.2, 3.2), "roof_thatch")
	add_clearing(west_cottage.position, Vector2(4.6, 4.6))
	_bunting(Vector3(-3.0, 3.7, -9.4), Vector3(4.2, 3.7, -9.8))
	_bunting(Vector3(-9.8, 3.4, -3.0), Vector3(-9.8, 3.4, 2.4))
	_bunting(Vector3(10.6, 3.4, -3.2), Vector3(10.6, 3.4, 2.2))
	for p: Array in [[-9.4, 3.4], [9.0, -4.6], [-10.6, -4.4], [9.6, -7.4]]:
		_planter(Vector3(p[0], 0, p[1]))
	Props.place(self, "lumber", Vector3(12.0, 0, -5.4), 0.4, 0.8)
	Props.place(self, "wheelbarrow", Vector3(13.0, 0, -6.2), 2.2)
	Props.place(self, "bucket", Vector3(5.6, 0, 6.8))
	Props.place(self, "tree_a", Vector3(-16.0, 0, 6.4), 0.5)
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
		[Vector3(-5.6, 0, 5.6), Vector3(-9.0, 0, 5.6), Vector3(-11.8, 0, 6.4)], # west cottage
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
	_villager("ruth", World.look_for("ruth"), Vector3(5.2, 0, 5.4), 1.2)
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
func _square(outline: Array[Vector2]) -> void:
	var pts := PackedVector2Array(outline)
	var tris := Geometry2D.triangulate_polygon(pts)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in tris.size():
		var q := pts[tris[i]]
		st.set_uv(q / 4.0)
		st.add_vertex(Vector3(q.x, 0.03, q.y))
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
	for b: Array in [[Vector3(-10.6, 0, 1.8), "barrel"], [Vector3(11.4, 0, 1.6), "barrel"], [Vector3(9.9, 0, 5.4), "crate"], [Vector3(-13.6, 0, 6.8), "barrel"]]:
		Props.place(self, b[1], b[0], b[0].x)
	for f: Array in [[Vector3(9.8, 0, 7.9), "flower_pink"], [Vector3(-11.2, 0, 6.6), "flower_yellow"], [Vector3(-10.2, 0, -1.6), "flower_white"]]:
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
	var pool := MeshKit.cylinder(self, 1.5, 1.5, 0.05, at + Vector3(0, 0.5, 0), "water", 16)
	pool.material_override = Palette.mat("water")
	MeshKit.cylinder(self, 0.25, 0.32, 1.3, at + Vector3(0, 1.0, 0), "stone", 10)
	MeshKit.cylinder(self, 0.75, 0.5, 0.22, at + Vector3(0, 1.62, 0), "stone", 12)
	MeshKit.cylinder(self, 0.65, 0.65, 0.04, at + Vector3(0, 1.72, 0), "water", 12)
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
		return
	for i in goods.size():
		Props.place(root, goods[i], Vector3(-0.45 + i * 0.9, 0.8, 0.05), 0.0, 0.75)


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


func _find_anchor(anchor_id: String) -> Node3D:
	if anchor_id.is_empty():
		return null
	for a in get_tree().get_nodes_in_group("anchors"):
		if a.name == "Anchor_%s" % anchor_id:
			return a
	return null


## From day 7 (once there is flour) the oven is where the bread is baked. On
## baking day a fire glows in its mouth and fresh loaves cool beside it.
func _baking_day(oven: Vector3) -> void:
	var bake := Interactable.create(self, oven + Vector3(-0.3, 0, 1.4), "Bake bread with Mr. Tobias", func() -> void:
		get_tree().call_group("main", "start_activity_here", "oven_bake", position + oven + Vector3(0, 0.8, 0.4)), 0.7, 1.7)
	bake.conditions = [{"day_at_least": 7}, {"fact": "village.flour_day", "exists": true}]
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
