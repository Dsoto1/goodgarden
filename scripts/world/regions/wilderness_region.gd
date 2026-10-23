class_name WildernessRegion
extends FarRegion
## The wilderness west of the valley, at the foot of the great waterfall:
## old trees, ferns and mossy rocks, a forest trail with its signpost, deer
## grazing in a clearing, and leaves of every shape underfoot.


func build() -> void:
	area = Rect2(-17, -17, 34, 34)
	# Arrive from the valley (east) looking north-west, toward the waterfall.
	lay_ground(Vector3(13.0, 0, 11.0), 0.9)
	path([Vector3(16.5, 0, 12.0), Vector3(10.0, 0, 8.5), Vector3(3.0, 0, 3.0), Vector3(-3.0, 0, -3.0), Vector3(-9.0, 0, -9.0), Vector3(-14.0, 0, -15.5)], 1.6, "path")
	path([Vector3(3.0, 0, 3.0), Vector3(-4.0, 0, 9.0), Vector3(-11.0, 0, 11.0)], 1.2, "path")
	CraftedProps.signpost(self, Vector3(4.6, 0, 4.6), [["Waterfall", 0.79], ["Valley", PI + 0.9]])
	# Big old trees round the clearings.
	for t: Array in [["grove_a_large", Vector3(-10.0, 0, 3.0)], ["twisted_tree", Vector3(9.0, 0, -6.0)], ["tree_b", Vector3(-4.0, 0, 14.0)],
			["grove_a_medium", Vector3(11.0, 0, 1.0)], ["tree_a", Vector3(-11.0, 0, -4.0)], ["twisted_tree_b", Vector3(2.5, 0, -10.0)], ["pine_wide", Vector3(13.0, 0, 15.0)],
			["grove_a_large", Vector3(6.0, 0, -14.0)], ["tree_a", Vector3(-15.0, 0, 13.0)], ["twisted_tree", Vector3(-5.0, 0, -13.0)], ["grove_a_medium", Vector3(15.0, 0, -12.0)]]:
		Props.place(self, str(t[0]), t[1], t[1].x, 1.25)
	ring_of_trees(["grove_b_medium", "tree_a", "pine_wide", "grove_a_small"], 20, 0.4, 81)
	for f: Vector3 in [Vector3(-7.8, 0, 1.0), Vector3(-2.0, 0, 7.0), Vector3(6.0, 0, -3.5), Vector3(-7.0, 0, -7.0), Vector3(5.0, 0, 9.0), Vector3(-2.0, 0, -9.0),
			Vector3(-12.0, 0, 7.0), Vector3(10.0, 0, -9.5), Vector3(0.5, 0, 12.0)]:
		Props.place(self, "fern", f, f.x, 1.3)
	for r: Array in [["rock_b", Vector3(-3.8, 0, -1.0)], ["rock_c", Vector3(6.5, 0, 5.0)], ["rock", Vector3(-9.0, 0, 9.0)], ["rock_flat", Vector3(8.0, 0, -1.0)],
			["rock_b", Vector3(-13.0, 0, -11.0)], ["rock_c", Vector3(-8.0, 0, -12.5)]]:
		Props.place(self, str(r[0]), r[1], r[1].z, 1.1)
	for m: Vector3 in [Vector3(-8.6, 0, 2.0), Vector3(-8.2, 0, 2.8), Vector3(8.4, 0, -4.6), Vector3(-3.0, 0, -8.0), Vector3(-3.6, 0, 12.8)]:
		Props.place(self, "mushroom", m, m.x)
	MeshKit.flowers(self, Vector3(-3.0, 0, 4.0), 2.6, 22, 83)
	MeshKit.flowers(self, Vector3(7.0, 0, -9.0), 2.0, 14, 84)
	Props.place(self, "fallen_log", Vector3(6.0, 0, 1.0), 0.7)
	Props.place(self, "fallen_log", Vector3(-6.6, 0, -2.6), 2.2, 0.8)
	# A little woodcutter's camp off the side path.
	Props.place(self, "camp_tent", Vector3(-12.0, 0, 13.6), 2.6)
	Props.place(self, "campfire", Vector3(-9.6, 0, 13.0), 0.0)
	Props.place(self, "firewood", Vector3(-8.6, 0, 14.4), 0.4)
	# Fallen leaves of different shapes at the foot of the big trees.
	var colours := ["cloth_gold", "leaf_autumn", "leaf_light", "cloth_red"]
	for k in 30:
		var a := k * 2.39
		var at := Vector3(-9.4, 0.03, 3.0) + Vector3(cos(a), 0, sin(a)) * (0.5 + (k % 6) * 0.4)
		MeshKit.box(self, Vector3(0.18, 0.02, 0.12), at, colours[k % 4]).rotation.y = a
	# Deer in the clearing, grazing and wandering.
	for i in 3:
		var deer := Wanderer.new().setup(AnimalModel.make("deer"), 950 + i)
		deer.position = Vector3(-3.0 + i * 3.5, 0, -6.0 + i)
		deer.radius = 3.0
		deer.speed = 0.35
		deer.pause_range = Vector2(4, 9)
		add_child(deer)
	for i in 4:
		var b := Wanderer.new().setup(AnimalModel.make("butterfly"), 960 + i)
		b.gait = "flutter"
		b.radius = 2.4
		b.position = Vector3(-4.0 + i, 0.4, 4.0)
		add_child(b)
	SoundSpot.looping(self, "waterfall", Vector3(-15.0, 1.0, -15.0), 34.0, -6.0)
	add_activity_focus(Vector3(0, 0.8, 0))
