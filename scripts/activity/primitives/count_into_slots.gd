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
##   container: how the places look: "hole" (in soil, the default), "plant"
##              (a bean plant growing from its hole), "basket" or "trough"
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
		# Rolls and hay bundles are a little bigger than seeds and drops.
		var p := DragPiece.create(kind, Vector2(40, 30) if _baskets() else Vector2(30, 22))
		p.home = _bowl + _bowl_offset(i) - p.size / 2.0
		p.position = p.home
		p.dropped.connect(_on_dropped)
		p.grabbed.connect(_on_grabbed)
		add_child(p)
		pieces.append(p)
	queue_redraw()


## Baskets and troughs are wide and lined up on a shelf or the ground;
## holes and plants sit in a row of soil.
func _baskets() -> bool:
	return config.get("container", "hole") in ["basket", "trough"]


func _container() -> String:
	return str(config.get("container", "hole"))


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
	# Count along out loud: "one", "two", "three"...
	AudioService.narrate(count_word(target.contents.size()))
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
		return Vector2((i % per_row - (in_row - 1) / 2.0) * 38.0, -6.0 + row * 26.0)
	if n == 1:
		return Vector2.ZERO
	var a := -PI / 2.0 + TAU * i / n
	return Vector2(cos(a), sin(a)) * 17.0


func count_word(n: int) -> String:
	var words := ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"]
	return tr(words[n]) if n < words.size() else str(n)


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
		if _container() == "basket":
			BoardArt._fill(self, BoardArt._round_rect(Rect2(_from - 20, _row_y + 30, _to - _from + 40, 26), 6), Color("8a5a3a"))
		for h in holes:
			var c := h.center()
			if _container() == "trough":
				BoardArt.trough(self, c)
			else:
				_basket(c)
			if config.get("show_dimples", true):
				for i in _count_of(h):
					var filled := i < h.contents.size()
					draw_arc(c + _dimple(i, _count_of(h)), 11, 0, TAU, 14, Color("f3e6d2", 0.25 if filled else 0.8), 2.0)
			if config.has("counts"):
				draw_circle(c + Vector2(0, 62), 20, Color("f3e6d2"))
				draw_arc(c + Vector2(0, 62), 20, 0, TAU, 24, Color("8a5a3a"), 2.0)
				draw_string(font, c + Vector2(-20, 72), str(_count_of(h)), HORIZONTAL_ALIGNMENT_CENTER, 40, 28, Color("3b3430"))
			if h == _hint_slot:
				draw_arc(c, 74, 0, TAU, 32, Color(1, 0.95, 0.7), 4.0)
	else:
		BoardArt.soil_row(self, Rect2(_from, _row_y - 40, _to - _from, 80))
		for h in holes:
			var c := h.center()
			if _container() == "plant":
				_bean_plant(c, h.contents.size() >= _count_of(h))
			draw_circle(c, 33, Color("4a2f20"))
			if config.get("show_dimples", true):
				for i in _count_of(h):
					var filled := i < h.contents.size()
					draw_arc(c + _dimple(i, _count_of(h)), 9, 0, TAU, 14, Color("f3e6d2", 0.25 if filled else 0.7), 2.0)
			if h == _hint_slot:
				draw_arc(c, 42, 0, TAU, 32, Color(1, 0.95, 0.7), 4.0)
	# The supply: a bowl of seeds, or a cloth-lined bread tray.
	BoardArt.bowl(self, _bowl, 74, Color(str(config.get("supply_color", "f3e6d2" if _baskets() else "a8774f"))))
	draw_string(font, _bowl + Vector2(-100, 100), tr(str(config.get("supply_label", "seed bowl"))), HORIZONTAL_ALIGNMENT_CENTER, 200, 18, Color("f3e6d2"))


## A bean plant rising from its hole; it perks up once it has had its water.
func _bean_plant(c: Vector2, watered: bool) -> void:
	var lean := 0.0 if watered else 14.0
	var top := c + Vector2(lean, -120)
	draw_line(c + Vector2(0, -20), top, Color("5f8a3f"), 5.0)
	for k in 3:
		var at := c.lerp(top, 0.4 + k * 0.25) + Vector2(0, -10)
		for side: float in [-1.0, 1.0]:
			var leaf := PackedVector2Array()
			for i in 9:
				var a := TAU * i / 9.0
				leaf.append(at + Vector2(side * 18 + cos(a) * 16, sin(a) * 8 + (0.0 if watered else 6.0)))
			draw_colored_polygon(leaf, Color("7fb04a") if watered else Color("9fae6a"))


func _basket(c: Vector2) -> void:
	# A woven bread basket with a handle arching over it.
	draw_arc(c + Vector2(3, -14), 54, PI, TAU, 24, Color(0, 0, 0, 0.12), 6.0)
	draw_arc(c + Vector2(0, -16), 54, PI, TAU, 24, Color("8a5a3a"), 7.0)
	draw_arc(c + Vector2(0, -18), 54, PI * 1.1, PI * 1.5, 12, Color("b8875e"), 2.0)
	BoardArt.basket(self, Rect2(c + Vector2(-66, -28), Vector2(132, 76)))