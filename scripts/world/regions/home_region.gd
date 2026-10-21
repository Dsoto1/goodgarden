extends Region
## The child's cottage and yard: today's letter, the supper table (practical
## life), and the bed where a day ends. Interior-lite: the roof and front wall
## lift away while the child is inside.

var _letter: Node3D
var _letter_use: Interactable
var _table_settings: Node3D
var _vase: Node3D
var _smoke: GPUParticles3D


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
	_cottage_details(cutaway)
	# Doorstep and a little path.
	MeshKit.box(self, Vector3(1.6, 0.12, 0.8), Vector3(0, 0.06, 3.5), "stone")

	# Bed (end the day).
	Props.place(self, "bed", Vector3(-3.0, 0.1, -1.9))
	var bed := Interactable.create(self, Vector3(-2.9, 0, -0.5), "Rest until morning", func() -> void:
		get_tree().call_group("main", "request_rest"), 0.6, 1.4)
	bed.reach = 1.6

	# Supper table (practical life) with two stools.
	Props.place(self, "table", Vector3(1.6, 0.1, -1.2))
	for dx: float in [-1.05, 1.05]:
		Props.place(self, "stool", Vector3(1.6 + dx, 0.1, -1.2))
	var table := Interactable.create(self, Vector3(1.6, 0, -0.4), "Set the table", func() -> void:
		get_tree().call_group("main", "start_activity_here", "home_set_table", Vector3(1.6, 0.8, -1.2) + position), 0.7, 1.5)
	table.conditions = [{"not": {"fact": "home.table_set_day", "is_today": true}}]
	table.reach = 1.8
	_table_settings = group_node("TableSettings")
	for dx: float in [-0.4, 0.4]:
		Props.place(_table_settings, "plate", Vector3(1.6 + dx, 0.86, -0.9))
		Props.place(_table_settings, "bowl", Vector3(1.6 + dx + 0.22, 0.86, -1.15))
		MeshKit.box(_table_settings, Vector3(0.12, 0.01, 0.18), Vector3(1.6 + dx - 0.25, 0.86, -0.9), "cloth_red")
	_vase = group_node("Vase")
	MeshKit.cylinder(_vase, 0.06, 0.08, 0.2, Vector3(1.6, 0.96, -1.45), "cloth_blue", 8)
	MeshKit.flowers(_vase, Vector3(1.6, 0.76, -1.45), 0.05, 4, 3)

	# Today's letter on a little stand by the door.
	MeshKit.box(self, Vector3(0.6, 0.6, 0.4), Vector3(-1.3, 0.3, 2.5), "wood")
	_letter = group_node("Letter")
	MeshKit.box(_letter, Vector3(0.36, 0.03, 0.26), Vector3(-1.3, 0.63, 2.5), "cloth_cream")
	MeshKit.cylinder(_letter, 0.05, 0.05, 0.02, Vector3(-1.3, 0.65, 2.5), "roof_red", 8)
	_letter_use = Interactable.create(self, Vector3(-1.3, 0, 2.2), "Read the letter", func() -> void:
		get_tree().call_group("main", "open_invitation", Invitations.pending_id), 0.6, 1.1)
	_letter_use.reach = 1.6

	# Shelf, stove and rug for a lived-in feel.
	Props.place(self, "bookshelf", Vector3(-0.6, 0.1, -2.85))
	Props.place(self, "jar", Vector3(2.6, 0.1, -2.6))
	Props.place(self, "picture", Vector3(1.6, 1.4, -2.88))
	Props.place(self, "cutting_board", Vector3(3.3, 0.92, -2.4))
	MeshKit.box(self, Vector3(0.9, 0.9, 0.7), Vector3(3.3, 0.45, -2.4), "dark", true)
	MeshKit.cylinder(self, 0.1, 0.1, 1.8, Vector3(3.5, 1.8, -2.6), "dark", 6)
	Props.place(self, "rug_stripes", Vector3(-0.6, 0.1, 0.6))

	# Yard.
	for f: Array in [[-3.2, 4.0, "flowers_a"], [-2.0, 4.4, "flowers_b"], [-3.6, 3.6, "bush_flowers"], [2.2, 4.3, "flowers_b"], [3.3, 4.0, "flowers_a"], [3.7, 3.6, "bush"]]:
		Props.place(self, f[2], Vector3(f[0], 0, f[1]), f[0])
	Props.place(self, "tree_a", Vector3(-6.5, 0, -1.5), 0.2, 1.1)
	Props.place(self, "tree_b", Vector3(-6, 0, 4.5), 1.0)
	Props.place(self, "lumber", Vector3(-5.6, 0, 1.2), PI / 2.0, 0.7)
	_build_coop(Vector3(-6.5, 0, 8.5))
	# Everyday life around the house: letters, firewood, washing.
	CraftedProps.letterbox(self, Vector3(4.4, 0, 6.0), PI)
	CraftedProps.woodpile(self, Vector3(-4.75, 0, -1.9), PI / 2.0)
	CraftedProps.chopping_block(self, Vector3(-5.2, 0, -0.1), 0.6)
	CraftedProps.clothesline(self, Vector3(-1.0, 0, 8.2), Vector3(3.2, 0, 8.6))
	var cat := Wanderer.new().setup(AnimalModel.make("cat"), 3)
	cat.position = Vector3(1.8, 0, 5.2)
	cat.radius = 1.2
	cat.speed = 0.35
	cat.pause_range = Vector2(6, 14)
	add_child(cat)

	add_clearing(Vector3(0, 0, 0.3), Vector2(8.8, 7.4))
	add_clearing(Vector3(-6.5, 0, 8.5), Vector2(2.6, 2.4))
	add_anchor("home_spawn", Vector3(-2.0, 0.1, -0.6), PI)
	add_anchor("home_door", Vector3(0, 0, 5.0), 0.0)
	add_discovery_zone(Vector3(0, 1, 2), Vector3(12, 3, 10))
	add_interior("home", Vector3(0, 1.2, 0), Vector3(7.6, 2.4, 5.6), [cutaway])
	add_camera_zone(Vector3(0, 1.2, 0), Vector3(7.6, 2.4, 5.6), {"pitch": 55.0, "distance": 10.5, "height": 0.8, "fov": 42.0})


## Timber framing, a stone footing, shuttered windows with flower boxes, a
## ridge beam and a smoking chimney: the small things that make it a home.
func _cottage_details(cutaway: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		var x := side * 4.12
		MeshKit.box(self, Vector3(0.08, 0.16, 6.2), Vector3(x, 2.5, 0), "wood_dark")
		MeshKit.box(self, Vector3(0.08, 0.12, 6.2), Vector3(x, 0.95, 0), "wood_dark")
		MeshKit.box(self, Vector3(0.22, 0.4, 6.3), Vector3(side * 4.05, 0.2, 0), "stone")
		for z: float in [-2.0, 2.0]:
			var brace := MeshKit.box(self, Vector3(0.07, 1.6, 0.1), Vector3(x, 1.72, z), "wood_dark")
			brace.rotation.x = 0.55 * side * signf(z)
		_window_trim(self, Vector3(x + side * 0.03, 1.5, 0), PI / 2.0, 0.9)
	MeshKit.box(self, Vector3(8.3, 0.16, 0.08), Vector3(0, 2.5, -3.12), "wood_dark")
	MeshKit.box(self, Vector3(8.4, 0.4, 0.22), Vector3(0, 0.2, -3.05), "stone")
	for x: float in [-2.35, 2.35]:
		MeshKit.box(cutaway, Vector3(3.3, 0.16, 0.08), Vector3(x, 2.5, 3.12), "wood_dark")
		MeshKit.box(cutaway, Vector3(3.3, 0.4, 0.22), Vector3(x, 0.2, 3.05), "stone")
		_window_trim(cutaway, Vector3(x, 1.5, 3.14), 0.0, 0.9)
	# Door frame and an open door leaf.
	for x: float in [-0.75, 0.75]:
		MeshKit.box(cutaway, Vector3(0.14, 2.1, 0.26), Vector3(x, 1.05, 3.05), "wood_dark")
	var door := MeshKit.box(self, Vector3(1.3, 2.0, 0.08), Vector3(-1.2, 1.0, 3.55), "wood", false, -1.2)
	door.name = "DoorLeaf"
	MeshKit.box(cutaway, Vector3(0.3, 0.12, 9.2), Vector3(0, 4.5, 0), "wood_dark").rotation.y = PI / 2.0
	var smoke := _chimney_smoke()
	smoke.position = Vector3(2.4, 4.9, -1.2)
	cutaway.add_child(smoke)


## Frame, shutters and a flower box around a window centred at `at`.
func _window_trim(parent: Node3D, at: Vector3, yaw: float, width: float) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation.y = yaw
	parent.add_child(root)
	MeshKit.box(root, Vector3(width + 0.16, 0.08, 0.08), Vector3(0, 0.44, 0.04), "wood_dark")
	MeshKit.box(root, Vector3(width + 0.16, 0.08, 0.08), Vector3(0, -0.44, 0.04), "wood_dark")
	MeshKit.box(root, Vector3(0.05, 0.8, 0.06), Vector3(0, 0, 0.05), "wood_dark")
	for s: float in [-1.0, 1.0]:
		MeshKit.box(root, Vector3(0.4, 0.82, 0.05), Vector3(s * (width / 2.0 + 0.24), 0, 0.06), "cloth_blue")
	MeshKit.box(root, Vector3(width + 0.1, 0.18, 0.22), Vector3(0, -0.56, 0.14), "wood")
	for i in 3:
		Props.place(root, "flowers_a" if i % 2 == 0 else "flowers_b", Vector3(-0.3 + i * 0.3, -0.48, 0.14), i * 1.7, 0.45)


## Soft, slow chimney smoke. Stilled when the child chooses "Less motion".
func _chimney_smoke() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 10
	p.lifetime = 4.0
	p.emitting = not Settings.get_value("reduced_motion")
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0.3, 1, 0)
	mat.spread = 12.0
	mat.initial_velocity_min = 0.35
	mat.initial_velocity_max = 0.55
	mat.gravity = Vector3(0.12, 0.05, 0)
	mat.scale_min = 0.6
	mat.scale_max = 1.1
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 1.6))
	var tex := CurveTexture.new()
	tex.curve = curve
	mat.scale_curve = tex
	p.process_material = mat
	var puff := SphereMesh.new()
	puff.radius = 0.22
	puff.height = 0.44
	puff.radial_segments = 8
	puff.rings = 4
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.albedo_color = Color(0.95, 0.95, 0.97, 0.45)
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = smoke_mat
	p.draw_pass_1 = puff
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_smoke = p
	Settings.changed.connect(_on_setting_changed)
	return p


func _on_setting_changed(key: String) -> void:
	if key == "reduced_motion":
		_smoke.emitting = not Settings.get_value("reduced_motion")


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
