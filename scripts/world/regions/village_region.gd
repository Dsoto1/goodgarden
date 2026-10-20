extends Region
## The village: a small plaza with a well, the bakery and workshop, two
## neighbors, and the north road with an overlook where Bellhaven can be seen.


func build() -> void:
	# A cozy plaza: buildings close around the well so they share the frame.
	MeshKit.cylinder(self, 4.5, 4.5, 0.04, Vector3(0, 0.02, 0), "path", 16)
	Props.place(self, "well", Vector3(0, 0, 0), 0.0)
	_building("market", Vector3(-4.8, 0, -5.2), 0.0, "Bakery", 3.2)
	_building("workshop", Vector3(5.0, 0, -5.6), 0.0, "Workshop", 3.6)
	_building("house_yellow", Vector3(-7.4, 0, 1.6), PI / 2.0, "")
	_building("house_blue", Vector3(7.6, 0, 1.0), -PI / 2.0, "")
	_building("house_tall_red", Vector3(-9.0, 0, -4.6), PI / 4.0, "")
	Props.place(self, "barrel", Vector3(-2.2, 0, -3.0))
	Props.place(self, "barrel", Vector3(-1.7, 0, -3.5), 0.6)
	Props.place(self, "sack", Vector3(-2.8, 0, -2.6), 0.3)
	Props.place(self, "crate", Vector3(2.6, 0, -3.0), 0.2)
	Props.place(self, "crate_open", Vector3(3.3, 0, -2.8), -0.3)
	Props.place(self, "lumber", Vector3(8.2, 0, -3.0), 0.1, 0.8)
	Props.place(self, "wheelbarrow", Vector3(7.4, 0, -1.8), 2.2)
	Props.place(self, "bucket", Vector3(1.2, 0, 0.9))

	# North road to the overlook.
	MeshKit.path(self, Vector3(0, 0, -4.0), Vector3(0, 0, -13), 2.0)
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

	_villager("tobias", {"skin": "skin_1", "hair": "hair_dark", "shirt": "white", "pants": "cloth_blue", "apron": "cloth_cream", "height": 1.12, "build": 1.2}, Vector3(-4.8, 0, -2.6), 1.0)
	_villager("ruth", {"skin": "skin_3", "hair": "hair_dark", "hair_style": "bun", "shirt": "cloth_purple", "skirt": "cloth_blue", "pants": "cloth_blue", "height": 1.05}, Vector3(1.8, 0, 1.6), 1.0)
	for i in 3:
		var bird := Wanderer.new().setup(AnimalModel.make("bird"), 60 + i)
		bird.gait = "hop"
		bird.speed = 0.6
		bird.radius = 2.5
		bird.position = Vector3(-2 + i * 2.0, 0, 3.0)
		add_child(bird)
	Props.place(self, "tree_b", Vector3(10.5, 0, -6.0), 1.2)
	Props.place(self, "tree_a", Vector3(10.0, 0, 5.0), 0.5)
	MeshKit.flowers(self, Vector3(-2.5, 0, -5.0), 0.6, 6, 30)

	add_anchor("village_plaza", Vector3(0, 0, 4.0), 0.0)
	add_discovery_zone(Vector3(0, 1, -1), Vector3(20, 3, 14))


## A KayKit building with an optional painted sign over its front.
func _building(prop: String, at: Vector3, rot: float, sign_text: String, sign_height := 3.0) -> void:
	var b := Props.place(self, prop, at, rot)
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
