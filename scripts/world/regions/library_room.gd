class_name LibraryRoom
extends RoomRegion
## Bellhaven's library: tall bookcases all round, reading tables and a quiet
## corner with a rug, where Sam helps on winter afternoons. Entered from the
## high street (the door under the "Library" sign).


func build() -> void:
	floor_color = "wood_light"
	wall_color = "plaster_warm"
	room(Vector2(12, 9), "city_library_door", "Go back out to the street")
	window(Vector3(-2.6, 2.0, -4.48))
	window(Vector3(2.6, 2.0, -4.48))
	# Bookcases along the back wall and down both sides.
	for x: float in [-5.0, -3.9, 0.0, 3.9, 5.0]:
		Props.place(self, "bookcase_tall", Vector3(x, 0, -4.05), 0.0)
	for z: float in [-2.6, -1.2, 0.2]:
		Props.place(self, "bookcase_tall", Vector3(-5.6, 0, z), PI / 2.0)
		Props.place(self, "bookcase_tall", Vector3(5.6, 0, z), -PI / 2.0)
	# Two reading tables with books open on them.
	for t: Vector3 in [Vector3(-2.2, 0, -1.4), Vector3(2.2, 0, -1.4)]:
		Props.place(self, "table", t, 0.0)
		Props.place(self, "chair", t + Vector3(-0.9, 0, 0), PI / 2.0)
		Props.place(self, "chair", t + Vector3(0.9, 0, 0), -PI / 2.0)
		Props.place(self, "book_stack", t + Vector3(-0.3, 0.78, 0.1), 0.4)
		Props.place(self, "book", t + Vector3(0.3, 0.78, -0.1), 1.2)
		Props.place(self, "candle_stand", t + Vector3(0, 0, -1.0), 0.0)
	# The little ones' reading corner: a rug, cushions, picture books on a stand.
	Props.place(self, "rug_oval", Vector3(-3.4, 0.01, 2.2), 0.0, 1.3)
	for c: Vector3 in [Vector3(-4.2, 0, 2.6), Vector3(-2.6, 0, 2.8), Vector3(-3.4, 0, 1.4)]:
		Props.place(self, "cushion", c, c.x)
	Props.place(self, "book_stand", Vector3(-4.6, 0, 1.0), 0.6)
	Props.place(self, "books", Vector3(3.6, 0, 2.6), 0.3)
	Props.place(self, "wall_lantern", Vector3(0, 2.4, -4.2), 0.0)
	Props.place(self, "picture", Vector3(5.7, 1.6, 2.4), -PI / 2.0)
	# Sam, and a reader at the table.
	var sam := {"skin": "skin_3", "hair": "hair_black", "hair_style": "short", "shirt": "cloth_green", "pants": "cloth_brown", "height": 0.98}
	passerby(sam, Vector3(-3.2, 0, 1.8), 1101, 1.2)
	var folk: Array = Content.get_world("characters").get("villagers", [])
	if folk.size() > 0:
		passerby(folk[1 % folk.size()], Vector3(2.0, 0, 0.2), 1102, 0.8)
	add_activity_focus(Vector3(0, 0.8, 0))
