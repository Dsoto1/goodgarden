class_name MonasteryRegion
extends FarRegion
## The monastery on its hill east of the valley: the abbey church, a walled
## cloister garden with a fountain and herb beds, tall dark cypresses, and
## Brother Elias at his writing desk in the shade, who copies the old books
## and keeps the old maps.


func build() -> void:
	area = Rect2(-18, -18, 36, 36)
	lay_ground(Vector3(0, 0, 16.0), 0.0)
	# An avenue of cypresses up to the cloister gate, the church beyond.
	path([Vector3(0, 0, 17.5), Vector3(0, 0, 8.5), Vector3(0, 0, 2.0), Vector3(0, 0, -8.0)], 2.2, "path")
	path([Vector3(-6.2, 0, 2.0), Vector3(6.2, 0, 2.0)], 1.6, "path")
	path([Vector3(1.0, 0, 11.0), Vector3(9.0, 0, 11.0)], 1.6, "path")
	path([Vector3(-1.0, 0, 11.0), Vector3(-9.0, 0, 11.0)], 1.4, "path")
	for z: float in [9.5, 12.5, 15.5]:
		_cypress(Vector3(-2.2, 0, z))
		_cypress(Vector3(2.2, 0, z))
	Props.place(self, "church_yellow", Vector3(0, 0, -12.5), 0.0, 1.45)
	Props.place(self, "house_b_yellow", Vector3(-12.5, 0, -9.0), PI / 2.0)
	Props.place(self, "house_yellow", Vector3(-12.5, 0, -1.0), PI / 2.0)
	Props.place(self, "tower_blue", Vector3(12.0, 0, -10.5), 0.0, 0.8)
	# The cloister garden: low stone walls, gravel walks and herb beds.
	for wall: Array in [[Vector3(-7, 0, -4), Vector3(-1.4, 0, -4)], [Vector3(1.4, 0, -4), Vector3(7, 0, -4)],
			[Vector3(-7, 0, -4), Vector3(-7, 0, 7)], [Vector3(7, 0, -4), Vector3(7, 0, 7)],
			[Vector3(-7, 0, 7), Vector3(-1.4, 0, 7)], [Vector3(1.4, 0, 7), Vector3(7, 0, 7)]]:
		CraftedProps.stone_wall(self, wall[0], wall[1], int(wall[0].x * 10 + wall[0].z))
	Props.place(self, "town_fountain", Vector3(0, 0, 2.0), 0.0)
	add_clearing(Vector3(0, 0, 2.0), Vector2(3.6, 3.6))
	for v: Vector3 in [Vector3(-1.9, 0, -0.1), Vector3(1.9, 0, 4.1)]:
		Props.place(self, "clay_vase", v, v.x)
	for b: Array in [[Vector3(-5.6, 0, 2.0), PI / 2.0], [Vector3(5.6, 0, 2.0), -PI / 2.0]]:
		Props.place(self, "garden_bench", b[0], b[1])
	# Low hedges along the cloister walks.
	for h: Array in [[Vector3(-6.2, 0, 1.1), Vector3(-1.4, 0, 1.1)], [Vector3(1.4, 0, 1.1), Vector3(6.2, 0, 1.1)], [Vector3(-6.2, 0, 2.9), Vector3(-1.4, 0, 2.9)], [Vector3(1.4, 0, 2.9), Vector3(6.2, 0, 2.9)]]:
		Props.fence(self, "hedge", h[0], h[1])
	for bed: Vector3 in [Vector3(-3.8, 0, -1.2), Vector3(3.8, 0, -1.2), Vector3(-3.8, 0, 5.0), Vector3(3.8, 0, 5.0)]:
		MeshKit.box(self, Vector3(3.6, 0.22, 2.8), bed + Vector3(0, 0.11, 0), "soil")
		MeshKit.flowers(self, bed + Vector3(0, 0.22, 0), 1.1, 10, int(bed.x * 7 + bed.z))
		add_clearing(bed, Vector2(3.8, 3.0))
	# The brothers' vegetable garden to the west, with a well and a cart.
	for k in 3:
		var row := Vector3(-12.0, 0, 7.0 + k * 2.4)
		MeshKit.box(self, Vector3(6.0, 0.18, 1.2), row + Vector3(0, 0.09, 0), "soil")
		for j in 6:
			MeshKit.sphere(self, 0.24, row + Vector3(-2.5 + j, 0.3, 0), "leaf_light" if k % 2 == 0 else "pine", Vector3(1.0, 0.7, 1.0), 6, 4)
		add_clearing(row, Vector2(6.4, 1.6))
	Props.place(self, "well", Vector3(-12.0, 0, 3.4), 0.0, 0.8)
	Props.place(self, "carrot_crate", Vector3(-8.4, 0, 5.4), 0.4)
	Props.place(self, "wood_bucket", Vector3(-10.6, 0, 3.0), 0.0)
	# More cypresses round the church, and trees at the edge.
	for c: Vector3 in [Vector3(-7.0, 0, -15.0), Vector3(7.0, 0, -15.0), Vector3(-15.5, 0, -15.0), Vector3(15.5, 0, -2.0), Vector3(15.5, 0, 4.0)]:
		_cypress(c)
	ring_of_trees(["tree_a", "grove_b_small"], 12, 0.8, 41)
	# Brother Elias's writing desk under an awning, east of the gate.
	var desk := Vector3(10.0, 0, 9.4)
	MeshKit.box(self, Vector3(1.4, 0.08, 0.7), desk + Vector3(0, 0.78, 0), "wood")
	for x: float in [-0.6, 0.6]:
		MeshKit.box(self, Vector3(0.08, 0.78, 0.6), desk + Vector3(x, 0.39, 0), "wood_dark")
	MeshKit.box(self, Vector3(0.5, 0.02, 0.36), desk + Vector3(-0.2, 0.83, 0), "cloth_cream")
	MeshKit.cylinder(self, 0.04, 0.05, 0.08, desk + Vector3(0.4, 0.86, 0.1), "dark", 6)
	Props.place(self, "book_stack", desk + Vector3(0.45, 0.82, -0.15), 0.3)
	Props.place(self, "scroll", desk + Vector3(-0.5, 0.83, 0.18), 0.6)
	Props.place(self, "book_stand", desk + Vector3(1.6, 0, 0.3), -0.5)
	Props.place(self, "candle_stand", desk + Vector3(-1.8, 0, 0.6), 0.0)
	MeshKit.solid(self, Vector3(1.4, 0.9, 0.7), desk + Vector3(0, 0.45, 0))
	var awning := MeshKit.box(self, Vector3(2.4, 0.06, 1.6), desk + Vector3(0, 2.2, -0.2), "awning_red")
	awning.rotation.x = 0.2
	for x: float in [-1.1, 1.1]:
		MeshKit.box(self, Vector3(0.08, 2.2, 0.08), desk + Vector3(x, 1.1, -0.9), "wood_dark")
	Props.place(self, "bookcase_tall", desk + Vector3(-1.6, 0, -0.75), 0.0)
	Props.place(self, "bookcase_tall", desk + Vector3(1.6, 0, -0.75), 0.0)
	neighbour("elias", desk + Vector3(0.2, 0, -1.0), 0.4)
	add_anchor("monastery_elias", desk + Vector3(0.2, 0, -1.0), PI)
	# Monks at work in the gardens.
	var robe := {"skin": "skin_2", "hair": "hair_grey", "hair_style": "cropped", "shirt": "monk_brown", "pants": "monk_brown", "apron": "monk_brown", "height": 1.0}
	passerby(robe, Vector3(-4.0, 0, 2.0), 701, 2.2)
	var robe2 := robe.duplicate()
	robe2["skin"] = "skin_4"
	robe2["hair"] = "hair_dark"
	passerby(robe2, Vector3(-12.0, 0, 9.0), 702, 2.0)
	var robe3 := robe.duplicate()
	robe3["skin"] = "skin_3"
	robe3["hair"] = "hair_black"
	passerby(robe3, Vector3(4.0, 0, -7.0), 703, 2.5)
	SoundSpot.looping(self, "fountain", Vector3(0, 0.8, 2.0), 9.0, -10.0)
	add_activity_focus(desk + Vector3(0, 0.9, 0))


func _cypress(at: Vector3) -> void:
	MeshKit.cylinder(self, 0.12, 0.16, 1.2, at + Vector3(0, 0.6, 0), "trunk", 6)
	MeshKit.sphere(self, 0.9, at + Vector3(0, 3.0, 0), "pine", Vector3(0.75, 2.6, 0.75), 8, 6)
