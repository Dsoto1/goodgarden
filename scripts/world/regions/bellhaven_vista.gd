extends Region
## Bellhaven, seen far across the valley: a promise of the wider world. Not
## yet reachable; drawn with soft, distant colours. When Bellhaven becomes a
## playable region it replaces this vista with its own streamed scene.


func build() -> void:
	MeshKit.sphere(self, 70.0, Vector3(0, -28, 0), "distant_dark", Vector3(1.4, 0.55, 0.8), 14, 6)
	MeshKit.cylinder(self, 24.0, 24.0, 6.0, Vector3(0, 11, 0), "distant", 16)
	for i in 8:
		var a := TAU * i / 8.0
		var p := Vector3(cos(a) * 24.0, 0, sin(a) * 24.0)
		MeshKit.cylinder(self, 2.2, 2.4, 11.0, p + Vector3(0, 13, 0), "distant", 8)
		MeshKit.cone(self, 3.0, 4.0, p + Vector3(0, 20.5, 0), "distant_dark", 8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 26:
		var p := Vector3(rng.randf_range(-18, 18), 0, rng.randf_range(-14, 14))
		var h := rng.randf_range(4, 9)
		MeshKit.box(self, Vector3(rng.randf_range(3, 5), h, rng.randf_range(3, 5)), p + Vector3(0, 12 + h / 2.0, 0), "distant")
		MeshKit.roof(self, 4.6, 2.4, 4.6, p + Vector3(0, 13.2 + h, 0), "distant_dark")
	# The great church, larger than the village chapel but not replacing it.
	MeshKit.box(self, Vector3(9, 14, 18), Vector3(0, 19, -2), "distant")
	MeshKit.roof(self, 10, 5, 19, Vector3(0, 28.5, -2), "distant_dark")
	MeshKit.cylinder(self, 2.6, 3.0, 22.0, Vector3(0, 28, 9), "distant", 8)
	MeshKit.cone(self, 3.4, 12.0, Vector3(0, 45, 9), "distant_dark", 8)
	for m in get_children():
		if m is GeometryInstance3D:
			(m as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
