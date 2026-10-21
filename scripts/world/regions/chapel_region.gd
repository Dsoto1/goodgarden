extends Region
## The village chapel with a children's Atrium inside: low shelves of
## Scripture materials, a work table, and a prayer corner. Entering shifts
## World into its quiet mood (light, sound, a calmer HUD). Nothing here is
## scored or timed.

var light: OmniLight3D


func build() -> void:
	# Three rooms: the Main Hall (the nave, for worship and prayer), the Atrium
	# to the east (the children's Scripture materials) and a small Library to
	# the west, joined by open doorways. Nave 7 x 10 m, door to the south.
	MeshKit.box(self, Vector3(7, 0.1, 10), Vector3(0, 0.05, 0), "wood_light")
	MeshKit.box(self, Vector3(7.2, 3.4, 0.25), Vector3(0, 1.7, -5), "stone", true)
	for side: float in [-1.0, 1.0]:
		# Side walls with a doorway into each wing.
		MeshKit.box(self, Vector3(0.25, 3.4, 4.1), Vector3(side * 3.5, 1.7, -2.95), "stone", true)
		MeshKit.box(self, Vector3(0.25, 3.4, 4.1), Vector3(side * 3.5, 1.7, 2.95), "stone", true)
		MeshKit.box(self, Vector3(0.25, 1.0, 1.8), Vector3(side * 3.5, 2.9, 0), "stone")
		for x: float in [-0.95, 0.95]:
			MeshKit.box(self, Vector3(0.36, 2.4, 0.16), Vector3(side * 3.5, 1.2, x), "stone_dark")
		for z: float in [-3.7, 3.7]:
			MeshKit.box(self, Vector3(0.4, 0.45, 2.6), Vector3(side * 3.6, 0.22, z), "stone_dark")
		for z: float in [-2.9, 3.1]:
			_lancet_window(Vector3(side * 3.64, 0, z), side)
		for z: float in [-4.3, 4.4]:
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
	_wing(cutaway, -1.0, 3.1) # Library
	_wing(cutaway, 1.0, 4.1) # Atrium

	_main_hall()
	_atrium(Vector3(5.55, 0, 0))
	_library(Vector3(-5.05, 0, 0))

	for at: Vector3 in [Vector3(0, 2.8, 0), Vector3(5.55, 2.4, 0), Vector3(-5.05, 2.4, 0)]:
		var l := OmniLight3D.new()
		l.position = at
		l.light_color = Color("ffd9a0")
		l.omni_range = 8.0 if at.x == 0.0 else 5.0
		l.light_energy = 0.0
		l.add_to_group("chapel_light")
		add_child(l)
		if light == null:
			light = l

	# Outside.
	for f: Array in [[-2.6, 6.2, "flowers_a"], [-2.0, 7.0, "flowers_b"], [2.4, 6.3, "flowers_b"], [3.0, 7.0, "flowers_a"], [-3.6, 5.6, "bush_flowers"], [6.4, 4.2, "bush"]]:
		Props.place(self, f[2], Vector3(f[0], 0, f[1]), f[0])
	# Stepping stones from the village path up to the door.
	for i in 3:
		Props.place(self, "stepping_stone" if i % 2 == 0 else "stepping_stone_b", Vector3(0.1 * (i % 2), 0, 7.2 + i * 1.0), i * 0.7)
	Props.place(self, "tree_a", Vector3(-8.6, 0, 4.6), 0.7)
	CraftedProps.birdbath(self, Vector3(-3.4, 0, 7.4))
	for side: float in [-1.0, 1.0]:
		CraftedProps.flower_pot(self, Vector3(side * 1.6, 0, 5.9), "flower_white", 1.1)
	Props.place(self, "tree_b", Vector3(-7.2, 0, -4.6), 0.2)
	MeshKit.box(self, Vector3(1.6, 0.45, 0.5), Vector3(5.4, 0.22, 4.3), "wood", true)

	add_clearing(Vector3(0.5, 0, 0), Vector2(15.2, 10.8))
	add_clearing(Vector3(0, 0, -6.2), Vector2(2.8, 2.8))
	path([Vector3(0, 0, 5.3), Vector3(0.1, 0, 6.4)], 2.4)
	clearings.append({"a": Vector2(position.x, position.z + 6.5), "b": Vector2(position.x, position.z + 10.0), "width": 1.6})
	add_anchor("chapel_door", Vector3(0, 0, 7.2), 0.0)
	add_discovery_zone(Vector3(0, 1, 2), Vector3(16, 3, 16))
	# One interior across all three rooms, so the roofs stay lifted while the
	# child walks between them.
	add_interior("chapel", Vector3(0, 1.5, -0.2), Vector3(6.6, 3, 9.4), [cutaway]).add_box(Vector3(5.55, 1.5, 0), Vector3(3.9, 3, 4.5)).add_box(Vector3(-5.05, 1.5, 0), Vector3(2.9, 3, 4.5))
	add_camera_zone(Vector3(0, 1.5, -0.2), Vector3(6.6, 3, 9.4), {"pitch": 56.0, "distance": 9.5, "fov": 44.0}).add_box(Vector3(5.55, 1.5, 0), Vector3(3.9, 3, 4.5)).add_box(Vector3(-5.05, 1.5, 0), Vector3(2.9, 3, 4.5))
	add_place_zone("chapel_hall", Vector3(0, 1.5, -0.2), Vector3(6.6, 3, 9.4))
	add_place_zone("atrium", Vector3(5.55, 1.5, 0), Vector3(3.7, 3, 4.4))
	add_place_zone("library", Vector3(-5.05, 1.5, 0), Vector3(2.7, 3, 4.4))


## A single-storey wing off one side of the nave (`side` -1 west, 1 east),
## `width` metres deep, with its own window and a roof that lifts away inside.
func _wing(cutaway: Node3D, side: float, width: float) -> void:
	var cx := side * (3.5 + width / 2.0)
	var outer := side * (3.5 + width)
	MeshKit.box(self, Vector3(width, 0.1, 4.8), Vector3(cx, 0.05, 0), "wood_light")
	MeshKit.box(self, Vector3(0.25, 3.0, 4.8), Vector3(outer, 1.5, 0), "stone", true)
	MeshKit.box(self, Vector3(width, 3.0, 0.25), Vector3(cx, 1.5, -2.4), "stone", true)
	MeshKit.box(cutaway, Vector3(width, 3.0, 0.25), Vector3(cx, 1.5, 2.4), "stone", true)
	MeshKit.box(self, Vector3(0.4, 0.45, 5.0), Vector3(outer + side * 0.1, 0.22, 0), "stone_dark")
	_lancet_window(Vector3(outer + side * 0.14, 0, 0), side)
	MeshKit.roof(cutaway, width + 0.5, 1.3, 5.4, Vector3(cx, 3.65, 0), "roof_slate")


## The Main Hall: pews either side of a red runner, the altar with its cross
## and candles, a lectern with the open Bible, and a cushion for sitting quietly.
func _main_hall() -> void:
	MeshKit.box(self, Vector3(1.0, 0.012, 7.4), Vector3(0, 0.11, 0.9), "cloth_red")
	for side: float in [-1.0, 1.0]:
		for z: float in [1.7, 3.1]:
			_pew(Vector3(side * 1.65, 0, z))
	# Altar.
	MeshKit.box(self, Vector3(3.2, 0.12, 1.6), Vector3(0, 0.16, -4.1), "stone")
	MeshKit.box(self, Vector3(1.4, 0.8, 0.7), Vector3(0, 0.6, -4.1), "wood", true)
	MeshKit.box(self, Vector3(1.5, 0.04, 0.8), Vector3(0, 1.02, -4.1), "white")
	MeshKit.box(self, Vector3(0.3, 0.42, 0.03), Vector3(0, 0.78, -3.7), "cloth_green")
	for x: float in [-0.5, 0.5]:
		MeshKit.cylinder(self, 0.06, 0.08, 0.06, Vector3(x, 1.07, -4.2), "gold", 8)
		MeshKit.cylinder(self, 0.035, 0.035, 0.3, Vector3(x, 1.25, -4.2), "white", 8)
		MeshKit.sphere(self, 0.03, Vector3(x, 1.43, -4.2), "lantern", Vector3(0.8, 1.4, 0.8), 6, 3)
	MeshKit.box(self, Vector3(0.42, 0.06, 0.3), Vector3(0, 1.07, -4.0), "roof_red")
	MeshKit.box(self, Vector3(0.12, 1.3, 0.06), Vector3(0, 2.4, -4.82), "wood_dark")
	MeshKit.box(self, Vector3(0.7, 0.12, 0.06), Vector3(0, 2.65, -4.82), "wood_dark")
	# Lectern with the open Bible.
	MeshKit.box(self, Vector3(0.12, 1.0, 0.12), Vector3(-2.0, 0.6, -3.0), "wood_dark")
	MeshKit.box(self, Vector3(0.5, 0.06, 0.4), Vector3(-2.0, 0.1, -3.0), "wood_dark")
	var top := MeshKit.box(self, Vector3(0.6, 0.05, 0.45), Vector3(-2.0, 1.15, -3.0), "wood")
	top.rotation.x = -0.35
	for x: float in [-0.13, 0.13]:
		var page := MeshKit.box(self, Vector3(0.25, 0.02, 0.34), Vector3(-2.0 + x, 1.19, -3.0), "white")
		page.rotation.x = -0.35
		page.rotation.z = -x * 0.6
	MeshKit.solid(self, Vector3(0.6, 1.2, 0.5), Vector3(-2.0, 0.6, -3.0))
	Props.place(self, "cushion", Vector3(0, 0.1, -3.0))
	var sit := Interactable.create(self, Vector3(0, 0, -2.6), "Sit quietly", func() -> void:
		get_tree().call_group("main", "sit_quietly", position + Vector3(0, 1.2, -4.3)), 0.5, 1.2)
	sit.reach = 1.5


func _pew(at: Vector3) -> void:
	MeshKit.box(self, Vector3(2.0, 0.08, 0.45), at + Vector3(0, 0.45, 0), "wood")
	MeshKit.box(self, Vector3(2.0, 0.5, 0.06), at + Vector3(0, 0.78, 0.22), "wood")
	for x: float in [-0.95, 0.95]:
		MeshKit.box(self, Vector3(0.07, 0.95, 0.5), at + Vector3(x, 0.48, 0.02), "wood_dark")
	MeshKit.solid(self, Vector3(2.0, 0.95, 0.55), at + Vector3(0, 0.48, 0.02))


## The Atrium: the shelf of Scripture materials and a low work table on a rug,
## everything at a child's height.
func _atrium(c: Vector3) -> void:
	# The work table sits to the south, leaving a clear way from the doorway
	# to the shelf.
	Props.place(self, "rug_oval", c + Vector3(-0.95, 0.1, 1.45))
	Props.place(self, "table_low", c + Vector3(-0.95, 0.1, 1.45))
	MeshKit.box(self, Vector3(1.2, 0.01, 0.75), c + Vector3(-0.95, 0.44, 1.45), "felt_blue")
	_shelf(c + Vector3(1.6, 0, 0), 4.0)
	_material_trays(c + Vector3(1.6, 0.88, 0))
	MeshKit.cylinder(self, 0.12, 0.1, 0.2, c + Vector3(-1.4, 0.15, -1.9), "roof_red", 8)
	MeshKit.sphere(self, 0.26, c + Vector3(-1.4, 0.45, -1.9), "leaf", Vector3.ONE, 8, 5)


## The Library: bookshelves, a reading nook with cushions and a lamp, and a
## shelf of books a child can open and have read aloud.
func _library(c: Vector3) -> void:
	for i in 2:
		CraftedProps.bookcase(self, c + Vector3(-0.72 + i * 1.38, 0.1, -1.98), PI, 7 + i)
	CraftedProps.bookcase(self, c + Vector3(-1.22, 0.1, 1.1), PI / 2.0, 3)
	Props.place(self, "rug_oval", c + Vector3(0.2, 0.1, 0.4))
	for p: Vector3 in [Vector3(-0.2, 0.1, 1.2), Vector3(0.6, 0.1, 1.4)]:
		Props.place(self, "cushion", c + p)
	# A small reading table with a lamp and a stack of books.
	var t := c + Vector3(-0.95, 0, -0.75)
	MeshKit.cylinder(self, 0.32, 0.32, 0.05, t + Vector3(0, 0.55, 0), "wood", 14)
	MeshKit.cylinder(self, 0.05, 0.08, 0.5, t + Vector3(0, 0.3, 0), "wood_dark", 8)
	MeshKit.cylinder(self, 0.04, 0.06, 0.3, t + Vector3(0.12, 0.72, -0.05), "gold", 8)
	MeshKit.cylinder(self, 0.08, 0.15, 0.14, t + Vector3(0.12, 0.92, -0.05), "lantern", 10)
	Props.place(self, "books", t + Vector3(-0.12, 0.58, 0.1), 0.4)
	MeshKit.solid(self, Vector3(0.7, 0.6, 0.7), t + Vector3(0, 0.3, 0))
	var read := Interactable.create(self, c + Vector3(0.1, 0, -0.2), "Choose a book", func() -> void:
		get_tree().call_group("main", "open_library"), 0.5, 1.3)
	read.reach = 1.6


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


## One tray per material listed in content/world/atrium_shelf.json, along a
## shelf running north-south and centred on `base`.
func _material_trays(base: Vector3) -> void:
	var items: Array = Content.get_world("atrium_shelf").get("items", [])
	for i in items.size():
		var item: Dictionary = items[i]
		var at := base + Vector3(0, 0, (i - (items.size() - 1) / 2.0) * 1.0)
		MeshKit.box(self, Vector3(0.5, 0.06, 0.8), at, "wood_light")
		MeshKit.box(self, Vector3(0.44, 0.02, 0.7), at + Vector3(0, 0.04, 0), item.get("tray_color", "cloth_cream"))
		for k in 3:
			MeshKit.cylinder(self, 0.04, 0.05, 0.16, at + Vector3(-0.1 + k * 0.1, 0.13, -0.15 + k * 0.12), ["cloth_cream", "cloth_red", "cloth_blue"][k], 6)
		var activity_id := str(item["activity"])
		var use := Interactable.create(self, at + Vector3(-0.9, -0.88, 0), "Choose %s" % tr(str(item.get("label", activity_id))), func() -> void:
			# The work happens at the Atrium's low table.
			get_tree().call_group("main", "start_activity_here", activity_id, position + Vector3(4.6, 0.6, 1.45)), 0.5, 1.5)
		use.reach = 1.5
