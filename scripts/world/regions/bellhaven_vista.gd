extends Region
## Bellhaven, seen far across the valley: a promise of the wider world. Not
## yet reachable; distance fog softens it. When Bellhaven becomes a
## playable region it replaces this vista with its own streamed scene.


## The rise the city sits on: an ellipsoid mound, centre below ground.
const HILL_RADII := Vector3(52, 28, 36)
const HILL_CENTER_Y := -22.0


func build() -> void:
	# The city crowns a rise in the terrain (World places this region at ground height).
	MeshKit.sphere(self, 40.0, Vector3(0, HILL_CENTER_Y, 0), "grass_dark", HILL_RADII / 40.0, 14, 6)
	_on_hill("castle_far", -0.0, -6.0, 0.0, 1.4)
	_on_hill("church_far", -16.0, 6.0, 0.3, 1.1)
	for t: Array in [[-24.0, -3.2], [22.4, -1.6], [12.8, 11.2], [-9.6, 12.8]]:
		_on_hill("tower_far", t[0], t[1], 0.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 14:
		var a := TAU * i / 14.0
		_on_hill("house_far", cos(a) * rng.randf_range(12, 20), sin(a) * rng.randf_range(8, 14) + 6, rng.randf() * TAU, rng.randf_range(0.8, 1.1))
	for m in find_children("*", "GeometryInstance3D", true, false):
		(m as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Places a building on the hill's surface at (x, z), sunk a little so no
## base shows daylight underneath.
func _on_hill(prop: String, x: float, z: float, yaw: float, size: float) -> void:
	Props.place(self, prop, Vector3(x, hill_height(x, z) - 0.6, z), yaw, size)


static func hill_height(x: float, z: float) -> float:
	var t := 1.0 - pow(x / HILL_RADII.x, 2) - pow(z / HILL_RADII.z, 2)
	return HILL_CENTER_Y + HILL_RADII.y * sqrt(maxf(t, 0.0))
