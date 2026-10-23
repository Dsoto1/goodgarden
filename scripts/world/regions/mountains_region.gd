class_name MountainsRegion
extends FarRegion
## A high meadow in the mountains north-east of the valley: a shepherd's hut,
## the old mine, a stone cairn that marks the trail, pines and boulders, and
## sheep on the slopes, with snowy peaks all round. Mr. Silas, the shepherd,
## knows the weather and every path.


func build() -> void:
	area = Rect2(-12, -12, 24, 24)
	# Arrive looking north-east, up to the peaks.
	lay_ground(Vector3(-8.0, 0, 8.0), -0.785)
	path([Vector3(-11.5, 0, 9.0), Vector3(-6.0, 0, 5.0), Vector3(-1.0, 0, 1.0), Vector3(4.0, 0, -3.5), Vector3(8.5, 0, -9.5)], 1.4, "path")
	Props.place(self, "mine", Vector3(7.5, 0, -7.5), -0.8)
	CraftedProps.cottage(self, Vector3(-6.5, 0, -4.5), PI / 2.0 + 0.3, 31, Vector2(3.2, 3.6), "roof_slate")
	# Mr. Silas's camp by the hut: tent, fire, firewood, a workbench.
	Props.place(self, "camp_tent", Vector3(-1.8, 0, -8.2), 0.4)
	Props.place(self, "campfire", Vector3(-1.2, 0, -5.6), 0.0)
	Props.place(self, "firewood", Vector3(-2.6, 0, -5.4), 0.6)
	Props.place(self, "bedroll", Vector3(0.2, 0, -7.4), 1.2)
	Props.place(self, "camp_workbench", Vector3(-4.6, 0, -7.2), 0.2)
	CraftedProps.woodpile(self, Vector3(-4.0, 0, -6.0), 0.4)
	Props.place(self, "pickaxe", Vector3(6.0, 0, -5.6), 0.5)
	Props.place(self, "fallen_log", Vector3(-9.0, 0, -1.0), 0.3)
	Props.place(self, "trail_sign", Vector3(-1.6, 0, 3.0), -0.8)
	# The cairn: a heap of stones marking the trail up.
	_cairn(Vector3(3.0, 0, 0.0))
	for r: Array in [["rock", Vector3(-9.0, 0, -9.0)], ["rock_b", Vector3(9.5, 0, 3.0)], ["rock_c", Vector3(5.0, 0, 8.5)], ["rock", Vector3(-3.0, 0, 9.5)], ["stone_pile", Vector3(5.5, 0, -4.8)], ["rock_flat", Vector3(-1.5, 0, 4.5)]]:
		Props.place(self, str(r[0]), r[1], r[1].x, 1.3)
	ring_of_trees(["pine_wide"], 14, 0.5, 91)
	for p: Vector3 in [Vector3(-9.5, 0, 2.0), Vector3(9.0, 0, -1.5), Vector3(1.0, 0, -10.0)]:
		Props.place(self, "pine_wide", p, p.x, 1.2)
	MeshKit.flowers(self, Vector3(1.5, 0, 6.0), 2.5, 16, 93)
	for i in 4:
		var sheep := Wanderer.new().setup(AnimalModel.make("sheep" if i < 3 else "lamb"), 970 + i)
		sheep.position = Vector3(2.0 + i * 1.4, 0, 4.0 - i)
		sheep.radius = 2.8
		sheep.speed = 0.3
		sheep.pause_range = Vector2(4, 10)
		add_child(sheep)
		AnimalMoments.pettable(sheep, "Pet the sheep", ["The mountain sheep has thick, warm wool."], "sheep")
	neighbour("silas", Vector3(-3.6, 0, -2.0), 0.6)
	add_anchor("mountains_silas", Vector3(-3.6, 0, -2.0), 0.0)
	SoundSpot.calling(self, "sheep", Vector3(4.0, 0.6, 3.0), 20.0, Vector2(8, 18), -8.0)
	add_activity_focus(Vector3(0, 0.8, 0))


func _cairn(at: Vector3) -> void:
	for k in 7:
		var size := 0.42 - k * 0.05
		MeshKit.sphere(self, size, at + Vector3(0.04 * (k % 2), 0.2 + k * 0.26, 0.03 * (k % 3)), "stone" if k % 2 == 0 else "stone_dark", Vector3(1.2, 0.6, 1.0), 8, 4)
	MeshKit.solid(self, Vector3(1.0, 1.6, 1.0), at + Vector3(0, 0.8, 0))
