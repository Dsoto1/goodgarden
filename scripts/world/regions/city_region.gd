class_name CityRegion
extends FarRegion
## Bellhaven: the market street inside the city's south gate. Houses and
## shops close round a cobbled street that climbs to the cathedral, with
## the castle on its hill beyond. Mrs. Greta keeps the spice and cloth stall,
## and the library stands by the street.


func build() -> void:
	area = Rect2(-13, -15, 26, 30)
	lay_ground(Vector3(0, 0, 12.5), 0.0)
	# The cobbled street, north to the cathedral steps.
	path([Vector3(0, 0, 15.0), Vector3(0.4, 0, 6.0), Vector3(-0.3, 0, -3.0), Vector3(0, 0, -11.5)], 6.5, "cobble")
	path([Vector3(-6.5, 0, -4.0), Vector3(6.5, 0, -4.0)], 4.0, "cobble")
	# The city wall behind, with its gate standing open to the cathedral.
	Props.place(self, "cathedral", Vector3(0, 0, -22), 0.0)
	for x: float in [-11.0, -5.6, 5.6, 11.0]:
		Props.place(self, "city_wall", Vector3(x, 0, -14.6), 0.0)
	Props.place(self, "city_gate", Vector3(0, 0, -14.6), 0.0)
	Props.place(self, "tower_red", Vector3(-15.5, 0, -15.5), 0.0)
	Props.place(self, "tower_blue", Vector3(15.5, 0, -15.5), 0.0)
	# Houses and shops along both sides, fronts to the street.
	var west := [["house_tall_red", -9.0, 8.5], ["tavern_red", -9.5, 1.5], ["house_b_yellow", -9.0, -8.0]]
	var east := [["house_b_blue", 9.0, 8.5], ["tower_blue", 9.5, 1.2], ["house_yellow", 9.0, -8.0]]
	for h: Array in west:
		Props.place(self, str(h[0]), Vector3(h[1], 0, h[2]), PI / 2.0)
	for h: Array in east:
		Props.place(self, str(h[0]), Vector3(h[1], 0, h[2]), -PI / 2.0)
	_sign(Vector3(6.6, 3.2, 1.2), -PI / 2.0, "Library")
	_sign(Vector3(-6.7, 3.0, 1.5), PI / 2.0, "The Bell Inn")
	# Market stalls along the street.
	_stall(Vector3(-4.2, 0, 4.0), PI / 2.0, "awning_red", ["crate_carrots", "crate_lettuce"])
	_stall(Vector3(4.2, 0, 4.0), -PI / 2.0, "awning_blue", ["crate_open", "crate_carrots"])
	_stall(Vector3(4.2, 0, -1.6), -PI / 2.0, "awning_green", ["crate_lettuce", "crate_open"])
	for p: Array in [["barrel", Vector3(-5.8, 0, 6.8)], ["crate_big", Vector3(-6.0, 0, 5.6)], ["crate_long", Vector3(6.2, 0, 6.4)], ["barrel", Vector3(6.0, 0, -3.4)], ["sack", Vector3(-5.6, 0, -2.0)]]:
		Props.place(self, str(p[0]), p[1], 0.3)
	Props.place(self, "well", Vector3(-3.2, 0, -6.4), 0.4, 0.9)
	for f: Array in [["flag_red", Vector3(-3.6, 0, -12.5)], ["flag_blue", Vector3(3.6, 0, -12.5)], ["flag_red", Vector3(-6.5, 0, 12.0)], ["flag_blue", Vector3(6.5, 0, 12.0)]]:
		Props.place(self, str(f[0]), f[1], 0.0)
	# Townsfolk about their day.
	var folk: Array = Content.get_world("characters").get("villagers", [])
	var spots := [Vector3(-1.6, 0, 7.0), Vector3(2.0, 0, 0.0), Vector3(-2.2, 0, -5.0), Vector3(1.8, 0, -9.0), Vector3(-1.0, 0, 2.5)]
	for i in spots.size():
		if folk.size() > 0:
			passerby(folk[(i + 2) % folk.size()], spots[i], 600 + i, 2.0)
	neighbour("greta", Vector3(-2.8, 0, 4.0), 0.6)
	add_anchor("city_greta", Vector3(-2.8, 0, 4.0), PI / 2.0)
	add_clearing(Vector3(0, 0, 0), Vector2(14, 28))
	add_activity_focus(Vector3(0, 0.8, 2.0))


## A hanging shop sign with the shop's name.
func _sign(at: Vector3, rot: float, text: String) -> void:
	var board := Node3D.new()
	board.position = at
	board.rotation.y = rot
	add_child(board)
	MeshKit.box(board, Vector3(1.6, 0.42, 0.05), Vector3.ZERO, "wood_light")
	var l := Label3D.new()
	l.text = tr(text)
	l.font = UiStyle.font()
	l.font_size = 56
	l.pixel_size = 0.0055
	l.modulate = Color("3b3430")
	l.outline_size = 0
	l.position = Vector3(0, 0, 0.04)
	board.add_child(l)


## A market stall: counter, goods and a striped awning, front facing +Z
## before turning by `rot`.
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
	for i in goods.size():
		Props.place(root, str(goods[i]), Vector3(-0.45 + i * 0.9, 0.8, 0.05), 0.0, 0.75)
