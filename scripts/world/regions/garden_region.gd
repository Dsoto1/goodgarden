class_name GardenRegion
extends Region
## Miriam's garden: three raised beds inside a fence. Bed 1 is the child's
## bean row. Its look is derived entirely from the "garden.bed_1" fact and
## the current day, so the row grows across days and survives reloads.

const BED_X := 0.5
const BED_LENGTH := 7.0
const BED_ROWS := {"cabbages": -3.2, "flowers": 0.0, "bed_1": 3.2}

var _bed_1_plants: Node3D
var _bed_1_ready: Node3D


func build() -> void:
	# Fence with a gate gap on the west side, facing the home path.
	Props.fence(self, "fence_wood", Vector3(-6, 0, -5.5), Vector3(6, 0, -5.5))
	Props.fence(self, "fence_wood", Vector3(-6, 0, 5.5), Vector3(6, 0, 5.5))
	Props.fence(self, "fence_wood", Vector3(6, 0, -5.5), Vector3(6, 0, 5.5))
	Props.fence(self, "fence_wood", Vector3(-6, 0, -5.5), Vector3(-6, 0, -1.2))
	Props.fence(self, "fence_wood", Vector3(-6, 0, 1.2), Vector3(-6, 0, 5.5))
	for z: float in [-1.2, 1.2]:
		MeshKit.box(self, Vector3(0.2, 2.3, 0.2), Vector3(-6, 1.15, z), "wood")
	MeshKit.box(self, Vector3(0.3, 0.2, 2.8), Vector3(-6, 2.3, 0), "wood")
	MeshKit.roof(self, 0.9, 0.4, 3.0, Vector3(-6, 2.6, 0), "roof_thatch")

	for bed_name: String in BED_ROWS:
		_bed_frame(BED_ROWS[bed_name])
	_cabbages(BED_ROWS["cabbages"])
	for i in 7:
		Props.place(self, "flowers_a" if i % 2 == 0 else "flowers_b", Vector3(BED_X - 3.0 + i * 1.0, 0.28, BED_ROWS["flowers"]), i * 1.3, 0.8)
	for i in 3:
		var b := Wanderer.new().setup(AnimalModel.make("butterfly"), 40 + i)
		b.gait = "flutter"
		b.radius = 1.5 + i * 0.5
		b.position = Vector3(BED_X - 2.0 + i * 2.0, 0.3, BED_ROWS["flowers"])
		add_child(b)

	# The child's bed: plants are rebuilt from world facts in sync_with_world().
	_bed_1_plants = group_node("Bed1Plants")
	_bed_1_ready = group_node("Bed1Ready")
	var z1: float = BED_ROWS["bed_1"]
	for i in 6:
		MeshKit.box(_bed_1_ready, Vector3(BED_LENGTH - 0.4, 0.02, 0.06), Vector3(BED_X, 0.31, z1 - 0.4 + i * 0.16), "soil_dark")
	MeshKit.box(_bed_1_ready, Vector3(0.3, 0.12, 0.2), Vector3(BED_X - 3.8, 0.06, z1 + 0.9), "cloth_cream")
	MeshKit.box(_bed_1_ready, Vector3(0.9, 0.04, 0.06), Vector3(BED_X - 2.9, 0.33, z1 + 0.7), "wood_light")
	var bed_use := Interactable.create(self, Vector3(BED_X, 0, z1 + 1.2), "Look at the bean row", _on_bed_used, 0.9, 1.1)
	bed_use.reach = 2.2
	bed_use.focus_point = position + Vector3(BED_X, 0.3, z1)
	var focus := Marker3D.new()
	focus.position = Vector3(BED_X, 0.3, z1)
	focus.add_to_group("activity_focus")
	add_child(focus)

	# Shed, barrel and tools.
	MeshKit.box(self, Vector3(2.0, 2.0, 1.6), Vector3(4.6, 1.0, -4.3), "wood_dark", true)
	MeshKit.roof(self, 2.4, 0.8, 2.0, Vector3(4.6, 2.4, -4.3), "roof_red", PI / 2.0)
	MeshKit.box(self, Vector3(0.7, 1.5, 0.06), Vector3(4.6, 0.75, -3.48), "wood")
	Props.place(self, "barrel", Vector3(-5.0, 0, -4.6), 0.0, 1.2)
	Props.place(self, "bucket", Vector3(-4.3, 0, -4.8), 0.4)
	Props.place(self, "wheelbarrow", Vector3(3.2, 0, -4.4), 1.4)
	Props.place(self, "crate_lettuce", Vector3(5.2, 0, -1.8), 0.2)
	Props.place(self, "crate_carrots", Vector3(5.2, 0, -0.8), -0.1)
	Props.place(self, "sack", Vector3(-4.9, 0, 4.6), 0.5)
	Props.place(self, "tree_b", Vector3(-10.6, 0, -8.4), 0.3)
	Props.place(self, "tree_a", Vector3(8.0, 0, 6.5), 1.1)
	Props.place(self, "mushroom", Vector3(7.4, 0, 7.3), 0.4)
	Props.place(self, "fern", Vector3(-6.6, 0, -3.4), 0.2)
	CraftedProps.watering_can(self, Vector3(-4.1, 0, -1.7), 2.4)
	# From day 4 the beans are thirsty: the watering can starts the watering.
	var water := Interactable.create(self, Vector3(-4.1, 0, -1.7), "Water the beans", func() -> void:
		get_tree().call_group("main", "start_activity_here", "garden_water", position + Vector3(BED_X, 0.3, BED_ROWS["bed_1"])), 0.6, 1.0)
	water.conditions = [{"day_at_least": 4}, {"fact": "garden.bed_1", "exists": true}]
	# From the second week the beans are tall enough to measure, block by block.
	var measure_at := Vector3(BED_X + BED_LENGTH / 2.0 + 0.9, 0, BED_ROWS["bed_1"] + 0.5)
	MeshKit.box(self, Vector3(0.4, 0.25, 0.3), measure_at + Vector3(0, 0.125, -0.5), "wood_light")
	var measure := Interactable.create(self, measure_at, "Measure the bean plants", func() -> void:
		get_tree().call_group("main", "start_activity_here", "garden_measure", position + Vector3(BED_X, 0.5, BED_ROWS["bed_1"])), 0.6, 1.2)
	measure.conditions = [{"day_at_least": 9}, {"fact": "garden.bed_1", "exists": true}]
	CraftedProps.scarecrow(self, Vector3(3.2, 0, 4.4), 0.3)
	# Miriam's mustard plant, grown from the tiniest seed, in the corner by the fence.
	CraftedProps.mustard_plant(self, Vector3(5.2, 0, 1.6), 11, 1.9)
	CraftedProps.mustard_plant(self, Vector3(5.5, 0, 2.5), 5, 1.4)
	var mustard := Interactable.create(self, Vector3(4.6, 0, 2.0), "Look at the mustard plant", func() -> void:
		get_tree().call_group("main", "show_caption", tr("Miss Miriam's mustard plant. It grew from a seed smaller than a crumb, and now it is taller than you!")), 0.6, 2.1)
	mustard.reach = 1.6
	# Bees for the beans' flowers, just outside the fence.
	CraftedProps.bee_skeps(self, Vector3(-1.2, 0, -8.4), PI)

	for z: float in BED_ROWS.values():
		add_clearing(Vector3(BED_X, 0, z), Vector2(BED_LENGTH + 0.6, 1.8))
	add_clearing(Vector3(4.6, 0, -4.3), Vector2(2.6, 2.2))
	# From the lane, through the gate, up to the beds.
	path([Vector3(-8.4, 0, -0.3), Vector3(-7.0, 0, 0.2), Vector3(-5.0, 0, -0.1), Vector3(-3.4, 0, 0.0)], 1.3)
	add_anchor("garden_gate", Vector3(-7.6, 0, 0), -PI / 2.0)
	add_anchor("garden_miriam", Vector3(-4.3, 0, 3.6), -PI / 2.0)
	add_discovery_zone(Vector3(0, 1, 0), Vector3(12, 3, 11))


func _bed_frame(z: float) -> void:
	MeshKit.box(self, Vector3(BED_LENGTH, 0.28, 1.3), Vector3(BED_X, 0.14, z), "soil", false)
	for dz: float in [-0.7, 0.7]:
		MeshKit.box(self, Vector3(BED_LENGTH + 0.2, 0.35, 0.12), Vector3(BED_X, 0.17, z + dz), "wood")
	for dx: float in [-1.0, 1.0]:
		MeshKit.box(self, Vector3(0.12, 0.35, 1.5), Vector3(BED_X + dx * BED_LENGTH / 2.0, 0.17, z), "wood")
	MeshKit.solid(self, Vector3(BED_LENGTH + 0.2, 0.8, 1.5), Vector3(BED_X, 0.4, z))


func _cabbages(z: float) -> void:
	for i in 7:
		var x := BED_X - 3.0 + i
		MeshKit.sphere(self, 0.28, Vector3(x, 0.38, z), "leaf_light", Vector3(1.0, 0.7, 1.0), 7, 4)
		MeshKit.sphere(self, 0.18, Vector3(x, 0.45, z), "leaf", Vector3.ONE, 6, 3)


func _on_bed_used() -> void:
	if ActivityRunner.can_start("garden_bean_row"):
		# Planting is offered through Miriam, who explains what the row needs.
		var miriam := get_tree().get_first_node_in_group("npc_miriam") as NPC
		if miriam and miriam.visible:
			miriam.talk.trigger()
			return
	get_tree().call_group("main", "show_caption", _describe_bed())


func _describe_bed() -> String:
	var bed: Variant = WorldState.get_fact("garden.bed_1")
	if bed == null:
		return tr("The soil is smooth and ready. A little bag of bean seeds sits at the end of the row.")
	match growth_stage(bed):
		0: return tr("Little mounds of soil cover the seeds. They're resting.")
		1: return tr("Tiny green loops are pushing up through the soil!")
		2: return tr("The baby bean plants have opened their first leaves.")
		_:
			if WorldState.get_fact("garden.watered") != null:
				return tr("The bean plants are climbing their poles, and little green beans are hanging down!")
			return tr("The bean plants are climbing their poles.")


## 0 = just sown, 1 = sprouts, 2 = seedlings, 3 = climbing plants.
static func growth_stage(bed: Dictionary) -> int:
	return clampi(Days.current_day - int(bed.get("planted_day", Days.current_day)), 0, 3)


func sync_with_world() -> void:
	for c in _bed_1_plants.get_children():
		c.queue_free()
	var bed: Variant = WorldState.get_fact("garden.bed_1")
	_bed_1_ready.visible = bed == null
	if bed == null:
		return
	var z1: float = BED_ROWS["bed_1"]
	var stage := growth_stage(bed)
	var positions: Array = bed.get("positions", [])
	if positions.is_empty():
		for i in int(bed.get("holes", 4)):
			positions.append((i + 1.0) / (int(bed.get("holes", 4)) + 1.0))
	# Board row 80..940 maps onto the soil from the west end to the east end.
	for f: Variant in positions:
		var x := BED_X - BED_LENGTH / 2.0 + 0.2 + float(f) * (BED_LENGTH - 0.4)
		var at := Vector3(x, 0.28, z1)
		match stage:
			0:
				MeshKit.sphere(_bed_1_plants, 0.16, at, "soil_dark", Vector3(1.0, 0.35, 1.0), 6, 3)
			1:
				for k in 2:
					var sprout := MeshKit.cylinder(_bed_1_plants, 0.02, 0.025, 0.18, at + Vector3(k * 0.1 - 0.05, 0.08, 0), "sprout", 4)
					sprout.rotation.z = 0.5 - k
			2:
				MeshKit.cylinder(_bed_1_plants, 0.025, 0.03, 0.35, at + Vector3(0, 0.17, 0), "sprout", 5)
				MeshKit.sphere(_bed_1_plants, 0.1, at + Vector3(-0.08, 0.36, 0), "leaf_light", Vector3(1.0, 0.4, 0.7), 6, 3)
				MeshKit.sphere(_bed_1_plants, 0.1, at + Vector3(0.08, 0.36, 0), "leaf_light", Vector3(1.0, 0.4, 0.7), 6, 3)
			_:
				MeshKit.cylinder(_bed_1_plants, 0.025, 0.03, 1.6, at + Vector3(0, 0.8, 0), "wood_light", 4)
				for h in 4:
					MeshKit.sphere(_bed_1_plants, 0.14, at + Vector3(0.08 * (1 - (h % 2) * 2), 0.35 + h * 0.3, 0.05), "leaf", Vector3(1.0, 0.6, 0.8), 6, 3)
				MeshKit.sphere(_bed_1_plants, 0.05, at + Vector3(0.1, 1.2, 0.1), "bean_flower", Vector3.ONE, 5, 3)
	# Once measured, a notched measuring stick stays at the end of the row.
	if WorldState.has_fact("garden.measured"):
		var stick_at := Vector3(BED_X + BED_LENGTH / 2.0 + 0.15, 0, z1 + 0.35)
		MeshKit.box(_bed_1_plants, Vector3(0.06, 1.5, 0.04), stick_at + Vector3(0, 0.75, 0), "wood_light")
		for k in 7:
			MeshKit.box(_bed_1_plants, Vector3(0.1, 0.015, 0.05), stick_at + Vector3(0.02, 0.2 + k * 0.2, 0), "wood_dark")
	# Watered today: dark, damp soil round each plant. Once watered, the
	# climbing beans hang with pods.
	var watered: Variant = WorldState.get_fact("garden.watered")
	if watered != null:
		for f: Variant in positions:
			var x := BED_X - BED_LENGTH / 2.0 + 0.2 + float(f) * (BED_LENGTH - 0.4)
			if int(watered) == Days.current_day:
				MeshKit.sphere(_bed_1_plants, 0.3, Vector3(x, 0.285, z1), "soil_dark", Vector3(1.0, 0.03, 0.8), 10, 2)
			if stage >= 3:
				for k in 3:
					var pod := MeshKit.cylinder(_bed_1_plants, 0.018, 0.025, 0.2, Vector3(x + 0.12 - k * 0.12, 0.65 + k * 0.28, z1 + 0.12), "leaf_light", 5)
					pod.rotation.z = 0.25
	# A little wooden label at the row's end, the child's mark on the garden.
	MeshKit.box(_bed_1_plants, Vector3(0.04, 0.4, 0.04), Vector3(BED_X - BED_LENGTH / 2.0 + 0.1, 0.45, z1 + 0.5), "wood_light")
	MeshKit.box(_bed_1_plants, Vector3(0.22, 0.14, 0.03), Vector3(BED_X - BED_LENGTH / 2.0 + 0.1, 0.62, z1 + 0.5), "cloth_cream")
