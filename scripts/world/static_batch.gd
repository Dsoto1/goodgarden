class_name StaticBatch
extends RefCounted
## Merges unchanging scenery into a few combined meshes, so a tablet's GPU
## gets hundreds of draw calls instead of thousands. Pieces whose materials
## differ only in colour share one mesh: the colour is baked into vertex
## colours (the storybook shader multiplies albedo by vertex colour, so the
## result is identical). Meshes are grouped per patch of ground so distant
## patches can still be culled.
##
## Foliage sways about its own origin, so it is not merged; repeated foliage
## props (trees, flowers, bushes) are drawn with one MultiMesh per kind per
## patch instead, which keeps each copy's origin. Anything that changes at
## runtime stays live: nodes with a script, nodes marked with mark_live()
## (Region.group_node does this for containers the story shows or hides),
## animated imports, and hidden nodes.

const LIVE_META := &"batch_live"
## Uniforms that the merge bakes into vertices instead of keeping per material:
## the colour, and the colour grade (saturation and tint) applied to it.
const BAKED := ["albedo_color", "use_vertex_color", "ignore_vertex_color", "saturation", "tint"]

static var _uniform_names: Dictionary = {} # Shader -> Array[String]


static func mark_live(node: Node) -> void:
	node.set_meta(LIVE_META, true)


## Merges eligible meshes under `root` into children of `root`. `cell` sizes the
## patches (in metres); use INF for something small such as a character's
## head. Returns how many meshes were merged.
static func merge(root: Node3D, cell := 12.0) -> int:
	var groups := {}
	var merged: Array[MeshInstance3D] = []
	var solid := Style.shader("solid")
	for child in root.get_children():
		if child is Node3D:
			_collect(child, (child as Node3D).transform, solid, cell, groups, merged)
	merged.append_array(_instance_foliage(root, groups))
	for key: String in groups:
		var g: Dictionary = groups[key]
		if g.has("foliage"):
			continue
		var mi := MeshInstance3D.new()
		mi.name = "Batched"
		mi.mesh = _build(g["items"], g["bake"])
		mi.material_override = g["material"]
		mi.cast_shadow = g["shadow"]
		root.add_child(mi)
	for mi in merged:
		mi.mesh = null
	return merged.size()


static func _collect(node: Node3D, xform: Transform3D, solid: Shader, cell: float, groups: Dictionary, merged: Array[MeshInstance3D]) -> void:
	if node.get_script() != null or node.has_meta(LIVE_META) or not node.visible or node.top_level:
		return
	if node is Skeleton3D or node is BoneAttachment3D or node.find_children("*", "AnimationPlayer", false, false).size() > 0:
		return
	if node is MeshInstance3D:
		_take(node as MeshInstance3D, xform, solid, cell, groups, merged)
	for child in node.get_children():
		if child is Node3D:
			_collect(child, xform * (child as Node3D).transform, solid, cell, groups, merged)


static func _take(mi: MeshInstance3D, xform: Transform3D, solid: Shader, cell: float, groups: Dictionary, merged: Array[MeshInstance3D]) -> void:
	var mesh := mi.mesh
	if mesh == null or mesh is ArrayMesh and (mesh as ArrayMesh).get_blend_shape_count() > 0:
		return
	if mi.visibility_range_end > 0.0 or mi.transparency > 0.0 or mi.skin != null:
		return
	var mats: Array[ShaderMaterial] = []
	var foliage := false
	for s in mesh.get_surface_count():
		var m: Material = mi.material_override
		if m == null:
			m = mi.get_surface_override_material(s)
		if m == null:
			m = mesh.surface_get_material(s)
		if not (m is ShaderMaterial):
			return
		var sh := (m as ShaderMaterial).shader
		if sh == Style.shader("foliage"):
			foliage = true
		elif sh != solid:
			return
		mats.append(m)
	var at := xform.origin
	var patch := "" if is_inf(cell) else "%d:%d" % [floori(at.x / cell), floori(at.z / cell)]
	if foliage:
		var ids := PackedStringArray()
		for m in mats:
			ids.append(str(m.get_instance_id()))
		var fkey := "foliage|%d|%s|%d|%s" % [mesh.get_instance_id(), ",".join(ids), mi.cast_shadow, patch]
		if not groups.has(fkey):
			groups[fkey] = {"foliage": true, "mesh": mesh, "materials": mats, "shadow": mi.cast_shadow, "items": []}
		groups[fkey]["items"].append([mi, xform])
		return
	for s in mesh.get_surface_count():
		var m := mats[s]
		var bake: bool = m.get_shader_parameter("use_texture") != true
		# Flat materials group by everything except colour; textured ones by identity.
		var look := _signature(m) if bake else str(m.get_instance_id())
		var key := "%s|%d|%s" % [look, mi.cast_shadow, patch]
		if not groups.has(key):
			var shared := m
			if bake:
				shared = m.duplicate()
				shared.set_shader_parameter("albedo_color", Color.WHITE)
				shared.set_shader_parameter("use_vertex_color", true)
				shared.set_shader_parameter("saturation", 1.0)
				shared.set_shader_parameter("tint", Vector3.ONE)
			groups[key] = {"material": shared, "shadow": mi.cast_shadow, "bake": bake, "items": []}
		groups[key]["items"].append([mesh, s, xform, m])
	merged.append(mi)


## Turns each kind of foliage that repeats within a patch into one MultiMesh.
## Returns the original meshes that are now drawn by instancing.
static func _instance_foliage(root: Node3D, groups: Dictionary) -> Array[MeshInstance3D]:
	var done: Array[MeshInstance3D] = []
	for key: String in groups:
		var g: Dictionary = groups[key]
		if not g.has("foliage") or g["items"].size() < 2:
			continue
		var mesh := (g["mesh"] as Mesh).duplicate() as Mesh
		for s in mesh.get_surface_count():
			mesh.surface_set_material(s, g["materials"][s])
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = g["items"].size()
		for i in g["items"].size():
			mm.set_instance_transform(i, g["items"][i][1])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Instanced"
		mmi.multimesh = mm
		mmi.cast_shadow = g["shadow"]
		root.add_child(mmi)
		for item: Array in g["items"]:
			done.append(item[0])
	return done


static func _signature(m: ShaderMaterial) -> String:
	if not _uniform_names.has(m.shader):
		var names: Array[String] = []
		for u: Dictionary in m.shader.get_shader_uniform_list():
			if not BAKED.has(u["name"]):
				names.append(u["name"])
		_uniform_names[m.shader] = names
	var parts := PackedStringArray()
	for n: String in _uniform_names[m.shader]:
		parts.append(str(m.get_shader_parameter(n)))
	return "|".join(parts)


## Concatenates the surfaces in model space of the merge root. With `bake`,
## each vertex colour becomes the material's graded colour (times the mesh's
## own vertex colour when the material used it), matching storybook grade().
static func _build(items: Array, bake: bool) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for item: Array in items:
		var arrays: Array = (item[0] as Mesh).surface_get_arrays(item[1])
		var xform: Transform3D = item[2]
		var m: ShaderMaterial = item[3]
		var normal_basis := xform.basis.inverse().transposed()
		var src_v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var src_n: Variant = arrays[Mesh.ARRAY_NORMAL]
		var src_c: Variant = arrays[Mesh.ARRAY_COLOR]
		var src_uv: Variant = arrays[Mesh.ARRAY_TEX_UV]
		var src_i: Variant = arrays[Mesh.ARRAY_INDEX]
		var albedo := Color.WHITE
		var saturation := 1.0
		var grade_tint := Vector3.ONE
		var keep_vertex_color := src_c != null and not bake
		if bake:
			var a: Variant = m.get_shader_parameter("albedo_color")
			albedo = a if a is Color else Color.WHITE
			var s: Variant = m.get_shader_parameter("saturation")
			saturation = float(s) if s != null else 1.0
			var t: Variant = m.get_shader_parameter("tint")
			grade_tint = t if t is Vector3 else Vector3.ONE
			keep_vertex_color = src_c != null and (m.get_shader_parameter("use_vertex_color") == true) and not (m.get_shader_parameter("ignore_vertex_color") == true)
		var flat := _grade(albedo, saturation, grade_tint) if bake else Color.WHITE
		var base := verts.size()
		for i in src_v.size():
			verts.append(xform * src_v[i])
			normals.append((normal_basis * (src_n as PackedVector3Array)[i]).normalized() if src_n != null else Vector3.UP)
			if keep_vertex_color and bake:
				colors.append(_grade(albedo * (src_c as PackedColorArray)[i], saturation, grade_tint))
			elif keep_vertex_color:
				colors.append((src_c as PackedColorArray)[i])
			else:
				colors.append(flat)
			uvs.append((src_uv as PackedVector2Array)[i] if src_uv != null else Vector2.ZERO)
		if src_i != null:
			for idx in (src_i as PackedInt32Array):
				indices.append(base + idx)
		else:
			for i in src_v.size():
				indices.append(base + i)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var out := ArrayMesh.new()
	if verts.is_empty():
		return out
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## Same as grade() in shaders/storybook_common.gdshaderinc.
static func _grade(c: Color, saturation: float, tint: Vector3) -> Color:
	var luma := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	return Color(lerpf(luma, c.r, saturation) * tint.x, lerpf(luma, c.g, saturation) * tint.y, lerpf(luma, c.b, saturation) * tint.z, c.a)
