class_name BakeryRoom
extends RoomRegion
## Mr. Tobias's bakery in the village: the big oven at the back, the kneading
## table floured for the day's dough, sacks of flour and shelves of loaves.
## Entered by the door under the "Bakery" sign.


func build() -> void:
	floor_color = "stone"
	wall_color = "plaster_warm"
	room(Vector2(10, 7), "village_bakery_door", "Go back out to the square")
	window(Vector3(-3.0, 2.0, -3.48))
	# The oven, warm and glowing, with wood stacked beside it.
	Props.place(self, "bread_oven", Vector3(1.6, 0, -2.6), 0.0)
	var glow := OmniLight3D.new()
	glow.light_color = Color("ffb060")
	glow.light_energy = 0.8
	glow.omni_range = 3.5
	glow.position = Vector3(1.6, 0.8, -1.8)
	add_child(glow)
	Props.place(self, "firewood", Vector3(3.6, 0, -2.8), 0.2)
	Props.place(self, "wood_bucket", Vector3(-0.2, 0, -3.0), 0.0)
	# The kneading table, with dough and the morning's loaves.
	Props.place(self, "long_table", Vector3(-1.2, 0, 0.0), 0.0)
	for f: Array in [["food_bread_round", Vector3(-2.4, 0.8, 0.0)], ["food_loaf", Vector3(-1.6, 0.8, 0.1)], ["food_baguette", Vector3(-0.6, 0.8, -0.1)],
			["food_pretzel", Vector3(0.2, 0.8, 0.1)], ["bowl", Vector3(-1.2, 0.8, 0.2)]]:
		Props.place(self, str(f[0]), f[1], (f[1] as Vector3).x)
	# Flour in sacks, and shelves of bread along the side walls.
	for s: Vector3 in [Vector3(-4.2, 0, -2.6), Vector3(-3.5, 0, -2.9), Vector3(-4.3, 0, -1.8)]:
		Props.place(self, "sack", s, s.z)
	Props.place(self, "wall_shelf_long", Vector3(-4.75, 1.4, 0.6), PI / 2.0)
	Props.place(self, "wall_shelf_long", Vector3(4.75, 1.4, 0.4), -PI / 2.0)
	for b: Array in [["food_bread_round", Vector3(-4.6, 1.5, 0.2)], ["food_loaf", Vector3(-4.6, 1.5, 1.0)], ["food_bread_round", Vector3(4.6, 1.5, 0.0)], ["food_pretzel", Vector3(4.6, 1.5, 0.8)]]:
		Props.place(self, str(b[0]), b[1], 0.3)
	Props.place(self, "crate", Vector3(3.8, 0, 1.6), 0.3)
	Props.place(self, "stool", Vector3(2.6, 0, 1.0), 0.0)
	Props.place(self, "wall_lantern", Vector3(-1.2, 2.4, -3.2), 0.0)
	passerby(World.look_for("tobias"), Vector3(1.2, 0, -0.8), 1201, 0.8)
	add_activity_focus(Vector3(0, 0.8, 0))
