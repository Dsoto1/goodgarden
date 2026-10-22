extends ActivityStep
## Rotate-and-fit primitive, after the Montessori geometric insets: wooden
## shapes and a frame with an outline for each (the panes of a window, the
## walls and roof of a birdhouse). A shape fits only the outline of the same
## shape, turned the same way. Tapping a piece turns it a quarter turn.
##
## Control of error: the outline itself. A shape turned the wrong way, or the
## wrong shape, doesn't settle; it slides back, still turned as it was, and
## the child is told to look at the outline and turn it to match.
##
## Config:
##   shapes: [{"kind": "shape_triangle", "pos": [x, y], "turn": 0..3, "size"?: [w, h]}]
##           the outlines; "turn" is quarter turns clockwise (default 0)
##   spare: [kind]          extra shapes that fit nowhere here
##   picture: "window" | "birdhouse" | "floor"   what the frame looks like (default "window")
##   size: [w, h]           default size of each shape (default 100 x 100)
## Shapes: shape_square, shape_rect, shape_triangle, shape_semicircle, shape_circle.
## Feedback keys: "turn_it", "wrong_shape", "all_good".
## Result: {"shapes": int, "turns": int}

const TRAY_Y := 470.0
## How many quarter turns bring each shape back to looking the same.
const SYMMETRY := {"shape_square": 1, "shape_circle": 1, "shape_rect": 2, "shape_triangle": 4, "shape_semicircle": 4}

var outlines: Array[DropSlot] = []
var pieces: Array[DragPiece] = []
var turns := 0


func _build() -> void:
	var default_size := vec(config.get("size"), Vector2(100, 100))
	for spec: Dictionary in config.get("shapes", []):
		var kind := str(spec["kind"])
		var s := vec(spec.get("size"), default_size)
		var slot := DropSlot.create(kind, s, {"turn": int(spec.get("turn", 0)) % 4})
		slot.pivot_offset = s / 2.0
		slot.rotation = PI / 2.0 * int(slot.data["turn"])
		slot.set_center(vec(spec.get("pos")))
		add_child(slot)
		outlines.append(slot)
	var kinds: Array[Dictionary] = []
	for slot in outlines:
		kinds.append({"kind": slot.accepts, "size": slot.size, "turn": int(slot.data["turn"])})
	for k: Variant in config.get("spare", []):
		kinds.append({"kind": str(k), "size": default_size, "turn": 0})
	# Each piece starts turned away from how it fits (a quarter turn or three,
	# which never looks the same for a rectangle; squares and circles can't be
	# turned wrong). Pieces sit side by side in the tray, by their real widths.
	var widths: Array[float] = []
	var total := 0.0
	for i in kinds.size():
		var start := (int(kinds[i]["turn"]) + 1 + (i % 2) * 2) % 4
		kinds[i]["start"] = start
		var s: Vector2 = kinds[i]["size"]
		widths.append(s.x if start % 2 == 0 else s.y)
		total += widths[i]
	var spacing := clampf((BOARD_SIZE.x - 100 - total) / maxf(kinds.size() - 1, 1), 4.0, 40.0)
	var x := (BOARD_SIZE.x - total - spacing * (kinds.size() - 1)) / 2.0
	for i in kinds.size():
		var spec := kinds[i]
		var p := DragPiece.create(str(spec["kind"]), spec["size"] * 0.98, {"turn": int(spec["start"])})
		p.pivot_offset = p.size / 2.0
		p.rotation = PI / 2.0 * int(p.data["turn"])
		p.home = Vector2(x + widths[i] / 2.0, TRAY_Y) - p.size / 2.0
		x += widths[i] + spacing
		p.position = p.home
		p.dropped.connect(_on_dropped)
		p.grabbed.connect(_on_grabbed)
		p.tapped.connect(turn)
		add_child(p)
		pieces.append(p)
	queue_redraw()


## A quarter turn clockwise.
func turn(p: DragPiece) -> void:
	if is_done or p.placed_in != null:
		return
	turns += 1
	p.data["turn"] = (int(p.data["turn"]) + 1) % 4
	AudioService.play("place")
	var goal := PI / 2.0 * int(p.data["turn"])
	# Keep turning forward, never spinning all the way back.
	while goal < p.rotation - 0.01:
		goal += TAU
	if reduced_motion:
		p.rotation = goal
	else:
		create_tween().tween_property(p, "rotation", goal, 0.15)


## True when piece `p`, turned as it is, matches `slot`.
func matches(p: DragPiece, slot: DropSlot) -> bool:
	if p.kind != slot.accepts:
		return false
	var sym := int(SYMMETRY.get(p.kind, 4))
	return int(p.data["turn"]) % sym == int(slot.data["turn"]) % sym


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		(p.placed_in as DropSlot).take(p)


func _on_dropped(p: DragPiece) -> void:
	# The nearest empty outline it is over; where two outlines share a square
	# (two triangles), the one it matches.
	var target: DropSlot = null
	for slot in outlines:
		if not slot.contents.is_empty() or slot.center().distance_to(p.center()) >= maxf(slot.size.x, slot.size.y) * 0.5 + snap_tolerance * 0.5:
			continue
		if target == null or (matches(p, slot) and not matches(p, target)) or (matches(p, slot) == matches(p, target) and slot.center().distance_to(p.center()) < target.center().distance_to(p.center())):
			target = slot
	if target == null:
		tween_to(p, p.home)
		return
	if not matches(p, target):
		observed.emit("mismatch", {"step": config.get("id", "")})
		if p.kind == target.accepts:
			say("turn_it", "Almost! Look at the outline. Tap the shape to turn it until it matches.")
		else:
			say("wrong_shape", "That shape doesn't fit there. Look at the outline: which shape is the same?")
		reject(p, p.home)
		return
	target.put(p)
	p.draggable = false
	tween_to(p, target.center() - p.size / 2.0, 0.12)
	AudioService.play("place")
	for slot in outlines:
		if slot.contents.is_empty():
			return
	say("all_good", "Every shape fits in its place.")
	AudioService.play("step")
	finish({"shapes": outlines.size(), "turns": turns})


func reset_step() -> void:
	for slot in outlines:
		slot.contents.clear()
		slot.queue_redraw()
	for p in pieces:
		p.placed_in = null
		p.draggable = true
		tween_to(p, p.home)
	prompt_changed.emit(tr(str(config.get("prompt", ""))))


func show_hint() -> void:
	for slot in outlines:
		if not slot.contents.is_empty():
			continue
		for p in pieces:
			if p.kind == slot.accepts and p.placed_in == null:
				# Turn it the right way for the child, and show where it goes.
				while not matches(p, slot):
					turn(p)
				Sparkle.burst(self, slot.center())
				prompt_changed.emit(tr("Here: this shape, turned like this, goes there."))
				return


func supports_hint() -> bool:
	return true


func _draw() -> void:
	# The frame the shapes go into, around the outlines.
	var area := Rect2()
	for i in outlines.size():
		var r := Rect2(outlines[i].position, outlines[i].size)
		area = r if i == 0 else area.merge(r)
	area = area.grow(18)
	match str(config.get("picture", "window")):
		"birdhouse":
			BoardArt._fill(self, BoardArt._round_rect(area, 10), Color("e8dcc4"))
			draw_rect(Rect2(area.get_center().x - 8, area.end.y, 16, 30), Color("8a5a3a"))
		"floor":
			BoardArt._fill(self, BoardArt._round_rect(area, 6), Color("cdbb9a"))
		_:
			# A window frame: thick wood round a pale sky.
			BoardArt._fill(self, BoardArt._round_rect(area.grow(14), 8), Color("8a5a3a"))
			BoardArt._fill(self, BoardArt._round_rect(area, 4), Color("dbe9f2"))
	BoardArt.basket(self, Rect2(40, TRAY_Y - 70, BOARD_SIZE.x - 80, 140))
