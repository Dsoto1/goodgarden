class_name Terrain
extends RefCounted
## The shape of the land. The walkable valley floor stays level so play
## spaces, paths and interiors are predictable; beyond it the ground rolls up
## into forested hills and, far off, snow-capped mountains, with a low
## corridor to the north so Bellhaven stays in view and the river can run
## out of the valley. One height function serves the terrain mesh, distant
## forests and anything placed beyond the valley floor.

## Level ground (x, z) with a soft margin before the hills begin.
const FLOOR := Rect2(-36, -52, 76, 71)
## The river's mean line; it meanders either side of it (see river_z).
const RIVER_Z := -14.0
const BELLHAVEN := Vector2(26, -175)
const CITY_PLATEAU := 6.0
## The river enters the valley over a waterfall on the western hills.
const FALLS_X := -58.0
const FALLS_TOP := 12.0
## Water surface of the river through the valley (below the level floor).
const RIVER_LEVEL := -0.25

## The river's course: [x, offset from RIVER_Z, half width]. Held straight
## under the bridge (x 3..8) and still at the waterfall; elsewhere it bends
## where there is room, gently near the bank path, chapel, fold and seat.
const RIVER_KNOTS := [
	[-260.0, 0.0, 3.4], [-120.0, 2.0, 3.6], [-80.0, -2.5, 3.4], [-58.0, 0.0, 3.0],
	[-46.0, 4.0, 3.8], [-34.0, -1.4, 3.0], [-22.0, 1.8, 3.4], [-9.0, -1.0, 2.9],
	[-2.0, 0.7, 3.3], [3.0, 0.0, 3.5], [5.5, 0.0, 3.5], [8.0, 0.0, 3.5], [16.0, 0.6, 3.0],
	[25.0, -0.4, 2.9], [37.0, 3.6, 3.8], [52.0, -3.5, 3.4], [70.0, 3.5, 3.6],
	[100.0, 0.0, 3.4], [260.0, 0.0, 3.4],
]
## The wider world beyond the valley: each place stands on a level site
## (centre, flat radius) cut into the hills, where the concept map puts it.
## A site's level is the land's own height at its centre, unless given.
## How far each site's level ground slopes back into the land around it.
const SITE_SLOPE := 24.0
## The places beyond the valley: centre, radius of level ground (covering
## the place's whole walkable area), optionally its own level, and whether
## it lies by the water (it never fills in the water beside it).
const SITES := {
	"wilderness": [Vector2(-68, 36), 25.0, 6.0],
	"bellhaven": [Vector2(26, -124), 30.0],
	"mountains": [Vector2(110, -145), 28.0, 40.0],
	"monastery": [Vector2(108, -62), 26.0, 9.0],
	"coast": [Vector2(172, 24), 28.0, 1.2, true],
	"lake": [Vector2(52, 46), 22.0, 1.0, true],
	"farmlands": [Vector2(-20, 90), 36.0, 11.0],
}
## The sea, east beyond the river's mouth, and a lake in the south-east hills.
## Dirt roads out of the valley to each place beyond it (world x/z), painted
## onto the land by the ground shader. Each ends where the place's own path
## begins.
const ROADS := [
	[Vector2(-34, 6), Vector2(-44, 12), Vector2(-50, 24), Vector2(-53, 36), Vector2(-55, 46)], # wilderness
	[Vector2(4, 18), Vector2(2, 34), Vector2(-8, 50), Vector2(-16, 62), Vector2(-20, 68)], # farmlands
	[Vector2(30, 18), Vector2(29, 30), Vector2(33, 42), Vector2(37, 50)], # lake
	[Vector2(38, -4), Vector2(62, -3), Vector2(86, 2), Vector2(112, 4), Vector2(134, 12), Vector2(150, 24), Vector2(156, 29)], # coast
	[Vector2(98, 1), Vector2(104, -10), Vector2(103, -20), Vector2(111, -25), Vector2(115, -33), Vector2(108, -45)], # monastery, winding up its hill
	[Vector2(103, -21), Vector2(94, -32), Vector2(86, -42), Vector2(76, -56), Vector2(72, -74), Vector2(78, -94), Vector2(88, -108), Vector2(96, -128)], # mountains, forking past the bridge and keeping clear of the monastery's hill
	[Vector2(6, -47), Vector2(6.8, -56), Vector2(10, -66), Vector2(18, -82), Vector2(24, -96), Vector2(26, -104)], # Bellhaven
]
## Scenery along the roads (world x/z, kind, yaw): see Waysides.
const WAYSIDES := [
	[Vector2(-45, 2), "cottage", 0.6], [Vector2(-48, 6), "woodpile", 0.2], # woodcutter by the wilderness road
	[Vector2(10, 36), "cottage", -1.2], [Vector2(13, 45), "field", 0.3], [Vector2(9, 28), "haystack", 0.0], [Vector2(-19, 45), "windmill", 0.8], # farmstead on the farm road
	[Vector2(22, 30), "house_yellow", 1.4], # by the lake road
	[Vector2(68, -7), "watermill", PI], [Vector2(78, 12), "windmill", -0.4], [Vector2(113, 14), "house_b_blue", 3.0], [Vector2(127, 19), "house_yellow", 2.6],
	[Vector2(119, 27), "field", 0.2], [Vector2(130, 0), "house_tall_red", 2.9], # mill, windmill and hamlet along the coast road
	[Vector2(103.5, -14.2), "bridge", 0.0], # the monastery road over the river
	[Vector2(61, -66), "cottage", 1.4], [Vector2(63, -71), "woodpile", 0.9], # shepherd's hut on the mountain road
	[Vector2(-2, -72), "tower_red", 0.4], [Vector2(19, -64), "house_b_yellow", -0.8], [Vector2(15, -60), "house_blue", -0.6], # a watchtower and cottages on the Bellhaven road
]
const PEAKS := Vector2(135, -200)
const SEA_X := 192.0
const SEA_LEVEL := -0.55
const LAKE := Vector2(82, 46)
const LAKE_RADIUS := 18.0
const LAKE_LEVEL := -0.3

static var _site_levels := {}

## Ground within this many metres of the river is meshed finely so its banks
## can curve (the rest of the land uses a coarse grid).
const RIVER_DETAIL_BAND := 12.0

static var _hills: FastNoiseLite
static var _ridges: FastNoiseLite


static func _noise() -> void:
	if _hills:
		return
	_hills = FastNoiseLite.new()
	_hills.seed = 7
	_hills.frequency = 0.012
	_hills.fractal_octaves = 4
	_ridges = FastNoiseLite.new()
	_ridges.seed = 21
	_ridges.frequency = 0.006
	_ridges.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_ridges.fractal_octaves = 4


## Where the middle of the river is at `x` (its z).
static func river_z(x: float) -> float:
	return RIVER_Z + _river_knot(x).x


## Half the river's width at `x` on one bank. The banks wander a little each
## on their own, the way real ones are cut back and built up.
static func river_half_width(x: float, north: bool) -> float:
	var w := _river_knot(x).y
	var phase := 1.3 if north else 4.1
	return w + 0.32 * sin(x * 0.45 + phase) + 0.18 * sin(x * 1.1 + phase * 2.0)


## Signed distance into the bank from the water's edge (negative in water).
static func river_bank_distance(x: float, z: float) -> float:
	var c := river_z(x)
	return absf(z - c) - river_half_width(x, z < c)


## Smooth (Catmull-Rom) course through RIVER_KNOTS: (offset, half width).
static func _river_knot(x: float) -> Vector2:
	var k := RIVER_KNOTS
	if x <= k[0][0]:
		return Vector2(k[0][1], k[0][2])
	var i := 0
	while i < k.size() - 2 and x > k[i + 1][0]:
		i += 1
	var a: Array = k[maxi(i - 1, 0)]
	var b: Array = k[i]
	var c: Array = k[mini(i + 1, k.size() - 1)]
	var d: Array = k[mini(i + 2, k.size() - 1)]
	var t := clampf((x - b[0]) / maxf(c[0] - b[0], 0.001), 0.0, 1.0)
	var off := _catmull1(a[1], b[1], c[1], d[1], t)
	var w := _catmull1(a[2], b[2], c[2], d[2], t)
	return Vector2(off, w)


static func _catmull1(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	var t2 := t * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t2 * t)


## Metres outside the level valley floor (0 inside it).
static func outside(x: float, z: float) -> float:
	var dx := maxf(maxf(FLOOR.position.x - x, 0.0), x - FLOOR.end.x)
	var dz := maxf(maxf(FLOOR.position.y - z, 0.0), z - FLOOR.end.y)
	return sqrt(dx * dx + dz * dz)


static func height(x: float, z: float) -> float:
	return _with_roads(x, z, _with_river(x, z, _with_sites(x, z, _land(x, z))))


## The land before the roads are cut into it.
static func _base_height(x: float, z: float) -> float:
	return _with_sites(x, z, _land(x, z))


## How steep a road may climb (rise per metre), and how far its level bed
## reaches either side before easing back into the hillside.
const ROAD_GRADE := 0.28
## How far either side of a road bridge's middle the road runs level.
const BRIDGE_REACH := 7.0
const ROAD_BED := 2.5
const ROAD_BLEND := 8.0
## Where a road runs above the land (along a ridge or over a dip), its
## shoulder eases down further, so it never stands on a narrow bank: a
## little more width for every metre of height, up to this much more.
const ROAD_SHOULDER := 24.0

## Per road: its points, the distance along it at each point, its bounds
## (grown by the blend) and its bed height every metre.
static var _road_cache: Array = []


## Each road's bed: the land's height along it, smoothed and held to a gentle
## climb, starting where it leaves the valley (or the road it branches from)
## and ending on its place's level ground.
static func _roads() -> Array:
	if not _road_cache.is_empty():
		return _road_cache
	var cache: Array = []
	for road: Array in ROADS:
		var pts: Array[Vector2] = []
		for p: Vector2 in road:
			pts.append(p)
		var along := PackedFloat32Array([0.0])
		var box := Rect2(pts[0], Vector2.ZERO)
		for i in range(1, pts.size()):
			along.append(along[i - 1] + pts[i - 1].distance_to(pts[i]))
			box = box.expand(pts[i])
		var n := int(ceil(along[along.size() - 1])) + 1
		var raw := PackedFloat32Array()
		raw.resize(n)
		# Where the road is on level ground (the valley floor, a place's site)
		# its bed is that ground; between, it climbs as gently as it can.
		var pinned: Array[int] = []
		for k in n:
			var p := _road_point(pts, along, float(k))
			raw[k] = _base_height(p.x, p.y)
			if k == 0 or k == n - 1 or _on_level_ground(p):
				pinned.append(k)
		# A branch starts on the bed of the road it leaves, and follows it
		# until it has left that road's verge.
		var branch := false
		for prev: Dictionary in cache:
			if _road_param(prev, pts[0]).y >= 3.0:
				continue
			branch = true
			for k in n:
				var at := _road_param(prev, _road_point(pts, along, float(k)))
				if at.y >= ROAD_BLEND:
					break
				raw[k] = _road_bed(prev, at.x)
				if not k in pinned:
					pinned.append(k)
			pinned.sort()
		# Over a bridge the road runs level, at the mean of the land either end.
		for w: Array in WAYSIDES:
			if w[1] != "bridge":
				continue
			var at := _road_param({"pts": pts, "along": along}, w[0])
			if at.y > 3.0:
				continue
			var reach := BRIDGE_REACH
			var e0 := _road_point(pts, along, at.x - reach)
			var e1 := _road_point(pts, along, at.x + reach)
			var level := (_base_height(e0.x, e0.y) + _base_height(e1.x, e1.y)) / 2.0
			for k in range(maxi(0, int(at.x - reach)), mini(n, int(at.x + reach) + 2)):
				raw[k] = level
				if not k in pinned:
					pinned.append(k)
			pinned.sort()
		var grade := ROAD_GRADE
		for i in range(1, pinned.size()):
			var gap := pinned[i] - pinned[i - 1]
			if gap > 1:
				grade = maxf(grade, absf(raw[pinned[i]] - raw[pinned[i - 1]]) / gap * 1.05)
		var bed := PackedFloat32Array()
		bed.resize(n)
		for k in n:
			var sum := 0.0
			var count := 0
			for o in range(-12, 13):
				var kk := clampi(k + o, 0, n - 1)
				sum += raw[kk]
				count += 1
			bed[k] = sum / count
		var fixed := PackedByteArray()
		fixed.resize(n)
		for k: int in pinned:
			fixed[k] = 1
			bed[k] = raw[k]
		# Hold the climb to the grade, never moving the pinned ground: each pass
		# only lowers what is too high or raises what is too low next to it.
		for pass_i in 8:
			for k in range(1, n):
				if not fixed[k]:
					bed[k] = clampf(bed[k], bed[k - 1] - grade, bed[k - 1] + grade)
			for k in range(n - 2, -1, -1):
				if not fixed[k]:
					bed[k] = clampf(bed[k], bed[k + 1] - grade, bed[k + 1] + grade)
		cache.append({"pts": pts, "along": along, "box": box.grow(ROAD_BLEND + ROAD_SHOULDER + 1.0), "bed": bed, "grade": grade, "branch": branch})
	_road_cache = cache
	return cache


static func _road_point(pts: Array[Vector2], along: PackedFloat32Array, s: float) -> Vector2:
	for i in range(1, pts.size()):
		if s <= along[i] or i == pts.size() - 1:
			var t := clampf((s - along[i - 1]) / maxf(along[i] - along[i - 1], 0.001), 0.0, 1.0)
			return pts[i - 1].lerp(pts[i], t)
	return pts[pts.size() - 1]


## The distance along a road nearest `p`, and how far `p` is from it.
static func _road_param(road: Dictionary, p: Vector2) -> Vector2:
	var pts: Array[Vector2] = road["pts"]
	var along: PackedFloat32Array = road["along"]
	var best := Vector2(0.0, INF)
	for i in range(1, pts.size()):
		var c := Geometry2D.get_closest_point_to_segment(p, pts[i - 1], pts[i])
		var d := p.distance_to(c)
		if d < best.y:
			best = Vector2(along[i - 1] + pts[i - 1].distance_to(c), d)
	return best


static func _road_bed(road: Dictionary, s: float) -> float:
	var bed: PackedFloat32Array = road["bed"]
	var f := clampf(s, 0.0, bed.size() - 1.0)
	var k := mini(int(f), bed.size() - 2)
	return lerpf(bed[k], bed[k + 1], f - k)


## On the valley floor or a place's level ground, which the roads leave as it is.
static func _on_level_ground(p: Vector2) -> bool:
	if outside(p.x, p.y) <= 0.0:
		return true
	for id: String in SITES:
		var s: Array = SITES[id]
		if p.distance_to(s[0]) < float(s[1]):
			return true
	return false


## Cuts each road's level bed into the hills, easing back into the land
## either side. The valley floor and the places' level ground stay as they are.
static func _with_roads(x: float, z: float, h: float) -> float:
	var p := Vector2(x, z)
	if outside(x, z) <= 0.0:
		return h
	# A place's level ground stays level; at its edge the road eases in.
	var keep := 1.0
	var keep_wide := 1.0 # the broad shoulders stop well short of a place
	for id: String in SITES:
		var s: Array = SITES[id]
		var sd := p.distance_to(s[0])
		keep = minf(keep, smoothstep(float(s[1]) - 6.0, float(s[1]), sd))
		keep_wide = minf(keep_wide, smoothstep(float(s[1]), float(s[1]) + 10.0, sd))
	if keep <= 0.0:
		return h
	# The road keeps its level up to the water's edge, where a bridge carries
	# it over; the river's own channel stays as it is.
	var dry := smoothstep(0.0, 2.0, river_bank_distance(x, z))
	if dry <= 0.0:
		return h
	var num := 0.0
	var den := 0.0
	var pull := 0.0
	var nearest := INF
	for road: Dictionary in _roads():
		if not (road["box"] as Rect2).has_point(p):
			continue
		# Each stretch of the road pulls on its own, so inside a bend (near two
		# stretches at once) the land blends between them rather than jumping.
		var pts: Array[Vector2] = road["pts"]
		var along: PackedFloat32Array = road["along"]
		for i in range(1, pts.size()):
			var c := Geometry2D.get_closest_point_to_segment(p, pts[i - 1], pts[i])
			var d := p.distance_to(c)
			nearest = minf(nearest, d)
			if d >= ROAD_BLEND + ROAD_SHOULDER:
				continue
			# Distance along the road, measured along this stretch's own line
			# (past its ends too), so neighbouring stretches agree at a bend.
			var dir := (pts[i] - pts[i - 1]).normalized()
			var s := clampf(along[i - 1] + (p - pts[i - 1]).dot(dir), 0.0, along[along.size() - 1])
			var bed := _road_bed(road, s)
			# A broad, gentle shoulder where the road stands above the land
			# (about one in three), a little wider where it cuts into a hill.
			var extra := (bed - h) * 2.8 if bed > h else (h - bed) * 0.8
			var w := 1.0 - smoothstep(ROAD_BED, ROAD_BLEND + minf(extra, ROAD_SHOULDER), d)
			if w <= 0.0:
				continue
			if road["branch"]:
				w *= smoothstep(0.0, 8.0, s) # a branch fades in as it leaves its road
			var sharp := pow(w, 4.0)
			num += sharp * bed
			den += sharp
			pull = maxf(pull, w)
	if den <= 0.0:
		return h
	# Near the road the place's own edge decides; out on the shoulder, the
	# wider fade, so a shoulder never piles land up against a place's edge.
	var site := lerpf(keep, minf(keep, keep_wide), smoothstep(ROAD_BED, ROAD_BLEND, nearest))
	return lerpf(h, num / den, pull * dry * site)


## The roads as segments (a.x, a.y, b.x, b.y) for the ground shader.
static func road_segments() -> Array[Vector4]:
	var out: Array[Vector4] = []
	for road: Array in ROADS:
		for i in road.size() - 1:
			out.append(Vector4(road[i].x, road[i].y, road[i + 1].x, road[i + 1].y))
	return out


## True near a wayside building, where trees keep off.
static func near_wayside(x: float, z: float, r := 9.0) -> bool:
	for w: Array in WAYSIDES:
		if Vector2(x, z).distance_to(w[0]) < r:
			return true
	return false


## How far (x, z) is from the nearest road.
static func road_distance(x: float, z: float) -> float:
	var best := INF
	var p := Vector2(x, z)
	for road: Array in ROADS:
		for i in road.size() - 1:
			best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, road[i], road[i + 1])))
	return best


## A site's ground level.
static func site_level(id: String) -> float:
	if not _site_levels.has(id):
		var s: Array = SITES[id]
		var c: Vector2 = s[0]
		_site_levels[id] = float(s[2]) if s.size() > 2 else _land(c.x, c.y)
	return _site_levels[id]


## World position of a site's centre, on its level ground.
static func site_center(id: String) -> Vector3:
	var c: Vector2 = SITES[id][0]
	return Vector3(c.x, site_level(id), c.y)


## How far (x, z) is inside the nearest site's blend zone: 0 well outside,
## 1 on level ground. Trees keep off sites.
static func in_site(x: float, z: float, margin := 1.6) -> bool:
	for id: String in SITES:
		var s: Array = SITES[id]
		if Vector2(x, z).distance_to(s[0]) < float(s[1]) * margin:
			return true
	return false


## Levels each site, sloping gently back into the hills around it. A site
## by the water never fills in the water itself, so
## the sea and the lake keep their natural shores at its edge.
static func _with_sites(x: float, z: float, h: float) -> float:
	# Each site pulls the land toward its level, fully on its level ground and
	# fading over its slope. Where two slopes overlap, the stronger pull
	# decides the level smoothly (weights sharpened), so one site's level
	# ground is never raised by its neighbour and no cliff forms between them.
	var pull := 0.0
	var levels := 0.0
	var weights := 0.0
	for id: String in SITES:
		var s: Array = SITES[id]
		var r: float = s[1]
		var d := Vector2(x, z).distance_to(s[0])
		if d >= r + SITE_SLOPE:
			continue
		var level := site_level(id)
		if s.size() > 3 and h < level - 1.2:
			continue
		# Beyond the level ground, the river keeps its own valley: a site's
		# slope gives way to the natural land near the water.
		var t := smoothstep(r, r + SITE_SLOPE, d)
		t = maxf(t, (1.0 - smoothstep(6.0, 30.0, river_bank_distance(x, z))) * smoothstep(r, r + 8.0, d))
		var w := 1.0 - t
		var sharp := pow(w, 8.0)
		pull = maxf(pull, w)
		levels += sharp * level
		weights += sharp
	if weights <= 0.0:
		return h
	# The valley floor itself is never lifted by a site beyond it.
	pull *= smoothstep(0.0, 8.0, outside(x, z))
	return lerpf(h, levels / weights, pull)


static func _land(x: float, z: float) -> float:
	_noise()
	var d := outside(x, z)
	if d <= 0.0:
		return 0.0
	var n := _hills.get_noise_2d(x, z) * 0.5 + 0.5
	var hills := (smoothstep(0.0, 45.0, d) * 16.0 + maxf(d - 45.0, 0.0) * 0.12) * (0.45 + 0.75 * n)
	var mountains := smoothstep(80.0, 200.0, d) * pow(_ridges.get_noise_2d(x, z) * 0.5 + 0.5, 1.5) * 150.0
	# A range of snowy peaks rises north-east, behind the shepherd's meadow.
	var range_d := Vector2(x, z).distance_to(PEAKS)
	var peaks := (1.0 - smoothstep(10.0, 85.0, range_d)) * (75.0 + 85.0 * (_ridges.get_noise_2d(x * 1.6, z * 1.6) * 0.5 + 0.5))
	var h := hills + maxf(mountains, peaks)
	# A low corridor north toward Bellhaven keeps the city visible from the overlook.
	var to_city := absf(x - lerpf(6.0, BELLHAVEN.x, clampf((-z - 46.0) / 130.0, 0.0, 1.0)))
	if z < FLOOR.position.y:
		h *= lerpf(0.25, 1.0, smoothstep(18.0, 60.0, to_city)) if z > BELLHAVEN.y + 40.0 else 1.0
	# The river leaves the valley east and west through gentle low ground.
	h *= lerpf(0.15, 1.0, smoothstep(5.0, 42.0, absf(z - river_z(x))))
	# Bellhaven stands on a broad, modest rise so it shows above the near hills.
	var city := Vector2(x, z).distance_to(BELLHAVEN)
	h = lerpf(CITY_PLATEAU, h, smoothstep(35.0, 75.0, city))
	# Eastward the land falls to the sea, the coast wandering a little.
	var shore := SEA_X + 8.0 * sin(z * 0.035) + 4.0 * sin(z * 0.11)
	h = lerpf(h, 1.2, smoothstep(shore - 60.0, shore - 14.0, x))
	h = lerpf(h, SEA_LEVEL - 3.0, smoothstep(shore - 4.0, shore + 6.0, x))
	# The lake lies in a hollow among the south-eastern hills.
	var lake := Vector2(x, z).distance_to(LAKE)
	h *= lerpf(0.3, 1.0, smoothstep(LAKE_RADIUS + 8.0, LAKE_RADIUS + 70.0, lake)) # a broad, open basin
	h = lerpf(LAKE_LEVEL - 2.5, h, smoothstep(LAKE_RADIUS - 3.0, LAKE_RADIUS + 9.0, lake))
	# South of the river, the hills roll down to the sea in gentle green
	# slopes instead of rocky cliffs: the land may rise only so fast from
	# the shore (a soft minimum, so no crease where it starts).
	var cap := 1.2 + maxf(shore - x, 0.0) * 0.6
	var soft := -log(exp(-0.25 * h) + exp(-0.25 * cap)) / 0.25
	h = lerpf(h, soft, smoothstep(10.0, 50.0, z))
	return h


## Carves the river channel with sloping banks and raises the plateau the
## river falls from, so the upper river runs above the cliff.
static func _with_river(x: float, z: float, h: float) -> float:
	var west := smoothstep(FALLS_X + 1.5, FALLS_X - 2.5, x) # 0 below the cliff, 1 above it
	if west > 0.0:
		var band := 1.0 - smoothstep(14.0, 32.0, absf(z - river_z(FALLS_X)))
		h = lerpf(h, maxf(h, FALLS_TOP), west * band)
	var bed := lerpf(RIVER_LEVEL - 0.4, FALLS_TOP - 0.7, west)
	# The bank slopes from a metre inside the water's edge to under a metre
	# beyond it; where the land stands higher, it eases down over a wide,
	# shallow bank (about one in four), so the river never looks like a trench.
	var carve := 1.0 - smoothstep(-0.9, 0.7 + minf(maxf(h - bed - 1.0, 0.0) * 4.0, 14.0), river_bank_distance(x, z))
	return lerpf(h, minf(h, bed), carve)


## Builds the visible landscape: one mesh, coarse where it's far away.
static func build_mesh(size := 640.0, step := 4.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size / 2.0
	var cells := int(size / step)
	var heights := PackedFloat32Array()
	heights.resize((cells + 1) * (cells + 1))
	for j in cells + 1:
		for i in cells + 1:
			heights[j * (cells + 1) + i] = height(-half + i * step, -half + j * step)
	var at := func(i: int, j: int) -> Vector3:
		return Vector3(-half + i * step, heights[j * (cells + 1) + i], -half + j * step)
	# Cells near the river are split 4 x 4 so its banks can curve. Where a fine
	# cell meets a coarse one, its edge follows the coarse edge exactly, so
	# the two meshes join without cracks.
	var fine := func(i: int, j: int) -> bool:
		return _is_fine(i, j, size, step)
	for j in cells:
		for i in cells:
			if fine.call(i, j):
				_fine_cell(st, at.call(i, j), at.call(i + 1, j), at.call(i, j + 1), at.call(i + 1, j + 1), step,
					not fine.call(i - 1, j), not fine.call(i + 1, j), not fine.call(i, j - 1), not fine.call(i, j + 1))
				continue
			var a: Vector3 = at.call(i, j)
			var b: Vector3 = at.call(i + 1, j)
			var c: Vector3 = at.call(i, j + 1)
			var d: Vector3 = at.call(i + 1, j + 1)
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
			st.add_vertex(b)
			st.add_vertex(d)
			st.add_vertex(c)
	st.index()
	st.generate_normals()
	return st.commit()


## Cells near the river (so its banks can curve) and along the roads (so the
## road bed is smooth to walk on) are meshed finely.
static var _road_cells := {}
static func _is_fine(i: int, j: int, size: float, step: float) -> bool:
	var cells := int(size / step)
	if i < 0 or j < 0 or i >= cells or j >= cells:
		return false
	var half := size / 2.0
	var cx := -half + (i + 0.5) * step
	var cz := -half + (j + 0.5) * step
	if absf(cx) < 80.0 and absf(cz - river_z(cx)) < RIVER_DETAIL_BAND:
		return true
	if _road_cells.is_empty():
		_road_cells[-1] = true
		for road: Array in ROADS:
			var box := Rect2(road[0], Vector2.ZERO)
			for p: Vector2 in road:
				box = box.expand(p)
			box = box.grow(ROAD_BLEND + step)
			for ci in range(int((box.position.x + half) / step), int((box.end.x + half) / step) + 1):
				for cj in range(int((box.position.y + half) / step), int((box.end.y + half) / step) + 1):
					var c := Vector2(-half + (ci + 0.5) * step, -half + (cj + 0.5) * step)
					var near := INF
					for k in range(1, road.size()):
						near = minf(near, c.distance_to(Geometry2D.get_closest_point_to_segment(c, road[k - 1], road[k])))
					if near < ROAD_BLEND + step * 0.75:
						_road_cells[ci * 100000 + cj] = true
	return _road_cells.has(i * 100000 + j)


## The land's triangles in one cell of `build_mesh`'s grid (cell i, j of a
## mesh `size` across in `step` cells), exactly as the visible mesh has them,
## so a collider built from them is the ground the child sees.
static func cell_faces(st: SurfaceTool, i: int, j: int, size := 640.0, step := 4.0) -> void:
	var half := size / 2.0
	var at := func(ii: int, jj: int) -> Vector3:
		var x := -half + ii * step
		var z := -half + jj * step
		return Vector3(x, height(x, z), z)
	var fine := func(ii: int, jj: int) -> bool:
		return _is_fine(ii, jj, size, step)
	var a: Vector3 = at.call(i, j)
	var b: Vector3 = at.call(i + 1, j)
	var c: Vector3 = at.call(i, j + 1)
	var d: Vector3 = at.call(i + 1, j + 1)
	if fine.call(i, j):
		_fine_cell(st, a, b, c, d, step, not fine.call(i - 1, j), not fine.call(i + 1, j), not fine.call(i, j - 1), not fine.call(i, j + 1))
		return
	for v: Vector3 in [a, b, c, b, d, c]:
		st.add_vertex(v)


## One coarse cell split into 4 x 4. Corners a (min x, min z), b (+x), c (+z),
## d (+x +z). Edges flagged as bordering a coarse cell keep that cell's
## straight edge instead of the true height.
static func _fine_cell(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, step: float,
		coarse_left: bool, coarse_right: bool, coarse_top: bool, coarse_bottom: bool) -> void:
	const N := 4
	var pts: Array[Vector3] = []
	for v in N + 1:
		for u in N + 1:
			var fu := float(u) / N
			var fv := float(v) / N
			var x := a.x + fu * step
			var z := a.z + fv * step
			var y := height(x, z)
			if u == 0 and coarse_left:
				y = lerpf(a.y, c.y, fv)
			elif u == N and coarse_right:
				y = lerpf(b.y, d.y, fv)
			elif v == 0 and coarse_top:
				y = lerpf(a.y, b.y, fu)
			elif v == N and coarse_bottom:
				y = lerpf(c.y, d.y, fu)
			pts.append(Vector3(x, y, z))
	for v in N:
		for u in N:
			var p00 := pts[v * (N + 1) + u]
			var p10 := pts[v * (N + 1) + u + 1]
			var p01 := pts[(v + 1) * (N + 1) + u]
			var p11 := pts[(v + 1) * (N + 1) + u + 1]
			st.add_vertex(p00)
			st.add_vertex(p10)
			st.add_vertex(p01)
			st.add_vertex(p10)
			st.add_vertex(p11)
			st.add_vertex(p01)
