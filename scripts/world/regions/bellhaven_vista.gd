extends Region
## Bellhaven, seen far across the valley: a promise of the wider world. Not
## yet reachable; distance fog softens it. When Bellhaven becomes a
## playable region it replaces this vista with its own streamed scene.


func build() -> void:
	MeshKit.sphere(self, 70.0, Vector3(0, -28, 0), "grass_dark", Vector3(1.4, 0.55, 0.8), 14, 6)
	var top := 10.0
	Props.place(self, "castle_far", Vector3(0, top, -6), 0.0, 1.4)
	Props.place(self, "church_far", Vector3(-16, top, 4), 0.3)
	for t: Array in [[-26, -4], [24, -2], [14, 12], [-12, 14]]:
		Props.place(self, "tower_far", Vector3(t[0], top - 1, t[1]), 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 14:
		var a := TAU * i / 14.0
		Props.place(self, "house_far", Vector3(cos(a) * rng.randf_range(12, 20), top - 0.5, sin(a) * rng.randf_range(8, 14) + 6), rng.randf() * TAU, rng.randf_range(0.8, 1.1))
	for m in find_children("*", "GeometryInstance3D", true, false):
		(m as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
