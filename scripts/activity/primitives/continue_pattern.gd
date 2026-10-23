extends ActivityStep
## Pattern primitive: a row of places (a flower border, stepping stones) with
## the first few already set in a repeating pattern ("red, yellow, red,
## yellow"). The child carries the pattern on to the end of the row.
##
## Nothing depends on reading or naming colours: tapping a piece says its
## name, and "Show me" says the pattern aloud up to the next empty place
## ("red, yellow, red, yellow... what comes next?").
##
## Control of error: a piece only settles where it continues the pattern;
## anything else slides back to the basket.
##
## Config:
##   unit: [kind]       one repeat of the pattern, e.g. ["flower_red", "flower_yellow"]
##   length: int        places in the row (default 10)
##   given: int         places already set at the start (default one unit's worth)
##   names: {kind: String}   what each piece is called aloud
##   look: "border" | "path" | "plank" | "bunting"   a soil border, a path of
##         earth, a painted plank, or a string of bunting (default "border")
## Feedback keys: "wrong", "all_good".
## Result: {"unit": [kind], "length": int}

const PLACE := Vector2(74, 74)

var unit: Array[String] = []
var places: Array[DropSlot] = []
var pieces: Array[DragPiece] = []
var _row_y := 220.0
var _given := 0


func _build() -> void:
	for k: Variant in config.get("unit", ["flower_red", "flower_yellow"]):
		unit.append(str(k))
	var length := int(config.get("length", 10))
	_given = int(config.get("given", unit.size()))
	var gap := minf(PLACE.x + 14, (BOARD_SIZE.x - 60) / length)
	var x0 := (BOARD_SIZE.x - gap * length) / 2.0 + gap / 2.0
	for i in length:
		var kind := kind_at(i)
		var place := DropSlot.create(kind, PLACE, {"index": i})
		place.show_outline = false
		place.set_center(Vector2(x0 + i * gap, _row_y))
		add_child(place)
		places.append(place)
		if i < _given:
			var fixed := DragPiece.create(kind, PLACE * 0.8)
			fixed.draggable = false
			fixed.set_center(place.center())
			fixed.tapped.connect(func(p: DragPiece) -> void: AudioService.narrate(name_of(p.kind), true))
			add_child(fixed)
			place.put(fixed)
	# Enough of each kind for the rest of the row, and one spare of each.
	var supply: Array[String] = []
	for i in range(_given, length):
		supply.append(kind_at(i))
	for k in unit:
		supply.append(k)
	supply.sort()
	var tray_gap := minf(PLACE.x * 0.8 + 12, (BOARD_SIZE.x - 120) / supply.size())
	var tx0 := (BOARD_SIZE.x - tray_gap * supply.size()) / 2.0 + tray_gap / 2.0
	for i in supply.size():
		var p := DragPiece.create(supply[i], PLACE * 0.8)
		p.home = Vector2(tx0 + i * tray_gap, 440) - p.size / 2.0
		p.position = p.home
		p.dropped.connect(_on_dropped)
		p.grabbed.connect(_on_grabbed)
		p.tapped.connect(func(q: DragPiece) -> void: AudioService.narrate(name_of(q.kind), true))
		add_child(p)
		pieces.append(p)
	queue_redraw()


func kind_at(i: int) -> String:
	return unit[i % unit.size()]


func name_of(kind: String) -> String:
	return tr(str(config.get("names", {}).get(kind, kind.get_slice("_", kind.get_slice_count("_") - 1))))


## The pattern said aloud up to place `upto`, then the question.
func say_pattern(upto: int) -> String:
	var words: Array[String] = []
	for i in upto:
		words.append(name_of(kind_at(i)))
	return ", ".join(words) + "... " + tr("what comes next?")


func reset_step() -> void:
	for i in range(_given, places.size()):
		places[i].contents.clear()
	for p in pieces:
		p.placed_in = null
		p.draggable = true
		tween_to(p, p.home)
	prompt_changed.emit(tr(str(config.get("prompt", ""))))


func show_hint() -> void:
	for i in places.size():
		if places[i].contents.is_empty():
			prompt_changed.emit(say_pattern(i))
			AudioService.narrate(say_pattern(i), true)
			Sparkle.burst(self, places[i].center())
			return


func supports_hint() -> bool:
	return true


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		(p.placed_in as DropSlot).take(p)


func _on_dropped(p: DragPiece) -> void:
	var target: DropSlot = null
	for place in places:
		if place.near(p.center(), snap_tolerance * 0.5) and place.contents.is_empty():
			target = place
			break
	if target == null:
		tween_to(p, p.home)
		return
	if not target.fits(p):
		observed.emit("mismatch", {"step": config.get("id", "")})
		var i := int(target.data["index"])
		prompt_changed.emit(tr(str(config.get("feedback", {}).get("wrong", "Listen to the pattern: {pattern}"))).replace("{pattern}", say_pattern(i)))
		AudioService.narrate(say_pattern(i), true)
		reject(p, p.home)
		return
	target.put(p)
	p.draggable = false
	tween_to(p, target.center() - p.size / 2.0, 0.12)
	AudioService.play("place")
	AudioService.narrate(name_of(p.kind))
	for place in places:
		if place.contents.is_empty():
			return
	say("all_good", "The pattern goes all the way along. Beautiful!")
	AudioService.play("step")
	finish({"unit": unit.duplicate(), "length": places.size()})


func _draw() -> void:
	match str(config.get("look", "border")):
		"path":
			BoardArt._fill(self, BoardArt._round_rect(Rect2(20, _row_y - 56, BOARD_SIZE.x - 40, 112), 40), Color("c9a774"))
		"plank":
			BoardArt._fill(self, BoardArt._round_rect(Rect2(20, _row_y - 50, BOARD_SIZE.x - 40, 100), 8), Color("c79a62"))
			for k in 3:
				draw_line(Vector2(40, _row_y - 30 + k * 30), Vector2(BOARD_SIZE.x - 40, _row_y - 26 + k * 30), Color(0.45, 0.3, 0.18, 0.3), 2.0)
		"bunting":
			draw_line(Vector2(20, _row_y - 34), Vector2(BOARD_SIZE.x - 20, _row_y - 34), Color("8a6446"), 4.0)
		_:
			BoardArt.soil_row(self, Rect2(20, _row_y - 50, BOARD_SIZE.x - 40, 100))
	BoardArt.basket(self, Rect2(60, 390, BOARD_SIZE.x - 120, 100))
	for place in places:
		if place.contents.is_empty():
			draw_circle(place.center(), PLACE.x * 0.36, Color(1, 1, 1, 0.12))
			draw_arc(place.center(), PLACE.x * 0.36, 0, TAU, 24, Color(0.25, 0.18, 0.12, 0.5), 2.0)
