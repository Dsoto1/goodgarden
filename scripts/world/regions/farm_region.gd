class_name FarmRegion
extends FarRegion
## The farmlands south of the valley: golden wheat fields in strips, a
## windmill, a farmhouse and barn, haystacks, and cows in their meadow.
## Mrs. Hannah farms here and is glad of help at harvest.


func build() -> void:
	area = Rect2(-26, -24, 52, 48)
	lay_ground(Vector3(0, 0, -21.0), PI)
	# Arrive from the valley side (north) looking south over the fields. The
	# farm lane runs south; a cross track leads to the meadow and the fields.
	path([Vector3(0, 0, -24.0), Vector3(0.5, 0, -14.0), Vector3(-0.5, 0, -2.0), Vector3(0, 0, 12.0)], 2.4, "path")
	path([Vector3(-24.0, 0, 0.0), Vector3(24.0, 0, 0.0)], 2.0, "path")
	# Fields in strips to the west and south.
	for f: Array in [[Vector3(-14.0, 0, -9.0), 0.0], [Vector3(-14.0, 0, 9.5), 0.0], [Vector3(-14.0, 0, 18.5), PI / 2.0], [Vector3(10.0, 0, 16.0), 0.0]]:
		CraftedProps.grain_field(self, f[0], Vector2(12, 7), f[1], int(f[0].x * 3 + f[0].z))
		add_clearing(f[0], Vector2(12.5, 7.5))
	Props.place(self, "grain_field", Vector3(-2.0, 0, 18.0), 0.2)
	Props.place(self, "windmill", Vector3(-20.0, 0, -19.0), 0.6)
	# The farmyard north-east of the lane: the big barn and silo, the hen
	# house, the well and the farm cart.
	Props.place(self, "barn_big", Vector3(12.0, 0, -17.0), PI)
	Props.place(self, "silo", Vector3(20.0, 0, -18.5), 0.0)
	Props.place(self, "barn_small", Vector3(20.5, 0, -9.0), -PI / 2.0, 0.8)
	Props.place(self, "chicken_coop", Vector3(6.0, 0, -7.0), PI)
	Props.place(self, "farm_well", Vector3(4.0, 0, -12.0), 0.4)
	for c: Array in [["apple_crate", Vector3(3.4, 0, -4.4)], ["carrot_crate", Vector3(4.6, 0, -4.2)], ["apple_barrel", Vector3(2.4, 0, -4.8)], ["town_cart_high", Vector3(9.0, 0, -11.0)], ["firewood", Vector3(16.0, 0, -12.0)]]:
		Props.place(self, str(c[0]), c[1], c[1].x)
	Props.fence(self, "fence_wood", Vector3(3.0, 0, -9.5), Vector3(3.0, 0, -5.4))
	Props.fence(self, "fence_wood", Vector3(3.0, 0, -9.5), Vector3(9.0, 0, -9.5))
	for h: Vector3 in [Vector3(-6.0, 0, 6.0), Vector3(-6.5, 0, 9.5), Vector3(22.0, 0, 8.0)]:
		CraftedProps.haystack(self, h)
	for b: Array in [[Vector3(14.6, 0, -12.6), 0.4], [Vector3(15.8, 0, -13.2), -0.3], [Vector3(-7.0, 0, -4.0), 0.2]]:
		CraftedProps.hay_bale(self, b[0], b[1])
	CraftedProps.scarecrow(self, Vector3(-14.0, 0, -9.0), 0.4)
	CraftedProps.scarecrow(self, Vector3(10.0, 0, 16.0), -0.3)
	# A meadow fenced for the cows, south-east of the crossing.
	Props.fence(self, "fence_wood", Vector3(6.0, 0, 3.0), Vector3(23.0, 0, 3.0))
	Props.fence(self, "fence_wood", Vector3(23.0, 0, 3.0), Vector3(23.0, 0, 11.0))
	Props.fence(self, "fence_wood", Vector3(6.0, 0, 11.0), Vector3(23.0, 0, 11.0))
	Props.fence(self, "fence_wood", Vector3(6.0, 0, 3.0), Vector3(6.0, 0, 5.5))
	Props.fence(self, "fence_wood", Vector3(6.0, 0, 8.5), Vector3(6.0, 0, 11.0))
	CraftedProps.water_trough(self, Vector3(20.5, 0, 5.0), PI / 2.0)
	for i in 3:
		var cow := Wanderer.new().setup(AnimalModel.make("cow"), 910 + i)
		cow.position = Vector3(11.0 + i * 3.0, 0, 6.0 + (i % 2))
		cow.radius = 2.6
		cow.speed = 0.3
		cow.pause_range = Vector2(4, 10)
		add_child(cow)
		AnimalMoments.pettable(cow, "Pet the cow", ["The cow lowers her big head for a scratch.", "Moo! The cow seems to like you."], "cow")
	for i in 4:
		var hen := Wanderer.new().setup(AnimalModel.make("chicken"), 920 + i)
		hen.position = Vector3(5.0 + i * 0.6, 0, -6.4)
		hen.radius = 1.6
		add_child(hen)
	var worker := {"skin": "skin_4", "hair": "hair_black", "hair_style": "short", "shirt": "cloth_cream", "pants": "cloth_blue", "hat": "straw", "height": 1.0}
	passerby(worker, Vector3(-9.0, 0, 4.0), 901, 3.0)
	neighbour("hannah", Vector3(2.0, 0, -6.0), 0.8)
	add_anchor("farm_hannah", Vector3(2.0, 0, -6.0), PI)
	ring_of_trees(["tree_a", "grove_a_small", "tree_b"], 18, 0.6, 71)
	add_activity_focus(Vector3(0, 0.8, -4.0))
