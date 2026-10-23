class_name FarRegion
extends Region
## A place in the wider world beyond the valley (Bellhaven, the coast, the
## monastery...). It stands on one of Terrain.SITES, a level site cut into
## the hills, and is reached from the map once it has opened (regions.json
## "open_when"). It brings its own ground, gentle edges, an arrival spot,
## and the neighbours who live there. World bakes walking ground and grows
## grass for it from `area`.

## The walkable ground, in local x/z (the site's centre is the origin).
var area := Rect2(-12, -12, 24, 24)


## Ground under the whole area, invisible walls round it, the place's name
## on arrival, and the spot travel arrives at. The camera looks the way the
## child arrives facing (radians, 0 = north), toward what the place is
## about: the sea, the peaks, the fields.
func lay_ground(arrive_at: Vector3, arrive_facing := 0.0) -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = MeshKit.LAYER_GROUND
	ground.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(area.size.x + 8, 1, area.size.y + 8)
	shape.shape = box
	shape.position = Vector3(area.get_center().x, -0.5, area.get_center().y)
	ground.add_child(shape)
	add_child(ground)
	var edge := MeshKit.LAYER_INVISIBLE
	var c := area.get_center()
	MeshKit.solid(self, Vector3(1, 6, area.size.y), Vector3(area.position.x, 3, c.y), 0.0, edge)
	MeshKit.solid(self, Vector3(1, 6, area.size.y), Vector3(area.end.x, 3, c.y), 0.0, edge)
	MeshKit.solid(self, Vector3(area.size.x, 6, 1), Vector3(c.x, 3, area.position.y), 0.0, edge)
	MeshKit.solid(self, Vector3(area.size.x, 6, 1), Vector3(c.x, 3, area.end.y), 0.0, edge)
	add_discovery_zone(Vector3(c.x, 1, c.y), Vector3(area.size.x, 4, area.size.y))
	if arrive_facing != 0.0:
		add_camera_zone(Vector3(c.x, 1, c.y), Vector3(area.size.x, 4, area.size.y), {"yaw": rad_to_deg(arrive_facing)})
	add_anchor(region_id + "_arrive", arrive_at, arrive_facing)


## Someone who lives here: potters about near `at` and talks when tapped
## (their dialogue file has the same id).
func neighbour(id: String, at: Vector3, wander := 0.8) -> Wanderer:
	var look := World.look_for(id)
	var w := Wanderer.new().setup(CharacterModel.new().build(look), id.hash())
	w.name = id.capitalize()
	w.position = at
	w.radius = wander
	w.speed = 0.5
	w.pause_range = Vector2(3, 7)
	w.talk_dialogue_id = id
	add_child(w)
	MeshKit.solid(w, Vector3(0.5, 1.6, 0.5), Vector3(0, 0.8, 0), 0.0, MeshKit.LAYER_CHARACTER)
	var talk := Interactable.create(w, Vector3.ZERO, "Talk to %s" % Dialogue.character_name(id), func() -> void: Dialogue.start(id), 0.7, 1.95 * float(look.get("height", 1.0)))
	talk.reach = 2.2
	return w


## Someone in the background (no conversation): townsfolk, sailors, monks.
func passerby(look: Dictionary, at: Vector3, seed_value: int, wander := 2.5) -> Wanderer:
	var w := Wanderer.new().setup(CharacterModel.new().build(look), seed_value)
	w.position = at
	w.radius = wander
	w.speed = 0.5
	w.pause_range = Vector2(2, 6)
	add_child(w)
	return w


## Trees round the edge of the area, so it sits in its landscape.
func ring_of_trees(kinds: Array, count: int, inset := 1.5, seed_value := 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in count:
		var t := float(i) / count
		var p := _on_edge(t, inset + rng.randf_range(0.0, 2.0))
		Props.place(self, str(kinds[i % kinds.size()]), p, rng.randf() * TAU, rng.randf_range(0.9, 1.25))


## A point `inset` metres inside the area's edge, `t` (0..1) of the way round.
func _on_edge(t: float, inset: float) -> Vector3:
	var r := area.grow(-inset)
	var per := 2.0 * (r.size.x + r.size.y)
	var d := fmod(t, 1.0) * per
	if d < r.size.x:
		return Vector3(r.position.x + d, 0, r.position.y)
	d -= r.size.x
	if d < r.size.y:
		return Vector3(r.end.x, 0, r.position.y + d)
	d -= r.size.y
	if d < r.size.x:
		return Vector3(r.end.x - d, 0, r.end.y)
	d -= r.size.x
	return Vector3(r.position.x, 0, r.end.y - d)
