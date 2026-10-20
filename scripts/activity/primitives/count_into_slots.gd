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
##   slots: int              number of places, or
##   slots_from: step id     reuse "count"/"positions" from an earlier step
##   piece: kind             piece kind (default "bean_seed")
##   spare: int              extra pieces in the supply (default 2)
##   show_dimples: bool      default true; false for children ready for less support
## Result: {"slots": int, "per_slot": int, "pieces": int}

var holes: Array[DropSlot] = []
var pieces: Array[DragPiece] = []
var _per_slot := 3
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
		var n := int(config.get("slots", 4))
		for i in n:
			positions.append((i + 1.0) / (n + 1.0))
	for f: Variant in positions:
		var hole := DropSlot.create("hole", Vector2(70, 70))
		hole.capacity = _per_slot
		hole.show_outline = false
		hole.set_center(Vector2(lerpf(_from, _to, float(f)), _row_y))
		add_child(hole)
		holes.append(hole)
	var total := holes.size() * _per_slot + int(config.get("spare", 2))
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
		if h.contents.size() < _per_slot:
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
		say("full", "That hole already has its seeds. Each hole gets %d." % _per_slot)
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
			var spot := h.center() + _dimple(i)
			tween_to(h.contents[i], spot - h.contents[i].size / 2.0, 0.15)


func _dimple(i: int) -> Vector2:
	if _per_slot == 1:
		return Vector2.ZERO
	var a := -PI / 2.0 + TAU * i / _per_slot
	return Vector2(cos(a), sin(a)) * 17.0


func _check() -> void:
	for h in holes:
		if h.contents.size() != _per_slot:
			return
	for p in pieces:
		p.draggable = false
	say("all_good", "Every hole has %d seeds." % _per_slot)
	AudioService.play("step")
	var used := holes.size() * _per_slot
	finish({"slots": holes.size(), "per_slot": _per_slot, "pieces": used})


func _draw() -> void:
	draw_rect(Rect2(_from, _row_y - 40, _to - _from, 80), Color("6b4630"))
	for h in holes:
		var c := h.center()
		draw_circle(c, 33, Color("4a2f20"))
		if config.get("show_dimples", true):
			for i in _per_slot:
				var filled := i < h.contents.size()
				draw_arc(c + _dimple(i), 9, 0, TAU, 14, Color("f3e6d2", 0.25 if filled else 0.7), 2.0)
		if h == _hint_slot:
			draw_arc(c, 42, 0, TAU, 32, Color(1, 0.95, 0.7), 4.0)
	# Seed bowl.
	draw_circle(_bowl + Vector2(0, 8), 78, Color("8a6a4a"))
	draw_circle(_bowl, 74, Color("c49a6c"))
	draw_circle(_bowl, 62, Color("a8774f"))
	draw_string(ThemeDB.fallback_font, _bowl + Vector2(-100, 100), tr("seed bowl"), HORIZONTAL_ALIGNMENT_CENTER, 200, 18, Color("f3e6d2"))
