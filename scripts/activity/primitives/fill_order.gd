extends ActivityStep
## Reading-in-context primitive: a neighbour's note ("3 nails, 1 hook") and
## a shelf of things. The child reads each line, finds the right things, and
## puts the right number in the basket. Tapping a line of the note reads it
## aloud, so a child who can't read it yet is never stuck; younger children
## have a little picture beside each line, older ones read the words alone.
##
## Control of error: pressing "Done" checks the basket against the note, line
## by line, and says what is still missing or what there is too much of.
##
## Config:
##   order: [{"item": kind, "count": int, "word"?: String, "words"?: String}]
##          "word"/"words" are the singular/plural written on the note
##          (default: the kind's last part, plus "s")
##   pictures: bool          pictures beside the lines (default true)
##   extra: [kind]           things on the shelf the note doesn't ask for
##   spare: int              extra of each asked-for thing on the shelf (default 2)
##   note_from: String       signature at the bottom of the note
## Feedback keys: "missing", "too_many", "not_on_note", "all_good".
## Result: {"order": [{"item", "count"}]}

const NOTE := Rect2(30, 30, 300, 360)
const BASKET := Vector2(660, 200)
const SHELF := Rect2(370, 400, 600, 140)
const PIECE := Vector2(56, 56)

var order: Array = []
var pieces: Array[DragPiece] = []
var basket: DropSlot
var _lines: Array[Rect2] = []


func _build() -> void:
	order = config.get("order", [{"item": "nail", "count": 3}])
	basket = DropSlot.create("any", Vector2(420, 220), {"label": tr(str(config.get("basket_label", "basket"))), "look": "basket"})
	basket.capacity = 99
	basket.show_outline = false
	basket.set_center(BASKET)
	add_child(basket)
	var supply: Array[String] = []
	for line: Dictionary in order:
		for i in int(line["count"]) + int(config.get("spare", 2)):
			supply.append(str(line["item"]))
	for k: Variant in config.get("extra", []):
		for i in 2:
			supply.append(str(k))
	# Things of a kind sit together on the shelf, as they would in a shop.
	var gap := minf(PIECE.x + 6, (SHELF.size.x - 20) / ceilf(supply.size() / 2.0))
	for i in supply.size():
		var p := DragPiece.create(supply[i], PIECE)
		var col := i / 2
		p.home = SHELF.position + Vector2(10 + col * gap, 8 + (i % 2) * 64)
		p.position = p.home
		p.dropped.connect(_on_dropped)
		p.grabbed.connect(_on_grabbed)
		p.tapped.connect(func(q: DragPiece) -> void: AudioService.narrate(tr(word_for(q.kind, 1)), true))
		add_child(p)
		pieces.append(p)
	for i in order.size():
		_lines.append(Rect2(NOTE.position + Vector2(16, 70 + i * 66), Vector2(NOTE.size.x - 32, 58)))
	actions_changed.emit([{"label": tr("Done"), "primary": true, "icon": "yes", "callback": check}])
	queue_redraw()


func word_for(kind: String, n: int) -> String:
	for line: Dictionary in order:
		if str(line["item"]) == kind:
			var one := str(line.get("word", kind.get_slice("_", kind.get_slice_count("_") - 1)))
			return one if n == 1 else str(line.get("words", one + "s"))
	var base := kind.get_slice("_", kind.get_slice_count("_") - 1)
	return base if n == 1 else base + "s"


func line_text(i: int) -> String:
	var line: Dictionary = order[i]
	return "%d %s" % [int(line["count"]), tr(word_for(str(line["item"]), int(line["count"])))]


func count_in_basket(kind: String) -> int:
	var n := 0
	for p in basket.contents:
		if p.kind == kind:
			n += 1
	return n


func _gui_input(event: InputEvent) -> void:
	# Tapping a line of the note reads it aloud.
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var at := (event as InputEventMouseButton).position
		for i in _lines.size():
			if _lines[i].has_point(at):
				AudioService.narrate(line_text(i), true)
				prompt_changed.emit(line_text(i))
				accept_event()
				return


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		(p.placed_in as DropSlot).take(p)
	queue_redraw()


func _on_dropped(p: DragPiece) -> void:
	if basket.near(p.center(), snap_tolerance * 0.5):
		basket.put(p)
		AudioService.play("place")
		AudioService.narrate(str(count_in_basket(p.kind)))
	else:
		tween_to(p, p.home)
	queue_redraw()


## The Done button: check the basket against the note, line by line.
func check() -> void:
	if is_done:
		return
	for p in basket.contents:
		var asked := false
		for line: Dictionary in order:
			asked = asked or str(line["item"]) == p.kind
		if not asked:
			observed.emit("not_on_note", {"step": config.get("id", "")})
			_say_line("not_on_note", "The note doesn't ask for any {words}. Read it again, and take that out of the basket.", p.kind, 0)
			return
	for line: Dictionary in order:
		var kind := str(line["item"])
		var want := int(line["count"])
		var have := count_in_basket(kind)
		if have < want:
			observed.emit("missing", {"step": config.get("id", "")})
			_say_line("missing", "The note says {line}. There are only {n} in the basket.", kind, have)
			return
		if have > want:
			observed.emit("too_many", {"step": config.get("id", "")})
			_say_line("too_many", "The note says {line}. There are {n} in the basket: that's too many.", kind, have)
			return
	say("all_good", "Everything on the note is in the basket. Just right!")
	AudioService.play("step")
	actions_changed.emit([])
	var done: Array = []
	for line: Dictionary in order:
		done.append({"item": str(line["item"]), "count": int(line["count"])})
	finish({"order": done})


func _say_line(key: String, fallback: String, kind: String, n: int) -> void:
	var line := ""
	for i in order.size():
		if str(order[i]["item"]) == kind:
			line = line_text(i)
	prompt_changed.emit(tr(str(config.get("feedback", {}).get(key, fallback))).replace("{line}", line).replace("{n}", str(n)).replace("{words}", tr(word_for(kind, 2))))


func reset_step() -> void:
	for p in basket.contents.duplicate():
		basket.take(p)
		tween_to(p, p.home)
	queue_redraw()


func show_hint() -> void:
	for i in order.size():
		var kind := str(order[i]["item"])
		if count_in_basket(kind) != int(order[i]["count"]):
			AudioService.narrate(line_text(i), true)
			prompt_changed.emit(tr("Read this line: %s. Count them into the basket.") % line_text(i))
			Sparkle.burst(self, _lines[i].get_center())
			return


func supports_hint() -> bool:
	return true


func _draw() -> void:
	# The note: a slip of paper with the lines written on it.
	draw_rect(NOTE, Color("fbf5e8"))
	draw_rect(NOTE, Color("c9a86e"), false, 2.0)
	var font := UiStyle.font()
	draw_string(font, NOTE.position + Vector2(16, 44), tr(str(config.get("note_title", "Please bring:"))), HORIZONTAL_ALIGNMENT_LEFT, NOTE.size.x - 32, 24, Color("7a4a26"))
	var pictures: bool = config.get("pictures", true)
	for i in order.size():
		var r := _lines[i]
		var kind := str(order[i]["item"])
		var done := count_in_basket(kind) == int(order[i]["count"])
		var x := r.position.x
		if pictures:
			PieceArt.draw_at(self, kind, Rect2(r.position + Vector2(0, 4), Vector2(50, 50)))
			x += 60
		draw_string(font, Vector2(x, r.position.y + 40), line_text(i), HORIZONTAL_ALIGNMENT_LEFT, r.end.x - x, 34, Color("3b3430"))
		if done:
			draw_line(Vector2(r.end.x - 34, r.position.y + 30), Vector2(r.end.x - 24, r.position.y + 42), Color("4f7a3a"), 4.0)
			draw_line(Vector2(r.end.x - 24, r.position.y + 42), Vector2(r.end.x - 6, r.position.y + 16), Color("4f7a3a"), 4.0)
	var from := str(config.get("note_from", ""))
	if not from.is_empty():
		draw_string(font, Vector2(NOTE.position.x + 16, NOTE.end.y - 18), tr(from), HORIZONTAL_ALIGNMENT_RIGHT, NOTE.size.x - 32, 22, Color("7a4a26"))
	BoardArt.wood_box(self, SHELF)
	BoardArt.basket(self, Rect2(BASKET - Vector2(210, 110), Vector2(420, 220)))
