class_name World
extends Node3D
## Assembles the explorable world: sky and light, regions from
## content/world/regions.json, the child's avatar and camera, and NPCs placed
## by the day definition. Also owns the world's mood (outdoor, home, chapel).

const MOODS := {
	"outdoor": {"sun": 1.15, "ambient": 0.27, "ambient_color": Color("cfdff5"), "chapel_light": 0.0, "sound": "outdoor"},
	"home": {"sun": 0.6, "ambient": 0.38, "ambient_color": Color("f3e3cc"), "chapel_light": 0.0, "sound": "interior"},
	"chapel": {"sun": 0.25, "ambient": 0.25, "ambient_color": Color("e8cfa8"), "chapel_light": 1.6, "sound": "chapel"},
}

var regions: Dictionary = {} # id -> Region
var player: Player
var rig: CameraRig
var sun: DirectionalLight3D
var environment: Environment
var npcs: Dictionary = {} # id -> NPC
var mood := "outdoor"


func _ready() -> void:
	add_to_group("mood_listeners")
	Style.apply_settings()
	Quality.apply_viewport(get_viewport())
	Settings.changed.connect(_on_setting_changed)
	_build_environment()
	_water_bodies()
	for entry: Dictionary in Content.get_world("regions").get("regions", []):
		_load_region(entry)
	_bake_navigation()
	_grow_ground_cover()
	var waysides := Waysides.new()
	waysides.name = "Waysides"
	add_child(waysides)
	waysides.build()
	var forest := Forest.new()
	forest.name = "Forest"
	add_child(forest)
	forest.build(77, Quality.value("forest_density"))
	player = Player.new()
	player.name = "Player"
	add_child(player)
	rig = CameraRig.new()
	rig.name = "CameraRig"
	add_child(rig)
	rig.target = player
	player.camera = rig.camera
	_spawn_npcs()
	_place_player()
	rig.snap()
	_build_snowfall()
	_mark_snow_holes()
	_apply_snow()
	Days.day_started.connect(func(_d: int) -> void: _apply_snow())
	SaveService.player_provider = player.save_state
	Days.day_started.connect(func(_d: int) -> void: _place_npcs())
	AudioService.set_ambience("outdoor", 1.0)


## A method rather than a lambda, so the connection ends when the world is freed.
func _on_setting_changed(key: String) -> void:
	if key == "reduced_motion":
		Style.apply_settings()
	elif key == "scenery_quality":
		Quality.apply_viewport(get_viewport())
		sun.directional_shadow_max_distance = Quality.value("shadow_distance")


func _exit_tree() -> void:
	SaveService.player_provider = Callable()


## The land below the horizon (the sky shader's ground_color).
const GROUND_BELOW := Color("7f9f68")


## A painted sky with soft drifting clouds (Binbun Skies, adapted: see
## assets/third_party/binbun/skies), in the storybook's colours. Its cloud
## noise is generated here at a modest size, so it is quick to make on tablets.
func _painted_sky() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://assets/third_party/binbun/skies/sky.gdshader")
	m.set_shader_parameter("sky_day", Color("4d8ed8"))
	m.set_shader_parameter("horizon_day", Color("f3dfbf"))
	# Always day: the low afternoon sun mustn't turn the horizon to sunset.
	m.set_shader_parameter("sky_sunset", Color("4d8ed8"))
	m.set_shader_parameter("horizon_sunset", Color("f3dfbf"))
	m.set_shader_parameter("horizon_exponent", 14.0)
	m.set_shader_parameter("use_directional_light", true)
	m.set_shader_parameter("cloud_color", Color(1.0, 0.98, 0.94))
	m.set_shader_parameter("cloud_tiling", Vector2(0.35, 0.35))
	m.set_shader_parameter("wind_speed", Vector2(0.05, 0.05) if not Settings.get_value("reduced_motion") else Vector2.ZERO)
	m.set_shader_parameter("cloud_density", 0.55)
	m.set_shader_parameter("cloud_depth", 0.0)
	m.set_shader_parameter("cloud_shape_exponent", 0.2)
	m.set_shader_parameter("cloud_occlude_exponent", 1.6)
	m.set_shader_parameter("sun_scale", 0.04)
	m.set_shader_parameter("sun_strength", 3.0)
	m.set_shader_parameter("sun_color", Color(1, 0.93, 0.6))
	m.set_shader_parameter("ground_color", GROUND_BELOW)
	m.set_shader_parameter("cloud_tex_01", _cloud_noise(FastNoiseLite.TYPE_SIMPLEX, 4, 6, 0.2))
	m.set_shader_parameter("cloud_tex_02", _cloud_noise(FastNoiseLite.TYPE_PERLIN, 0, 8, 0.4))
	var dark := _cloud_noise(FastNoiseLite.TYPE_VALUE, 1, 1, 0.2, 64)
	m.set_shader_parameter("night_noise_01", dark)
	m.set_shader_parameter("night_noise_02", dark)
	return m


static func _cloud_noise(kind: FastNoiseLite.NoiseType, seed_value: int, octaves: int, skirt: float, size := 512) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = kind
	noise.seed = seed_value
	noise.fractal_octaves = octaves
	var tex := NoiseTexture2D.new()
	tex.width = size
	tex.height = size
	tex.seamless = true
	tex.seamless_blend_skirt = skirt
	tex.noise = noise
	return tex


func _build_environment() -> void:
	environment = Environment.new()
	var sky := Sky.new()
	sky.sky_material = _painted_sky()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = MOODS["outdoor"]["ambient_color"]
	environment.ambient_light_energy = MOODS["outdoor"]["ambient"]
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = true
	# Hazy distance: far hills turn soft blue, like aerial perspective in a painting.
	environment.fog_light_color = Color("9fbde3")
	environment.fog_density = 0.0019
	environment.fog_aerial_perspective = 0.4
	environment.fog_sky_affect = 0.15
	var we := WorldEnvironment.new()
	we.environment = environment
	add_child(we)
	sun = DirectionalLight3D.new()
	# Golden afternoon: a lower, warm sun with longer shadows.
	sun.rotation_degrees = Vector3(-34, -42, 0)
	sun.light_color = Color("ffdcae")
	sun.light_energy = MOODS["outdoor"]["sun"]
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = Quality.value("shadow_distance")
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)


## The sea beyond the river's mouth, and the lake in the south-eastern hills.
func _water_bodies() -> void:
	var sea := MeshInstance3D.new()
	sea.name = "Sea"
	var plane := PlaneMesh.new()
	plane.size = Vector2(900, 1200)
	plane.subdivide_width = 24
	plane.subdivide_depth = 24
	sea.mesh = plane
	sea.position = Vector3(Terrain.SEA_X - 40.0 + 450.0, Terrain.SEA_LEVEL, 0)
	sea.material_override = Palette.mat("water")
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sea)
	var lake := MeshInstance3D.new()
	lake.name = "Lake"
	var disc := CylinderMesh.new()
	disc.top_radius = Terrain.LAKE_RADIUS + 1.5
	disc.bottom_radius = Terrain.LAKE_RADIUS + 1.5
	disc.height = 0.02
	disc.radial_segments = 48
	lake.mesh = disc
	lake.position = Vector3(Terrain.LAKE.x, Terrain.LAKE_LEVEL, Terrain.LAKE.y)
	lake.material_override = Palette.mat("water")
	lake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lake)


func _grow_ground_cover() -> void:
	var clearings: Array[Dictionary] = []
	for region: Region in regions.values():
		clearings.append_array(region.clearings)
	var cover := GroundCover.new()
	cover.name = "GroundCover"
	add_child(cover)
	var area := ValleyRegion.BOUNDS.grow(10.0)
	var density: float = Quality.value("cover_density")
	cover.build(area, clearings, density, 2024)
	cover.fringe_paths(clearings, density, 2025)
	for far: Region in regions.values():
		if far is FarRegion:
			var a := (far as FarRegion).area
			var far_cover := GroundCover.new()
			far_cover.name = "GroundCover_" + far.region_id
			add_child(far_cover)
			far_cover.build(Rect2(Vector2(far.position.x, far.position.z) + a.position, a.size).grow(4.0), clearings, density, far.region_id.hash())


## Bakes walkable ground from the static colliders of every region, so tap-to-walk
## goes around fences and walls and through doors and gates.
func _bake_navigation() -> void:
	var nav := NavigationMesh.new()
	nav.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav.geometry_collision_mask = MeshKit.LAYER_GROUND | MeshKit.LAYER_OBSTACLE | MeshKit.LAYER_INVISIBLE
	nav.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	nav.geometry_source_group_name = &"navigation_source"
	add_to_group("navigation_source")
	nav.agent_radius = 0.25
	nav.agent_height = 1.25
	nav.agent_max_climb = 0.25
	nav.cell_size = 0.25
	nav.cell_height = 0.25
	var b := ValleyRegion.BOUNDS
	nav.filter_baking_aabb = AABB(Vector3(b.position.x, -1, b.position.y), Vector3(b.size.x, 4, b.size.y))
	var region := NavigationRegion3D.new()
	region.name = "Navigation"
	region.navigation_mesh = nav
	add_child(region)
	region.bake_navigation_mesh(false)
	# Each place in the wider world gets walking ground of its own.
	for far: Region in regions.values():
		if not far is FarRegion:
			continue
		var a := (far as FarRegion).area
		var far_nav: NavigationMesh = nav.duplicate()
		far_nav.filter_baking_aabb = AABB(far.position + Vector3(a.position.x, -1, a.position.y), Vector3(a.size.x, 5, a.size.y))
		var far_region := NavigationRegion3D.new()
		far_region.name = "Navigation_" + far.region_id
		far_region.navigation_mesh = far_nav
		add_child(far_region)
		far_region.bake_navigation_mesh(false)


func _load_region(entry: Dictionary) -> void:
	var scene: PackedScene = load(str(entry["scene"]))
	if scene == null:
		push_error("World: missing region scene %s" % entry["scene"])
		return
	var region: Region = scene.instantiate()
	region.region_id = str(entry["id"])
	region.display_name = tr(str(entry.get("name", entry["id"])))
	var o: Array = entry.get("origin", [0, 0, 0])
	region.position = Vector3(o[0], o[1], o[2])
	if entry.has("site"):
		region.position = Terrain.site_center(str(entry["site"]))
	elif entry.get("on_terrain", false):
		region.position.y = Terrain.height(o[0], o[2])
	add_child(region)
	regions[region.region_id] = region
	StaticBatch.merge(region, 40.0)


func anchor(anchor_id: String) -> Marker3D:
	for m in get_tree().get_nodes_in_group("anchors"):
		if m.get_meta("anchor_id", "") == anchor_id:
			return m
	return null


func _place_player() -> void:
	var saved: Dictionary = SaveService.loaded_player
	if saved.has("position"):
		var p: Array = saved["position"]
		player.teleport(Vector3(p[0], p[1], p[2]), float(saved.get("facing", 0.0)))
	else:
		move_player_to_anchor("home_spawn")


func move_player_to_anchor(anchor_id: String) -> void:
	var a := anchor(anchor_id)
	if a:
		player.teleport(a.global_position, a.global_rotation.y)
		rig.snap()


## Fast travel from the map: to places the child has been, and to places in
## the wider world once they have opened.
func travel_to(region_id: String) -> bool:
	for entry: Dictionary in Content.get_world("regions").get("regions", []):
		if entry["id"] != region_id or not entry.has("arrive"):
			continue
		if not (Discovery.is_discovered(region_id) or is_open(entry)):
			return false
		move_player_to_anchor(str(entry["arrive"]))
		return true
	return false


## A place in the wider world is open once its "open_when" conditions hold.
static func is_open(entry: Dictionary) -> bool:
	return entry.get("reachable", true) and entry.has("open_when") and WorldState.matches(entry["open_when"])


func _spawn_npcs() -> void:
	var miriam := NPC.create("miriam", look_for("miriam"), "miriam")
	add_child(miriam)
	npcs["miriam"] = miriam
	_place_npcs()


## A character's look from content/world/characters.json.
static func look_for(character_id: String) -> Dictionary:
	return Content.get_world("characters").get("characters", {}).get(character_id, {}).get("look", {})


func _place_npcs() -> void:
	for id: String in npcs:
		var npc: NPC = npcs[id]
		var a := anchor(Days.npc_anchor(id))
		npc.visible = a != null
		npc.talk.enabled = a != null
		if a:
			npc.global_position = a.global_position
			npc.rotation.y = a.global_rotation.y


# --- Mood ---------------------------------------------------------------

func on_mood_entered(new_mood: String) -> void:
	set_mood(new_mood)


func on_mood_exited(old_mood: String) -> void:
	if mood == old_mood:
		set_mood("outdoor")


func set_mood(new_mood: String) -> void:
	if new_mood == mood or not MOODS.has(new_mood):
		return
	mood = new_mood
	var m: Dictionary = MOODS[new_mood]
	var seconds := 0.01 if Settings.get_value("reduced_motion") else 1.6
	var t := create_tween().set_parallel(true)
	t.tween_property(sun, "light_energy", m["sun"], seconds)
	t.tween_property(environment, "ambient_light_energy", m["ambient"], seconds)
	t.tween_property(environment, "ambient_light_color", m["ambient_color"], seconds)
	for light in get_tree().get_nodes_in_group("chapel_light"):
		t.tween_property(light, "light_energy", m["chapel_light"], seconds)
	AudioService.set_ambience(m["sound"], 2.5 if new_mood == "chapel" else 1.5)
	_apply_snow()
	get_tree().call_group("hud", "set_quiet", new_mood == "chapel")


## The winter weeks: snow lies over the land as deep as the day says (the
## shaders read gg_snow), the grass is under it, and on snowy days flakes
## drift down around the child (not indoors, and not with "Less motion").
func _apply_snow() -> void:
	var snow := Days.snow()
	RenderingServer.global_shader_parameter_set(&"gg_snow", snow)
	# The land below the horizon, beyond the edge of the world, is snowy too.
	var sky_mat := environment.sky.sky_material as ShaderMaterial
	sky_mat.set_shader_parameter("ground_color", GROUND_BELOW.lerp(Color("cfd6e2"), snow))
	for cover in find_children("GroundCover*", "GroundCover", false, false):
		(cover as Node3D).visible = snow < 0.5
	if _snowfall:
		_snowfall.emitting = Days.snowing() and mood == "outdoor" and not Settings.get_value("reduced_motion")


var _snowfall: CPUParticles3D


func _build_snowfall() -> void:
	_snowfall = CPUParticles3D.new()
	_snowfall.name = "Snowfall"
	_snowfall.emitting = false
	_snowfall.amount = int(360 * clampf(Quality.value("forest_density"), 0.4, 1.0))
	_snowfall.lifetime = 7.0
	_snowfall.preprocess = 7.0
	_snowfall.local_coords = false
	_snowfall.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_snowfall.emission_box_extents = Vector3(14, 0.5, 14)
	_snowfall.direction = Vector3(0.15, -1, 0.05)
	_snowfall.spread = 12.0
	_snowfall.gravity = Vector3(0, -0.6, 0)
	_snowfall.initial_velocity_min = 0.6
	_snowfall.initial_velocity_max = 1.1
	_snowfall.scale_amount_min = 0.6
	_snowfall.scale_amount_max = 1.2
	var flake := QuadMesh.new()
	flake.size = Vector2(0.07, 0.07)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 1, 1, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	flake.material = m
	_snowfall.mesh = flake
	_snowfall.position = Vector3(0, 7, 0)
	player.add_child(_snowfall)


## Snow never lies indoors: the interiors' floor plans go to the shaders.
func _mark_snow_holes() -> void:
	var holes: Array[Vector4] = []
	for region: Region in regions.values():
		for zone in region.interiors:
			for shape in zone.find_children("*", "CollisionShape3D", false, false):
				var cs := shape as CollisionShape3D
				var half := (cs.shape as BoxShape3D).size / 2.0
				var c := cs.global_position
				holes.append(Vector4(c.x - half.x, c.z - half.z, c.x + half.x, c.z + half.z))
	for i in 4:
		RenderingServer.global_shader_parameter_set(StringName("gg_snow_hole_%d" % i), holes[i] if i < holes.size() else Vector4.ZERO)
