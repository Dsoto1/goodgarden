extends ActivityStep
## Sort primitive: a mixed pile is sorted into bins by kind (grain from chaff,
## shells from stones, red from blue).
##
## Control of error: a piece dropped into the wrong bin gently shakes and goes
## back to the pile. Placing it right afterwards is recorded as a
## self-correction. Nothing is marked wrong.
##
## Config:
##   pieces: [{"kind": "grain", "count": 8}, ...]   the mixed pile
##   bins: [{"kind": "grain", "label": "flour sack", "look": "sack"|"basket", "pos": [x, y]}]
##   pile: [x, y]                                     centre of the pile
## Feedback keys: "mismatch", "all_good".
## Result: {"sorted": int}

const BIN_SIZE := Vector2(210, 150)
const PIECE_SIZE := Vector2(30, 24)

var bins: Array[DropSlot] = []
var pieces: Array[DragPiece] = []
var _pile := Vector2(500, 440)
var _rejected := {}
var _hint_piece: DragPiece


func _build() -> void:
	_pile = vec(config.get("pile"), _pile)
	for b: Dictionary in config.get("bins", []):
		var slot := DropSlot.create(str(b["kind"]), BIN_SIZE, {"label": tr(str(b.get("label", ""))), "look": str(b.get("look", "basket"))})
		slot.capacity = 999
		slot.show_outline = false
		slot.set_center(vec(b.get("pos")))
		add_child(slot)
		bins.append(slot)
	var kinds: Array[String] = []
	for spec: Dictionary in config.get("pieces", []):
		for i in int(spec.get("count", 1)):
			kinds.append(str(spec["kind"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(config.get("id", "sort")))
	for i in range(kinds.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := kinds[i]
		kinds[i] = kinds[j]
		kinds[j] = t
	for i in kinds.size():
		var p := DragPiece.create(kinds[i], PIECE_SIZE)
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf())
		p.home = _pile + Vector2(cos(a) * 170.0 * r, sin(a) * 50.0 * r) - p.size / 2.0
		p.position = p.home
		p.rotation = rng.randf_range(-0.6, 0.6)
		p.dropped.connect(_on_dropped)
		p.grabbed.connect(_on_grabbed)
		add_child(p)
		pieces.append(p)
	queue_redraw()


func reset_step() -> void:
	for b in bins:
		b.contents.clear()
	for p in pieces:
		p.placed_in = null
		tween_to(p, p.home)
	_rejected.clear()
	prompt_changed.emit(tr(str(config.get("prompt", ""))))
	queue_redraw()


func show_hint() -> void:
	super.show_hint()
	for p in pieces:
		if p.placed_in == null:
			_hint_piece = p
			break
	queue_redraw()


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		var bin: DropSlot = p.placed_in
		bin.take(p)
		_layout(bin)


func _on_dropped(p: DragPiece) -> void:
	var target: DropSlot = null
	for b in bins:
		if b.near(p.center(), snap_tolerance * 0.5):
			target = b
			break
	if target == null:
		return # set down on the table: fine, it can be picked up again
	if not target.fits(p):
		_rejected[p] = true
		observed.emit("mismatch", {"step": config.get("id", ""), "piece": p.kind, "slot": target.accepts})
		say("mismatch", "That one goes somewhere else.")
		reject(p, p.home)
		return
	if _rejected.has(p):
		_rejected.erase(p)
		observed.emit("self_correction", {"step": config.get("id", ""), "piece": p.kind})
	target.put(p)
	AudioService.play("place")
	if p == _hint_piece:
		_hint_piece = null
	_layout(target)
	queue_redraw()
	_check()


## Lays the pieces in a bin out in tidy rows.
func _layout(bin: Variant) -> void:
	if not bin is DropSlot:
		return
	var b: DropSlot = bin
	for i in b.contents.size():
		var spot := b.center() + Vector2((i % 6 - 2.5) * 30.0, -26.0 + (i / 6) * 26.0)
		b.contents[i].rotation = 0.0
		tween_to(b.contents[i], spot - b.contents[i].size / 2.0, 0.15)


func _check() -> void:
	for p in pieces:
		if p.placed_in == null:
			return
	for p in pieces:
		p.draggable = false
	say("all_good", "Everything is sorted.")
	AudioService.play("step")
	finish({"sorted": pieces.size()})


func _draw() -> void:
	var font := UiStyle.font()
	# The cloth the mixed pile lies on.
	var cloth := PackedVector2Array()
	for k in 24:
		var a := TAU * k / 24.0
		cloth.append(_pile + Vector2(cos(a) * 205, sin(a) * 72))
	draw_colored_polygon(BoardArt._shadow(cloth, 5), Color(0, 0, 0, 0.12))
	draw_colored_polygon(cloth, Color("d9c7a3"))
	draw_polyline(cloth + PackedVector2Array([cloth[0]]), Color("b9a07a"), 2.0, true)
	for b in bins:
		var r := Rect2(b.position, b.size)
		if b.data.get("look", "basket") == "sack":
			BoardArt.sack(self, r)
		else:
			BoardArt.basket(self, r)
		draw_string(font, Vector2(r.position.x - 20, r.end.y + 24), str(b.data.get("label", "")), HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 40, 18, Color("f3e6d2"))
		# The outline of what belongs here, stitched on the front.
		PieceArt.draw_at(self, b.accepts, Rect2(Vector2(r.end.x - 52, r.end.y - 40), Vector2(36, 28)), true)
	if _hint_piece and _hint_piece.placed_in == null:
		draw_arc(_hint_piece.center(), 30, 0, TAU, 24, Color(1, 0.95, 0.7), 4.0)
