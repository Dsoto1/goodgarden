extends SceneTree
func _init() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	await process_frame
	var p := Props.place(root, "house_far", Vector3.ZERO)
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for s in m.mesh.get_surface_count():
			var mat: Material = m.material_override if m.material_override else (m.get_surface_override_material(s) if m.get_surface_override_material(s) else m.mesh.surface_get_material(s))
			var arr := m.mesh.surface_get_arrays(s)
			print(m.name, " s", s, " mat ", mat, " tex ", mat.get_shader_parameter("use_texture") if mat is ShaderMaterial else "-", " uv ", arr[Mesh.ARRAY_TEX_UV] != null, " uv2 ", arr[Mesh.ARRAY_TEX_UV2] != null, " col ", arr[Mesh.ARRAY_COLOR] != null, " vcol ", mat.get_shader_parameter("use_vertex_color") if mat is ShaderMaterial else "-", " shader ", (mat as ShaderMaterial).shader.resource_path if mat is ShaderMaterial else "")
			if mat is ShaderMaterial:
				print("   albedo ", mat.get_shader_parameter("albedo_color"), " tex ", mat.get_shader_parameter("albedo_texture"))
	quit()
