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
	return _with_river(x, z, _land(x, z))


static func _land(x: float, z: float) -> float:
	_noise()
	var d := outside(x, z)
	if d <= 0.0:
		return 0.0
	var n := _hills.get_noise_2d(x, z) * 0.5 + 0.5
	var hills := (smoothstep(0.0, 45.0, d) * 16.0 + maxf(d - 45.0, 0.0) * 0.12) * (0.45 + 0.75 * n)
	var mountains := smoothstep(80.0, 200.0, d) * pow(_ridges.get_noise_2d(x, z) * 0.5 + 0.5, 1.5) * 150.0
	var h := hills + mountains
	# A low corridor north toward Bellhaven keeps the city visible from the overlook.
	var to_city := absf(x - lerpf(6.0, BELLHAVEN.x, clampf((-z - 46.0) / 130.0, 0.0, 1.0)))
	if z < FLOOR.position.y:
		h *= lerpf(0.25, 1.0, smoothstep(18.0, 60.0, to_city)) if z > BELLHAVEN.y + 40.0 else 1.0
	# The river leaves the valley east and west through gentle low ground.
	h *= lerpf(0.15, 1.0, smoothstep(5.0, 22.0, absf(z - river_z(x))))
	# Bellhaven stands on a broad, modest rise so it shows above the near hills.
	var city := Vector2(x, z).distance_to(BELLHAVEN)
	h = lerpf(CITY_PLATEAU, h, smoothstep(35.0, 75.0, city))
	return h


## Carves the river channel with sloping banks and raises the plateau the
## river falls from, so the upper river runs above the cliff.
static func _with_river(x: float, z: float, h: float) -> float:
	var west := smoothstep(FALLS_X + 1.5, FALLS_X - 2.5, x) # 0 below the cliff, 1 above it
	if west > 0.0:
		var band := 1.0 - smoothstep(14.0, 32.0, absf(z - river_z(FALLS_X)))
		h = lerpf(h, maxf(h, FALLS_TOP), west * band)
	var bed := lerpf(RIVER_LEVEL - 0.4, FALLS_TOP - 0.7, west)
	# The bank slopes from a metre inside the water's edge to under a metre beyond it.
	var carve := 1.0 - smoothstep(-0.9, 0.7, river_bank_distance(x, z))
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
		if i < 0 or j < 0 or i >= cells or j >= cells:
			return false
		var cx := -half + (i + 0.5) * step
		var cz := -half + (j + 0.5) * step
		return absf(cx) < 80.0 and absf(cz - river_z(cx)) < RIVER_DETAIL_BAND
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
