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
	WorldState.fact_changed.connect(_on_fact_changed)
	Days.day_started.connect(func(_d: int) -> void: sync_with_world())
	sync_with_world()


## Construct static geometry, interactables and zones. Override.
func build() -> void:
	pass


## Make visible state match WorldState. Called on load, on new days and when
## facts change. Must be idempotent. Override.
func sync_with_world() -> void:
	pass


func _on_fact_changed(_key: String, _value: Variant) -> void:
	sync_with_world()


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
	MeshKit.path(self, a, b, width, material)
	clearings.append({"a": Vector2(position.x + a.x, position.z + a.z), "b": Vector2(position.x + b.x, position.z + b.z), "width": width + 0.4})


## Group node that can be shown/hidden together (roofs, crops, table settings).
func group_node(node_name: String) -> Node3D:
	var n := Node3D.new()
	n.name = node_name
	StaticBatch.mark_live(n) # shown and hidden by the story, so never merged
	add_child(n)
	return n
