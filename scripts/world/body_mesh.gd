class_name BodyMesh
extends RefCounted
## Builds one continuous, skinned body per character: torso, legs, arms,
## hands and feet lofted as smooth tubes with tapering profiles, bound to a
## small skeleton. Near each joint the vertices blend between the two bones,
## so knees and elbows bend smoothly instead of hinging like separate parts.
## Clothing is painted as colour regions on the same surface (trousers,
## shirt, cuffs, belt, vest, shoes), so there are no seams between pieces.

const SIDES := 14

enum Bone { HIPS, SPINE, CHEST, NECK, HEAD, L_THIGH, L_SHIN, L_FOOT, R_THIGH, R_SHIN, R_FOOT, L_ARM, L_FOREARM, L_HAND, R_ARM, R_FOREARM, R_HAND }

## Rest positions in model space (adult proportions; the root scales for height).
static func joints(w: float) -> Dictionary:
	var j := {
		Bone.HIPS: Vector3(0, 0.8, 0), Bone.SPINE: Vector3(0, 0.93, 0), Bone.CHEST: Vector3(0, 1.12, 0),
		Bone.NECK: Vector3(0, 1.34, 0), Bone.HEAD: Vector3(0, 1.44, 0),
	}
	for side: int in [-1, 1]:
		var leg := Bone.L_THIGH if side < 0 else Bone.R_THIGH
		j[leg] = Vector3(side * 0.095 * w, 0.8, 0)
		j[leg + 1] = Vector3(side * 0.095 * w, 0.44, 0)
		j[leg + 2] = Vector3(side * 0.095 * w, 0.08, 0)
		var arm := Bone.L_ARM if side < 0 else Bone.R_ARM
		j[arm] = Vector3(side * 0.205 * w, 1.29, 0)
		j[arm + 1] = Vector3(side * 0.225 * w, 1.02, 0)
		j[arm + 2] = Vector3(side * 0.235 * w, 0.78, 0)
	return j


static func parent_of(b: int) -> int:
	match b:
		Bone.HIPS: return -1
		Bone.SPINE, Bone.L_THIGH, Bone.R_THIGH: return Bone.HIPS
		Bone.CHEST: return Bone.SPINE
		Bone.NECK, Bone.L_ARM, Bone.R_ARM: return Bone.CHEST
		Bone.HEAD: return Bone.NECK
	return b - 1 # shin <- thigh, foot <- shin, forearm <- arm, hand <- forearm


## Creates the skeleton (identity bases; animation rotates about local axes).
static func make_skeleton(w: float) -> Skeleton3D:
	var sk := Skeleton3D.new()
	sk.name = "Skeleton"
	var j := joints(w)
	for b in Bone.size():
		sk.add_bone(Bone.keys()[b].to_lower())
	for b in Bone.size():
		var p := parent_of(b)
		sk.set_bone_parent(b, p)
		var rel: Vector3 = j[b] - (j[p] if p >= 0 else Vector3.ZERO)
		sk.set_bone_rest(b, Transform3D(Basis.IDENTITY, rel))
	sk.reset_bone_poses()
	return sk


## The look decides colours; `w` widens the build.
static func build(look: Dictionary, w: float) -> ArrayMesh:
	var col := func(key: String, fallback: String) -> Color:
		return Palette.color(str(look.get(key, fallback)))
	var skin: Color = col.call("skin", "skin_1")
	var shirt: Color = col.call("shirt", "cloth_cream")
	var pants: Color = col.call("pants", "cloth_blue")
	var shoes: Color = col.call("shoes", "shoe")
	var belt: Color = col.call("belt", "leather")
	var vest: Variant = Palette.color(look["vest"]) if look.has("vest") else null
	var long_sleeves: bool = look.get("sleeves", "long") == "long"
	var j := joints(w)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Torso: elliptical cross-sections from the seat to the top of the neck.
	var profile := [
		[0.7, 0.15, 0.115, 0.012], [0.78, 0.185, 0.135, 0.012], [0.88, 0.172, 0.125, 0.0],
		[0.98, 0.165, 0.12, -0.005], [1.1, 0.19, 0.13, -0.012], [1.22, 0.2, 0.125, -0.01],
		[1.29, 0.18, 0.11, 0.0], [1.33, 0.1, 0.075, 0.0], [1.37, 0.062, 0.058, 0.0], [1.47, 0.055, 0.052, 0.0],
	]
	var rings: Array = []
	var y := 0.7
	while y <= 1.47:
		var a := 0
		while a < profile.size() - 2 and profile[a + 1][0] < y:
			a += 1
		var p0: Array = profile[a]
		var p1: Array = profile[a + 1]
		var t := smoothstep(p0[0], p1[0], y)
		var rx := lerpf(p0[1], p1[1], t) * w
		var rz := lerpf(p0[2], p1[2], t) * w
		var cz := lerpf(p0[3], p1[3], t)
		var bones := _blend([[Bone.HIPS, 0.0], [Bone.SPINE, 0.9], [Bone.CHEST, 1.06], [Bone.NECK, 1.33]], y, 0.06)
		var c := shirt
		if y < 0.86:
			c = pants
		elif y < 0.92:
			c = belt
		elif y > 1.335:
			c = skin
		rings.append({"c": Vector3(0, y, cz), "rx": rx, "rz": rz, "bones": bones, "color": c, "vest": vest != null and y >= 0.92 and y < 1.3})
		y += 0.025
	_tube(st, rings, true, true, vest)

	# Legs: hip -> knee -> ankle, then a foot.
	for side: int in [-1, 1]:
		var thigh := Bone.L_THIGH if side < 0 else Bone.R_THIGH
		var hip: Vector3 = j[thigh] + Vector3(0, 0.03, 0)
		var knee: Vector3 = j[thigh + 1]
		var ankle: Vector3 = j[thigh + 2]
		var leg_rings: Array = []
		var s := 0.0
		var total := hip.distance_to(ankle)
		while s <= total + 0.001:
			var p := hip.lerp(ankle, s / total)
			var r := _profile(s / total, [[0.0, 0.098], [0.25, 0.088], [0.5, 0.066], [0.62, 0.07], [0.9, 0.05], [1.0, 0.047]]) * w
			var bones := _blend([[Bone.HIPS, -1.0], [thigh, 0.07], [thigh + 1, 0.39]], s, 0.06)
			var c := pants if s < total - 0.05 else shoes
			if s > total - 0.09 and s < total - 0.05:
				c = pants.darkened(0.18) # trouser cuff
			leg_rings.append({"c": p, "rx": r, "rz": r * 0.95, "bones": bones, "color": c})
			s += 0.025
		_tube(st, leg_rings, false, false)
		# Foot: a rounded shoe pointing forward (-Z).
		var foot_rings: Array = []
		for i in 9:
			var t := i / 8.0
			var p := ankle + Vector3(0, -0.035 - 0.012 * t, 0.04 - 0.19 * t)
			var r := sin(PI * (0.15 + 0.85 * t)) * 0.055 + 0.012
			foot_rings.append({"c": p, "rx": r * 1.05 * w, "rz": r * 0.75, "bones": _blend([[thigh + 1, -1.0], [thigh + 2, 0.02]], t * 0.2, 0.03), "color": shoes, "axis_z": true})
		_tube(st, foot_rings, true, true)

	# Arms: shoulder -> elbow -> wrist, then a soft mitten hand.
	for side: int in [-1, 1]:
		var arm := Bone.L_ARM if side < 0 else Bone.R_ARM
		var shoulder: Vector3 = j[arm] + Vector3(-side * 0.02, 0.02, 0)
		var elbow: Vector3 = j[arm + 1]
		var wrist: Vector3 = j[arm + 2]
		var arm_rings: Array = []
		var upper := shoulder.distance_to(elbow)
		var total := upper + elbow.distance_to(wrist)
		var s := 0.0
		var sleeve_end := total - 0.02 if long_sleeves else upper * 0.55
		while s <= total + 0.001:
			var p := shoulder.lerp(elbow, s / upper) if s <= upper else elbow.lerp(wrist, (s - upper) / (total - upper))
			var r := _profile(s / total, [[0.0, 0.07], [0.3, 0.06], [0.5, 0.047], [0.62, 0.05], [1.0, 0.04]]) * w
			var bones := _blend([[Bone.CHEST, -1.0], [arm, 0.05], [arm + 1, upper]], s, 0.05)
			var c := shirt if s < sleeve_end else skin
			if s >= sleeve_end - 0.03 and s < sleeve_end:
				c = shirt.darkened(0.15) # cuff
				r *= 1.08
			arm_rings.append({"c": p, "rx": r, "rz": r, "bones": bones, "color": c})
			s += 0.022
		_tube(st, arm_rings, false, false)
		# Hand: a soft palm-shaped mitten, flat toward the thigh like a relaxed hand,
		# starting inside the cuff so the wrist blends without a seam.
		var hand_rings: Array = []
		for i in 11:
			var t := i / 10.0
			var p := wrist + Vector3(side * 0.004, 0.01 - 0.14 * t, -0.01 * t)
			var r := 0.038 + sin(PI * clampf(t * 1.1, 0.0, 1.0)) * 0.016
			if t > 0.85:
				r *= 1.0 - (t - 0.85) / 0.15 * 0.8
			hand_rings.append({"c": p, "rx": r * 0.62, "rz": r * 1.05, "bones": _blend([[arm + 1, -1.0], [arm + 2, 0.02]], t * 0.14, 0.02), "color": skin})
		_tube(st, hand_rings, true, true)

	# Weld shared vertices first so normals are smooth across the whole body.
	st.index()
	st.generate_normals()
	return st.commit()


## Piecewise-smooth radius along a limb: points are [t, radius].
static func _profile(t: float, points: Array) -> float:
	for i in points.size() - 1:
		if t <= points[i + 1][0]:
			return lerpf(points[i][1], points[i + 1][1], smoothstep(points[i][0], points[i + 1][0], t))
	return points.back()[1]


## Bone weights along a chain: each entry is [bone, start]; near each start
## the weight cross-fades over `blend` from the previous bone to this one.
static func _blend(chain: Array, s: float, blend: float) -> Array:
	var weights := {}
	for i in chain.size():
		weights[chain[i][0]] = 0.0
	weights[chain[0][0]] = 1.0
	for i in range(1, chain.size()):
		var f := smoothstep(float(chain[i][1]) - blend, float(chain[i][1]) + blend, s)
		var prev: int = chain[i - 1][0]
		var moved: float = weights[prev] * f
		weights[prev] -= moved
		weights[chain[i][0]] += moved
	var out := []
	for b: int in weights:
		if weights[b] > 0.001:
			out.append([b, weights[b]])
	return out


static func _tube(st: SurfaceTool, rings: Array, cap_start: bool, cap_end: bool, vest: Variant = null) -> void:
	var verts: Array = []
	for ring: Dictionary in rings:
		var row: Array = []
		for i in SIDES:
			var a := TAU * i / SIDES
			var off := Vector3(cos(a) * ring["rx"], 0, sin(a) * ring["rz"])
			if ring.get("axis_z", false):
				off = Vector3(cos(a) * ring["rx"], sin(a) * ring["rz"], 0)
			var color: Color = ring["color"]
			# Open vest: vest colour all round except a strip down the front.
			if ring.get("vest", false) and not (absf(off.x) < 0.045 and off.z < 0.0):
				color = vest
			row.append({"p": ring["c"] + off, "color": color, "bones": ring["bones"]})
		verts.append(row)
	for r in verts.size() - 1:
		var mid: Vector3 = (rings[r]["c"] + rings[r + 1]["c"]) * 0.5
		for i in SIDES:
			var a: Dictionary = verts[r][i]
			var b: Dictionary = verts[r][(i + 1) % SIDES]
			var c: Dictionary = verts[r + 1][i]
			var d: Dictionary = verts[r + 1][(i + 1) % SIDES]
			_tri(st, a, c, b, (a["p"] + d["p"]) * 0.5 - mid)
			_tri(st, b, c, d, (a["p"] + d["p"]) * 0.5 - mid)
	var axis: Vector3 = rings.back()["c"] - rings[0]["c"]
	if cap_start:
		_cap(st, verts[0], rings[0], -axis)
	if cap_end:
		_cap(st, verts.back(), rings.back(), axis)


static func _cap(st: SurfaceTool, row: Array, ring: Dictionary, outward: Vector3) -> void:
	var center := {"p": ring["c"], "color": ring["color"], "bones": ring["bones"]}
	for i in SIDES:
		_tri(st, center, row[i], row[(i + 1) % SIDES], outward)


## Emits a triangle wound so its front face points along `outward`
## (Godot treats clockwise winding as the front).
static func _tri(st: SurfaceTool, a: Dictionary, b: Dictionary, c: Dictionary, outward: Vector3) -> void:
	var n: Vector3 = (b["p"] - a["p"]).cross(c["p"] - a["p"])
	if n.dot(outward) > 0.0:
		_add(st, a)
		_add(st, c)
		_add(st, b)
	else:
		_add(st, a)
		_add(st, b)
		_add(st, c)


static func _add(st: SurfaceTool, v: Dictionary) -> void:
	var bones := PackedInt32Array([0, 0, 0, 0])
	var weights := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	var list: Array = v["bones"]
	for k in mini(list.size(), 4):
		bones[k] = list[k][0]
		weights[k] = list[k][1]
	# Same colour space as palette uniforms in this renderer, so skin on the
	# body matches the face exactly.
	st.set_color(v["color"])
	st.set_bones(bones)
	st.set_weights(weights)
	st.add_vertex(v["p"])
