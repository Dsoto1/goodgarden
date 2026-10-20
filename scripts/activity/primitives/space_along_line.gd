extends ActivityStep
## Measure/compare primitive: place markers along a line at a regular spacing,
## using a measuring stick. Used for seed holes; the same step can space fence
## posts, tiles, or map distances.
##
## Control of error: once every marker is down, a ghost of the stick is laid
## into each gap. A gap that is too short shows the stick overlapping the next
## marker; too long shows bare ground left over. Nothing is marked "wrong".
##
## Config:
##   markers: int            number of markers to place (default 4)
##   stick_length: float     spacing, in board units (default 170)
##   tolerance: float        how close counts as "one stick" (default 20)
##   row_y, row_from, row_to row line on the board (defaults fit a garden bed)
##   feedback: {"crowded", "far", "all_good", "placed_all"} optional text overrides
## Result: {"count": int, "positions": Array[float] (0..1 along the row)}

var markers: Array[DragPiece] = []
var stick: DragPiece
var _row_y := 300.0
var _from := 80.0
var _to := 940.0
var _start_x := 110.0
var _length := 170.0
var _tolerance := 20.0
var _gap_state: Array[int] = [] # per gap: -1 crowded, 0 good, 1 far
var _checking := false
var _hint_ghost := -1.0
var _tray := Vector2(140, 470)


func _build() -> void:
	_row_y = float(config.get("row_y", 300.0))
	_from = float(config.get("row_from", 80.0))
	_to = float(config.get("row_to", 940.0))
	_length = float(config.get("stick_length", 170.0))
	_tolerance = float(config.get("tolerance", 20.0))
	_start_x = _from + 30.0
	var count := int(config.get("markers", 4))
	for i in count:
		var m := DragPiece.create("marker_peg", Vector2(34, 74))
		m.home = _tray + Vector2(i * 46, 0) - m.size / 2.0
		m.position = m.home
		m.dropped.connect(_on_marker_dropped)
		m.grabbed.connect(func(_p: DragPiece) -> void: _hint_ghost = -1.0)
		add_child(m)
		markers.append(m)
	stick = DragPiece.create("spacing_stick", Vector2(_length, 30))
	stick.home = Vector2(BOARD_SIZE.x - _length - 60, 450)
	stick.position = stick.home
	stick.dropped.connect(_on_stick_dropped)
	add_child(stick)
	queue_redraw()


func reset_step() -> void:
	_checking = false
	_gap_state.clear()
	for m in markers:
		m.placed_in = null
		tween_to(m, m.home)
	tween_to(stick, stick.home)
	prompt_changed.emit(tr(str(config.get("prompt", ""))))
	queue_redraw()


func show_hint() -> void:
	super.show_hint()
	# Lay the stick from the last good point and ghost the next marker spot.
	var anchor := _start_x
	for x in _placed_sorted():
		if absf(x - (anchor + _length)) <= _tolerance:
			anchor = x
		else:
			break
	_hint_ghost = anchor + _length
	stick.set_center(Vector2(anchor + _length / 2.0, _row_y - 52))
	queue_redraw()


func required_positions() -> Array[float]:
	var out: Array[float] = []
	for i in markers.size():
		out.append(_start_x + _length * (i + 1))
	return out


func _on_marker_dropped(m: DragPiece) -> void:
	var c := m.center()
	if absf(c.y - _row_y) <= 60.0 + snap_tolerance and c.x > _from and c.x < _to:
		m.set_center(Vector2(c.x, _row_y - 18))
		m.placed_in = "row"
		AudioService.play("place")
	else:
		m.placed_in = null
		tween_to(m, m.home)
	_evaluate()


func _on_stick_dropped(s: DragPiece) -> void:
	# Like a real ruler: butt its left end against the nearest marker or the start stone.
	var left := s.position.x
	var best := _start_x
	for x in _placed_sorted():
		if absf(x - left) < absf(best - left):
			best = x
	if absf(best - left) <= _length * 0.5 and absf(s.center().y - _row_y) < 120.0:
		tween_to(s, Vector2(best, _row_y - 67))
		AudioService.play("place")


func _placed_sorted() -> Array[float]:
	var xs: Array[float] = []
	for m in markers:
		if m.placed_in != null:
			xs.append(m.center().x)
	xs.sort()
	return xs


func _evaluate() -> void:
	var xs := _placed_sorted()
	if xs.size() < markers.size():
		_checking = false
		_gap_state.clear()
		queue_redraw()
		return
	if not _checking:
		_checking = true
		say("placed_all", "Now let's check with the stick. Does it fit each space?")
	var previous := _gap_state.duplicate()
	_gap_state.clear()
	var prev_x := _start_x
	for x in xs:
		var gap := x - prev_x
		_gap_state.append(0 if absf(gap - _length) <= _tolerance else (-1 if gap < _length else 1))
		prev_x = x
	for i in _gap_state.size():
		if i < previous.size() and previous[i] != 0 and _gap_state[i] == 0:
			observed.emit("self_correction", {"step": config.get("id", ""), "gap": i})
	queue_redraw()
	if not _gap_state.has(-1) and not _gap_state.has(1):
		_complete(xs)
	elif _gap_state.has(-1):
		say("crowded", "Look where the stick lies over a peg. Those beans would be crowded.")
	else:
		say("far", "Look where there is bare ground past the stick. Can that peg move closer?")


func _complete(xs: Array[float]) -> void:
	# Tidy the pegs onto the exact stick lengths the child measured.
	var exact := required_positions()
	var sorted := markers.duplicate()
	sorted.sort_custom(func(a: DragPiece, b: DragPiece) -> bool: return a.center().x < b.center().x)
	for i in sorted.size():
		tween_to(sorted[i], Vector2(exact[i], _row_y - 18) - sorted[i].size / 2.0)
		sorted[i].draggable = false
	stick.draggable = false
	say("all_good", "Every space is one stick long. The beans will have room to grow.")
	AudioService.play("step")
	var positions: Array[float] = []
	for x in exact:
		positions.append(snappedf((x - _from) / (_to - _from), 0.001))
	finish({"count": markers.size(), "positions": positions})


func _draw() -> void:
	# Soil row and start stone.
	draw_rect(Rect2(_from, _row_y - 34, _to - _from, 68), Color("6b4630"))
	for i in 40:
		draw_circle(Vector2(_from + 12 + i * 21.5, _row_y + ((i * 37) % 50) - 25), 3, Color("5a3a27"))
	draw_circle(Vector2(_start_x, _row_y), 20, Color("b7aea0"))
	draw_circle(Vector2(_start_x - 5, _row_y - 5), 8, Color("cfc7ba"))
	draw_string(ThemeDB.fallback_font, Vector2(_start_x - 60, _row_y - 44), tr("start"), HORIZONTAL_ALIGNMENT_CENTER, 120, 18, Color("f3e6d2"))
	draw_string(ThemeDB.fallback_font, Vector2(_tray.x - 40, _tray.y + 62), tr("pegs"), HORIZONTAL_ALIGNMENT_LEFT, 200, 18, Color("f3e6d2"))
	if _hint_ghost > 0.0:
		draw_dashed_line(Vector2(_hint_ghost, _row_y - 50), Vector2(_hint_ghost, _row_y + 30), Color(1, 0.95, 0.7), 4.0, 8.0)
	if not _checking:
		return
	var prev_x := _start_x
	var xs := _placed_sorted()
	for i in xs.size():
		var y := _row_y + 44.0
		var r := Rect2(prev_x, y - 9, _length, 18)
		draw_rect(r, Color(0.84, 0.68, 0.48, 0.85))
		draw_line(Vector2(prev_x, y - 12), Vector2(prev_x, y + 12), PieceArt.INK, 2.0)
		draw_line(Vector2(prev_x + _length, y - 12), Vector2(prev_x + _length, y + 12), PieceArt.INK, 2.0)
		var gap := xs[i] - prev_x
		if _gap_state[i] == -1:
			# Overlap: stick runs past the peg. Hatched so it reads without colour.
			_hatch(Rect2(xs[i], y - 9, prev_x + _length - xs[i], 18))
		elif _gap_state[i] == 1:
			_hatch(Rect2(prev_x + _length, y - 9, gap - _length, 18))
		else:
			draw_circle(Vector2(prev_x + _length / 2.0, y), 6, Color("8ccf5a"))
		prev_x = xs[i]


func _hatch(r: Rect2) -> void:
	draw_rect(r, Color(1, 0.95, 0.8, 0.35))
	var x := r.position.x
	while x < r.end.x:
		draw_line(Vector2(x, r.end.y), Vector2(minf(x + 10, r.end.x), r.position.y), Color("3b3430"), 2.0)
		x += 8.0
