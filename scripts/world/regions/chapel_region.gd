extends Region
## The village chapel with a children's Atrium inside: low shelves of
## Scripture materials, a work table, and a prayer corner. Entering shifts
## World into its quiet mood (light, sound, a calmer HUD). Nothing here is
## scored or timed.

var light: OmniLight3D


func build() -> void:
	# Nave 7 x 10 m, door to the south.
	MeshKit.box(self, Vector3(7, 0.1, 10), Vector3(0, 0.05, 0), "wood_light")
	MeshKit.box(self, Vector3(7.2, 3.4, 0.25), Vector3(0, 1.7, -5), "stone", true)
	for side: float in [-1.0, 1.0]:
		MeshKit.box(self, Vector3(0.25, 3.4, 10), Vector3(side * 3.5, 1.7, 0), "stone", true)
		MeshKit.box(self, Vector3(0.4, 0.45, 10.2), Vector3(side * 3.6, 0.22, 0), "stone_dark")
		for z: float in [-2.8, 0.2, 3.0]:
			_lancet_window(Vector3(side * 3.64, 0, z), side)
		for z: float in [-4.3, -1.3, 1.6, 4.4]:
			MeshKit.box(self, Vector3(0.5, 2.6, 0.55), Vector3(side * 3.85, 1.3, z), "stone_dark")
			MeshKit.box(self, Vector3(0.42, 0.5, 0.5), Vector3(side * 3.8, 2.75, z), "stone_dark").rotation.z = side * 0.5
	var cutaway := group_node("Cutaway")
	for x: float in [-2.2, 2.2]:
		MeshKit.box(cutaway, Vector3(2.6, 3.4, 0.25), Vector3(x, 1.7, 5), "stone", true)
	MeshKit.box(cutaway, Vector3(1.8, 1.0, 0.25), Vector3(0, 2.9, 5), "stone")
	# Arched door surround.
	for x: float in [-1.0, 1.0]:
		MeshKit.box(cutaway, Vector3(0.24, 2.4, 0.4), Vector3(x, 1.2, 5.05), "stone_dark")
	var arch := MeshKit.cylinder(cutaway, 1.12, 1.12, 0.4, Vector3(0, 2.4, 5.05), "stone_dark", 16)
	arch.rotation.x = PI / 2.0
	arch.scale = Vector3(1.0, 1.0, 0.55)
	MeshKit.roof(cutaway, 7.8, 2.6, 10.8, Vector3(0, 4.7, 0), "roof_slate")
	MeshKit.cylinder(cutaway, 0.5, 0.5, 0.06, Vector3(0, 4.2, 5.2), "glass", 12).rotation.x = PI / 2.0
	# Bell tower behind the nave, visible over the roof from the village.
	MeshKit.box(self, Vector3(2.2, 7.0, 2.2), Vector3(0, 3.5, -6.2), "stone", true)
	MeshKit.cone(self, 1.7, 2.6, Vector3(0, 8.3, -6.2), "roof_slate", 4).rotation.y = PI / 4.0
	MeshKit.sphere(self, 0.35, Vector3(0, 6.2, -5.0), "gold", Vector3(1, 1.1, 1), 8, 4)
	MeshKit.box(self, Vector3(0.16, 1.2, 0.16), Vector3(0, 10.2, -6.2), "gold")
	MeshKit.box(self, Vector3(0.7, 0.16, 0.16), Vector3(0, 10.4, -6.2), "gold")
	MeshKit.box(self, Vector3(2.4, 0.2, 1.4), Vector3(0, 0.1, 5.9), "stone")

	# Atrium: rug, child-height work table, shelves.
	Props.place(self, "rug_oval", Vector3(0, 0.1, 0.6))
	Props.place(self, "table_low", Vector3(0, 0.1, 0.6))
	MeshKit.box(self, Vector3(1.2, 0.01, 0.75), Vector3(0, 0.44, 0.6), "felt_blue")
	_shelf(Vector3(-2.95, 0, -0.6), 4.0)
	_shelf(Vector3(2.95, 0, -0.6), 4.0)
	_decor_shelf_items(Vector3(2.95, 0, -0.6))
	_material_trays()

	# Prayer corner at the north end.
	MeshKit.box(self, Vector3(1.4, 0.6, 0.7), Vector3(0, 0.3, -4.1), "wood", true)
	MeshKit.box(self, Vector3(1.5, 0.04, 0.8), Vector3(0, 0.62, -4.1), "cloth_green")
	MeshKit.box(self, Vector3(0.4, 0.08, 0.3), Vector3(-0.25, 0.68, -4.1), "roof_red")
	MeshKit.cylinder(self, 0.04, 0.04, 0.22, Vector3(0.35, 0.75, -4.1), "white", 8)
	MeshKit.box(self, Vector3(0.12, 1.3, 0.06), Vector3(0, 2.2, -4.82), "wood_dark")
	MeshKit.box(self, Vector3(0.7, 0.12, 0.06), Vector3(0, 2.45, -4.82), "wood_dark")
	Props.place(self, "cushion", Vector3(0, 0.1, -3.0))
	var sit := Interactable.create(self, Vector3(0, 0, -2.8), "Sit quietly", func() -> void:
		get_tree().call_group("main", "sit_quietly", position + Vector3(0, 1.2, -4.3)), 0.5, 1.2)
	sit.reach = 1.5

	light = OmniLight3D.new()
	light.position = Vector3(0, 2.8, 0)
	light.light_color = Color("ffd9a0")
	light.omni_range = 8.0
	light.light_energy = 0.0
	light.add_to_group("chapel_light")
	add_child(light)

	# Outside.
	for f: Array in [[-2.6, 6.2, "flowers_a"], [-2.0, 7.0, "flowers_b"], [2.4, 6.3, "flowers_b"], [3.0, 7.0, "flowers_a"], [-3.6, 5.6, "bush_flowers"], [3.6, 5.4, "bush"]]:
		Props.place(self, f[2], Vector3(f[0], 0, f[1]), f[0])
	# Stepping stones from the village path up to the door.
	for i in 3:
		Props.place(self, "stepping_stone" if i % 2 == 0 else "stepping_stone_b", Vector3(0.1 * (i % 2), 0, 7.2 + i * 1.0), i * 0.7)
	Props.place(self, "tree_a", Vector3(-6, 0, 3), 0.7)
	Props.place(self, "tree_b", Vector3(-6.5, 0, -4), 0.2)
	MeshKit.box(self, Vector3(1.6, 0.45, 0.5), Vector3(4.5, 0.22, 5.5), "wood", true)

	add_clearing(Vector3(0, 0, 0), Vector2(7.8, 10.8))
	add_clearing(Vector3(0, 0, -6.2), Vector2(2.8, 2.8))
	road(Vector3(0, 0, 5.6), Vector3(0, 0, 6.2), 2.4)
	clearings.append({"a": Vector2(position.x, position.z + 6.5), "b": Vector2(position.x, position.z + 10.0), "width": 1.6})
	add_anchor("chapel_door", Vector3(0, 0, 7.2), 0.0)
	add_discovery_zone(Vector3(0, 1, 2), Vector3(12, 3, 16))
	add_interior("chapel", Vector3(0, 1.5, -0.2), Vector3(6.6, 3, 9.4), [cutaway])
	add_camera_zone(Vector3(0, 1.5, -0.2), Vector3(6.6, 3, 9.4), {"pitch": 56.0, "distance": 9.5, "fov": 40.0})


## Tall pointed window with three bands of coloured glass and a stone surround.
func _lancet_window(at: Vector3, side: float) -> void:
	var bands := ["glass_blue", "glass_gold", "glass_red"]
	for i in 3:
		MeshKit.box(self, Vector3(0.08, 0.5, 0.56), at + Vector3(0, 1.3 + i * 0.52, 0), bands[i])
	var tip := MeshKit.box(self, Vector3(0.08, 0.38, 0.38), at + Vector3(0, 2.95, 0), "glass_gold")
	tip.rotation.x = PI / 4.0
	for dz: float in [-0.34, 0.34]:
		MeshKit.box(self, Vector3(0.12, 1.75, 0.1), at + Vector3(side * 0.02, 1.83, dz), "stone_dark")
	MeshKit.box(self, Vector3(0.16, 0.1, 0.8), at + Vector3(side * 0.03, 1.0, 0), "stone_dark")


func _shelf(at: Vector3, length: float) -> void:
	MeshKit.box(self, Vector3(0.6, 0.85, length), at + Vector3(0, 0.43, 0), "wood", true)
	MeshKit.box(self, Vector3(0.62, 0.04, length), at + Vector3(0, 0.45, 0), "wood_dark")


func _decor_shelf_items(at: Vector3) -> void:
	MeshKit.cylinder(self, 0.12, 0.1, 0.2, at + Vector3(0, 0.95, -1.4), "roof_red", 8)
	MeshKit.sphere(self, 0.2, at + Vector3(0, 1.15, -1.4), "leaf", Vector3.ONE, 7, 4)
	Props.place(self, "books", at + Vector3(0, 0.87, 0.2), -PI / 2.0)
	Props.place(self, "jar", at + Vector3(0, 0.87, 1.2))


## One tray per material listed in content/world/atrium_shelf.json.
func _material_trays() -> void:
	var items: Array = Content.get_world("atrium_shelf").get("items", [])
	for i in items.size():
		var item: Dictionary = items[i]
		var at := Vector3(-2.95, 0.88, -2.0 + i * 1.3)
		MeshKit.box(self, Vector3(0.5, 0.06, 0.8), at, "wood_light")
		MeshKit.box(self, Vector3(0.44, 0.02, 0.7), at + Vector3(0, 0.04, 0), item.get("tray_color", "cloth_cream"))
		for k in 3:
			MeshKit.cylinder(self, 0.04, 0.05, 0.16, at + Vector3(-0.1 + k * 0.1, 0.13, -0.15 + k * 0.12), ["cloth_cream", "cloth_red", "cloth_blue"][k], 6)
		var activity_id := str(item["activity"])
		var use := Interactable.create(self, at + Vector3(0.9, -0.88, 0), "Choose %s" % tr(str(item.get("label", activity_id))), func() -> void:
			get_tree().call_group("main", "start_activity_here", activity_id, position + Vector3(0, 0.6, 0.6)), 0.5, 1.5)
		use.reach = 1.5
