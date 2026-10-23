class_name MonasteryRegion
extends FarRegion
## The monastery on its hill east of the valley: the abbey church, a walled
## cloister garden with a fountain and herb beds, tall dark cypresses, and
## Brother Elias at his writing desk in the shade, who copies the old books
## and keeps the old maps.


func build() -> void:
	area = Rect2(-13, -13, 26, 26)
	lay_ground(Vector3(0, 0, 11.0), 0.0)
	Props.place(self, "church_yellow", Vector3(0, 0, -9.5), 0.0, 1.45)
	Props.place(self, "house_b_yellow", Vector3(-9.0, 0, -7.0), PI / 2.0)
	Props.place(self, "tower_blue", Vector3(9.0, 0, -8.0), 0.0, 0.8)
	# The cloister garden: low stone walls, gravel walks and herb beds.
	for wall: Array in [[Vector3(-7, 0, -3), Vector3(-1.4, 0, -3)], [Vector3(1.4, 0, -3), Vector3(7, 0, -3)],
			[Vector3(-7, 0, -3), Vector3(-7, 0, 6)], [Vector3(7, 0, -3), Vector3(7, 0, 6)],
			[Vector3(-7, 0, 6), Vector3(-1.4, 0, 6)], [Vector3(1.4, 0, 6), Vector3(7, 0, 6)]]:
		CraftedProps.stone_wall(self, wall[0], wall[1], int(wall[0].x * 10 + wall[0].z))
	path([Vector3(0, 0, 12.5), Vector3(0, 0, 6.5), Vector3(0, 0, 1.5), Vector3(0, 0, -5.5)], 2.0, "path")
	path([Vector3(-6.2, 0, 1.5), Vector3(6.2, 0, 1.5)], 1.6, "path")
	_fountain(Vector3(0, 0, 1.5))
	for bed: Vector3 in [Vector3(-3.8, 0, -0.6), Vector3(3.8, 0, -0.6), Vector3(-3.8, 0, 3.8), Vector3(3.8, 0, 3.8)]:
		MeshKit.box(self, Vector3(3.6, 0.22, 2.4), bed + Vector3(0, 0.11, 0), "soil")
		MeshKit.flowers(self, bed + Vector3(0, 0.22, 0), 1.0, 9, int(bed.x * 7 + bed.z))
		add_clearing(bed, Vector2(3.8, 2.6))
	# Cypresses: tall, narrow, dark.
	for c: Vector3 in [Vector3(-10.5, 0, 3), Vector3(-10.8, 0, 7.5), Vector3(10.5, 0, 3), Vector3(10.8, 0, 7.5), Vector3(-5.5, 0, -11.5), Vector3(5.5, 0, -11.5)]:
		_cypress(c)
	ring_of_trees(["tree_a", "grove_b_small"], 10, 0.8, 41)
	# Brother Elias's writing desk under an awning, by the garden gate.
	var desk := Vector3(3.6, 0, 8.4)
	MeshKit.box(self, Vector3(1.4, 0.08, 0.7), desk + Vector3(0, 0.78, 0), "wood")
	for x: float in [-0.6, 0.6]:
		MeshKit.box(self, Vector3(0.08, 0.78, 0.6), desk + Vector3(x, 0.39, 0), "wood_dark")
	MeshKit.box(self, Vector3(0.5, 0.02, 0.36), desk + Vector3(-0.2, 0.83, 0), "cloth_cream")
	MeshKit.cylinder(self, 0.04, 0.05, 0.08, desk + Vector3(0.4, 0.86, 0.1), "dark", 6)
	MeshKit.solid(self, Vector3(1.4, 0.9, 0.7), desk + Vector3(0, 0.45, 0))
	var awning := MeshKit.box(self, Vector3(2.4, 0.06, 1.6), desk + Vector3(0, 2.2, -0.2), "awning_red")
	awning.rotation.x = 0.2
	for x: float in [-1.1, 1.1]:
		MeshKit.box(self, Vector3(0.08, 2.2, 0.08), desk + Vector3(x, 1.1, -0.9), "wood_dark")
	CraftedProps.bookcase(self, desk + Vector3(-1.6, 0, -0.6), 0.0, 9)
	neighbour("elias", desk + Vector3(0.2, 0, -1.0), 0.4)
	add_anchor("monastery_elias", desk + Vector3(0.2, 0, -1.0), PI)
	# Monks at work in the garden.
	var robe := {"skin": "skin_2", "hair": "hair_grey", "hair_style": "cropped", "shirt": "monk_brown", "pants": "monk_brown", "apron": "monk_brown", "height": 1.0}
	passerby(robe, Vector3(-4.0, 0, 1.6), 701, 2.2)
	var robe2 := robe.duplicate()
	robe2["skin"] = "skin_4"
	robe2["hair"] = "hair_dark"
	passerby(robe2, Vector3(4.6, 0, -1.6), 702, 1.6)
	SoundSpot.looping(self, "fountain", Vector3(0, 0.8, 1.5), 9.0, -10.0)
	add_activity_focus(desk + Vector3(0, 0.9, 0))


func _fountain(at: Vector3) -> void:
	MeshKit.cylinder(self, 1.1, 1.2, 0.5, at + Vector3(0, 0.25, 0), "stone", 14, true)
	var pool := MeshKit.cylinder(self, 0.95, 0.95, 0.03, at + Vector3(0, 0.52, 0), "water", 14)
	pool.material_override = Palette.mat("water")
	MeshKit.cylinder(self, 0.16, 0.2, 1.0, at + Vector3(0, 0.8, 0), "stone", 8)
	MeshKit.cylinder(self, 0.45, 0.3, 0.14, at + Vector3(0, 1.3, 0), "stone", 10)
	add_clearing(at, Vector2(3.0, 3.0))


func _cypress(at: Vector3) -> void:
	MeshKit.cylinder(self, 0.12, 0.16, 1.2, at + Vector3(0, 0.6, 0), "trunk", 6)
	MeshKit.sphere(self, 0.9, at + Vector3(0, 3.0, 0), "pine", Vector3(0.75, 2.6, 0.75), 8, 6)
