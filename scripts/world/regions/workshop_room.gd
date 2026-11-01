class_name WorkshopRoom
extends RoomRegion
## Mr. Amos's workshop in the village: the long workbench under the window,
## tools on the wall, planks stacked and shavings on the floor. Entered by
## the door under the "Workshop" sign.


func build() -> void:
	floor_color = "wood_light"
	wall_color = "plaster"
	room(Vector2(10, 7), "village_workshop_door", "Go back out to the square")
	window(Vector3(-1.6, 2.0, -3.48), Vector2(2.2, 1.0))
	# The workbench under the window, with a half-made stool on it.
	Props.place(self, "camp_workbench", Vector3(-1.6, 0, -2.7), 0.0)
	Props.place(self, "stool", Vector3(0.4, 0, -1.2), 0.4)
	Props.place(self, "table", Vector3(1.6, 0, -2.4), 0.0)
	Props.place(self, "cutting_board", Vector3(1.4, 0.78, -2.4), 0.3)
	# Tools hung on the wall, and the planks and timber stacked by the side.
	Props.place(self, "wall_shelf_long", Vector3(3.3, 1.6, -3.3), 0.0)
	Props.place(self, "lumber", Vector3(-4.0, 0, 0.6), PI / 2.0)
	Props.place(self, "ladder", Vector3(4.6, 0, -1.2), -PI / 2.0)
	for c: Array in [["crate_long", Vector3(3.8, 0, 1.4), 0.2], ["crate_open", Vector3(-3.8, 0, -2.6), 0.4], ["barrel", Vector3(-4.2, 0, 2.2), 0.0], ["wood_bucket", Vector3(3.0, 0, 2.2), 0.0]]:
		Props.place(self, str(c[0]), c[1], c[2])
	# Curls of shavings on the floor under the bench.
	for i in 7:
		MeshKit.box(self, Vector3(0.18, 0.02, 0.06), Vector3(-2.6 + i * 0.32, 0.01, -1.9 + (i % 3) * 0.15), "wood_light", false, i * 0.7)
	Props.place(self, "wall_lantern", Vector3(-4.4, 2.3, -0.8), PI / 2.0)
	passerby(World.look_for("amos"), Vector3(-1.2, 0, -1.4), 1202, 0.8)
	add_activity_focus(Vector3(0, 0.8, 0))
