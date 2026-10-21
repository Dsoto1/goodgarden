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
const RIVER_Z := -14.0
const BELLHAVEN := Vector2(26, -175)
const CITY_PLATEAU := 6.0

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


## Metres outside the level valley floor (0 inside it).
static func outside(x: float, z: float) -> float:
	var dx := maxf(maxf(FLOOR.position.x - x, 0.0), x - FLOOR.end.x)
	var dz := maxf(maxf(FLOOR.position.y - z, 0.0), z - FLOOR.end.y)
	return sqrt(dx * dx + dz * dz)


static func height(x: float, z: float) -> float:
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
	h *= lerpf(0.15, 1.0, smoothstep(5.0, 22.0, absf(z - RIVER_Z)))
	# Bellhaven stands on a broad, modest rise so it shows above the near hills.
	var city := Vector2(x, z).distance_to(BELLHAVEN)
	h = lerpf(CITY_PLATEAU, h, smoothstep(35.0, 75.0, city))
	return h


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
	for j in cells:
		for i in cells:
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
