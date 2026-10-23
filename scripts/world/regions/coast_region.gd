class_name CoastRegion
extends FarRegion
## The harbour where the river meets the sea: a wooden dock with a tall ship
## at anchor, a lighthouse out on the rocks, fishermen's nets and crates,
## and Captain Mara readying her ship for a voyage. The sea lies east.


func build() -> void:
	area = Rect2(-13, -12, 27, 24)
	lay_ground(Vector3(-9.0, 0, 6.0), -PI / 2.0)
	# Harbour houses and a warehouse on the landward side.
	Props.place(self, "tavern_yellow", Vector3(-9.0, 0, -6.5), PI / 2.0)
	Props.place(self, "house_blue", Vector3(-9.5, 0, 1.0), PI / 2.0)
	Props.place(self, "lumbermill", Vector3(-3.0, 0, -9.0), 0.0, 0.8)
	path([Vector3(-12.5, 0, 5.0), Vector3(-6.0, 0, 3.5), Vector3(0.0, 0, 1.5), Vector3(8.0, 0, 0.8)], 2.4, "cobble")
	path([Vector3(-6.0, 0, 3.5), Vector3(-5.0, 0, -4.5)], 1.8, "cobble")
	# The dock: plank platforms on posts, from the quay out over the water.
	var sea_y := Terrain.SEA_LEVEL - position.y
	for i in 6:
		Props.place(self, "dock_tile", Vector3(10.5 + i * 3.0, 0.4 - 1.57, 0.8), 0.0)
	Props.place(self, "dock_tile_small", Vector3(25.5, 0.4 - 1.57, 3.8), 0.0)
	MeshKit.solid(self, Vector3(4.0, 1.0, 3.0), Vector3(12.0, 0.0, 0.8))
	add_clearing(Vector3(11.0, 0, 0.8), Vector2(6.0, 3.4))
	# Captain Mara's ship at anchor beside the end of the dock, a smaller one
	# further out, and rowboats tied up.
	Props.place(self, "ship_large", Vector3(23.0, sea_y - 0.9, 9.5), PI / 2.0 + 0.1)
	Props.place(self, "ship_medium", Vector3(44.0, sea_y - 0.9, -10.0), 2.2, 0.9)
	Props.place(self, "rowboat_kit", Vector3(16.5, sea_y - 0.35, -3.0), 0.4)
	Props.place(self, "rowboat_small", Vector3(19.5, sea_y - 0.35, -2.6), -0.2)
	# Dolphins playing out in the bay.
	for k in 2:
		Props.place(self, "dolphin", Vector3(36.0 + k * 3.0, sea_y - 0.4, 2.0 + k * 2.5), 1.2 + k * 0.3)
	# The lighthouse on its rocks, out to sea.
	_lighthouse(Vector3(30.0, Terrain.SEA_LEVEL - position.y, -14.0))
	# Work on the quay: crates, barrels, nets, ropes.
	for p: Array in [["crate_big", Vector3(6.0, 0, -2.6)], ["crate_long", Vector3(4.2, 0, -3.4)], ["barrel", Vector3(7.4, 0, 3.4)], ["barrel", Vector3(6.6, 0, 4.2)], ["sack", Vector3(5.2, 0, 3.8)],
			["crate_bottles", Vector3(2.8, 0, -3.0)], ["sea_chest", Vector3(9.6, 0.4, -0.2)], ["rope_coil", Vector3(11.5, 0.42, 1.8)], ["wood_bucket", Vector3(10.8, 0.42, -0.2)], ["apple_barrel", Vector3(4.6, 0, 4.4)]]:
		Props.place(self, str(p[0]), p[1], p[1].x)
	CraftedProps.net_rack(self, Vector3(-1.0, 0, 7.5), 0.2)
	CraftedProps.creel_and_rope(self, Vector3(3.0, 0, 6.4), 0.5)
	Props.place(self, "flag_blue", Vector3(9.5, 0, -1.4), 0.0)
	for k in 6:
		Props.place(self, "rock_b" if k % 2 == 0 else "rock_c", Vector3(13.5 + k * 0.4, -0.6, -9.0 + k * 3.3), k * 1.3, 1.2)
	var sailor := {"skin": "skin_3", "hair": "hair_dark", "hair_style": "short", "shirt": "cloth_blue", "pants": "cloth_tan", "height": 1.02}
	passerby(sailor, Vector3(3.0, 0, 1.5), 801, 2.5)
	var sailor2 := sailor.duplicate()
	sailor2["skin"] = "skin_1"
	sailor2["hair"] = "hair_red"
	sailor2["shirt"] = "cloth_red"
	passerby(sailor2, Vector3(-2.0, 0, -1.5), 802, 2.0)
	neighbour("mara", Vector3(8.6, 0, 2.6), 0.6)
	add_anchor("coast_mara", Vector3(8.6, 0, 2.6), -PI / 2.0)
	ring_of_trees(["pine_wide", "tree_b"], 6, 0.6, 51)
	SoundSpot.looping(self, "river", Vector3(16, 0.2, 0), 26.0, -8.0)
	add_activity_focus(Vector3(5.0, 0.8, 0.5))


## A white-and-red lighthouse on a heap of rocks.
func _lighthouse(at: Vector3) -> void:
	var l := Node3D.new()
	l.name = "Lighthouse"
	l.position = at
	add_child(l)
	MeshKit.sphere(l, 3.4, Vector3(0, 0.2, 0), "stone_dark", Vector3(1.0, 0.45, 1.0), 10, 5)
	for k in 4:
		var band := "white" if k % 2 == 0 else "cloth_red"
		MeshKit.cylinder(l, 1.15 - (k + 1) * 0.1, 1.15 - k * 0.1, 2.2, Vector3(0, 1.6 + k * 2.2, 0), band, 12)
	MeshKit.cylinder(l, 0.9, 0.9, 0.2, Vector3(0, 10.4, 0), "dark", 12)
	MeshKit.cylinder(l, 0.55, 0.55, 1.0, Vector3(0, 11.0, 0), "lantern", 10)
	MeshKit.cone(l, 0.75, 0.9, Vector3(0, 12.0, 0), "cloth_red", 10)
