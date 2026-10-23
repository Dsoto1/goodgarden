class_name FarmRegion
extends FarRegion
## The farmlands south of the valley: golden wheat fields in strips, a
## windmill, a farmhouse and barn, haystacks, and cows in their meadow.
## Mrs. Hannah farms here and is glad of help at harvest.


func build() -> void:
	area = Rect2(-17, -15, 34, 30)
	lay_ground(Vector3(0, 0, -12.5), PI)
	# Arrive from the valley side (north) looking south over the fields.
	path([Vector3(0, 0, -15.0), Vector3(0.5, 0, -8.0), Vector3(-0.5, 0, 0.0), Vector3(0, 0, 8.0)], 2.2, "path")
	path([Vector3(-15.0, 0, 1.5), Vector3(15.0, 0, 1.5)], 1.8, "path")
	for f: Array in [[Vector3(-8.5, 0, 7.5), 0.0], [Vector3(8.5, 0, 7.5), 0.0], [Vector3(-8.5, 0, -5.0), PI / 2.0]]:
		CraftedProps.grain_field(self, f[0], Vector2(10, 7), f[1], int(f[0].x * 3 + f[0].z))
		add_clearing(f[0], Vector2(10.5, 7.5))
	Props.place(self, "windmill", Vector3(12.0, 0, -9.0), -0.6)
	CraftedProps.cottage(self, Vector3(4.5, 0, -8.5), 0.0, 23, Vector2(4.0, 4.4), "roof_red")
	Props.place(self, "grain_field", Vector3(-1.0, 0, 13.0), 0.2)
	for h: Vector3 in [Vector3(14.0, 0, 6.0), Vector3(14.5, 0, 9.0)]:
		CraftedProps.haystack(self, h)
	CraftedProps.hay_bale(self, Vector3(3.2, 0, -3.2), 0.4)
	CraftedProps.hay_bale(self, Vector3(4.6, 0, -3.6), -0.3)
	CraftedProps.scarecrow(self, Vector3(-8.0, 0, 7.5), 0.4)
	CraftedProps.water_trough(self, Vector3(13.0, 0, -2.6), PI / 2.0)
	# A meadow fenced for the cows.
	Props.fence(self, "fence_wood", Vector3(9.0, 0, -6.0), Vector3(16.5, 0, -6.0))
	Props.fence(self, "fence_wood", Vector3(16.5, 0, -6.0), Vector3(16.5, 0, 0.5))
	Props.fence(self, "fence_wood", Vector3(9.0, 0, 0.5), Vector3(13.0, 0, 0.5))
	for i in 3:
		var cow := Wanderer.new().setup(AnimalModel.make("cow"), 910 + i)
		cow.position = Vector3(11.0 + i * 1.6, 0, -3.5 + (i % 2))
		cow.radius = 1.8
		cow.speed = 0.3
		cow.pause_range = Vector2(4, 10)
		add_child(cow)
		AnimalMoments.pettable(cow, "Pet the cow", ["The cow lowers her big head for a scratch.", "Moo! The cow seems to like you."], "cow")
	for i in 4:
		var hen := Wanderer.new().setup(AnimalModel.make("chicken"), 920 + i)
		hen.position = Vector3(2.5 + i * 0.6, 0, -4.8)
		hen.radius = 1.6
		add_child(hen)
	var worker := {"skin": "skin_4", "hair": "hair_black", "hair_style": "short", "shirt": "cloth_cream", "pants": "cloth_blue", "hat": "straw", "height": 1.0}
	passerby(worker, Vector3(-7.0, 0, 3.0), 901, 3.0)
	neighbour("hannah", Vector3(1.6, 0, -3.0), 0.8)
	add_anchor("farm_hannah", Vector3(1.6, 0, -3.0), PI)
	ring_of_trees(["tree_a", "grove_a_small", "tree_b"], 12, 0.6, 71)
	add_activity_focus(Vector3(0, 0.8, 0))
