class_name PathKit
extends RefCounted
## Builds footpaths that flow like real ones: a smooth curve through a few
## points, edges that wander a little in and out (feet wear paths unevenly),
## and rounded ends, laid onto the ground. Patterns are world-space, so the
## worn-earth or cobble texture runs continuously along the curve.

const STEP := 0.3 # metres between cross-sections along the path
const SIDES_ROUNDING := 8 # segments in each rounded end


## Lays a path through `points` (in `parent`'s space). Returns the mesh and the
## smoothed centre line (for clearings).
static func lay(parent: Node3D, points: Array, width: float, material: String, seed_value: int) -> Dictionary:
	var line := smooth(points)
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.35
	var base := parent.global_position if parent.is_inside_tree() else Vector3.ZERO
	# Cobbled roads lie a little above dirt paths (and below the village square,
	# at 0.055), so where different surfaces cross, one cleanly covers the
	# other instead of flickering.
	var lift := 0.045 if material == "cobble" else 0.03
	var height := func(p: Vector3) -> float:
		return Terrain.height(base.x + p.x, base.z + p.z) - base.y + lift if parent.is_inside_tree() else lift
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	var dist := 0.0
	for i in line.size():
		if i > 0:
			dist += line[i].distance_to(line[i - 1])
		var dir := _direction(line, i)
		var side := Vector3(-dir.z, 0, dir.x)
		var half := width * 0.5
		# Each edge wanders on its own; the ends taper slightly.
		var wl := half * (1.0 + 0.16 * noise.get_noise_2d(dist, 0.0) + 0.05 * noise.get_noise_2d(dist * 4.0, 7.0))
		var wr := half * (1.0 + 0.16 * noise.get_noise_2d(dist, 31.0) + 0.05 * noise.get_noise_2d(dist * 4.0, 53.0))
		var l := line[i] - side * wl
		var r := line[i] + side * wr
		l.y = height.call(l)
		r.y = height.call(r)
		left.append(l)
		right.append(r)
	for i in line.size() - 1:
		_quad(st, left[i], right[i], left[i + 1], right[i + 1])
	_cap(st, line[0], left[0], right[0], -_direction(line, 0), height)
	_cap(st, line[line.size() - 1], right[line.size() - 1], left[line.size() - 1], _direction(line, line.size() - 1), height)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = Palette.mat(material)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return {"mesh": mi, "line": line}


## Catmull-Rom curve through the points, sampled about every STEP metres.
static func smooth(points: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if points.size() < 2:
		for p: Vector3 in points:
			out.append(p)
		return out
	for i in points.size() - 1:
		var p0: Vector3 = points[maxi(i - 1, 0)]
		var p1: Vector3 = points[i]
		var p2: Vector3 = points[i + 1]
		var p3: Vector3 = points[mini(i + 2, points.size() - 1)]
		var steps := maxi(1, ceili(p1.distance_to(p2) / STEP))
		for k in steps:
			var t := float(k) / steps
			out.append(_catmull(p0, p1, p2, p3, t))
	out.append(points.back())
	return out


static func _catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


static func _direction(line: Array[Vector3], i: int) -> Vector3:
	var a := line[maxi(i - 1, 0)]
	var b := line[mini(i + 1, line.size() - 1)]
	var d := Vector3(b.x - a.x, 0, b.z - a.z)
	return d.normalized() if d.length() > 0.0001 else Vector3.FORWARD


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, b, d, c)


## Emits a triangle facing up whatever order the corners arrive in.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	if (b - a).cross(c - a).y > 0.0:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)
	else:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)


## A rounded end: a half-disc fan from one edge to the other, bulging along `out`.
static func _cap(st: SurfaceTool, centre: Vector3, from: Vector3, to: Vector3, out: Vector3, height: Callable) -> void:
	var c := centre
	c.y = (from.y + to.y) * 0.5
	var a0 := Vector3(from.x - c.x, 0, from.z - c.z)
	var b0 := Vector3(to.x - c.x, 0, to.z - c.z)
	var across := a0.normalized()
	var prev := from
	for k in range(1, SIDES_ROUNDING):
		var t := float(k) / SIDES_ROUNDING
		var ang := PI * t
		# Half a disc: from one edge, out past the end, round to the other edge.
		var r := lerpf(a0.length(), b0.length(), t)
		var p := c + across * cos(ang) * r + out * sin(ang) * r * 0.8
		p.y = height.call(p)
		_tri(st, c, prev, p)
		prev = p
	_tri(st, c, prev, to)
