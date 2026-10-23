class_name CoastRegion
extends FarRegion
## The harbour where the river meets the sea: a wooden dock with a tall ship
## at anchor, a lighthouse out on the rocks, fishermen's nets and crates,
## and Captain Mara readying her ship for a voyage. The sea lies east.


func build() -> void:
	var shore := _shore_x()
	area = Rect2(-20, -16, shore + 19.0, 32)
	lay_ground(Vector3(-12.0, 0, 5.0), -PI / 2.0)
	# The quay street runs east to the water; houses and the warehouse stand
	# back on the landward side, with a lane north between them.
	path([Vector3(-19.5, 0, 6.0), Vector3(-10.0, 0, 4.0), Vector3(0.0, 0, 1.5), Vector3(shore, 0, 0.8)], 3.0, "cobble")
	path([Vector3(-6.0, 0, 3.0), Vector3(-5.0, 0, -9.0)], 2.0, "cobble")
	add_clearing(Vector3(shore - 6.0, 0, 0.8), Vector2(10.0, 9.0))
	Props.place(self, "tavern_yellow", Vector3(-14.0, 0, -6.5), PI / 2.0)
	Props.place(self, "house_blue", Vector3(-15.0, 0, 13.0), PI)
	Props.place(self, "house_b_blue", Vector3(-9.0, 0, 13.0), PI)
	Props.place(self, "lumbermill", Vector3(2.0, 0, -11.0), 0.0, 0.8)
	Props.place(self, "house_tall_red", Vector3(-9.5, 0, -10.5), 0.0)
	for l: Vector3 in [Vector3(-9.0, 0, 6.6), Vector3(0.0, 0, 4.0), Vector3(shore - 6.0, 0, 3.2)]:
		Props.place(self, "lantern_post", l, 0.0)
	# The dock: plank platforms on posts, from the quay out over the water.
	var sea_y := Terrain.SEA_LEVEL - position.y
	for i in 6:
		Props.place(self, "dock_tile", Vector3(shore - 1.5 + i * 3.0, 0.4 - 1.57, 0.8), 0.0)
	Props.place(self, "dock_tile_small", Vector3(shore + 13.5, 0.4 - 1.57, 3.8), 0.0)
	# Captain Mara's ship at anchor beside the end of the dock, a smaller one
	# further out, and rowboats tied up.
	Props.place(self, "ship_large", Vector3(shore + 11.0, sea_y - 0.9, 9.5), PI / 2.0 + 0.1)
	Props.place(self, "ship_medium", Vector3(shore + 32.0, sea_y - 0.9, -10.0), 2.2, 0.9)
	Props.place(self, "rowboat_kit", Vector3(shore + 4.5, sea_y - 0.35, -3.0), 0.4)
	Props.place(self, "rowboat_small", Vector3(shore + 7.5, sea_y - 0.35, -2.6), -0.2)
	# Dolphins playing out in the bay.
	for k in 2:
		Props.place(self, "dolphin", Vector3(shore + 24.0 + k * 3.0, sea_y - 0.4, 2.0 + k * 2.5), 1.2 + k * 0.3)
	# The lighthouse on its rocks, out to sea.
	_lighthouse(Vector3(shore + 18.0, sea_y, -16.0))
	# Work on the quay: crates, barrels, nets, ropes.
	var q := shore - 12.0
	for p: Array in [["crate_big", Vector3(q + 6.0, 0, -2.6)], ["crate_long", Vector3(q + 4.2, 0, -3.6)], ["barrel", Vector3(q + 7.4, 0, 3.8)], ["barrel", Vector3(q + 6.6, 0, 4.6)], ["sack", Vector3(q + 5.2, 0, 4.2)],
			["crate_bottles", Vector3(q + 2.6, 0, -3.2)], ["sea_chest", Vector3(q + 9.4, 0, -1.6)], ["rope_coil", Vector3(shore - 0.5, 0.42, 1.8)], ["wood_bucket", Vector3(shore - 1.0, 0.42, -0.2)], ["apple_barrel", Vector3(q + 4.4, 0, 4.8)],
			["crate_big", Vector3(1.0, 0, -6.0)], ["barrel", Vector3(-1.2, 0, -6.6)]]:
		Props.place(self, str(p[0]), p[1], p[1].x)
	CraftedProps.net_rack(self, Vector3(q - 1.0, 0, 8.5), 0.2)
	CraftedProps.net_rack(self, Vector3(q + 3.0, 0, 9.5), -0.2)
	CraftedProps.creel_and_rope(self, Vector3(q + 3.0, 0, 6.8), 0.5)
	Props.place(self, "flag_blue", Vector3(shore - 2.5, 0, -1.4), 0.0)
	for k in 7:
		Props.place(self, "rock_b" if k % 2 == 0 else "rock_c", Vector3(shore + 1.5 + (k % 2) * 0.6, -0.6, -13.0 + k * 3.2 if k < 4 else 4.5 + (k - 4) * 3.4), k * 1.3, 1.2)
	var sailor := {"skin": "skin_3", "hair": "hair_dark", "hair_style": "short", "shirt": "cloth_blue", "pants": "cloth_tan", "height": 1.02}
	passerby(sailor, Vector3(q + 3.0, 0, 1.5), 801, 2.5)
	var sailor2 := sailor.duplicate()
	sailor2["skin"] = "skin_1"
	sailor2["hair"] = "hair_red"
	sailor2["shirt"] = "cloth_red"
	passerby(sailor2, Vector3(-4.0, 0, -2.0), 802, 2.5)
	neighbour("mara", Vector3(shore - 3.4, 0, 2.6), 0.6)
	add_anchor("coast_mara", Vector3(shore - 3.4, 0, 2.6), -PI / 2.0)
	for t: Array in [["pine_wide", Vector3(-18.0, 0, -14.0)], ["tree_b", Vector3(-18.5, 0, 14.0)], ["pine_wide", Vector3(8.0, 0, -14.5)], ["tree_b", Vector3(-3.0, 0, 14.5)], ["pine_wide", Vector3(4.0, 0, 13.5)]]:
		Props.place(self, str(t[0]), t[1], t[1].x, 1.1)
	SoundSpot.looping(self, "river", Vector3(shore + 4.0, 0.2, 0), 26.0, -8.0)
	add_activity_focus(Vector3(shore - 7.0, 0.8, 0.5))


## How far east of the site's centre the sea begins (local x).
func _shore_x() -> float:
	var x := 8.0
	while x < 40.0 and Terrain.height(position.x + x, position.z) > Terrain.SEA_LEVEL + 0.9:
		x += 0.5
	return x


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
