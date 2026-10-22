extends ActivityStep
## Sequence primitive: picture cards put in order along a row of numbered
## places (how a tree grows, the days of creation, making bread).
##
## Control of error: when every place holds a card, cards in the wrong place
## gently slide back to the table and the rest stay, so the child sees which
## part of the order to look at again. The places carry dots (1 to 5) as well
## as numerals, for children who don't read numbers yet.
##
## Config:
##   cards: [kind, ...]            in the right order (PieceArt kinds)
##   labels: [text, ...]           optional caption under each card
##   show_dots: bool               dots on the places (default true)
## Feedback keys: "out_of_order", "all_good".
## Result: {"cards": int, "tries": int}

const CARD := Vector2(132, 150)

var places: Array[DropSlot] = []
var cards: Array[DragPiece] = []
var _tries := 0


func _build() -> void:
	var kinds: Array = config.get("cards", [])
	var labels: Array = config.get("labels", [])
	var n := kinds.size()
	var gap := (BOARD_SIZE.x - 80.0) / n
	for i in n:
		var slot := DropSlot.create("card", CARD)
		slot.show_outline = false
		slot.set_meta(&"order", i)
		slot.set_center(Vector2(40.0 + gap * (i + 0.5), 150))
		add_child(slot)
		places.append(slot)
	# The cards start shuffled along the table below.
	var order: Array = range(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(config.get("id", "seq")))
	while order == range(n):
		for i in range(n - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t: int = order[i]
			order[i] = order[j]
			order[j] = t
	for i in n:
		var k: int = order[i]
		var data := {"label": tr(str(labels[k])) if k < labels.size() else ""}
		var c := DragPiece.create(str(kinds[k]), CARD, data)
		c.set_meta(&"order", k)
		c.home = Vector2(40.0 + gap * (i + 0.5), 410) - CARD / 2.0 + Vector2(0, (i % 2) * 14.0)
		c.position = c.home
		c.dropped.connect(_on_dropped)
		c.grabbed.connect(_on_grabbed)
		add_child(c)
		cards.append(c)
	queue_redraw()


func reset_step() -> void:
	for s in places:
		s.contents.clear()
	for c in cards:
		c.placed_in = null
		tween_to(c, c.home)
	prompt_changed.emit(tr(str(config.get("prompt", ""))))
	queue_redraw()


func show_hint() -> void:
	super.show_hint()
	# Show where the next missing card goes.
	for s in places:
		if s.contents.is_empty():
			for c in cards:
				if c.placed_in == null and int(c.get_meta(&"order")) == int(s.get_meta(&"order")):
					tween_to(c, s.position)
					s.put(c)
					_check()
					return


func _on_grabbed(c: DragPiece) -> void:
	if c.placed_in is DropSlot:
		(c.placed_in as DropSlot).take(c)
	queue_redraw()


func _on_dropped(c: DragPiece) -> void:
	var target: DropSlot = null
	for s in places:
		if s.near(c.center(), snap_tolerance * 0.6) and s.contents.is_empty():
			target = s
			break
	if target == null:
		return
	target.put(c)
	tween_to(c, target.position, 0.15)
	AudioService.play("place")
	_check()


func _check() -> void:
	for s in places:
		if s.contents.is_empty():
			return
	_tries += 1
	var wrong: Array[DragPiece] = []
	for s in places:
		var c: DragPiece = s.contents[0]
		if int(c.get_meta(&"order")) != int(s.get_meta(&"order")):
			wrong.append(c)
	if wrong.is_empty():
		for c in cards:
			c.draggable = false
		say("all_good", "That's the right order!")
		AudioService.play("step")
		finish({"cards": cards.size(), "tries": _tries})
		return
	observed.emit("mismatch", {"step": config.get("id", ""), "out_of_order": wrong.size()})
	say("out_of_order", "Some pictures are in the wrong place. They've gone back to the table. What comes next?")
	for c in wrong:
		(c.placed_in as DropSlot).take(c)
		reject(c, c.home)
	queue_redraw()


func _draw() -> void:
	var font := UiStyle.font()
	var show_dots: bool = config.get("show_dots", true)
	for i in places.size():
		var s := places[i]
		var r := Rect2(s.position, s.size)
		BoardArt._fill(self, BoardArt._round_rect(r.grow(6), 12), Color(0.25, 0.17, 0.1, 0.25), 1.0)
		# The place's number, with as many dots as the number.
		draw_string(font, Vector2(r.position.x, r.end.y + 34), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, Color("f3e6d2"))
		if show_dots:
			for k in i + 1:
				draw_circle(Vector2(r.get_center().x + (k - i / 2.0) * 12.0, r.end.y + 48), 4.0, Color("f3e6d2"))
		if i < places.size() - 1:
			var a := Vector2(r.end.x + 4, r.get_center().y)
			var b := Vector2(places[i + 1].position.x - 4, r.get_center().y)
			draw_line(a, b, Color("f3e6d2", 0.7), 3.0)
			draw_colored_polygon(PackedVector2Array([b, b + Vector2(-8, -6), b + Vector2(-8, 6)]), Color("f3e6d2", 0.7))
	BoardArt.cloth(self, Rect2(30, 320, BOARD_SIZE.x - 60, 190))
