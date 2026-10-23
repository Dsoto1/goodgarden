extends ActivityStep
## Division primitive: sharing out. A pile of things (rolls, apples, seeds)
## and a plate or basket for each person. The child deals them out, one
## each, round and round, until the pile is gone. Nothing on the plates
## says how many: the child finds out by sharing. Older children may meet a
## pile that doesn't share evenly; what can't be shared fairly goes in the
## "left over" bowl.
##
## Control of error: "Done" counts each plate. Plates that don't match are
## named; a pile not yet shared, or a "left over" bowl holding enough to go
## round once more, is pointed out.
##
## Config:
##   piece: kind          (default "bread_roll")
##   total: int           how many to share (default 12)
##   plates: int          how many shares (default 3)
##   names: [String]      a name under each plate ("Mrs. Ruth", ...)
##   look: "plate" | "basket"   (default "basket")
##   leftover: bool       a "left over" bowl, for a share that isn't even (default false)
## Feedback keys: "not_shared", "not_equal", "share_more", "all_good"; "{n}" is
## each share and "{left}" what is left over.
## Result: {"each": int, "left": int}

const PLATE := Vector2(190, 130)
const PILE := Rect2(250, 400, 500, 140)

var plates: Array[DropSlot] = []
var leftover: DropSlot
var pieces: Array[DragPiece] = []


func _build() -> void:
	var n := int(config.get("plates", 3))
	var names: Array = config.get("names", [])
	var has_left: bool = config.get("leftover", false)
	var spots := n + (1 if has_left else 0)
	var gap := (BOARD_SIZE.x - 40) / spots
	for i in n:
		var p := DropSlot.create("share", PLATE, {"label": tr(str(names[i])) if i < names.size() else "", "look": str(config.get("look", "basket"))})
		p.capacity = 99
		p.show_outline = false
		p.set_center(Vector2(20 + gap * (i + 0.5), 160))
		add_child(p)
		plates.append(p)
	if has_left:
		leftover = DropSlot.create("share", Vector2(150, 110), {"label": tr("left over"), "look": "bowl"})
		leftover.capacity = 99
		leftover.show_outline = false
		leftover.set_center(Vector2(20 + gap * (n + 0.5), 170))
		add_child(leftover)
	var total := int(config.get("total", 12))
	var kind := str(config.get("piece", "bread_roll"))
	for i in total:
		var p := DragPiece.create(kind, Vector2(48, 48))
		p.home = PILE.position + Vector2(20 + (i % 10) * 46, 14 + (i / 10) * 50 + (i % 2) * 6)
		p.position = p.home
		p.dropped.connect(_on_dropped)
		p.grabbed.connect(_on_grabbed)
		add_child(p)
		pieces.append(p)
	actions_changed.emit([{"label": tr("Done"), "primary": true, "icon": "yes", "callback": check}])
	queue_redraw()


func _all_places() -> Array[DropSlot]:
	var all: Array[DropSlot] = plates.duplicate()
	if leftover:
		all.append(leftover)
	return all


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		var from := p.placed_in as DropSlot
		from.take(p)
		_lay(from)
	queue_redraw()


func _on_dropped(p: DragPiece) -> void:
	for place in _all_places():
		if place.near(p.center(), snap_tolerance * 0.3):
			place.put(p)
			_lay(place)
			AudioService.play("place")
			AudioService.narrate(str(place.contents.size()))
			queue_redraw()
			return
	tween_to(p, p.home)


## The pieces on a plate sit in tidy rows, so they can be counted.
func _lay(place: DropSlot) -> void:
	var n := place.contents.size()
	var cols := mini(4, maxi(n, 1))
	var rows := ceili(n / float(cols))
	for i in n:
		var c := place.contents[i]
		var spot := place.center() + Vector2((i % cols - (cols - 1) / 2.0) * 36, (i / cols - (rows - 1) / 2.0) * 32)
		tween_to(c, spot - c.size / 2.0, 0.12)


func left_in_pile() -> int:
	var n := 0
	for p in pieces:
		if p.placed_in == null:
			n += 1
	return n


## The Done button.
func check() -> void:
	if is_done:
		return
	if left_in_pile() > 0:
		observed.emit("not_shared", {"step": config.get("id", "")})
		say("not_shared", "There are still some to share. Keep going: one for each, round and round.")
		return
	var counts: Array[int] = []
	for p in plates:
		counts.append(p.contents.size())
	for i in range(1, counts.size()):
		if counts[i] != counts[0]:
			observed.emit("not_equal", {"step": config.get("id", "")})
			Sparkle.burst(self, plates[i].center())
			prompt_changed.emit(tr(str(config.get("feedback", {}).get("not_equal", "Count each one. Do they all have the same?"))))
			return
	var left := leftover.contents.size() if leftover else 0
	if left >= plates.size():
		observed.emit("share_more", {"step": config.get("id", "")})
		say("share_more", "There are enough left over to give everyone one more!")
		return
	prompt_changed.emit(tr(str(config.get("feedback", {}).get("all_good", "Fair shares: {n} each!"))).replace("{n}", str(counts[0])).replace("{left}", str(left)))
	AudioService.play("step")
	actions_changed.emit([])
	finish({"each": counts[0], "left": left})


func reset_step() -> void:
	for place in _all_places():
		for c in place.contents.duplicate():
			place.take(c)
	for p in pieces:
		tween_to(p, p.home)
	queue_redraw()


func show_hint() -> void:
	# Deal one more onto the plate with fewest, as a child would: one each, round.
	var fewest := plates[0]
	for p in plates:
		if p.contents.size() < fewest.contents.size():
			fewest = p
	Sparkle.burst(self, fewest.center())
	prompt_changed.emit(tr("Give one to each, round and round. This one is next."))


func supports_hint() -> bool:
	return true


func _draw() -> void:
	var font := UiStyle.font()
	for place in _all_places():
		var r := Rect2(place.position, place.size)
		if str(place.data.get("look", "")) == "plate" or place == leftover:
			BoardArt.bowl(self, r.get_center(), r.size.x * 0.45, Color("e9dcc0"))
		else:
			BoardArt.basket(self, r)
		var label := str(place.data.get("label", ""))
		if not label.is_empty():
			draw_string(font, Vector2(r.position.x - 6, r.end.y + 30), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 12, 22 if plates.size() <= 4 else 18, Color("3b3430"))
	BoardArt.wood_box(self, PILE)
