class_name AnimalMoments
extends RefCounted
## Small, unscored moments with the animals: stroke a lamb and it hops, the
## cat stays to be petted and purrs, scattered grain brings the hens running.
## Nothing is counted or required; they are there for a child who stops to
## look. Each moment says one short line, so a non-reader knows what happened.

## Makes the animal walking about as `w` something the child can stroke.
## `lines` are what the caption may say (one is picked each time); `sound`
## is a world sound name (see AudioService.FILES), played from the animal.
static func strokable(w: Wanderer, prompt: String, lines: Array, sound := "") -> Interactable:
	var it := Interactable.create(w, Vector3.ZERO, prompt, Callable(), 0.6, _marker_height(w))
	it.reach = 1.6
	it.action = func() -> void:
		w.pause_for(5.0)
		if w.model is FarmAnimal and (w.model as FarmAnimal).kind in ["lamb", "dog", "pig"]:
			(w.model as FarmAnimal).hop()
		hearts(w, Vector3(0, _marker_height(w) - 0.4, 0))
		if not sound.is_empty():
			SoundSpot.once(w, sound, Vector3(0, 0.6, 0), 14.0)
		w.get_tree().call_group("main", "show_caption", tr_line(lines.pick_random()), 3.0)
	return it


## A grain bin by a coop: scattering grain brings `hens` to peck at it for a
## while, and a little grain lies on the ground until they have eaten it.
static func grain_bin(parent: Node3D, pos: Vector3, scatter_at: Vector3, hens: Array[Wanderer]) -> Interactable:
	# A small lidded tub with a scoop resting on it.
	MeshKit.cylinder(parent, 0.26, 0.22, 0.5, pos + Vector3(0, 0.25, 0), "wood_dark", 10)
	MeshKit.cylinder(parent, 0.28, 0.28, 0.05, pos + Vector3(0, 0.52, 0), "wood", 10)
	var scoop := MeshKit.cylinder(parent, 0.07, 0.06, 0.1, pos + Vector3(0.08, 0.6, 0), "stone_dark", 6)
	scoop.rotation.z = 1.2
	var it := Interactable.create(parent, pos, "Scatter grain for the hens", Callable(), 0.6, 1.1)
	var grain := Node3D.new()
	grain.name = "Grain"
	grain.position = scatter_at
	parent.add_child(grain)
	it.action = func() -> void:
		for c in grain.get_children():
			c.queue_free()
		var rng := RandomNumberGenerator.new()
		for k in 26:
			var a := rng.randf() * TAU
			var r := sqrt(rng.randf()) * 0.75
			var g := MeshKit.box(grain, Vector3(0.035, 0.012, 0.025), Vector3(cos(a) * r, 0.02, sin(a) * r), "gold", false, rng.randf() * PI)
			g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		grain.visible = true
		for h in hens:
			if is_instance_valid(h):
				h.visit(grain.global_position, 12.0, 0.6)
		parent.get_tree().create_timer(12.0).timeout.connect(func() -> void:
			if is_instance_valid(grain):
				grain.visible = false)
		SoundSpot.once(parent, "hens", scatter_at + Vector3(0, 0.4, 0), 16.0)
		parent.get_tree().call_group("main", "show_caption", tr_line("Chook, chook! The hens come running for the grain."), 3.5)
	return it


## A few small hearts that float up from `pos` (parent-local) and fade.
static func hearts(parent: Node3D, pos: Vector3) -> void:
	var reduced: bool = Settings.get_value("reduced_motion")
	for i in (1 if reduced else 3):
		var h := heart(parent, pos + Vector3((i - 1) * 0.18, 0, 0))
		h.scale = Vector3.ONE * 0.01
		var tw := h.create_tween()
		tw.tween_interval(i * 0.25)
		tw.tween_property(h, "scale", Vector3.ONE, 0.25)
		tw.parallel().tween_property(h, "position:y", pos.y + (0.15 if reduced else 0.7), 1.6)
		tw.tween_property(h, "scale", Vector3.ONE * 0.01, 0.3)
		tw.tween_callback(h.queue_free)


## A small rosy heart, about 0.18 m across, standing upright.
static func heart(parent: Node3D, pos: Vector3) -> Node3D:
	var h := Node3D.new()
	h.name = "Heart"
	h.position = pos
	parent.add_child(h)
	for side: float in [-1.0, 1.0]:
		MeshKit.sphere(h, 0.05, Vector3(side * 0.042, 0.03, 0), "flower_pink", Vector3(1, 1, 0.5), 8, 4)
	var tip := MeshKit.cone(h, 0.075, 0.1, Vector3(0, -0.035, 0), "flower_pink", 8)
	tip.rotation.x = PI
	tip.scale = Vector3(1, 1, 0.5)
	for mi in h.find_children("*", "GeometryInstance3D", true, false):
		(mi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	h.set_script(_FaceCamera)
	return h


static func tr_line(text: String) -> String:
	return TranslationServer.translate(text)


static func _marker_height(w: Wanderer) -> float:
	if w.model is FarmAnimal:
		return {"cow": 1.9, "horse": 2.2, "sheep": 1.3, "lamb": 1.0, "pig": 1.0, "dog": 0.9}.get((w.model as FarmAnimal).kind, 1.2)
	return 0.9


## Keeps a heart turned toward the camera.
const _FaceCamera := preload("res://scripts/world/face_camera.gd")
