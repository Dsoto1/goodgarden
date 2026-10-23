class_name LakeRegion
extends FarRegion
## The lake among the south-eastern hills: a little fishing jetty, a
## rowboat on the still water, reeds and water lilies at the edge, and Mr.
## Finn's hut. Mr. Finn fishes here and knows every creature in the lake.


func build() -> void:
	area = Rect2(-9, -9, 18, 18)
	# Arrive on the landward side, looking out over the water (south-east).
	lay_ground(Vector3(-6.5, 0, -6.0), -2.3)
	var to_lake := (Vector3(Terrain.LAKE.x, 0, Terrain.LAKE.y) - position).normalized()
	to_lake.y = 0
	var water_y := Terrain.LAKE_LEVEL - position.y
	# The jetty runs out from the shore toward the middle of the lake.
	var start := to_lake * 6.5
	var yaw := atan2(to_lake.x, to_lake.z)
	CraftedProps.jetty(self, start + Vector3(0, 0, 0), yaw + PI, 6.0)
	CraftedProps.rowboat(self, start + to_lake * 5.0 + to_lake.cross(Vector3.UP) * 2.0 + Vector3(0, water_y - 0.05, 0), yaw + 0.4)
	# Mr. Finn's hut, nets drying, and a bench to watch the water.
	CraftedProps.cottage(self, Vector3(-5.5, 0, 3.5), PI * 0.75, 11, Vector2(3.2, 3.6), "roof_thatch")
	CraftedProps.net_rack(self, Vector3(-1.5, 0, 6.0), 0.5)
	CraftedProps.creel_and_rope(self, start - to_lake * 1.2 + Vector3(0.8, 0, 0), 0.3)
	MeshKit.box(self, Vector3(1.6, 0.45, 0.5), Vector3(2.0, 0.22, -4.0), "wood", true)
	# Reeds and lilies along the water's edge.
	for k in 8:
		var side := to_lake.cross(Vector3.UP) * (-6.0 + k * 1.7)
		CraftedProps.reeds(self, to_lake * 8.2 + side, 300 + k, 0.8)
	for k in 6:
		var lily := to_lake * (11.0 + (k % 3) * 1.4) + to_lake.cross(Vector3.UP) * (-3.0 + k * 1.3)
		Props.place(self, "waterlily", lily + Vector3(0, water_y + 0.02, 0), k * 1.1, 1.4)
	path([Vector3(-8.5, 0, -6.0), Vector3(-4.0, 0, -2.5), start - to_lake * 0.6], 1.5, "path")
	ring_of_trees(["tree_a", "tree_b", "grove_b_small"], 9, 0.6, 61)
	for k in 3:
		var duck := AnimalModel.make("bird")
		duck.scale = Vector3.ONE * 2.6
		duck.position = to_lake * (13.0 + k * 1.2) + to_lake.cross(Vector3.UP) * (k - 1) * 1.5 + Vector3(0, water_y + 0.05, 0)
		add_child(duck)
	neighbour("finn", start + to_lake * 1.5 + Vector3(0, 0.35, 0), 0.3)
	add_anchor("lake_finn", start + Vector3(0.6, 0, 0.6), yaw)
	add_activity_focus(start + Vector3(0, 0.8, 0))
