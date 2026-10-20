extends ActivityStep
## Sort/match primitive: each piece has one place whose outline it fits, like
## a Montessori placemat, a tool shadow board, or the compartments of a
## Scripture material box.
##
## Control of error: a piece dropped on the wrong outline gently shakes and
## returns. Placing it correctly afterwards is recorded as a self-correction.
##
## Config:
##   slots: [{"kind": "plate", "pos": [x, y], "label": "..."}]  centers in board units
##   pieces_from_previous: bool   reuse pieces handed over by the prior step
##   tray: [x, y, w, h]           where loose pieces start (default bottom strip)
##   mats: [[x, y, w, h], ...]    placemats/cloths drawn under the outlines
##   box:  [x, y, w, h]           a material box drawn under the outlines
## Result: {"placed": int}

const SIZES := {
	"plate": Vector2(96, 96), "bowl_small": Vector2(70, 70), "cup": Vector2(56, 60),
	"fork": Vector2(26, 104), "spoon": Vector2(26, 104), "knife": Vector2(26, 104),
	"napkin": Vector2(56, 84), "coin": Vector2(30, 30), "figure": Vector2(56, 96),
}

var slots: Array[DropSlot] = []
var pieces: Array[DragPiece] = []
var _mismatched := {}


static func size_for(kind: String) -> Vector2:
	return SIZES.get(kind.get_slice(":", 0), Vector2(60, 60))


func _build() -> void:
	for s: Dictionary in config.get("slots", []):
		var kind := str(s.get("kind", ""))
		var data: Dictionary = s.get("data", {})
		var slot := DropSlot.create(kind, size_for(kind), data)
		slot.set_center(vec(s.get("pos")))
		add_child(slot)
		slots.append(slot)
	if config.get("pieces_from_previous", false):
		for p: DragPiece in context.get("pieces", []):
			p.reparent(self, false)
			p.home = p.position # a mismatched figure returns to where the child left it
			_adopt(p)
		# Outlines borrow the label/shape of the figure that belongs there.
		for slot in slots:
			for p in pieces:
				if slot.data.is_empty() and p.kind == slot.accepts:
					slot.data = p.data
	else:
		var tray := _tray_rect()
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(config.get("id", ""))
		var order := slots.duplicate()
		order.shuffle()
		var cols := 6
		for i in order.size():
			var slot: DropSlot = order[i]
			var p := DragPiece.create(slot.accepts, slot.size, slot.data)
			var cell := Vector2(tray.size.x / cols, tray.size.y / ceili(order.size() / float(cols)))
			var c := tray.position + Vector2((i % cols + 0.5) * cell.x, (i / cols + 0.5) * cell.y)
			p.home = c + Vector2(rng.randf_range(-8, 8), rng.randf_range(-6, 6)) - p.size / 2.0
			p.position = p.home
			add_child(p)
			_adopt(p)
	queue_redraw()


func _adopt(p: DragPiece) -> void:
	p.draggable = true
	p.set_lying(false)
	if not p.dropped.is_connected(_on_dropped):
		p.dropped.connect(_on_dropped)
		p.grabbed.connect(_on_grabbed)
	pieces.append(p)


func _tray_rect() -> Rect2:
	var t: Array = config.get("tray", [80, 360, 840, 180])
	return Rect2(t[0], t[1], t[2], t[3])


func reset_step() -> void:
	for slot in slots:
		slot.contents.clear()
		slot.queue_redraw()
	for p in pieces:
		p.placed_in = null
		tween_to(p, p.home)
	prompt_changed.emit(tr(str(config.get("prompt", ""))))


func show_hint() -> void:
	super.show_hint()
	for p in pieces:
		if p.placed_in == null:
			for slot in slots:
				if slot.contents.is_empty() and slot.fits(p):
					_place(p, slot)
					return


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		(p.placed_in as DropSlot).take(p)


func _on_dropped(p: DragPiece) -> void:
	var best: DropSlot = null
	var best_d := INF
	for slot in slots:
		var d := slot.center().distance_to(p.center())
		if slot.near(p.center(), snap_tolerance * 0.5) and d < best_d and slot.contents.is_empty():
			best = slot
			best_d = d
	if best == null:
		p.home = p.position # set it down where the child left it
		return
	if not best.fits(p):
		_mismatched[p] = true
		observed.emit("mismatch", {"step": config.get("id", ""), "piece": p.kind, "slot": best.accepts})
		say("mismatch", "Hmm, it doesn't fit there. Look at the shape.")
		reject(p, p.home)
		return
	if _mismatched.has(p):
		_mismatched.erase(p)
		observed.emit("self_correction", {"step": config.get("id", ""), "piece": p.kind})
	_place(p, best)


func _place(p: DragPiece, slot: DropSlot) -> void:
	slot.put(p)
	tween_to(p, slot.position, 0.15)
	AudioService.play("place")
	for s in slots:
		if s.contents.is_empty():
			return
	for piece in pieces:
		piece.draggable = false
	say("all_good", "Everything is in its place.")
	AudioService.play("step")
	finish({"placed": slots.size()})


func _draw() -> void:
	for m: Array in config.get("mats", []):
		var r := Rect2(m[0], m[1], m[2], m[3])
		draw_rect(r.grow(4), Color("a85646"))
		draw_rect(r, Color("efe3c6"))
		var y := r.position.y + 10
		while y < r.end.y:
			draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color("e2d3b0"), 1.0)
			y += 14
	if config.has("box"):
		var b: Array = config["box"]
		var r := Rect2(b[0], b[1], b[2], b[3])
		draw_rect(r.grow(8), Color("7b5338"))
		draw_rect(r, Color("c49a6c"))
		draw_string(ThemeDB.fallback_font, Vector2(r.position.x, r.end.y + 26), tr(str(config.get("box_label", ""))), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, Color("f3e6d2"))
	if not config.has("box") and not config.get("pieces_from_previous", false):
		var t := _tray_rect()
		draw_rect(t, Color(0, 0, 0, 0.08))
