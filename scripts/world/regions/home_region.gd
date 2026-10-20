extends Region
## The child's cottage and yard: today's letter, the supper table (practical
## life), and the bed where a day ends. Interior-lite: the roof and front wall
## lift away while the child is inside.

var _letter: Node3D
var _letter_use: Interactable
var _table_settings: Node3D
var _vase: Node3D


func build() -> void:
	# Floor and walls (8 x 6 m, door facing the camera to the south).
	MeshKit.box(self, Vector3(8, 0.1, 6), Vector3(0, 0.05, 0), "wood_light")
	MeshKit.box(self, Vector3(8.2, 2.6, 0.2), Vector3(0, 1.3, -3), "plaster", true)
	MeshKit.box(self, Vector3(0.2, 2.6, 6), Vector3(-4, 1.3, 0), "plaster", true)
	MeshKit.box(self, Vector3(0.2, 2.6, 6), Vector3(4, 1.3, 0), "plaster", true)
	for x: float in [-1.0, 1.0]:
		MeshKit.box(self, Vector3(0.25, 2.6, 0.25), Vector3(x * 4, 1.3, 3), "wood_dark")
		MeshKit.box(self, Vector3(0.25, 2.6, 0.25), Vector3(x * 4, 1.3, -3), "wood_dark")
	var cutaway := group_node("Cutaway")
	for x: float in [-2.35, 2.35]:
		MeshKit.box(cutaway, Vector3(3.3, 2.6, 0.2), Vector3(x, 1.3, 3), "plaster", true)
		MeshKit.box(cutaway, Vector3(0.9, 0.8, 0.06), Vector3(x, 1.5, 3.12), "glass")
		MeshKit.box(cutaway, Vector3(1.1, 0.1, 0.16), Vector3(x, 1.05, 3.15), "wood_dark")
	MeshKit.box(cutaway, Vector3(1.4, 0.5, 0.2), Vector3(0, 2.35, 3), "plaster")
	MeshKit.box(cutaway, Vector3(1.6, 0.14, 0.3), Vector3(0, 2.1, 3.05), "wood_dark")
	MeshKit.roof(cutaway, 7.0, 1.9, 9.0, Vector3(0, 3.55, 0), "roof_red", PI / 2.0)
	MeshKit.box(cutaway, Vector3(0.7, 1.6, 0.7), Vector3(2.4, 4.0, -1.2), "stone")
	for side: float in [-1.0, 1.0]:
		MeshKit.box(self, Vector3(0.06, 0.8, 0.9), Vector3(side * 4.12, 1.5, 0), "glass")
	# Doorstep and a little path.
	MeshKit.box(self, Vector3(1.6, 0.12, 0.8), Vector3(0, 0.06, 3.5), "stone")

	# Bed (end the day).
	MeshKit.box(self, Vector3(1.2, 0.4, 2.1), Vector3(-3.0, 0.3, -1.85), "wood")
	MeshKit.box(self, Vector3(1.1, 0.2, 1.9), Vector3(-3.0, 0.58, -1.8), "white")
	MeshKit.box(self, Vector3(1.14, 0.08, 1.3), Vector3(-3.0, 0.7, -1.4), "cloth_blue")
	MeshKit.box(self, Vector3(0.7, 0.15, 0.4), Vector3(-3.0, 0.75, -2.55), "cloth_cream")
	MeshKit.box(self, Vector3(1.2, 1.0, 0.1), Vector3(-3.0, 0.6, -2.9), "wood_dark")
	MeshKit.solid(self, Vector3(1.2, 1.0, 2.1), Vector3(-3.0, 0.5, -1.85))
	var bed := Interactable.create(self, Vector3(-2.9, 0, -0.5), "Rest until morning", func() -> void:
		get_tree().call_group("main", "request_rest"), 0.6, 1.4)
	bed.reach = 1.6

	# Supper table (practical life) with two stools.
	MeshKit.box(self, Vector3(1.8, 0.08, 1.1), Vector3(1.6, 0.74, -1.2), "wood")
	for dx: float in [-0.8, 0.8]:
		for dz: float in [-0.45, 0.45]:
			MeshKit.box(self, Vector3(0.08, 0.7, 0.08), Vector3(1.6 + dx, 0.35, -1.2 + dz), "wood_dark")
	MeshKit.solid(self, Vector3(1.9, 1.0, 1.2), Vector3(1.6, 0.5, -1.2))
	for dx: float in [-0.5, 0.5]:
		MeshKit.cylinder(self, 0.22, 0.22, 0.45, Vector3(1.6 + dx, 0.23, -0.35), "wood_light", 8)
	var table := Interactable.create(self, Vector3(1.6, 0, -0.4), "Set the table", func() -> void:
		get_tree().call_group("main", "start_activity_here", "home_set_table", Vector3(1.6, 0.8, -1.2) + position), 0.7, 1.5)
	table.conditions = [{"not": {"fact": "home.table_set_day", "is_today": true}}]
	table.reach = 1.8
	_table_settings = group_node("TableSettings")
	for dx: float in [-0.45, 0.45]:
		MeshKit.cylinder(_table_settings, 0.17, 0.15, 0.03, Vector3(1.6 + dx, 0.8, -1.05), "white", 12)
		MeshKit.cylinder(_table_settings, 0.05, 0.045, 0.12, Vector3(1.6 + dx + 0.22, 0.84, -1.3), "cloth_blue", 8)
		MeshKit.box(_table_settings, Vector3(0.12, 0.01, 0.18), Vector3(1.6 + dx - 0.25, 0.79, -1.05), "cloth_red")
	_vase = group_node("Vase")
	MeshKit.cylinder(_vase, 0.06, 0.08, 0.2, Vector3(1.6, 0.88, -1.45), "cloth_blue", 8)
	MeshKit.flowers(_vase, Vector3(1.6, 0.68, -1.45), 0.05, 4, 3)

	# Today's letter on a little stand by the door.
	MeshKit.box(self, Vector3(0.6, 0.6, 0.4), Vector3(-1.3, 0.3, 2.5), "wood")
	_letter = group_node("Letter")
	MeshKit.box(_letter, Vector3(0.36, 0.03, 0.26), Vector3(-1.3, 0.63, 2.5), "cloth_cream")
	MeshKit.cylinder(_letter, 0.05, 0.05, 0.02, Vector3(-1.3, 0.65, 2.5), "roof_red", 8)
	_letter_use = Interactable.create(self, Vector3(-1.3, 0, 2.2), "Read the letter", func() -> void:
		get_tree().call_group("main", "open_invitation", Invitations.pending_id), 0.6, 1.1)
	_letter_use.reach = 1.6

	# Shelf, stove and rug for a lived-in feel.
	MeshKit.box(self, Vector3(1.6, 1.2, 0.4), Vector3(-0.5, 0.6, -2.7), "wood")
	for i in 3:
		MeshKit.sphere(self, 0.12, Vector3(-1.0 + i * 0.45, 1.3, -2.7), ["cloth_red", "cloth_gold", "cloth_green"][i], Vector3.ONE, 6, 3)
	MeshKit.box(self, Vector3(0.9, 0.9, 0.7), Vector3(3.3, 0.45, -2.4), "dark", true)
	MeshKit.cylinder(self, 0.1, 0.1, 1.8, Vector3(3.5, 1.8, -2.6), "dark", 6)
	MeshKit.box(self, Vector3(2.4, 0.02, 1.6), Vector3(-0.6, 0.11, 0.6), "cloth_green")

	# Yard.
	MeshKit.flowers(self, Vector3(-2.5, 0, 4.3), 1.0, 10, 1)
	MeshKit.flowers(self, Vector3(2.5, 0, 4.3), 1.0, 10, 2)
	MeshKit.tree(self, Vector3(-6.5, 0, -1.5), 1.2)
	MeshKit.tree(self, Vector3(-6, 0, 4.5), 0.9, "leaf_light")
	_build_coop(Vector3(-6.5, 0, 8.5))
	var cat := Wanderer.new().setup(AnimalModel.make("cat"), 3)
	cat.position = Vector3(1.8, 0, 5.2)
	cat.radius = 1.2
	cat.speed = 0.35
	cat.pause_range = Vector2(6, 14)
	add_child(cat)

	add_anchor("home_spawn", Vector3(-2.0, 0.1, -0.6), PI)
	add_anchor("home_door", Vector3(0, 0, 5.0), 0.0)
	add_discovery_zone(Vector3(0, 1, 2), Vector3(12, 3, 10))
	add_interior("home", Vector3(0, 1.2, 0), Vector3(7.6, 2.4, 5.6), [cutaway])


func _build_coop(at: Vector3) -> void:
	MeshKit.box(self, Vector3(1.6, 1.0, 1.2), at + Vector3(0, 0.7, 0), "wood", true)
	MeshKit.roof(self, 1.5, 0.6, 1.9, at + Vector3(0, 1.5, 0), "roof_thatch", PI / 2.0)
	for i in 3:
		var hen := Wanderer.new().setup(AnimalModel.make("chicken"), 20 + i)
		hen.position = at + Vector3(-1.0 + i * 1.0, 0, 1.6)
		hen.radius = 2.0
		hen.speed = 0.5
		add_child(hen)


func sync_with_world() -> void:
	_letter.visible = Invitations.has_unread()
	_letter_use.enabled = Invitations.has_unread()
	var set_today := WorldState.matches([{"fact": "home.table_set_day", "is_today": true}])
	_table_settings.visible = set_today
	# On later days the table is cleared, but a little vase stays as a memory of the work.
	_vase.visible = WorldState.has_fact("home.table_set_day") and not set_today


func _ready() -> void:
	super._ready()
	Invitations.delivered.connect(func(_id: String) -> void: sync_with_world())
	Invitations.opened.connect(func(_id: String) -> void: sync_with_world())
