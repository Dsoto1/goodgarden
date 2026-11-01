class_name ShepherdHut
extends RoomRegion
## Mr. Silas's hut on the mountain meadow: small and snug, with a stone
## hearth, a bunk, his crook and lantern, fleeces and the stores that keep
## him through the weather. Entered from the meadow by his camp.


func build() -> void:
	floor_color = "wood_dark"
	wall_color = "stone"
	trim_color = "wood_dark"
	room(Vector2(8, 6), "mountains_hut_door", "Go back out to the meadow")
	window(Vector3(1.8, 2.0, -2.98), Vector2(0.9, 0.8))
	# The hearth in the corner, with the kettle on.
	MeshKit.box(self, Vector3(1.6, 1.4, 0.8), Vector3(-2.6, 0.7, -2.6), "stone_dark", true)
	Props.place(self, "cooking_pot", Vector3(-2.6, 0, -1.9), 0.0)
	var fire := OmniLight3D.new()
	fire.light_color = Color("ffa050")
	fire.light_energy = 0.7
	fire.omni_range = 3.0
	fire.position = Vector3(-2.6, 0.6, -1.9)
	add_child(fire)
	# His bunk along the side wall, with a fleece and a blanket.
	Props.place(self, "bed", Vector3(3.0, 0, -1.0), -PI / 2.0)
	MeshKit.box(self, Vector3(0.9, 0.08, 0.7), Vector3(2.0, 0.04, 0.4), "cloth_cream")
	# A little table and stool, and the stores on shelves and in sacks.
	Props.place(self, "table_low", Vector3(0.0, 0, -0.6), 0.0)
	Props.place(self, "stool", Vector3(0.0, 0, 0.4), 0.0)
	Props.place(self, "cooking_pot", Vector3(0.1, 0.45, -0.6), 0.0, 0.5)
	Props.place(self, "wall_shelf", Vector3(-3.75, 1.4, 0.4), PI / 2.0)
	for s: Array in [["sack", Vector3(-3.2, 0, 1.6)], ["crate", Vector3(-3.4, 0, 0.6)], ["firewood", Vector3(-1.2, 0, -2.6)], ["wood_chest", Vector3(1.0, 0, -2.6)]]:
		Props.place(self, str(s[0]), s[1], (s[1] as Vector3).x * 0.3)
	Props.place(self, "wall_lantern", Vector3(0.6, 2.2, -2.7), 0.0)
	passerby(World.look_for("silas"), Vector3(1.4, 0, 0.4), 1204, 0.6)
	add_activity_focus(Vector3(0, 0.8, 0))
