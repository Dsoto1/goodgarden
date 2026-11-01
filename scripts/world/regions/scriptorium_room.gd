class_name ScriptoriumRoom
extends RoomRegion
## The monastery scriptorium: stone walls and tall windows, writing desks
## with candles, old books and scrolls, where the brothers copy books by
## hand. Entered from the cloister (the door of the yellow house by the church).


func build() -> void:
	floor_color = "stone"
	wall_color = "stone"
	trim_color = "wood_dark"
	room(Vector2(12, 9), "monastery_scriptorium_door", "Go back out to the cloister")
	for x: float in [-3.6, 0.0, 3.6]:
		window(Vector3(x, 2.1, -4.48), Vector2(0.9, 1.5))
	# Writing desks in a row under the windows, each with a candle and a book.
	for x: float in [-3.6, 0.0, 3.6]:
		var desk := Vector3(x, 0, -2.6)
		MeshKit.box(self, Vector3(1.4, 0.08, 0.7), desk + Vector3(0, 0.78, 0), "wood")
		for dx: float in [-0.6, 0.6]:
			MeshKit.box(self, Vector3(0.08, 0.78, 0.6), desk + Vector3(dx, 0.39, 0), "wood_dark")
		MeshKit.solid(self, Vector3(1.4, 0.9, 0.7), desk + Vector3(0, 0.45, 0))
		MeshKit.box(self, Vector3(0.5, 0.02, 0.36), desk + Vector3(-0.2, 0.83, 0), "cloth_cream")
		MeshKit.cylinder(self, 0.04, 0.05, 0.08, desk + Vector3(0.4, 0.86, 0.1), "dark", 6)
		Props.place(self, "book_stack", desk + Vector3(0.45, 0.82, -0.15), 0.3)
		Props.place(self, "candle_stand", desk + Vector3(0.9, 0, 0.3), 0.0)
		Props.place(self, "stool", desk + Vector3(0, 0, 0.75), 0.0)
	# Shelves of old books down the sides, a long table of scrolls in the middle.
	for z: float in [-1.4, 0.2, 1.8]:
		Props.place(self, "bookcase_tall", Vector3(-5.6, 0, z), PI / 2.0)
		Props.place(self, "bookcase_tall", Vector3(5.6, 0, z), -PI / 2.0)
	Props.place(self, "long_table", Vector3(0, 0, 0.6), 0.0)
	for k in 3:
		Props.place(self, "scroll", Vector3(-0.8 + k * 0.8, 0.82, 0.6), k * 0.9)
	Props.place(self, "book_stand", Vector3(3.6, 0, 1.8), -0.4)
	Props.place(self, "wood_chest", Vector3(-3.8, 0, 2.6), 0.2)
	Props.place(self, "rug_stripes", Vector3(0, 0.01, 2.4), 0.0)
	# Brothers at their copying.
	var robe := {"skin": "skin_2", "hair": "hair_grey", "hair_style": "cropped", "shirt": "monk_brown", "pants": "monk_brown", "apron": "monk_brown", "height": 1.0}
	passerby(robe, Vector3(-3.6, 0, -1.6), 1201, 0.4)
	var robe2 := robe.duplicate()
	robe2["skin"] = "skin_4"
	robe2["hair"] = "hair_dark"
	passerby(robe2, Vector3(3.6, 0, -1.6), 1202, 0.4)
	add_activity_focus(Vector3(0, 0.8, -1.0))
