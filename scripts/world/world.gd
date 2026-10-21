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
	Settings.changed.connect(func(key: String) -> void:
		if key == "reduced_motion":
			Style.apply_settings())
	_build_environment()
	for entry: Dictionary in Content.get_world("regions").get("regions", []):
		_load_region(entry)
	_bake_navigation()
	_grow_ground_cover()
	var forest := Forest.new()
	forest.name = "Forest"
	add_child(forest)
	forest.build(77, 1.0 if Settings.get_value("lush_detail") else 0.5)
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
	SaveService.player_provider = player.save_state
	Days.day_started.connect(func(_d: int) -> void: _place_npcs())
	AudioService.set_ambience("outdoor", 1.0)


func _exit_tree() -> void:
	SaveService.player_provider = Callable()


func _build_environment() -> void:
	environment = Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("4d8ed8")
	sky_mat.sky_horizon_color = Color("f3dfbf")
	sky_mat.sky_curve = 0.12
	sky_mat.ground_horizon_color = Color("e9d9bd")
	sky_mat.ground_bottom_color = Color("7f9f68")
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
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
	sun.directional_shadow_max_distance = 40.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)


func _grow_ground_cover() -> void:
	var clearings: Array[Dictionary] = []
	for region: Region in regions.values():
		clearings.append_array(region.clearings)
	var cover := GroundCover.new()
	cover.name = "GroundCover"
	add_child(cover)
	var area := ValleyRegion.BOUNDS.grow(10.0)
	var density := 1.0 if Settings.get_value("lush_detail") else 0.4
	cover.build(area, clearings, density, 2024)
	cover.fringe_paths(clearings, density, 2025)


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
	if entry.get("on_terrain", false):
		region.position.y = Terrain.height(o[0], o[2])
	add_child(region)
	regions[region.region_id] = region


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


## Fast travel from the map: only to discovered places.
func travel_to(region_id: String) -> bool:
	if not Discovery.is_discovered(region_id):
		return false
	for entry: Dictionary in Content.get_world("regions").get("regions", []):
		if entry["id"] == region_id and entry.has("arrive"):
			move_player_to_anchor(str(entry["arrive"]))
			return true
	return false


func _spawn_npcs() -> void:
	var miriam := NPC.create("miriam", {
		"skin": "skin_1", "hair": "hair_grey", "hair_style": "bun", "shirt": "cloth_green",
		"skirt": "cloth_blue", "pants": "cloth_blue", "apron": "cloth_cream", "hat": "straw",
		"hat_band": "cloth_red", "height": 1.08,
	}, "miriam")
	add_child(miriam)
	npcs["miriam"] = miriam
	_place_npcs()


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
	get_tree().call_group("hud", "set_quiet", new_mood == "chapel")
