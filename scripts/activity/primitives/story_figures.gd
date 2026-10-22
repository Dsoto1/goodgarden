extends ActivityStep
## Story manipulation/retelling primitive, used for Atrium Scripture materials
## and later for any told story (letters, local legends, history).
##
## Reflection by design: no correctness checks, no timers, no score. The
## narration moves the figures the way a guide would; the child may move them
## at any time, lay figures down or stand them up with a tap, hear any part
## again, sit with the wondering questions, and retell freely.
##
## Config:
##   places: [{"label", "pos": [x,y], "kind": "city"|"inn"|"field"|"house"|"fold"|"hills"|"sea"|"hillside"|"pasture"}]  fixed scenery
##   road: [[x,y], ...]                 path drawn on the felt
##   figures: [{"id", "label", "color", "shape"?, "accent"?, "kind"?}]  kind: shared by look-alike figures
##   box: [x, y, w, h]                  material box where figures rest
##   segments: [{"text", "reveal": [ids], "hide": [ids], "show": {id: {"pos": [x,y], "lying": bool}}}]
##                                      "hide" returns a figure to the box (the seed
##                                      gives way to the grown plant)
##   wonderings: [String]               open questions; never answered or checked
##   reference: String                  e.g. "Luke 10:25-37"
## Result: {"retell_seconds": int}

enum Phase { STORY, WONDER, RETELL }

var figures: Dictionary = {} # id -> DragPiece
var _segment := -1
var _wonder := 0
var _phase := Phase.STORY
var _retell_start := 0
var _retell_part := 0


func supports_reset() -> bool:
	return false


func supports_hint() -> bool:
	return false


func _build() -> void:
	var box := _box_rect()
	var defs: Array = config.get("figures", [])
	for i in defs.size():
		var f: Dictionary = defs[i]
		var data := {"label": tr(str(f.get("label", ""))), "color": f.get("color", "cloth_cream")}
		if f.has("shape"):
			data["shape"] = f["shape"]
		if f.has("accent"):
			data["accent"] = f["accent"]
		# Figures that look alike (a flock's sheep) may share a kind, so any of
		# them fits any of their places in the box.
		var p := DragPiece.create("figure:%s" % f.get("kind", f["id"]), match_size(), data)
		p.home = box.position + Vector2((i + 0.5) * box.size.x / defs.size(), box.size.y / 2.0) - p.size / 2.0
		p.position = p.home
		p.visible = false
		p.tapped.connect(func(piece: DragPiece) -> void: piece.set_lying(not piece.lying))
		p.dropped.connect(func(_piece: DragPiece) -> void: AudioService.play("place"))
		add_child(p)
		figures[f["id"]] = p
	_next_segment()


static func match_size() -> Vector2:
	return Vector2(56, 96)


func handoff() -> Array[DragPiece]:
	var out: Array[DragPiece] = []
	for id: String in figures:
		var p: DragPiece = figures[id]
		p.visible = true
		out.append(p)
	return out


func _segments() -> Array:
	return config.get("segments", [])


func _next_segment() -> void:
	_segment += 1
	if _segment >= _segments().size():
		_begin_wondering()
		return
	var seg: Dictionary = _segments()[_segment]
	for id: String in seg.get("reveal", []):
		if figures.has(id):
			figures[id].visible = true
	for id: String in seg.get("hide", []):
		if figures.has(id):
			var gone: DragPiece = figures[id]
			tween_to(gone, gone.home, 0.6)
			gone.set_lying(false)
	var show: Dictionary = seg.get("show", {})
	for id: String in show:
		if figures.has(id):
			var p: DragPiece = figures[id]
			var spot: Dictionary = show[id]
			tween_to(p, vec(spot.get("pos")) - p.size / 2.0, 0.9)
			p.set_lying(bool(spot.get("lying", false)))
	_tell(str(seg.get("text", "")))
	var last := _segment == _segments().size() - 1
	actions_changed.emit([
		{"label": tr("Hear again"), "icon": "speaker", "callback": func() -> void: _tell(str(seg.get("text", "")), true)},
		{"label": tr("Continue") if not last else tr("Wonder"), "icon": "next" if not last else "wonder", "callback": _next_segment, "primary": true},
	])


func _tell(text: String, force := false) -> void:
	var t := tr(text)
	prompt_changed.emit(t)
	AudioService.narrate(t, force)


func _begin_wondering() -> void:
	_phase = Phase.WONDER
	_wonder = 0
	_show_wondering()


func _show_wondering() -> void:
	var wonderings: Array = config.get("wonderings", [])
	if _wonder >= wonderings.size():
		_begin_retell()
		return
	_tell(str(wonderings[_wonder]))
	actions_changed.emit([
		{"label": tr("Hear again"), "icon": "speaker", "callback": func() -> void: _tell(str(wonderings[_wonder]), true)},
		{"label": tr("Wonder some more") if _wonder < wonderings.size() - 1 else tr("Tell it myself"), "icon": "wonder" if _wonder < wonderings.size() - 1 else "talk", "callback": func() -> void:
			_wonder += 1
			_show_wondering(), "primary": true},
	])


func _begin_retell() -> void:
	_phase = Phase.RETELL
	_retell_start = Time.get_ticks_msec()
	_retell_part = 0
	for id: String in figures:
		figures[id].visible = true
	say("retell", "Now the story pieces are yours. Move them and tell the story your way. You can hear any part again.")
	_retell_actions()


func _retell_actions() -> void:
	var segs := _segments()
	actions_changed.emit([
		# Stepping back or on reads that part aloud, so the parts can be found by ear.
		{"label": tr("Back"), "icon": "back", "callback": func() -> void:
			_retell_part = posmod(_retell_part - 1, segs.size())
			_tell(str(segs[_retell_part].get("text", "")), true)
			_retell_actions()},
		{"label": tr("Hear part %d") % (_retell_part + 1), "icon": "speaker", "callback": func() -> void: _tell(str(segs[_retell_part].get("text", "")), true)},
		{"label": tr("Next part"), "icon": "next", "callback": func() -> void:
			_retell_part = (_retell_part + 1) % segs.size()
			_tell(str(segs[_retell_part].get("text", "")), true)
			_retell_actions()},
		{"label": tr("Put the story away"), "icon": "box", "callback": put_away, "primary": true},
	])


## Ends the work with the material. Available at any time from the workspace.
func put_away() -> void:
	var seconds := 0
	if _phase == Phase.RETELL:
		seconds = int((Time.get_ticks_msec() - _retell_start) / 1000.0)
		observed.emit("retold", {"seconds": seconds})
	actions_changed.emit([])
	finish({"retell_seconds": seconds})


func _box_rect() -> Rect2:
	var b: Array = config.get("box", [220, 380, 560, 150])
	return Rect2(b[0], b[1], b[2], b[3])


func _draw() -> void:
	var road: Array = config.get("road", [])
	if road.size() > 1:
		var pts := PackedVector2Array()
		for p: Array in road:
			pts.append(Vector2(p[0], p[1]))
		draw_polyline(pts, Color("c9b38a"), 34.0, true)
		draw_polyline(pts, Color("dcc9a2"), 26.0, true)
	for place: Dictionary in config.get("places", []):
		var c := vec(place.get("pos"))
		match place.get("kind", "city"):
			"city":
				draw_rect(Rect2(c - Vector2(46, 26), Vector2(92, 52)), Color("e8dcc4"))
				for x: float in [-46.0, 30.0]:
					draw_rect(Rect2(c + Vector2(x, -44), Vector2(16, 70)), Color("d8c9ab"))
				draw_rect(Rect2(c + Vector2(-10, 4), Vector2(20, 22)), Color("8d6b4a"))
			"inn", "house":
				draw_rect(Rect2(c - Vector2(40, 18), Vector2(80, 50)), Color("e8dcc4"))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-50, -16), c + Vector2(0, -52), c + Vector2(50, -16)]), Color("b8584a"))
				draw_rect(Rect2(c + Vector2(-9, 8), Vector2(18, 24)), Color("8d6b4a"))
			"field":
				# A ploughed field: brown earth with furrows.
				draw_rect(Rect2(c - Vector2(110, 44), Vector2(220, 88)), Color("8a6446"))
				for k in 5:
					var y := c.y - 34 + k * 17
					draw_line(Vector2(c.x - 104, y), Vector2(c.x + 104, y), Color("6f4e35"), 3.0)
			"fold":
				# A sheepfold: a ring of low stone wall with a gap for the gate.
				for k in 20:
					var a := TAU * k / 20.0
					if k == 5:
						continue
					draw_circle(c + Vector2(cos(a) * 62, sin(a) * 38), 9.0, Color("c9bfae"))
			"sea":
				# A lake with gentle waves, and a sandy shore along its edge.
				var water := PackedVector2Array()
				for k in 25:
					var t := k / 24.0
					water.append(Vector2(c.x - 260 + t * 510, c.y + 32 + sin(t * TAU * 2.0) * 6))
				for k in 25:
					var t := 1.0 - k / 24.0
					water.append(Vector2(c.x - 260 + t * 510, c.y - 66 - sin(t * PI) * 10 + sin(t * TAU * 3.0) * 3))
				draw_rect(Rect2(c.x - 266, c.y + 20, 522, 30), Color("e2cf9e"))
				draw_colored_polygon(water, Color("6f9fc0"))
				for p: Vector2 in [Vector2(-200, -30), Vector2(-120, 6), Vector2(40, -45), Vector2(-20, 12), Vector2(220, -40)]:
					draw_arc(c + p, 14.0, PI * 1.15, PI * 1.85, 8, Color("a9c8dc"), 2.0)
			"hillside":
				# A green hillside with plenty of grass, and the sea beyond it.
				var sea := PackedVector2Array()
				for k in 20:
					var a := TAU * k / 20.0
					sea.append(c + Vector2(150 + cos(a) * 120, -40 + sin(a) * 34))
				draw_colored_polygon(sea, Color("6f9fc0"))
				for p: Vector2 in [Vector2(110, -55), Vector2(200, -50)]:
					draw_arc(c + p, 12.0, PI * 1.15, PI * 1.85, 8, Color("a9c8dc"), 2.0)
				var hill := PackedVector2Array()
				for k in 25:
					var t := k / 24.0
					hill.append(Vector2(c.x - 250 + t * 500, c.y + 60 - sin(t * PI) * 120 + sin(t * TAU * 2.5) * 5))
				draw_colored_polygon(hill, Color("8db562"))
				for p: Vector2 in [Vector2(-190, 40), Vector2(-120, 5), Vector2(-60, -25), Vector2(50, -20), Vector2(130, 10), Vector2(200, 42), Vector2(-20, 30), Vector2(90, 40)]:
					for k in 3:
						draw_line(c + p + Vector2(k * 4 - 4, 0), c + p + Vector2(k * 5 - 5, -9), Color("5f8a3f"), 2.0)
			"pasture":
				# Green pasture with a pool of fresh water at one side.
				var meadow := PackedVector2Array()
				for k in 24:
					var a := TAU * k / 24.0
					meadow.append(c + Vector2(cos(a) * (130 + sin(a * 3.0) * 6), sin(a) * 62))
				draw_colored_polygon(meadow, Color("8db562"))
				var pool := PackedVector2Array()
				for k in 16:
					var a := TAU * k / 16.0
					pool.append(c + Vector2(95 + cos(a) * 30, -32 + sin(a) * 13))
				draw_colored_polygon(pool, Color("6f9fc0"))
				for p: Vector2 in [Vector2(-100, 30), Vector2(-60, -30), Vector2(20, 40), Vector2(60, -20), Vector2(-20, 5), Vector2(100, 25)]:
					for k in 3:
						draw_line(c + p + Vector2(k * 4 - 4, 0), c + p + Vector2(k * 5 - 5, -8), Color("5f8a3f"), 2.0)
			"hills":
				# The wilderness: rocky hills with a few thorny shrubs.
				draw_colored_polygon(PackedVector2Array([c + Vector2(-110, 40), c + Vector2(-50, -40), c + Vector2(0, 10), c + Vector2(50, -55), c + Vector2(120, 40)]), Color("a89a7c"))
				for p: Vector2 in [Vector2(-70, 28), Vector2(30, 26), Vector2(80, 30)]:
					draw_circle(c + p, 10.0, Color("7f8a55"))
		var label_y := 70.0 if place.get("kind", "") in ["field", "fold", "hills", "hillside", "pasture"] else 54.0
		if place.get("kind", "") == "sea":
			label_y = -48.0
		elif place.get("kind", "") == "hillside":
			label_y = -82.0
		draw_string(UiStyle.font(), c + Vector2(-80, label_y), tr(str(place.get("label", ""))), HORIZONTAL_ALIGNMENT_CENTER, 160, 18, Color("f6f1e4"))
	var box := _box_rect()
	BoardArt.wood_box(self, box)
	if not str(config.get("reference", "")).is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(box.position.x, box.end.y + 26), str(config["reference"]), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 16, Color("f6f1e4", 0.8))
