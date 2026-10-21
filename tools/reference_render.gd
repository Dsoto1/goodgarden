extends Node3D
## Renders simple storybook blockouts of props, on a plain background, to use
## as references for image-to-3D generation (see docs/ARTLIST_SPENDING.md).
##   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1024x1024 res://tools/reference_render.tscn -- --out=/abs/dir

var out_dir := "user://references"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr(6)
	DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("e4e6e8")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("e8eef5")
	env.environment.ambient_light_energy = 0.45
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -35, 0)
	sun.light_color = Color("fff1dc")
	sun.light_energy = 1.0
	add_child(sun)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 30
	cam.make_current()
	var builders := {"trough": _trough, "gate": _gate, "basket": _basket}
	for id: String in builders:
		var root := Node3D.new()
		add_child(root)
		var size: float = builders[id].call(root)
		cam.position = Vector3(size * 1.35, size * 1.55, size * 1.9)
		cam.look_at(Vector3(0, size * 0.3, 0))
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir.path_join(id + ".png"))
		root.queue_free()
		await get_tree().process_frame
	get_tree().quit()


## Wooden kneading trough on splayed legs, a mound of dough inside, a cloth over one end.
func _trough(r: Node3D) -> float:
	MeshKit.box(r, Vector3(1.3, 0.08, 0.6), Vector3(0, 0.62, 0), "wood")
	for side: float in [-1.0, 1.0]:
		MeshKit.box(r, Vector3(1.4, 0.22, 0.07), Vector3(0, 0.75, side * 0.3), "wood").rotation.x = side * 0.25
		MeshKit.box(r, Vector3(0.07, 0.22, 0.66), Vector3(side * 0.66, 0.75, 0), "wood_dark")
		for z: float in [-0.22, 0.22]:
			var leg := MeshKit.box(r, Vector3(0.08, 0.66, 0.08), Vector3(side * 0.5, 0.31, z), "wood_dark")
			leg.rotation.z = side * 0.12
	MeshKit.sphere(r, 0.42, Vector3(0.12, 0.8, 0), "cloth_cream", Vector3(1.15, 0.5, 0.62), 16, 8)
	MeshKit.sphere(r, 0.17, Vector3(-0.32, 0.86, 0.04), "cloth_cream", Vector3(1.0, 0.7, 0.9), 12, 6)
	var cloth := MeshKit.box(r, Vector3(0.26, 0.03, 0.72), Vector3(-0.56, 0.89, 0), "cloth_blue")
	cloth.rotation.z = 0.1
	MeshKit.box(r, Vector3(0.26, 0.18, 0.03), Vector3(-0.56, 0.8, 0.37), "cloth_blue")
	return 1.4


## A sheepfold gate: two stout posts, three rails and a diagonal brace, with
## a stretch of dry-stone wall on either side.
func _gate(r: Node3D) -> float:
	for x: float in [-0.8, 0.8]:
		MeshKit.box(r, Vector3(0.16, 1.25, 0.16), Vector3(x, 0.62, 0), "wood_dark")
		MeshKit.sphere(r, 0.09, Vector3(x, 1.27, 0), "wood_dark", Vector3.ONE, 8, 4)
	for y: float in [0.3, 0.65, 1.0]:
		MeshKit.box(r, Vector3(1.44, 0.1, 0.06), Vector3(0, y, 0), "wood")
	var brace := MeshKit.box(r, Vector3(1.55, 0.09, 0.05), Vector3(0, 0.65, 0.04), "wood_light")
	brace.rotation.z = 0.47
	MeshKit.box(r, Vector3(0.12, 0.2, 0.09), Vector3(0.62, 0.65, -0.06), "dark")
	for y: float in [0.3, 1.0]:
		MeshKit.box(r, Vector3(0.05, 0.14, 0.12), Vector3(-0.72, y, 0.02), "dark")
	return 1.9


## A round woven basket heaped with bread rolls, a cloth tucked in at one side.
func _basket(r: Node3D) -> float:
	MeshKit.cylinder(r, 0.42, 0.34, 0.32, Vector3(0, 0.16, 0), "wood", 20)
	for y: float in [0.08, 0.17, 0.26]:
		MeshKit.cylinder(r, 0.36 + y * 0.25 + 0.012, 0.36 + y * 0.25 + 0.012, 0.025, Vector3(0, y, 0), "wood_dark", 20)
	MeshKit.cylinder(r, 0.44, 0.44, 0.05, Vector3(0, 0.32, 0), "wood_dark", 20)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var spots := [Vector3(0, 0.42, 0), Vector3(0.2, 0.36, 0.08), Vector3(-0.18, 0.37, 0.12), Vector3(0.05, 0.37, -0.22), Vector3(-0.16, 0.36, -0.15), Vector3(0.22, 0.35, -0.12), Vector3(0.0, 0.36, 0.24)]
	for p: Vector3 in spots:
		var roll := MeshKit.sphere(r, 0.13, p, "roof_thatch", Vector3(1.25, 0.7, 0.9), 12, 6)
		roll.rotation.y = rng.randf() * TAU
		var score := MeshKit.box(r, Vector3(0.18, 0.012, 0.025), p + Vector3(0, 0.088, 0), "cloth_cream")
		score.rotation.y = roll.rotation.y
	var cloth := MeshKit.sphere(r, 0.22, Vector3(-0.3, 0.36, 0.22), "cloth_red", Vector3(0.9, 0.35, 0.7), 10, 5)
	cloth.rotation.z = 0.6
	return 1.0
