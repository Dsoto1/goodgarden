class_name WildernessRegion
extends FarRegion
## The wilderness west of the valley, at the foot of the great waterfall:
## old trees, ferns and mossy rocks, a forest trail with its signpost, deer
## grazing in a clearing, and leaves of every shape underfoot.


func build() -> void:
	area = Rect2(-9, -9, 18, 18)
	# Arrive looking north-west, toward the waterfall.
	lay_ground(Vector3(4.5, 0, 6.5), 0.57)
	path([Vector3(8.5, 0, 6.5), Vector3(4.0, 0, 4.5), Vector3(0.5, 0, 0.5), Vector3(-3.0, 0, -3.0), Vector3(-6.5, 0, -7.5)], 1.4, "path")
	CraftedProps.signpost(self, Vector3(1.6, 0, 1.6), [["Waterfall", 0.57], ["Valley", PI + 0.6]])
	# Big old trees, close round the clearing.
	for t: Array in [["grove_a_large", Vector3(-6.5, 0, 2.5)], ["twisted_tree", Vector3(6.0, 0, -4.5)], ["tree_b", Vector3(-3.5, 0, 6.5)],
			["grove_a_medium", Vector3(6.5, 0, 2.0)], ["tree_a", Vector3(-7.0, 0, -3.0)], ["twisted_tree_b", Vector3(2.5, 0, -7.0)], ["pine_wide", Vector3(7.5, 0, 7.5)]]:
		Props.place(self, str(t[0]), t[1], t[1].x, 1.25)
	ring_of_trees(["grove_b_medium", "tree_a", "pine_wide", "grove_a_small"], 12, 0.4, 81)
	for f: Vector3 in [Vector3(-4.8, 0, 0.5), Vector3(-1.8, 0, 4.5), Vector3(4.0, 0, -2.5), Vector3(-5.0, 0, -5.0), Vector3(3.0, 0, 6.0), Vector3(-2.0, 0, -6.5)]:
		Props.place(self, "fern", f, f.x, 1.3)
	for r: Array in [["rock_b", Vector3(-2.8, 0, -1.5)], ["rock_c", Vector3(3.5, 0, 3.0)], ["rock", Vector3(-6.0, 0, 6.5)], ["rock_flat", Vector3(5.5, 0, -1.0)]]:
		Props.place(self, str(r[0]), r[1], r[1].z, 1.1)
	for m: Vector3 in [Vector3(-5.6, 0, 1.6), Vector3(-5.2, 0, 2.2), Vector3(5.4, 0, -3.6), Vector3(-2.4, 0, -5.8)]:
		Props.place(self, "mushroom", m, m.x)
	MeshKit.flowers(self, Vector3(-1.5, 0, 2.5), 2.2, 18, 83)
	# Fallen leaves of different shapes at the foot of the big trees.
	var colours := ["cloth_gold", "leaf_autumn", "leaf_light", "cloth_red"]
	for k in 26:
		var a := k * 2.39
		var at := Vector3(-6.0, 0.03, 2.5) + Vector3(cos(a), 0, sin(a)) * (0.5 + (k % 6) * 0.35)
		MeshKit.box(self, Vector3(0.18, 0.02, 0.12), at, colours[k % 4]).rotation.y = a
	# Deer in the clearing, grazing and wandering.
	for i in 2:
		var deer := Wanderer.new().setup(AnimalModel.make("deer"), 950 + i)
		deer.position = Vector3(-2.0 + i * 3.5, 0, -3.5 + i)
		deer.radius = 2.4
		deer.speed = 0.35
		deer.pause_range = Vector2(4, 9)
		add_child(deer)
	for i in 3:
		var b := Wanderer.new().setup(AnimalModel.make("butterfly"), 960 + i)
		b.gait = "flutter"
		b.radius = 2.0
		b.position = Vector3(-1.5 + i, 0.4, 2.5)
		add_child(b)
	SoundSpot.looping(self, "waterfall", Vector3(-8.0, 1.0, -8.0), 30.0, -6.0)
	add_activity_focus(Vector3(0, 0.8, 0))
