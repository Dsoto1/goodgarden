class_name ShipCabin
extends RoomRegion
## Captain Mara's cabin aboard her ship: dark timber, round portholes on the
## sea, the captain's table with her charts, a hammock, sea chests and
## barrels. Entered from the end of the quay, where the ship lies alongside.


func build() -> void:
	floor_color = "wood"
	wall_color = "wood_dark"
	trim_color = "wood"
	room(Vector2(10, 7), "coast_ship_door", "Go back ashore")
	# Round portholes looking out at the sea.
	for x: float in [-3.0, 0.0, 3.0]:
		MeshKit.cylinder(self, 0.42, 0.42, 0.1, Vector3(x, 2.0, -3.46), "wood", 14).rotation.x = PI / 2.0
		MeshKit.cylinder(self, 0.32, 0.32, 0.12, Vector3(x, 2.0, -3.45), "glass_blue", 14).rotation.x = PI / 2.0
	# Curved ribs of the hull along the walls.
	for z: float in [-2.4, -0.8, 0.8, 2.4]:
		for side: float in [-1.0, 1.0]:
			MeshKit.box(self, Vector3(0.14, 3.2, 0.2), Vector3(side * 4.85, 1.6, z), "wood")
	# The captain's table, her chart spread on it, a lantern above.
	Props.place(self, "table", Vector3(0, 0, -1.4), 0.0, 1.2)
	MeshKit.box(self, Vector3(1.1, 0.02, 0.8), Vector3(0, 0.95, -1.4), "cloth_cream")
	for k in 4:
		MeshKit.box(self, Vector3(0.9, 0.025, 0.012), Vector3(0, 0.965, -1.7 + k * 0.2), "wood_dark")
	Props.place(self, "chair", Vector3(0, 0, -2.4), 0.0)
	Props.place(self, "wall_lantern", Vector3(0, 2.6, -3.2), 0.0)
	# A sailor's bedroll by the hull, sea chests, barrels and rope.
	Props.place(self, "bedroll", Vector3(-3.6, 0, 1.4), 0.2)
	for p: Array in [["sea_chest", Vector3(3.6, 0, -2.6)], ["sea_chest", Vector3(-3.8, 0, -2.6)], ["barrel", Vector3(3.9, 0, 1.4)],
			["barrel", Vector3(3.3, 0, 2.2)], ["rope_coil", Vector3(2.0, 0, 2.4)], ["crate_bottles", Vector3(-1.8, 0, 2.6)]]:
		Props.place(self, str(p[0]), p[1], (p[1] as Vector3).x)
	Props.place(self, "food_salmon", Vector3(3.9, 1.0, 1.4), 0.4)
	Props.place(self, "rug_oval", Vector3(0, 0.01, 1.0), 0.0, 1.1)
	# A sailor at work.
	var sailor := {"skin": "skin_3", "hair": "hair_dark", "hair_style": "short", "shirt": "cloth_blue", "pants": "cloth_tan", "height": 1.02}
	passerby(sailor, Vector3(2.2, 0, 0.6), 1301, 0.8)
	add_activity_focus(Vector3(0, 0.9, -1.4))
