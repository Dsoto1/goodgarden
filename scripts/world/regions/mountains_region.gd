class_name MountainsRegion
extends FarRegion
## A high meadow in the mountains north-east of the valley: a shepherd's hut,
## the old mine, a stone cairn that marks the trail, pines and boulders, and
## sheep on the slopes, with snowy peaks all round. Mr. Silas, the shepherd,
## knows the weather and every path.


func build() -> void:
	area = Rect2(-19, -19, 38, 38)
	# Arrive looking north-east, up the trail to the peaks and the mine.
	lay_ground(Vector3(-14.0, 0, 14.0), -0.785)
	path([Vector3(-18.5, 0, 16.0), Vector3(-10.0, 0, 9.0), Vector3(-2.0, 0, 2.0), Vector3(6.0, 0, -5.0), Vector3(13.0, 0, -13.0)], 1.6, "path")
	path([Vector3(-6.0, 0, 5.5), Vector3(-9.0, 0, -2.0)], 1.2, "path")
	Props.place(self, "mine", Vector3(13.5, 0, -14.0), -0.8)
	Props.place(self, "pickaxe", Vector3(10.5, 0, -10.6), 0.5)
	Props.place(self, "stone_pile", Vector3(11.5, 0, -9.0), 0.8, 1.3)
	Props.place(self, "town_cart", Vector3(15.5, 0, -9.6), 0.6)
	# Mr. Silas's hut with his camp beside it: tent, fire, firewood, bench.
	CraftedProps.cottage(self, Vector3(-11.0, 0, -6.0), PI / 2.0 + 0.3, 31, Vector2(3.4, 3.8), "roof_slate")
	Props.place(self, "camp_tent", Vector3(-4.0, 0, -11.0), 0.4)
	Props.place(self, "campfire", Vector3(-4.6, 0, -6.6), 0.0)
	Props.place(self, "firewood", Vector3(-6.0, 0, -7.4), 0.6)
	Props.place(self, "bedroll", Vector3(-2.2, 0, -9.0), 1.2)
	Props.place(self, "camp_workbench", Vector3(-8.0, 0, -10.6), 0.2)
	CraftedProps.woodpile(self, Vector3(-13.6, 0, -9.6), 0.4)
	Props.place(self, "fallen_log", Vector3(-15.0, 0, 0.0), 0.3)
	Props.place(self, "trail_sign", Vector3(-4.0, 0, 5.0), -0.8)
	# Cairns marking the trail up.
	_cairn(Vector3(1.6, 0, 0.0))
	_cairn(Vector3(9.5, 0, -6.6))
	# A stone pen for the sheep, open to the south.
	for wall: Array in [[Vector3(4.0, 0, 6.0), Vector3(14.0, 0, 6.0)], [Vector3(14.0, 0, 6.0), Vector3(14.0, 0, 14.0)], [Vector3(4.0, 0, 6.0), Vector3(4.0, 0, 14.0)], [Vector3(4.0, 0, 14.0), Vector3(7.5, 0, 14.0)], [Vector3(10.5, 0, 14.0), Vector3(14.0, 0, 14.0)]]:
		CraftedProps.stone_wall(self, wall[0], wall[1], int(wall[0].x * 10 + wall[0].z))
	for r: Array in [["rock", Vector3(-15.0, 0, -15.0)], ["rock_b", Vector3(16.0, 0, 2.0)], ["rock_c", Vector3(0.0, 0, 15.0)], ["rock", Vector3(-8.0, 0, 15.0)], ["rock_flat", Vector3(-2.0, 0, 7.0)],
			["rock_b", Vector3(4.0, 0, -15.0)], ["rock_c", Vector3(16.0, 0, 15.5)], ["rock_flat", Vector3(-16.0, 0, 6.0)]]:
		Props.place(self, str(r[0]), r[1], r[1].x, 1.3)
	ring_of_trees(["pine_wide"], 20, 0.5, 91)
	for p: Vector3 in [Vector3(-15.0, 0, 4.0), Vector3(16.0, 0, -4.0), Vector3(2.0, 0, -15.5), Vector3(-1.0, 0, 12.0)]:
		Props.place(self, "pine_wide", p, p.x, 1.2)
	MeshKit.flowers(self, Vector3(0.0, 0, 9.0), 3.0, 22, 93)
	MeshKit.flowers(self, Vector3(-12.0, 0, 4.0), 2.2, 14, 94)
	for i in 5:
		var sheep := Wanderer.new().setup(AnimalModel.make("sheep" if i < 3 else "lamb"), 970 + i)
		sheep.position = Vector3(6.5 + (i % 3) * 2.4, 0, 8.5 + (i / 3) * 2.4)
		sheep.radius = 2.2
		sheep.speed = 0.3
		sheep.pause_range = Vector2(4, 10)
		add_child(sheep)
		AnimalMoments.pettable(sheep, "Pet the sheep", ["The mountain sheep has thick, warm wool."], "sheep")
	neighbour("silas", Vector3(-6.0, 0, -4.0), 0.6)
	add_anchor("mountains_silas", Vector3(-6.0, 0, -4.0), 0.0)
	SoundSpot.calling(self, "sheep", Vector3(9.0, 0.6, 10.0), 20.0, Vector2(8, 18), -8.0)
	add_activity_focus(Vector3(-2.0, 0.8, 0))


func _cairn(at: Vector3) -> void:
	for k in 7:
		var size := 0.42 - k * 0.05
		MeshKit.sphere(self, size, at + Vector3(0.04 * (k % 2), 0.2 + k * 0.26, 0.03 * (k % 3)), "stone" if k % 2 == 0 else "stone_dark", Vector3(1.2, 0.6, 1.0), 8, 4)
	MeshKit.solid(self, Vector3(1.0, 1.6, 1.0), at + Vector3(0, 0.8, 0))
