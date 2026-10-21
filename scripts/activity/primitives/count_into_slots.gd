extends ActivityStep
## Count/group primitive: put exactly N pieces into each of several places
## (seeds into holes, apples into baskets, coins into purses).
##
## Control of error: each place shows N little dimples. A piece dropped into a
## full place rolls back to the supply, and spare pieces are left over at the
## end, so the child can see when something went astray.
##
## Config:
##   per_slot: int           pieces each place needs (default 3)
##   counts: [int]           or a different number for each place, shown as a
##                           numeral on it (reading numbers in a real job)
##   slots: int              number of places, or
##   slots_from: step id     reuse "count"/"positions" from an earlier step
##   piece: kind             piece kind (default "bean_seed")
##   container: "hole"|"basket"  how the places look (default "hole", in soil)
##   supply_label: text      name under the supply (default "seed bowl")
##   spare: int              extra pieces in the supply (default 2)
##   show_dimples: bool      default true; false for children ready for less support
## Feedback keys: "full" and "all_good"; "{n}" in them becomes the place's count.
## Result: {"slots": int, "per_slot": int, "pieces": int} (+ "counts" when given)

var holes: Array[DropSlot] = []
var pieces: Array[DragPiece] = []
var _per_slot := 3
var _counts: Array[int] = [] # pieces each place needs, by place
var _row_y := 300.0
var _from := 80.0
var _to := 940.0
var _bowl := Vector2(500, 470)
var _hint_slot: DropSlot
var _rejected := {}


func _build() -> void:
	_per_slot = int(config.get("per_slot", 3))
	var positions: Array = []
	if config.has("slots_from"):
		var prior: Dictionary = context.get(str(config["slots_from"]), {})
		positions = prior.get("positions", [])
	if positions.is_empty():
		var n := int(config.get("slots", config.get("counts", []).size() if config.has("counts") else 4))
		for i in n:
			positions.append((i + 1.0) / (n + 1.0))
	for i in positions.size():
		var given: Array = config.get("counts", [])
		_counts.append(int(given[i]) if i < given.size() else _per_slot)
	for i in positions.size():
		var f: float = positions[i]
		var hole := DropSlot.create("hole", Vector2(70, 70) if not _baskets() else Vector2(130, 100))
		hole.capacity = _counts[i]
		hole.show_outline = false
		hole.set_center(Vector2(lerpf(_from, _to, float(f)), _row_y))
		add_child(hole)
		holes.append(hole)
	var total := _needed() + int(config.get("spare", 2))
	var kind := str(config.get("piece", "bean_seed"))
	for i in total:
		var p := DragPiece.create(kind, Vector2(30, 22))
		p.home = _bowl + _bowl_offset(i) - p.size / 2.0
		p.position = p.home
		p.dropped.connect(_on_dropped)
		p.grabbed.connect(_on_grabbed)
		add_child(p)
		pieces.append(p)
	queue_redraw()


func _baskets() -> bool:
	return config.get("container", "hole") == "basket"


func _needed() -> int:
	var n := 0
	for c in _counts:
		n += c
	return n


func _count_of(h: DropSlot) -> int:
	return _counts[holes.find(h)]


func _bowl_offset(i: int) -> Vector2:
	var ring := i % 7
	var layer := i / 7
	return Vector2(cos(ring * TAU / 7.0 + layer) * (22 + layer * 18), sin(ring * TAU / 7.0 + layer) * (10 + layer * 6))


func reset_step() -> void:
	for h in holes:
		h.contents.clear()
		h.queue_redraw()
	for p in pieces:
		p.placed_in = null
		tween_to(p, p.home)
	prompt_changed.emit(tr(str(config.get("prompt", ""))))
	queue_redraw()


func show_hint() -> void:
	super.show_hint()
	for h in holes:
		if h.contents.size() < _count_of(h):
			_hint_slot = h
			break
	queue_redraw()


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		(p.placed_in as DropSlot).take(p)
		_layout_hole_contents()
	queue_redraw()


func _on_dropped(p: DragPiece) -> void:
	var target: DropSlot = null
	for h in holes:
		if h.near(p.center(), snap_tolerance * 0.6):
			target = h
			break
	if target == null:
		tween_to(p, p.home)
		return
	if target.is_full():
		# The dimples are all used: the seed rolls back to the bowl.
		_rejected[p] = true
		observed.emit("overfilled", {"step": config.get("id", "")})
		say_count("full", "That hole already has its seeds. Each hole gets {n}.", _count_of(target))
		reject(p, p.home)
		return
	if _rejected.has(p):
		_rejected.erase(p)
		observed.emit("self_correction", {"step": config.get("id", "")})
	target.put(p)
	AudioService.play("place")
	_hint_slot = null
	_layout_hole_contents()
	queue_redraw()
	_check()


func _layout_hole_contents() -> void:
	for h in holes:
		for i in h.contents.size():
			var spot := h.center() + _dimple(i, _count_of(h))
			tween_to(h.contents[i], spot - h.contents[i].size / 2.0, 0.15)


## Where the i-th of n pieces sits in a place: round a small circle, or in
## two rows across a basket.
func _dimple(i: int, n: int) -> Vector2:
	if _baskets():
		var per_row := ceili(n / 2.0)
		var row := i / per_row
		var in_row := mini(per_row, n - row * per_row)
		return Vector2((i % per_row - (in_row - 1) / 2.0) * 30.0, -8.0 + row * 22.0)
	if n == 1:
		return Vector2.ZERO
	var a := -PI / 2.0 + TAU * i / n
	return Vector2(cos(a), sin(a)) * 17.0


func say_count(key: String, fallback: String, n: int) -> void:
	prompt_changed.emit(tr(str(config.get("feedback", {}).get(key, fallback))).replace("{n}", str(n)))


func _check() -> void:
	for h in holes:
		if h.contents.size() != _count_of(h):
			return
	for p in pieces:
		p.draggable = false
	say_count("all_good", "Every hole has {n} seeds.", _per_slot)
	AudioService.play("step")
	var result := {"slots": holes.size(), "per_slot": _per_slot, "pieces": _needed()}
	if config.has("counts"):
		result["counts"] = _counts.duplicate()
	finish(result)


func _draw() -> void:
	var font := UiStyle.font()
	if _baskets():
		# A plain shelf with a woven basket for each household, its number on a tag.
		draw_rect(Rect2(_from - 20, _row_y + 30, _to - _from + 40, 26), Color("8a5a3a"))
		for h in holes:
			var c := h.center()
			_basket(c)
			if config.get("show_dimples", true):
				for i in _count_of(h):
					var filled := i < h.contents.size()
					draw_arc(c + _dimple(i, _count_of(h)), 11, 0, TAU, 14, Color("f3e6d2", 0.25 if filled else 0.8), 2.0)
			draw_circle(c + Vector2(0, 62), 20, Color("f3e6d2"))
			draw_arc(c + Vector2(0, 62), 20, 0, TAU, 24, Color("8a5a3a"), 2.0)
			draw_string(font, c + Vector2(-20, 72), str(_count_of(h)), HORIZONTAL_ALIGNMENT_CENTER, 40, 28, Color("3b3430"))
			if h == _hint_slot:
				draw_arc(c, 74, 0, TAU, 32, Color(1, 0.95, 0.7), 4.0)
	else:
		draw_rect(Rect2(_from, _row_y - 40, _to - _from, 80), Color("6b4630"))
		for h in holes:
			var c := h.center()
			draw_circle(c, 33, Color("4a2f20"))
			if config.get("show_dimples", true):
				for i in _count_of(h):
					var filled := i < h.contents.size()
					draw_arc(c + _dimple(i, _count_of(h)), 9, 0, TAU, 14, Color("f3e6d2", 0.25 if filled else 0.7), 2.0)
			if h == _hint_slot:
				draw_arc(c, 42, 0, TAU, 32, Color(1, 0.95, 0.7), 4.0)
	# The supply: a bowl of seeds, or a cloth-lined bread tray.
	draw_circle(_bowl + Vector2(0, 8), 78, Color("8a6a4a"))
	draw_circle(_bowl, 74, Color("c49a6c"))
	draw_circle(_bowl, 62, Color("f3e6d2") if _baskets() else Color("a8774f"))
	draw_string(font, _bowl + Vector2(-100, 100), tr(str(config.get("supply_label", "seed bowl"))), HORIZONTAL_ALIGNMENT_CENTER, 200, 18, Color("f3e6d2"))


func _basket(c: Vector2) -> void:
	var outer := PackedVector2Array()
	for k in 25:
		var a := PI * k / 24.0
		outer.append(c + Vector2(cos(a) * 62, sin(a) * 46))
	outer.append(c + Vector2(-62, -10))
	outer.append(c + Vector2(62, -10))
	draw_colored_polygon(outer, Color("c8955a"))
	for k in 4:
		var y := c.y + 2 + k * 10
		draw_line(Vector2(c.x - 58 + k * 3, y), Vector2(c.x + 58 - k * 3, y), Color("9c6b3c"), 2.0)
	draw_rect(Rect2(c + Vector2(-66, -16), Vector2(132, 10)), Color("a8743f"))
	draw_arc(c + Vector2(0, -16), 52, PI, TAU, 24, Color("9c6b3c"), 5.0)
