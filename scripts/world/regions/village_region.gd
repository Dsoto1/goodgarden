extends Region
## The village: a small plaza with a well, the bakery and workshop, two
## neighbors, and the north road with an overlook where Bellhaven can be seen.


func build() -> void:
	MeshKit.cylinder(self, 6.0, 6.0, 0.04, Vector3(0, 0.02, 0), "stone", 16)
	_well(Vector3(0, 0, 0))
	_building(Vector3(-5.5, 0, -7), Vector3(5, 3, 4), "plaster_warm", "roof_red", "Bakery")
	_building(Vector3(5.5, 0, -7.5), Vector3(5, 3.2, 4.5), "plaster", "roof_slate", "Workshop")
	_building(Vector3(-9.5, 0, 1.5), Vector3(4, 2.8, 4), "plaster", "roof_thatch", "", PI / 2.0)
	_building(Vector3(10.5, 0, 0.5), Vector3(4, 2.8, 4), "plaster_warm", "roof_blue", "", -PI / 2.0)
	MeshKit.cylinder(self, 0.5, 0.6, 0.5, Vector3(-3, 0.25, -4.4), "wood", 8, true)
	for i in 3:
		MeshKit.box(self, Vector3(0.5, 0.5, 0.5), Vector3(3.2 + i * 0.6, 0.25, -4.6), "wood_light", true)

	# North road to the overlook.
	MeshKit.path(self, Vector3(0, 0, -5.5), Vector3(0, 0, -13), 2.0)
	MeshKit.box(self, Vector3(12, 0.7, 0.6), Vector3(0, 0.35, -15.2), "stone", true)
	MeshKit.box(self, Vector3(1.6, 0.45, 0.5), Vector3(-2.5, 0.22, -13.8), "wood", true)
	var sign_post := MeshKit.box(self, Vector3(0.12, 1.8, 0.12), Vector3(2.0, 0.9, -12.2), "wood")
	sign_post.name = "SignPost"
	MeshKit.box(self, Vector3(1.4, 0.4, 0.08), Vector3(2.5, 1.55, -12.2), "wood_light")
	var label := Label3D.new()
	label.text = tr("To Bellhaven")
	label.font_size = 48
	label.pixel_size = 0.005
	label.modulate = Color("3b3430")
	label.outline_size = 0
	label.position = Vector3(2.5, 1.55, -12.14)
	add_child(label)
	add_camera_zone(Vector3(0, 1, -12.5), Vector3(11, 3, 4.5), {"pitch": 9.0, "distance": 7.0, "height": 1.8, "fov": 52.0})
	add_anchor("village_overlook", Vector3(0, 0, -12.5), 0.0)

	_villager("tobias", {"skin": "skin_1", "hair": "hair_dark", "shirt": "white", "pants": "cloth_blue", "apron": "cloth_cream", "height": 1.12, "build": 1.2}, Vector3(-5.5, 0, -4.2), 1.2)
	_villager("ruth", {"skin": "skin_3", "hair": "hair_dark", "hair_style": "bun", "shirt": "cloth_purple", "skirt": "cloth_blue", "pants": "cloth_blue", "height": 1.05}, Vector3(1.8, 0, 1.6), 1.0)
	for i in 3:
		var bird := Wanderer.new().setup(AnimalModel.make("bird"), 60 + i)
		bird.gait = "hop"
		bird.speed = 0.6
		bird.radius = 2.5
		bird.position = Vector3(-2 + i * 2.0, 0, 3.0)
		add_child(bird)
	MeshKit.tree(self, Vector3(-11, 0, -6), 1.1)
	MeshKit.tree(self, Vector3(11.5, 0, -6.5), 1.0, "leaf_light")
	MeshKit.flowers(self, Vector3(-2.5, 0, -5.0), 0.6, 6, 30)

	add_anchor("village_plaza", Vector3(0, 0, 4.0), 0.0)
	add_discovery_zone(Vector3(0, 1, -2), Vector3(22, 3, 16))


func _well(at: Vector3) -> void:
	MeshKit.cylinder(self, 0.9, 0.95, 0.8, at + Vector3(0, 0.4, 0), "stone", 10, true)
	MeshKit.cylinder(self, 0.72, 0.72, 0.02, at + Vector3(0, 0.79, 0), "water", 10)
	for x: float in [-0.8, 0.8]:
		MeshKit.box(self, Vector3(0.12, 1.8, 0.12), at + Vector3(x, 0.9, 0), "wood")
	MeshKit.roof(self, 2.0, 0.6, 1.4, at + Vector3(0, 2.1, 0), "roof_red", PI / 2.0)


func _building(at: Vector3, size: Vector3, wall: String, roof: String, sign_text: String, rot := 0.0) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = rot
	add_child(root)
	MeshKit.box(root, size, Vector3(0, size.y / 2.0, 0), wall, true)
	MeshKit.roof(root, size.z + 0.6, size.y * 0.55, size.x + 0.6, Vector3(0, size.y + size.y * 0.275, 0), roof, PI / 2.0)
	MeshKit.box(root, Vector3(0.9, 1.7, 0.08), Vector3(0, 0.85, size.z / 2.0 + 0.02), "wood_dark")
	for x: float in [-size.x * 0.3, size.x * 0.3]:
		MeshKit.box(root, Vector3(0.8, 0.7, 0.06), Vector3(x, 1.6, size.z / 2.0 + 0.03), "glass")
		MeshKit.box(root, Vector3(0.9, 0.1, 0.12), Vector3(x, 1.2, size.z / 2.0 + 0.05), "wood_dark")
	if not sign_text.is_empty():
		var l := Label3D.new()
		l.text = tr(sign_text)
		l.font_size = 56
		l.pixel_size = 0.006
		l.modulate = Color("3b3430")
		l.position = Vector3(0, size.y - 0.35, size.z / 2.0 + 0.06)
		var board := MeshKit.box(root, Vector3(1.9, 0.45, 0.05), Vector3(0, size.y - 0.35, size.z / 2.0 + 0.03), "wood_light")
		board.name = "SignBoard"
		root.add_child(l)


func _villager(id: String, look: Dictionary, at: Vector3, wander_radius: float) -> void:
	var w := Wanderer.new().setup(CharacterModel.new().build(look), id.hash())
	w.position = at
	w.radius = wander_radius
	w.speed = 0.6
	w.pause_range = Vector2(3, 7)
	w.talk_dialogue_id = id
	add_child(w)
	MeshKit.solid(w, Vector3(0.5, 1.6, 0.5), Vector3(0, 0.8, 0))
	var talk := Interactable.create(w, Vector3.ZERO, "Talk to %s" % Dialogue.character_name(id), func() -> void: Dialogue.start(id), 0.7, 1.95 * float(look.get("height", 1.0)))
	talk.reach = 2.2
