extends SceneTree
func _init() -> void:
	var r: Dictionary = Terrain._roads()[5]
	var bed: PackedFloat32Array = r["bed"]
	var n := bed.size()
	for k in range(n - 30, n):
		var p := Terrain._road_point(r["pts"], r["along"], float(k))
		print(k, " ", p, " lvl ", Terrain._on_level_ground(p), " base %.2f bed %.2f h %.2f" % [Terrain._base_height(p.x, p.y), bed[k], Terrain.height(p.x, p.y)])
	quit()
