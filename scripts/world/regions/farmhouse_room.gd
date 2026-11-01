class_name FarmhouseRoom
extends RoomRegion
## Mrs. Hannah's farmhouse kitchen at the farmlands: the hearth with the
## stew pot, the big table, the pantry shelves of jars and the store of
## apples and potatoes for the winter. Entered from the farm lane.


func build() -> void:
	floor_color = "wood_light"
	wall_color = "plaster_warm"
	room(Vector2(10, 7), "farmlands_house_door", "Go back out to the farm")
	window(Vector3(-2.4, 2.0, -3.48))
	window(Vector3(2.8, 2.0, -3.48))
	# The hearth, with the stew pot over the fire.
	MeshKit.box(self, Vector3(2.0, 1.6, 0.8), Vector3(0.2, 0.8, -3.1), "stone", true)
	MeshKit.box(self, Vector3(1.0, 0.7, 0.2), Vector3(0.2, 0.45, -2.68), "dark")
	Props.place(self, "stew_pot", Vector3(0.2, 0, -2.2), 0.0)
	var fire := OmniLight3D.new()
	fire.light_color = Color("ffa050")
	fire.light_energy = 0.7
	fire.omni_range = 3.0
	fire.position = Vector3(0.2, 0.6, -2.2)
	add_child(fire)
	# The kitchen table, with bread, cheese and a jug of milk.
	Props.place(self, "table", Vector3(-1.4, 0, 0.4), 0.0)
	for c: Vector3 in [Vector3(-2.3, 0, 0.4), Vector3(-0.5, 0, 0.4)]:
		Props.place(self, "chair", c, PI / 2.0 if c.x < -1.4 else -PI / 2.0)
	for f: Array in [["food_bread_round", Vector3(-1.6, 0.78, 0.3)], ["food_cheese_wheel", Vector3(-1.1, 0.78, 0.5)], ["jar", Vector3(-1.4, 0.78, 0.0)]]:
		Props.place(self, str(f[0]), f[1], 0.4)
	# The pantry wall: shelves of jars and honey, and the winter store.
	Props.place(self, "cabinet", Vector3(-4.4, 0, -1.6), PI / 2.0)
	Props.place(self, "wall_shelf_long", Vector3(-4.75, 1.5, 0.8), PI / 2.0)
	for j: Array in [["food_jam", Vector3(-4.6, 1.6, 0.4)], ["food_honey", Vector3(-4.6, 1.6, 1.0)], ["jar", Vector3(-4.6, 1.6, 1.4)]]:
		Props.place(self, str(j[0]), j[1], 0.0)
	for s: Array in [["apple_crate", Vector3(3.8, 0, -2.4)], ["apple_barrel", Vector3(4.2, 0, -1.2)], ["sack", Vector3(3.6, 0, 1.4)], ["carrot_crate", Vector3(4.0, 0, 0.2)]]:
		Props.place(self, str(s[0]), s[1], (s[1] as Vector3).z)
	for p: Array in [["food_pumpkin", Vector3(2.6, 0, -2.8)], ["food_potato", Vector3(3.2, 0, 1.0)], ["food_onion", Vector3(2.9, 0, 1.3)]]:
		Props.place(self, str(p[0]), p[1], 0.5)
	Props.place(self, "rug_stripes", Vector3(1.6, 0.01, 1.0), 0.0)
	Props.place(self, "wall_lantern", Vector3(2.8, 2.4, -3.2), 0.0)
	passerby(World.look_for("hannah"), Vector3(1.0, 0, -0.6), 1203, 0.8)
	add_activity_focus(Vector3(0, 0.8, 0))
