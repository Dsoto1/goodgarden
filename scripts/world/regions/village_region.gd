extends Region
## The village: a market square around a fountain, with stalls, the bakery,
## the workshop and houses around its edge, neighbours about their day, and
## the north road to an overlook where Bellhaven can be seen.


func build() -> void:
	# A proper market square: room to walk between stalls, buildings around
	# the edge, the fountain at the heart, and the south side open to the road.
	MeshKit.cylinder(self, 8.2, 8.2, 0.04, Vector3(0, 0.02, 0), "cobble", 32)
	add_clearing(Vector3.ZERO, Vector2(16.8, 16.8))
	_fountain(Vector3(0, 0, 0))
	Props.place(self, "well", Vector3(6.4, 0, 6.0), -0.6, 0.85)
	var stalls := [
		[Vector3(-5.2, 0, 3.2), "awning_red", ["crate_carrots", "crate_lettuce"]],
		[Vector3(-5.8, 0, -2.8), "awning_blue", ["crate_lettuce", "crate"]],
		[Vector3(5.8, 0, -2.8), "awning_green", ["crate_carrots", "crate_open"]],
		[Vector3(4.6, 0, 3.6), "awning_red", ["crate_lettuce", "crate_carrots"]],
	]
	var stock := ["barrel", "crate", "sack", "barrel"]
	for i in stalls.size():
		var at: Vector3 = stalls[i][0]
		_stall(at, atan2(-at.x, -at.z), stalls[i][1], stalls[i][2])
		# Spare stock stacked behind each stall.
		Props.place(self, stock[i], at * 1.32, i * 0.8)
		Props.place(self, "sack", at * 1.3 + Vector3(0.7, 0, 0.4).rotated(Vector3.UP, i * 1.6), i * 1.1)
	for b: Array in [[Vector3(-2.4, 0, -4.0), 0.55], [Vector3(2.6, 0, 4.4), PI + 0.55]]:
		_bench(b[0], b[1])
	for deg: float in [-150.0, -90.0, -30.0, 30.0, 62.0, 118.0, 150.0]:
		var a := deg_to_rad(deg)
		_lantern(Vector3(cos(a), 0, sin(a)) * 8.7)

	_building("market", Vector3(-6.5, 0, -10.5), 0.0, "Bakery", 3.2)
	_building("workshop", Vector3(7.0, 0, -11.0), 0.0, "Workshop", 3.6)
	_building("house_yellow", Vector3(-12.6, 0, -0.5), PI / 2.0, "")
	_building("house_blue", Vector3(13.2, 0, -0.5), -PI / 2.0, "")
	_building("house_tall_red", Vector3(-12.0, 0, -9.8), PI / 4.0, "")
	_building("house_yellow", Vector3(12.6, 0, -9.6), -PI / 4.0, "")
	_bunting(Vector3(-3.0, 3.7, -7.9), Vector3(4.2, 3.7, -8.3))
	_bunting(Vector3(-10.2, 3.4, -3.0), Vector3(-10.2, 3.4, 2.4))
	_bunting(Vector3(10.8, 3.4, -3.0), Vector3(10.8, 3.4, 2.4))
	for p: Array in [[-6.5, -7.0], [7.0, -7.4], [-9.6, 3.2], [10.2, 3.2], [-9.4, -4.2], [10.0, -4.4]]:
		_planter(Vector3(p[0], 0, p[1]))
	Props.place(self, "lumber", Vector3(10.4, 0, -6.2), 0.4, 0.8)
	Props.place(self, "wheelbarrow", Vector3(9.4, 0, -5.4), 2.2)
	Props.place(self, "bucket", Vector3(5.6, 0, 6.8))
	Props.place(self, "tree_a", Vector3(-9.6, 0, 7.2), 0.5)
	Props.place(self, "tree_b", Vector3(10.6, 0, 8.4), 1.2)
	for f: Array in [[-7.4, 8.4, "flowers_a"], [8.4, 9.0, "flowers_b"], [-3.2, 8.9, "bush_flowers"], [3.4, 9.0, "flowers_a"]]:
		Props.place(self, f[2], Vector3(f[0], 0, f[1]), f[0])

	# North road between the bakery and workshop to the overlook.
	road(Vector3(0, 0, -8.0), Vector3(0, 0, -15.0), 2.0, "cobble")
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

	_villager("tobias", World.look_for("tobias"), Vector3(-6.5, 0, -6.2), 1.2)
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

	add_anchor("village_plaza", Vector3(0, 0, 9.5), 0.0)
	add_discovery_zone(Vector3(0, 1, -2), Vector3(30, 3, 24))


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
	w.position = at
	w.radius = wander_radius
	w.speed = 0.6
	w.pause_range = Vector2(3, 7)
	w.talk_dialogue_id = id
	add_child(w)
	MeshKit.solid(w, Vector3(0.5, 1.6, 0.5), Vector3(0, 0.8, 0), 0.0, MeshKit.LAYER_CHARACTER)
	var talk := Interactable.create(w, Vector3.ZERO, "Talk to %s" % Dialogue.character_name(id), func() -> void: Dialogue.start(id), 0.7, 1.95 * float(look.get("height", 1.0)))
	talk.reach = 2.2
