extends SceneTree
func _init() -> void:
	var names := ["wilderness", "farmlands", "lake", "coast", "monastery", "mountains", "bellhaven"]
	var t0 := Time.get_ticks_msec()
	for ri in Terrain.ROADS.size():
		var road: Array = Terrain.ROADS[ri]
		var maxslope := 0.0
		var maxside := 0.0
		var prev := INF
		var where := Vector2()
		for i in road.size() - 1:
			var a: Vector2 = road[i]
			var b: Vector2 = road[i + 1]
			var n := int(ceil(a.distance_to(b)))
			var dir := (b - a).normalized()
			var side := Vector2(-dir.y, dir.x)
			for k in n:
				var p := a.lerp(b, float(k) / n)
				var h := Terrain.height(p.x, p.y)
				if prev != INF:
					var sl := absf(h - prev) / a.distance_to(b) * n
					if sl > maxslope:
						maxslope = sl; where = p
				prev = h
				var hs := absf(Terrain.height(p.x + side.x * 2.5, p.y + side.y * 2.5) - Terrain.height(p.x - side.x * 2.5, p.y - side.y * 2.5)) / 5.0
				maxside = maxf(maxside, hs)
		print("%s maxslope %.2f at %s maxside %.2f" % [names[ri], maxslope, where, maxside])
	print("ms ", Time.get_ticks_msec() - t0)
	for r: Dictionary in Terrain._roads(): print("grade ", r["grade"])
	t0 = Time.get_ticks_msec()
	Terrain.build_mesh()
	print("mesh ms ", Time.get_ticks_msec() - t0)
	quit()
