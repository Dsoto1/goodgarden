class_name Region
extends Node3D
## Base for an independently loadable world region (Home, Garden, Village...).
##
## Each region is its own scene, built in local coordinates and placed by
## World from content/world/regions.json. Regions keep their visible state in
## sync with WorldState facts, so the world remembers the child's work across
## days and reloads. Future regions (Bellhaven, the Abbey) follow the same
## contract and can be streamed in and out by distance.

var region_id := ""
var display_name := ""
## Areas (world space) where ground cover must not grow: floors, paths, beds.
## Each is {"rect": Rect2} in x/z, or {"a": Vector2, "b": Vector2, "width": float}.
var clearings: Array[Dictionary] = []


func _ready() -> void:
	build()
	_build_job_spots()
	WorldState.fact_changed.connect(_on_fact_changed)
	Days.day_started.connect(func(_d: int) -> void: sync_with_world())
	Days.day_started.connect(func(_d: int) -> void: _sync_job_spots())
	sync_with_world()
	_sync_job_spots()


## Job spots (content/world/job_spots.json): places in this region where a
## day's work is started, each with a little sign of the work waiting (a
## crate, a basket, a table). The thing shows from its first day until the
## end of that week ("until_day"); the prompt only while the activity can be
## started.
##   {"region", "at": [x, y, z], "prompt", "activity", "from_day", "until_day"?,
##    "look": "crate"|"basket"|"table"|"none", "conditions"?: [...]}
var _job_props: Array[Array] = [] # [node, from_day, until_day]


func _build_job_spots() -> void:
	for spot: Dictionary in Content.get_world("job_spots").get("spots", []):
		if str(spot.get("region", "")) != region_id:
			continue
		var a: Array = spot["at"]
		var at := Vector3(a[0], a[1], a[2])
		var activity := str(spot["activity"])
		var from_day := int(spot.get("from_day", 1))
		var until_day := int(spot.get("until_day", from_day + 5 - (from_day - 1) % 7))
		var holder := group_node("JobSpot_" + activity)
		match str(spot.get("look", "crate")):
			"crate":
				MeshKit.box(holder, Vector3(0.6, 0.4, 0.45), at + Vector3(0, 0.2, 0), "wood")
				MeshKit.box(holder, Vector3(0.5, 0.04, 0.35), at + Vector3(0, 0.41, 0), "wood_light")
			"basket":
				MeshKit.cylinder(holder, 0.24, 0.18, 0.26, at + Vector3(0, 0.13, 0), "wood_light", 10)
			"table":
				MeshKit.box(holder, Vector3(1.0, 0.06, 0.6), at + Vector3(0, 0.7, 0), "wood_light")
				for x: float in [-0.42, 0.42]:
					MeshKit.box(holder, Vector3(0.06, 0.7, 0.5), at + Vector3(x, 0.35, 0), "wood_dark")
		_job_props.append([holder, from_day, until_day])
		var focus := position + at + Vector3(0, 0.8, 0)
		var it := Interactable.create(self, at + Vector3(0, 0, 0.7), str(spot["prompt"]), func() -> void:
			get_tree().call_group("main", "start_activity_here", activity, focus), 0.7, 1.3)
		it.conditions = [{"day_at_least": from_day}, {"not": {"day_at_least": until_day + 1}}, {"can_start": activity}] + spot.get("conditions", [])


func _sync_job_spots() -> void:
	for entry: Array in _job_props:
		(entry[0] as Node3D).visible = Days.current_day >= int(entry[1]) and Days.current_day <= int(entry[2])


## Construct static geometry, interactables and zones. Override.
func build() -> void:
	pass


## Make visible state match WorldState. Called on load, on new days and when
## facts change. Must be idempotent. Override.
func sync_with_world() -> void:
	pass


func _on_fact_changed(_key: String, _value: Variant) -> void:
	sync_with_world()


## Where the camera looks when work is started from a conversation nearby
## (the bean row, the bread table, the troughs).
func add_activity_focus(local_pos: Vector3) -> void:
	var focus := Marker3D.new()
	focus.position = local_pos
	focus.add_to_group("activity_focus")
	add_child(focus)


## Named spot used for spawning and NPC placement ("garden_beds", "home_bed").
func add_anchor(anchor_id: String, local_pos: Vector3, facing_y := 0.0) -> Marker3D:
	var m := Marker3D.new()
	m.name = "Anchor_%s" % anchor_id
	m.position = local_pos
	m.rotation.y = facing_y
	m.set_meta("anchor_id", anchor_id)
	m.add_to_group("anchors")
	add_child(m)
	return m


## Walking into this volume discovers the region for the map.
func add_discovery_zone(center: Vector3, size: Vector3) -> Zone:
	var z := Zone.create(self, center, size)
	z.player_entered.connect(func() -> void: Discovery.enter(region_id))
	z.player_exited.connect(func() -> void: Discovery.leave(region_id))
	return z


## A smaller named spot within a region (e.g. "The River"): it labels the HUD
## while the child is there but is not a map destination.
func add_place_zone(place_id: String, center: Vector3, size: Vector3) -> Zone:
	var z := Zone.create(self, center, size)
	z.player_entered.connect(func() -> void: Discovery.enter(place_id, false))
	z.player_exited.connect(func() -> void: Discovery.leave(place_id))
	return z


## An interior: hides the roof/front wall while the child is inside and tells
## World which mood to use ("home" or "chapel").
func add_interior(mood: String, center: Vector3, size: Vector3, cutaway: Array[Node3D]) -> Zone:
	var z := Zone.create(self, center, size)
	z.player_entered.connect(func() -> void:
		for n in cutaway:
			n.visible = false
		get_tree().call_group("mood_listeners", "on_mood_entered", mood))
	z.player_exited.connect(func() -> void:
		for n in cutaway:
			n.visible = true
		get_tree().call_group("mood_listeners", "on_mood_exited", mood))
	return z


## Changes camera framing while inside, e.g. a vista toward Bellhaven.
func add_camera_zone(center: Vector3, size: Vector3, framing: Dictionary) -> Zone:
	var z := Zone.create(self, center, size)
	z.player_entered.connect(func() -> void: get_tree().call_group("camera_rig", "push_zone", framing))
	z.player_exited.connect(func() -> void: get_tree().call_group("camera_rig", "pop_zone", framing))
	return z


## Keeps grass and flowers off a rectangle (local centre and x/z size).
func add_clearing(center: Vector3, size: Vector2) -> void:
	var c := position + center
	clearings.append({"rect": Rect2(c.x - size.x / 2.0, c.z - size.y / 2.0, size.x, size.y)})


## A path strip that also keeps ground cover off itself.
func road(a: Vector3, b: Vector3, width := 1.6, material := "path") -> void:
	path([a, b], width, material)


## A footpath flowing through `points` (see PathKit), kept clear of grass.
func path(points: Array, width := 1.6, material := "path") -> void:
	var laid := PathKit.lay(self, points, width, material, hash(points))
	var line: Array[Vector3] = laid["line"]
	var stride := 4
	for i in range(0, line.size() - 1, stride):
		var a := line[i]
		var b := line[mini(i + stride, line.size() - 1)]
		clearings.append({"a": Vector2(position.x + a.x, position.z + a.z), "b": Vector2(position.x + b.x, position.z + b.z), "width": width + 0.3})


## Group node that can be shown/hidden together (roofs, crops, table settings).
func group_node(node_name: String) -> Node3D:
	var n := Node3D.new()
	n.name = node_name
	StaticBatch.mark_live(n) # shown and hidden by the story, so never merged
	add_child(n)
	return n
