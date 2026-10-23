class_name LakeRegion
extends FarRegion
## The lake among the south-eastern hills: a little fishing jetty, a
## rowboat on the still water, reeds and water lilies at the edge, and Mr.
## Finn's hut. Mr. Finn fishes here and knows every creature in the lake.
## The lake lies east of the site.


func build() -> void:
	var shore := _shore_x()
	area = Rect2(-16, -14, shore + 15.0, 28)
	# Arrive on the landward side, looking east over the water.
	lay_ground(Vector3(-8.0, 0, 3.0), -PI / 2.0)
	var water_y := Terrain.LAKE_LEVEL - position.y
	# The jetty runs out from the shore over the water.
	var start := Vector3(shore - 1.0, 0, 0.0)
	CraftedProps.jetty(self, start, -PI / 2.0, 7.0)
	Props.place(self, "rowboat_small", Vector3(shore + 5.0, water_y - 0.3, 2.6), 0.4)
	# Mr. Finn's fire on the bank, with a fish cooking, and his catch.
	Props.place(self, "campfire", Vector3(shore - 6.0, 0, -4.0), 0.0)
	Props.place(self, "fishing_stand", Vector3(shore - 6.0, 0, -4.0), 0.6)
	Props.place(self, "firewood", Vector3(shore - 7.6, 0, -5.2), 0.3)
	Props.place(self, "wood_bucket", start + Vector3(-1.2, 0, 1.2), 0.0)
	MeshKit.box(self, Vector3(1.6, 0.45, 0.5), Vector3(shore - 4.0, 0.22, -6.5), "wood", true)
	Props.place(self, "fish_small", Vector3(shore - 4.0, 0.46, -6.5), 0.4)
	# Mr. Finn's hut back from the water, nets drying, a bench to watch from.
	CraftedProps.cottage(self, Vector3(-6.0, 0, -8.0), 0.0, 11, Vector2(3.6, 4.0), "roof_thatch")
	CraftedProps.woodpile(self, Vector3(-9.0, 0, -8.6), PI / 2.0)
	CraftedProps.net_rack(self, Vector3(-1.0, 0, -9.0), 0.2)
	CraftedProps.net_rack(self, Vector3(shore - 3.0, 0, 6.5), -0.3)
	CraftedProps.creel_and_rope(self, start + Vector3(-1.6, 0, -1.4), 0.3)
	Props.place(self, "garden_bench", Vector3(shore - 4.5, 0, 4.0), -PI / 2.0)
	Props.place(self, "rowboat_kit", Vector3(-3.0, 0, 7.5), 1.2, 0.8)
	Props.place(self, "fallen_log", Vector3(-10.0, 0, 9.0), 0.4)
	# Reeds and lilies along the water's edge.
	for k in 10:
		var z := -12.0 + k * 2.6
		if absf(z) > 1.6:
			CraftedProps.reeds(self, Vector3(shore + 0.6, 0, z), 300 + k, 0.8)
	for k in 8:
		Props.place(self, "waterlily", Vector3(shore + 3.0 + (k % 3) * 1.8, water_y + 0.02, -8.0 + k * 2.2), k * 1.1, 1.4)
	path([Vector3(-15.5, 0, 4.0), Vector3(-8.0, 0, 2.0), Vector3(-2.0, 0, 0.5), start + Vector3(-0.6, 0, 0)], 1.6, "path")
	path([Vector3(-8.0, 0, 2.0), Vector3(-6.0, 0, -5.6)], 1.2, "path")
	for t: Array in [["tree_a", Vector3(-13.0, 0, -11.0)], ["tree_b", Vector3(-13.5, 0, 11.0)], ["grove_b_small", Vector3(2.0, 0, -12.0)], ["tree_a", Vector3(2.5, 0, 11.5)]]:
		Props.place(self, str(t[0]), t[1], t[1].x, 1.2)
	for k in 3:
		var duck := AnimalModel.make("bird")
		duck.scale = Vector3.ONE * 2.6
		duck.position = Vector3(shore + 9.0 + k * 1.2, water_y + 0.05, -3.0 + k * 1.5)
		add_child(duck)
	neighbour("finn", start + Vector3(-2.0, 0, -1.4), 0.5)
	add_anchor("lake_finn", start + Vector3(-1.4, 0, -1.0), -PI / 2.0)
	add_activity_focus(start + Vector3(0, 0.8, 0))


## How far east of the site's centre the water begins (local x).
func _shore_x() -> float:
	var x := 4.0
	while x < 26.0 and Terrain.height(position.x + x, position.z) > Terrain.LAKE_LEVEL + 0.5:
		x += 0.5
	return x
