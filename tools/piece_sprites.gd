extends Node
## Photographs 3D food models into small pictures for the hands-on boards,
## so a loaf, an apple or a fish on a board looks like the one on the market
## stall. Each picture is the prop in the storybook lighting, seen from a
## gentle three-quarter angle, on a clear background; PieceArt draws it in
## place of the hand-drawn shape (and its shadow as the matching outline).
##   xvfb-run godot --path . --rendering-driver opengl3 res://tools/piece_sprites.tscn
## Writes assets/pieces/<piece kind>.png; run the editor once afterwards to import them.

## Board piece kind -> prop. Existing kinds keep their names, so every activity
## that uses them gets the new look; the rest are new kinds for future boards.
const PIECES := {
	"apple": "food_apple_red",
	"loaf_round": "food_bread_round",
	"loaf_long": "food_loaf",
	"jam_jar": "food_jam",
	"minnow": "food_bluegill",
	"pear": "food_pear",
	"plum": "food_plum",
	"grapes": "food_grapes",
	"carrot": "food_carrot",
	"potato": "food_potato",
	"onion": "food_onion",
	"turnip": "food_turnip",
	"cabbage": "food_cabbage",
	"pumpkin": "food_pumpkin",
	"corn": "food_corn",
	"melon": "food_melon",
	"cheese": "food_cheese_wheel",
	"honey": "food_honey",
	"cake": "food_cake",
	"pretzel": "food_pretzel",
	"baguette": "food_baguette",
	"salmon": "food_salmon",
	"mushroom": "food_mushroom",
}
const SIZE := 256
const OUT := "res://assets/pieces/"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var view := SubViewport.new()
	view.size = Vector2i(SIZE, SIZE)
	view.transparent_bg = true
	view.own_world_3d = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff4e0")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	view.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.1
	view.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 26.0
	view.add_child(cam)
	var stage := Node3D.new()
	view.add_child(stage)
	for kind: String in PIECES:
		for c in stage.get_children():
			c.free()
		var prop := Props.place(stage, PIECES[kind], Vector3.ZERO)
		Style.no_snow(prop)
		var box := Props.bounds(prop)
		var centre := box.get_center()
		var radius := box.size.length() / 2.0
		# Three-quarters from the front and a little above, framing the whole piece.
		var dir := Vector3(0.0, 0.62, 1.0).normalized()
		cam.position = centre + dir * radius / sin(deg_to_rad(cam.fov / 2.0)) * 1.02
		cam.look_at(centre)
		for i in 4:
			await RenderingServer.frame_post_draw
		var img := view.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path(OUT + kind + ".png"))
		print("piece ", kind)
	get_tree().quit()
