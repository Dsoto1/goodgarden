class_name CityRegion
extends FarRegion
## Bellhaven: inside the city's south gate. A long cobbled high street runs
## north between houses and shops to a market square with a fountain, and on
## to the inner wall and gate, with the cathedral and the castle beyond.
## Mrs. Greta keeps her stall in the square; the library stands on the street.


func build() -> void:
	area = Rect2(-19, -22, 38, 43)
	lay_ground(Vector3(0, 0, 17.5), 0.0)
	# The high street, and the market square it opens into.
	path([Vector3(0, 0, 21.0), Vector3(0.4, 0, 12.0), Vector3(-0.3, 0, 4.0), Vector3(0, 0, -2.0)], 6.0, "cobble")
	path([Vector3(-10.0, 0, -7.0), Vector3(10.0, 0, -7.0)], 11.0, "cobble")
	path([Vector3(0, 0, -12.0), Vector3(0, 0, -19.5)], 5.0, "cobble")
	add_clearing(Vector3(0, 0, -7.0), Vector2(21, 12))
	add_clearing(Vector3(0, 0, 8.0), Vector2(7, 28))
	# The inner wall and its open gate, the cathedral and towers beyond.
	Props.place(self, "cathedral", Vector3(0, 0, -33.0), 0.0, 1.1)
	for x: float in [-16.5, -11.0, -5.6, 5.6, 11.0, 16.5]:
		Props.place(self, "city_wall", Vector3(x, 0, -20.5), 0.0)
	Props.place(self, "city_gate", Vector3(0, 0, -20.5), 0.0)
	Props.place(self, "tower_red", Vector3(-21.5, 0, -21.0), 0.0)
	Props.place(self, "tower_blue", Vector3(21.5, 0, -21.0), 0.0)
	for f: Array in [["flag_red", Vector3(-3.6, 0, -18.6)], ["flag_blue", Vector3(3.6, 0, -18.6)], ["flag_red", Vector3(-4.2, 0, 19.0)], ["flag_blue", Vector3(4.2, 0, 19.0)]]:
		Props.place(self, str(f[0]), f[1], 0.0)
	# Houses and shops, fronts to the street and the square.
	var west := [["house_tall_red", 15.0], ["tavern_red", 6.5], ["house_b_yellow", -2.5], ["market_red", -11.5]]
	var east := [["house_b_blue", 15.0], ["tower_blue", 6.5], ["house_blue", -2.5], ["tavern_yellow", -11.5]]
	for h: Array in west:
		Props.place(self, str(h[0]), Vector3(-14.5, 0, h[1]), PI / 2.0)
	for h: Array in east:
		Props.place(self, str(h[0]), Vector3(14.5, 0, h[1]), -PI / 2.0)
	_sign(Vector3(11.6, 3.2, 6.5), -PI / 2.0, "Library")
	_sign(Vector3(-11.7, 3.0, 6.5), PI / 2.0, "The Bell Inn")
	# The square: fountain in the middle, stalls round it.
	Props.place(self, "town_fountain", Vector3(0, 0, -7.0), 0.0, 1.5)
	_stall(Vector3(-7.0, 0, -3.0), PI / 2.0, "awning_red", ["crate_carrots", "crate_lettuce"])
	Props.place(self, "stall_green", Vector3(7.0, 0, -3.0), -PI / 2.0)
	Props.place(self, "stall_red", Vector3(-7.0, 0, -11.0), PI / 2.0)
	_stall(Vector3(7.0, 0, -11.0), -PI / 2.0, "awning_blue", ["crate_open", "crate_carrots"])
	Props.place(self, "market_cart", Vector3(-4.5, 0, 9.5), PI / 2.0)
	for p: Array in [["apple_crate", Vector3(-7.4, 0.78, -2.6)], ["coin_pile", Vector3(-6.6, 0.82, -3.6)], ["apple_barrel", Vector3(8.8, 0, -1.2)],
			["carrot_crate", Vector3(-9.0, 0, -4.6)], ["barrel", Vector3(9.4, 0, -12.6)], ["crate_big", Vector3(-9.2, 0, -12.4)], ["sack", Vector3(9.0, 0, -9.4)],
			["crate_long", Vector3(5.0, 0, 13.0)], ["barrel", Vector3(-5.2, 0, 13.6)]]:
		Props.place(self, str(p[0]), p[1], 0.3)
	for l: Vector3 in [Vector3(-3.6, 0, 16.0), Vector3(3.6, 0, 16.0), Vector3(-3.6, 0, 6.0), Vector3(3.6, 0, 6.0), Vector3(-9.5, 0, -13.5), Vector3(9.5, 0, -13.5)]:
		Props.place(self, "lantern_post", l, 0.0)
	for b: Array in [[Vector3(-3.4, 0, -12.6), 0.0], [Vector3(3.4, 0, -12.6), 0.0]]:
		Props.place(self, "garden_bench", b[0], b[1])
	Props.place(self, "well", Vector3(10.5, 0, 11.0), 0.4, 0.9)
	# Townsfolk about their day.
	var folk: Array = Content.get_world("characters").get("villagers", [])
	var spots := [Vector3(-1.6, 0, 11.0), Vector3(2.0, 0, 2.0), Vector3(-3.2, 0, -9.0), Vector3(3.0, 0, -5.0), Vector3(-1.0, 0, -15.0), Vector3(1.5, 0, 16.0)]
	for i in spots.size():
		if folk.size() > 0:
			passerby(folk[(i + 2) % folk.size()], spots[i], 600 + i, 2.5)
	neighbour("greta", Vector3(-5.2, 0, -3.0), 0.6)
	add_anchor("city_greta", Vector3(-5.2, 0, -3.0), PI / 2.0)
	add_activity_focus(Vector3(0, 0.8, -4.0))


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
