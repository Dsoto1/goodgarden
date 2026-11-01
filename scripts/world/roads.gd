class_name Roads
extends Node3D
## The roads out of the valley, walkable. Each road in `Terrain.ROADS` gets
## ground built from the very triangles of the visible land (so the child
## walks on what they see), an invisible verge either side to keep to the
## road, a gate that stays shut until the place it leads to has opened, and
## walking ground for tap-to-walk, linked to the valley's and each place's.
## The valley's edge and each place's edge leave a gap where a road comes
## through (`edge`).

## Where each road leads (by index in Terrain.ROADS).
const PLACES := ["wilderness", "farmlands", "lake", "coast", "monastery", "mountains", "city"]
## How far each verge stands from the middle of the road. A little wider than
## the painted dirt, and as wide as the stone bridge's parapets.
const VERGE := 2.3
## Gates: road, metres along it, and the places whose opening opens it. The
## coast road leads to the monastery and the mountains too, so it opens with
## them; a second gate past the monastery turning waits for the coast.
const GATES := [
	[0, 6.0, ["wilderness"]], [1, 2.0, ["farmlands"]], [2, 2.0, ["lake"]],
	[3, 3.0, ["coast", "monastery", "mountains"]], [3, 66.0, ["coast"]],
	[4, 6.0, ["monastery", "mountains"]], [5, 6.0, ["mountains"]], [6, 2.0, ["city"]],
]
## The land's grid (Terrain.build_mesh): size and cell.
const GRID_SIZE := 640.0
const GRID_STEP := 4.0

var _gates: Array = [] # [node, blocker, place ids]
var _areas: Array[Rect2] = [] # each place's walkable area, in world x/z


## Builds the roads; `areas` are the places' walkable areas in world x/z.
func build(areas: Array[Rect2]) -> void:
	_areas = areas
	var ground := StaticBody3D.new()
	ground.name = "RoadGround"
	ground.collision_layer = MeshKit.LAYER_GROUND
	ground.collision_mask = 0
	add_child(ground)
	var verges := StaticBody3D.new()
	verges.name = "Verges"
	verges.collision_layer = MeshKit.LAYER_INVISIBLE
	verges.collision_mask = 0
	add_child(verges)
	var source := NavigationMeshSourceGeometryData3D.new()
	# Ground: every cell of the land near a road. Walking ground: the same,
	# beyond the valley and the places (which have their own), joined to
	# theirs by links where each road comes in.
	var all := SurfaceTool.new()
	all.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nav := SurfaceTool.new()
	nav.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells := {}
	var half := GRID_SIZE / 2.0
	for i in Terrain.ROADS.size():
		var line := walk_line(i)
		var box := Rect2(line[0], Vector2.ZERO)
		for p: Vector2 in line:
			box = box.expand(p)
		box = box.grow(8.0)
		for ci in range(int((box.position.x + half) / GRID_STEP), int((box.end.x + half) / GRID_STEP) + 1):
			for cj in range(int((box.position.y + half) / GRID_STEP), int((box.end.y + half) / GRID_STEP) + 1):
				var key := ci * 10000 + cj
				if cells.has(key):
					continue
				var c := Vector2(-half + (ci + 0.5) * GRID_STEP, -half + (cj + 0.5) * GRID_STEP)
				if _line_distance(line, c) >= 6.5 or ValleyRegion.BOUNDS.grow(-1.0).has_point(c) or _in_area(c, -2.0):
					continue
				cells[key] = true
				Terrain.cell_faces(all, ci, cj, GRID_SIZE, GRID_STEP)
				if not ValleyRegion.BOUNDS.grow(1.0).has_point(c) and not _in_area(c, 1.0) and Terrain.river_bank_distance(c.x, c.y) > -1.0:
					Terrain.cell_faces(nav, ci, cj, GRID_SIZE, GRID_STEP)
	_bridge_decks(source)
	var faces: PackedVector3Array = all.commit_to_arrays()[Mesh.ARRAY_VERTEX]
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = shape
	ground.add_child(cs)
	var nav_faces: PackedVector3Array = nav.commit_to_arrays()[Mesh.ARRAY_VERTEX]
	source.add_faces(nav_faces, Transform3D.IDENTITY)
	for i in Terrain.ROADS.size():
		_verges(i, verges, source)
		_links(i)
		_name_zone(i)
	for g: Array in GATES:
		_gate(g[0], g[1], g[2])
	_bake(source)
	sync()
	Days.day_started.connect(func(_d: int) -> void: sync())
	WorldState.fact_changed.connect(func(_k: String, _v: Variant) -> void: sync())


## Opens each gate once a place it leads to has opened (or been visited).
func sync() -> void:
	var entries := {}
	for entry: Dictionary in Content.get_world("regions").get("regions", []):
		entries[entry["id"]] = entry
	for g: Array in _gates:
		var open := false
		for id: String in g[2]:
			if Discovery.is_discovered(id) or (entries.has(id) and World.is_open(entries[id])):
				open = true
		(g[0] as Node3D).visible = not open
		(g[1] as StaticBody3D).collision_layer = 0 if open else MeshKit.LAYER_INVISIBLE


## A road's line as the child walks it: from just inside the valley (or
## where it leaves another road) to its place.
static func walk_line(i: int) -> PackedVector2Array:
	var road: Array = Terrain.ROADS[i]
	var line := PackedVector2Array()
	for p: Vector2 in road:
		line.append(p)
	if is_branch(i) or ValleyRegion.BOUNDS.has_point(line[0]):
		return line
	var back := (line[0] - line[1]).normalized()
	var p := line[0]
	for k in 60:
		p += back * 0.5
		if ValleyRegion.BOUNDS.grow(-2.0).has_point(p):
			break
	line.insert(0, p)
	return line


## Whether road `i` leaves another road rather than the valley.
static func is_branch(i: int) -> bool:
	var start: Vector2 = Terrain.ROADS[i][0]
	for j in i:
		if _line_distance(Terrain.ROADS[j], start) < 3.0:
			return true
	return false


## How far `p` is from the nearest walkable road's middle.
static func distance(p: Vector2) -> float:
	var best := INF
	for i in Terrain.ROADS.size():
		best = minf(best, _line_distance(walk_line(i), p))
	return best


## An invisible edge from `a` to `b` (in `parent`'s space), with a gap
## wherever a road comes through it. The valley and each place use it.
static func edge(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var origin := Vector2(parent.position.x, parent.position.z)
	var wa := origin + Vector2(a.x, a.z)
	var wb := origin + Vector2(b.x, b.z)
	var length := wa.distance_to(wb)
	var dir := (wb - wa) / length
	var gaps: Array[Vector2] = []
	for i in Terrain.ROADS.size():
		var line := walk_line(i)
		for k in range(1, line.size()):
			var hit: Variant = Geometry2D.segment_intersects_segment(wa, wb, line[k - 1], line[k])
			if hit == null:
				continue
			var along := (hit as Vector2).distance_to(wa)
			var sine := absf(dir.cross((line[k] - line[k - 1]).normalized()))
			var w := minf(VERGE / maxf(sine, 0.3) + 0.6, 8.0)
			gaps.append(Vector2(along - w, along + w))
	gaps.sort_custom(func(x: Vector2, y: Vector2) -> bool: return x.x < y.x)
	var pieces: Array[Vector2] = []
	var from := 0.0
	for g: Vector2 in gaps:
		if g.x > from:
			pieces.append(Vector2(from, g.x))
		from = maxf(from, g.y)
	if from < length:
		pieces.append(Vector2(from, length))
	var yaw := atan2(dir.x, dir.y)
	var la := Vector2(a.x, a.z)
	for piece: Vector2 in pieces:
		if piece.y - piece.x < 0.05:
			continue
		var mid := la + dir * (piece.x + piece.y) / 2.0
		MeshKit.solid(parent, Vector3(1, 6, piece.y - piece.x), Vector3(mid.x, a.y + 3.0, mid.y), yaw, MeshKit.LAYER_INVISIBLE)


static func _line_distance(line: Variant, p: Vector2) -> float:
	var best := INF
	for k in range(1, line.size()):
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, line[k - 1], line[k])))
	return best


func _in_area(p: Vector2, grow: float) -> bool:
	for a: Rect2 in _areas:
		if a.grow(grow).has_point(p):
			return true
	return false


## A verge stays open where the road is in the valley or a place, where it
## meets another road, and on the bridge (whose parapets keep the child on).
func _verge_open(p: Vector2, i: int) -> bool:
	if ValleyRegion.BOUNDS.has_point(p) or _in_area(p, 0.0):
		return true
	for j in Terrain.ROADS.size():
		if j != i and _line_distance(walk_line(j), p) < VERGE + 0.4:
			return true
	for w: Array in Terrain.WAYSIDES:
		if w[1] == "bridge" and absf(p.x - w[0].x) < 3.0 and absf(p.y - w[0].y) < StoneBridge.LENGTH * 0.75:
			return true
	return false


## Both verges of road `i`: short invisible walls along each side, mitred at
## the bends, skipped where the verge is open.
func _verges(i: int, body: StaticBody3D, source: NavigationMeshSourceGeometryData3D) -> void:
	var line := walk_line(i)
	for side: float in [-1.0, 1.0]:
		var offset := PackedVector2Array()
		for k in line.size():
			var n_in := Vector2.ZERO if k == 0 else (line[k] - line[k - 1]).normalized().orthogonal()
			var n_out := Vector2.ZERO if k == line.size() - 1 else (line[k + 1] - line[k]).normalized().orthogonal()
			var n := (n_in + n_out).normalized()
			var seg := n_out if k < line.size() - 1 else n_in
			offset.append(line[k] + n * side * VERGE / maxf(n.dot(seg), 0.5))
		var pts: Array[Vector2] = []
		for k in range(1, offset.size()):
			var steps := maxi(1, int(ceil(offset[k - 1].distance_to(offset[k]))))
			for s in steps:
				pts.append(offset[k - 1].lerp(offset[k], float(s) / steps))
		pts.append(offset[offset.size() - 1])
		for k in range(1, pts.size()):
			var a := pts[k - 1]
			var b := pts[k]
			if _verge_open(a, i) or _verge_open(b, i):
				continue
			var mid := (a + b) / 2.0
			var length := a.distance_to(b) + 0.15
			var xform := Transform3D(Basis(Vector3.UP, atan2(b.x - a.x, b.y - a.y)), Vector3(mid.x, Terrain.height(mid.x, mid.y) + 1.0, mid.y))
			var box := BoxShape3D.new()
			box.size = Vector3(0.3, 3.0, length)
			var cs := CollisionShape3D.new()
			cs.shape = box
			cs.transform = xform
			body.add_child(cs)
			source.add_faces(_box_faces(box.size), xform)


## Links the road's walking ground to the valley's and its place's where it
## comes through their edges, so tap-to-walk finds the way along it.
func _links(i: int) -> void:
	var line := walk_line(i)
	var inside_before := false
	var first := true
	for k in range(1, line.size()):
		var a := line[k - 1]
		var b := line[k]
		var steps := maxi(1, int(ceil(a.distance_to(b) / 0.25)))
		var dir := (b - a).normalized()
		for s in steps + 1:
			var p := a.lerp(b, float(s) / steps)
			var inside := ValleyRegion.BOUNDS.has_point(p) or _in_area(p, 0.0)
			if not first and inside != inside_before:
				# Crossing an edge: in = 2 m inside, out = 5 m outside.
				var into := dir if inside else -dir
				_link(p + into * 2.0, p - into * 5.0)
			inside_before = inside
			first = false


func _link(inner: Vector2, outer: Vector2) -> void:
	var l := NavigationLink3D.new()
	l.bidirectional = true
	l.start_position = Vector3(inner.x, Terrain.height(inner.x, inner.y), inner.y)
	l.end_position = Vector3(outer.x, Terrain.height(outer.x, outer.y), outer.y)
	add_child(l)


## The road's name on the HUD while the child walks it ("The Coast Road").
func _name_zone(i: int) -> void:
	var id: String = "road_" + str(PLACES[i])
	var line := walk_line(i)
	var zone: Zone = null
	for k in range(1, line.size()):
		var steps := maxi(1, int(ceil(line[k - 1].distance_to(line[k]) / 4.0)))
		for s in steps:
			var p := line[k - 1].lerp(line[k], float(s) / steps)
			if ValleyRegion.BOUNDS.grow(3.0).has_point(p) or _in_area(p, 3.0):
				continue # (the zone reaches 3 m round each point)
			var at := Vector3(p.x, Terrain.height(p.x, p.y) + 1.5, p.y)
			if zone == null:
				zone = Zone.create(self, at, Vector3(6, 5, 6))
			else:
				zone.add_box(at, Vector3(6, 5, 6))
	if zone:
		zone.player_entered.connect(func() -> void: Discovery.enter(id, false))
		zone.player_exited.connect(func() -> void: Discovery.leave(id))


## A gate across road `i`, `at` metres along its own line, shut until one of
## `places` opens: a wooden fence and an invisible bar.
func _gate(i: int, at: float, places: Array) -> void:
	var road: Array = Terrain.ROADS[i]
	var walked := 0.0
	var p: Vector2 = road[0]
	var dir := Vector2.ZERO
	for k in range(1, road.size()):
		var seg: float = road[k - 1].distance_to(road[k])
		dir = (road[k] - road[k - 1]).normalized()
		if walked + seg >= at:
			p = road[k - 1] + dir * (at - walked)
			break
		walked += seg
	var across := dir.orthogonal() * (VERGE + 0.2)
	var node := Node3D.new()
	node.name = "Gate_" + PLACES[i]
	add_child(node)
	var left := Vector3(p.x + across.x, 0, p.y + across.y)
	var right := Vector3(p.x - across.x, 0, p.y - across.y)
	left.y = Terrain.height(left.x, left.z)
	right.y = Terrain.height(right.x, right.z)
	for v: Vector3 in [left, right]:
		MeshKit.box(node, Vector3(0.22, 1.3, 0.22), v + Vector3(0, 0.65, 0), "wood_dark")
	for h: float in [0.45, 0.9]:
		var rail := MeshKit.box(node, Vector3(0.12, 0.14, left.distance_to(right)), (left + right) / 2.0 + Vector3(0, h, 0), "wood")
		rail.rotation.y = atan2(right.x - left.x, right.z - left.z)
		rail.rotation.x = -atan2(right.y - left.y, Vector2(right.x - left.x, right.z - left.z).length())
	var blocker := MeshKit.solid(self, Vector3(0.4, 3.0, left.distance_to(right) + 0.4), (left + right) / 2.0 + Vector3(0, 1.5, 0), atan2(right.x - left.x, right.z - left.z), MeshKit.LAYER_INVISIBLE)
	_gates.append([node, blocker, places])


## A box's twelve triangles, centred on the origin.
static func _box_faces(size: Vector3) -> PackedVector3Array:
	var h := size / 2.0
	var c := []
	for k in 8:
		c.append(Vector3(h.x if k & 1 else -h.x, h.y if k & 2 else -h.y, h.z if k & 4 else -h.z))
	var out := PackedVector3Array()
	for q: Array in [[0, 1, 3, 2], [4, 6, 7, 5], [0, 4, 5, 1], [2, 3, 7, 6], [0, 2, 6, 4], [1, 5, 7, 3]]:
		for t: int in [0, 1, 2, 0, 2, 3]:
			out.append(c[q[t]])
	return out


## The walking ground over each road bridge: its deck, from Waysides.
func _bridge_decks(source: NavigationMeshSourceGeometryData3D) -> void:
	for w: Array in Terrain.WAYSIDES:
		if w[1] != "bridge":
			continue
		var xform := Waysides.bridge_transform(w)
		var faces := PackedVector3Array()
		var inner := StoneBridge.WIDTH / 2.0 - 0.3
		var n := StoneBridge.SAMPLES
		for k in n:
			var z0 := -StoneBridge.LENGTH / 2.0 + StoneBridge.LENGTH * k / n
			var z1 := -StoneBridge.LENGTH / 2.0 + StoneBridge.LENGTH * (k + 1) / n
			var a := Vector3(-inner, StoneBridge.deck_y(z0), z0)
			var b := Vector3(inner, StoneBridge.deck_y(z0), z0)
			var c := Vector3(-inner, StoneBridge.deck_y(z1), z1)
			var d := Vector3(inner, StoneBridge.deck_y(z1), z1)
			faces.append_array(PackedVector3Array([a, b, c, b, d, c]))
		source.add_faces(faces, xform)
		# Its parapets, so the walking ground keeps between them.
		for side: float in [-1.0, 1.0]:
			source.add_faces(_box_faces(Vector3(0.3, 3.0, StoneBridge.LENGTH)), xform * Transform3D(Basis.IDENTITY, Vector3(side * (inner + 0.15), 1.0, 0)))


func _bake(source: NavigationMeshSourceGeometryData3D) -> void:
	var nav := NavigationMesh.new()
	nav.agent_radius = 0.25
	nav.agent_height = 1.25
	nav.agent_max_climb = 0.25
	nav.cell_size = 0.25
	nav.cell_height = 0.25
	NavigationServer3D.bake_from_source_geometry_data(nav, source)
	var region := NavigationRegion3D.new()
	region.name = "RoadNavigation"
	region.navigation_mesh = nav
	add_child(region)
