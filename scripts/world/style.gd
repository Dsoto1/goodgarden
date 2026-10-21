class_name Style
extends RefCounted
## One look for the whole world. Every surface, procedural or imported, is
## drawn with the storybook shaders in res://shaders/, so KayKit buildings,
## Quaternius foliage and hand-built pieces share the same light, shade and
## colour grading. Materials are converted once and cached, so instances keep
## sharing them (draw-call friendly).

const SHADERS := {
	"solid": "res://shaders/storybook.gdshader",
	"foliage": "res://shaders/storybook_foliage.gdshader",
	"ground": "res://shaders/ground.gdshader",
	"water": "res://shaders/water.gdshader",
	"falls": "res://shaders/falls.gdshader",
}

static var _shaders := {}
static var _converted := {}


static func shader(kind: String) -> Shader:
	if not _shaders.has(kind):
		_shaders[kind] = load(SHADERS[kind])
	return _shaders[kind]


## A flat-coloured storybook material for procedural geometry.
static func flat(color: Color, params: Dictionary = {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader("foliage" if params.get("foliage", false) else "solid")
	m.set_shader_parameter("albedo_color", color)
	for key: String in params:
		if key != "foliage":
			m.set_shader_parameter(key, params[key])
	return m


static func material(kind: String, params: Dictionary = {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader(kind)
	for key: String in params:
		m.set_shader_parameter(key, params[key])
	return m


## Converts an imported glTF material. `grade` holds saturation/tint/wrap for
## the source pack or prop; `sway` animates alpha-cut foliage in the wind.
static func convert_material(source: Material, grade: Dictionary, sway: float, cache_key: String) -> Material:
	var src := source as BaseMaterial3D
	if src == null:
		return source
	var key := "%s:%d" % [cache_key, src.get_instance_id()]
	if _converted.has(key):
		return _converted[key]
	var cutout := src.transparency in [BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, BaseMaterial3D.TRANSPARENCY_ALPHA, BaseMaterial3D.TRANSPARENCY_ALPHA_HASH, BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS]
	var two_sided := src.cull_mode == BaseMaterial3D.CULL_DISABLED
	var m := ShaderMaterial.new()
	m.shader = shader("foliage" if cutout or two_sided or sway > 0.0 else "solid")
	m.set_shader_parameter("albedo_color", src.albedo_color)
	if src.albedo_texture:
		m.set_shader_parameter("albedo_texture", src.albedo_texture)
		m.set_shader_parameter("use_texture", true)
	# Some packs store shader masks (not colour) in vertex colours; grades opt out.
	m.set_shader_parameter("use_vertex_color", src.vertex_color_use_as_albedo and not grade.get("ignore_vertex_color", false))
	if src.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
		m.set_shader_parameter("alpha_cut", src.alpha_scissor_threshold)
	if not cutout:
		m.set_shader_parameter("alpha_cut", 0.0)
	m.set_shader_parameter("sway", sway)
	if src.emission_enabled:
		m.set_shader_parameter("emission_color", src.emission * src.emission_energy_multiplier)
	for param: String in ["saturation", "wrap", "rim_strength", "root_shade"]:
		if grade.has(param):
			m.set_shader_parameter(param, float(grade[param]))
	if grade.has("up_normals"):
		m.set_shader_parameter("up_normals", bool(grade["up_normals"]))
	if grade.has("tint"):
		var t: Array = grade["tint"]
		m.set_shader_parameter("tint", Vector3(t[0], t[1], t[2]))
	_converted[key] = m
	return m


## Applies `convert_material` to every surface under `root`.
static func apply(root: Node, grade: Dictionary, sway: float, cache_key: String) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var source := mi.get_active_material(i)
			if source:
				mi.set_surface_override_material(i, convert_material(source, grade, sway, cache_key))


## Wind follows the "Less motion" setting.
static func apply_settings() -> void:
	RenderingServer.global_shader_parameter_set("gg_wind", 0.0 if Settings.get_value("reduced_motion") else 1.0)
