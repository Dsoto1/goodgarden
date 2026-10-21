extends Node3D
## Renders the cast side by side for character review (front, three-quarter,
## and mid-stride side views).
##   xvfb-run godot --path . --rendering-driver opengl3 res://tools/character_lineup.tscn -- --out=/abs/dir

var out_dir := "user://lineup"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("cfe0ef")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d6e4f5")
	env.environment.ambient_light_energy = 0.3
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, -30, 0)
	sun.light_color = Color("ffdcae")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshKit.box(self, Vector3(20, 0.1, 6), Vector3(0, -0.05, 0), "grass")
	ground.name = "Ground"
	var chars: Dictionary = Content.get_world("characters").get("characters", {})
	var looks: Array = [chars["player"]["look"], chars["miriam"]["look"], chars["tobias"]["look"], chars["ruth"]["look"]]
	looks.append_array(Content.get_world("characters").get("villagers", []))
	var models: Array[CharacterModel] = []
	for i in looks.size():
		var m := CharacterModel.new().build(looks[i])
		m.position = Vector3(-4.8 + i * 1.2, 0, 0)
		m.rotation.y = PI
		add_child(m)
		models.append(m)
	var cam := Camera3D.new()
	cam.fov = 40
	add_child(cam)
	cam.make_current()
	for m in models:
		m.animate(0.016, 0.0)
	await _frames(5)
	cam.position = Vector3(0, 1.1, 8.5)
	cam.look_at(Vector3(0, 0.9, 0))
	await shot("lineup_front")
	cam.position = Vector3(-3.0, 1.3, 2.4)
	cam.look_at(Vector3(-3.6, 0.9, 0))
	await shot("lineup_closeup")
	for m in models:
		m.rotation.y = PI / 2.0
		for f in 9:
			m.animate(0.016, 2.6)
	await _frames(3)
	cam.position = Vector3(-3.0, 1.0, 4.0)
	cam.look_at(Vector3(-3.0, 0.8, 0))
	await shot("lineup_walk")
	# Expressions: each model in turn shows one mood, front on.
	var moods := CharacterModel.MOODS.keys()
	for i in models.size():
		models[i].rotation.y = PI
		models[i].set_expression(moods[i % moods.size()])
		for f in 4:
			models[i].animate(0.3, 0.0)
	await _frames(3)
	cam.fov = 30
	cam.position = Vector3(-2.4, 1.55, 3.2)
	cam.look_at(Vector3(-2.4, 1.5, 0))
	await shot("lineup_moods")
	cam.position = Vector3(0.0, 1.45, 3.2)
	cam.look_at(Vector3(0.0, 1.4, 0))
	await shot("lineup_moods_2")
	cam.position = Vector3(-1.75, 0.8, 0.8)
	cam.look_at(Vector3(-2.16, 0.7, 0))
	await shot("lineup_hands")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
