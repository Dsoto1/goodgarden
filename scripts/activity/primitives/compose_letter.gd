extends ActivityStep
## Writing primitive: a letter (or card, or note) with a few blanks, and
## word cards to choose from for each. The child writes their own letter by
## choosing: there is no single right answer, only words that make sense in
## that place. Each blank and its cards share a colour, so a child who can't
## read yet still knows which cards go where; younger children's cards also
## carry a little picture. Tapping a card says its word; tapping a line of
## the letter reads it aloud as it stands.
##
## Control of error: a card only fits a blank of its own colour (a "thing"
## where a thing goes, a name where a name goes). When every blank is
## filled, the whole letter is read aloud, and the child can still change a
## word before sending it.
##
## Config:
##   lines: [String]    the letter, with blanks written {key}: "Dear {to},"
##   choices: {key: [String | {"word": String, "icon": String}]}
##   signature: String  written at the bottom ("from {child}" by default)
## Feedback keys: "wrong_place", "read_back", "all_good".
## Result: {"words": {key: word}, "text": String}

const PAPER := Rect2(110, 14, 780, 350)
const CARD_H := 46.0
const TRAY := Rect2(30, 380, 940, 170)
const TINTS := [Color("4f7a3a"), Color("5f8fd0"), Color("b8392f"), Color("c9a23a"), Color("7a4a7a")]

var lines: Array[String] = []
var blanks: Array[DropSlot] = []
var cards: Array[DragPiece] = []
var _keys: Array[String] = [] # each blank's key, in the order they appear
var _line_rects: Array[Rect2] = []
var _blank_w := {} # key -> width of its spaces: room for its longest word


func _build() -> void:
	for l: Variant in config.get("lines", ["Dear {to},", "Thank you for the {thing}."]):
		lines.append(str(l))
	var font := UiStyle.font()
	# The keys in order, and each card's word.
	for line in lines:
		var rest := line
		while rest.find("{") >= 0:
			var open := rest.find("{")
			var key := rest.substr(open + 1, rest.find("}", open) - open - 1)
			if not key in _keys:
				_keys.append(key)
			rest = rest.substr(rest.find("}", open) + 1)
	var all: Array[Dictionary] = []
	var choices: Dictionary = config.get("choices", {})
	for key in _keys:
		for c: Variant in choices.get(key, []):
			var d: Dictionary = c if c is Dictionary else {"word": str(c)}
			var word := tr(str(d["word"]))
			var icon := str(d.get("icon", ""))
			# Each card is as wide as its word (and picture) needs.
			var width := clampf(font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x + (CARD_H if not icon.is_empty() else 0.0) + 24, 96, 300)
			all.append({"key": key, "word": word, "icon": icon, "width": width})
			_blank_w[key] = maxf(float(_blank_w.get(key, 0.0)), width + 8)
	# Lay out each line: words, then a space where a {key} is.
	for i in lines.size():
		var y := PAPER.position.y + 30 + i * 56
		var x := PAPER.position.x + 30
		var rest := lines[i]
		while true:
			var open := rest.find("{")
			if open < 0:
				break
			var close := rest.find("}", open)
			x += font.get_string_size(tr(rest.substr(0, open)), HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x + 6
			var key := rest.substr(open + 1, close - open - 1)
			var w: float = _blank_w.get(key, 120.0)
			var slot := DropSlot.create(key, Vector2(w, CARD_H + 6), {"line": i, "tint": _tint(key)})
			slot.show_outline = false
			slot.position = Vector2(x, y - 7)
			add_child(slot)
			blanks.append(slot)
			x += w + 6
			rest = rest.substr(close + 1)
		_line_rects.append(Rect2(PAPER.position.x + 20, y - 8, PAPER.size.x - 40, 54))
	# The word cards flow along the tray, row by row.
	var cx := TRAY.position.x + 12
	var cy := TRAY.position.y + 12
	for card: Dictionary in all:
		if cx + float(card["width"]) > TRAY.end.x - 12:
			cx = TRAY.position.x + 12
			cy += CARD_H + 8
		var data := {"key": card["key"], "tint": _tint(card["key"])}
		if not str(card["icon"]).is_empty():
			data["icon"] = card["icon"]
		var c := DragPiece.create("word:" + str(card["word"]), Vector2(float(card["width"]), CARD_H), data)
		c.home = Vector2(cx, cy)
		c.position = c.home
		cx += float(card["width"]) + 10
		c.dropped.connect(_on_dropped)
		c.grabbed.connect(_on_grabbed)
		c.tapped.connect(func(p: DragPiece) -> void: AudioService.narrate(p.kind.substr(5), true))
		add_child(c)
		cards.append(c)
	queue_redraw()


func _tint(key: String) -> Color:
	var i := _keys.find(key)
	return TINTS[(i if i >= 0 else 0) % TINTS.size()]


func word_in(slot: DropSlot) -> String:
	return slot.contents[0].kind.substr(5) if not slot.contents.is_empty() else ""


## A line of the letter as it stands, blanks read as "something".
func line_text(i: int) -> String:
	var text := tr(lines[i])
	for slot in blanks:
		if int(slot.data["line"]) == i:
			var open := text.find("{")
			var close := text.find("}", open)
			var w := word_in(slot)
			text = text.substr(0, open) + (w if not w.is_empty() else "...") + text.substr(close + 1)
	return text


func letter_text() -> String:
	var parts: Array[String] = []
	for i in lines.size():
		parts.append(line_text(i))
	return "\n".join(parts)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var at := (event as InputEventMouseButton).position
		for i in _line_rects.size():
			if _line_rects[i].has_point(at):
				AudioService.narrate(line_text(i), true)
				accept_event()
				return


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		(p.placed_in as DropSlot).take(p)
	queue_redraw()


func _on_dropped(p: DragPiece) -> void:
	var target: DropSlot = null
	for slot in blanks:
		if slot.near(p.center(), snap_tolerance * 0.5):
			target = slot
			break
	if target == null:
		tween_to(p, p.home)
		return
	if str(p.data["key"]) != target.accepts:
		observed.emit("mismatch", {"step": config.get("id", "")})
		say("wrong_place", "That word goes in a space of its own colour.")
		reject(p, p.home)
		return
	# A new choice replaces the word already there.
	for old in target.contents.duplicate():
		target.take(old)
		tween_to(old, old.home)
	target.put(p)
	tween_to(p, target.position + (target.size - p.size) / 2.0, 0.12)
	AudioService.play("place")
	AudioService.narrate(line_text(int(target.data["line"])))
	queue_redraw()
	_offer_send()


## Once every blank has a word, the letter can be read back and sent.
func _offer_send() -> void:
	for slot in blanks:
		if slot.contents.is_empty():
			return
	say("read_back", "Your letter is ready. Listen to it. You can still change a word, or send it.")
	AudioService.narrate(letter_text(), true)
	actions_changed.emit([{"label": tr("Send it"), "primary": true, "icon": "yes", "callback": send}])


func send() -> void:
	if is_done:
		return
	var words := {}
	for slot in blanks:
		if slot.contents.is_empty():
			return
		words[slot.accepts] = word_in(slot)
	say("all_good", "Your letter is written!")
	AudioService.play("step")
	actions_changed.emit([])
	finish({"words": words, "text": letter_text()})


func reset_step() -> void:
	for slot in blanks:
		for c in slot.contents.duplicate():
			slot.take(c)
	for c in cards:
		tween_to(c, c.home)
	actions_changed.emit([])
	queue_redraw()


func show_hint() -> void:
	for slot in blanks:
		if slot.contents.is_empty():
			Sparkle.burst(self, slot.center())
			prompt_changed.emit(tr("Find a card with the same colour as this space. Which one would you like?"))
			return


func supports_hint() -> bool:
	return true


func _draw() -> void:
	# Writing paper, with the letter's words written in and coloured spaces.
	BoardArt._fill(self, BoardArt._round_rect(PAPER, 6), Color("fbf5e8"))
	draw_rect(PAPER, Color("c9a86e"), false, 2.0)
	var font := UiStyle.font()
	var fsize := 28
	for i in lines.size():
		var y := PAPER.position.y + 30 + i * 56
		draw_line(Vector2(PAPER.position.x + 20, y + 40), Vector2(PAPER.end.x - 20, y + 40), Color(0.4, 0.55, 0.75, 0.25), 1.0)
		var x := PAPER.position.x + 30
		var rest := tr(lines[i])
		while true:
			var open := rest.find("{")
			var piece := rest if open < 0 else rest.substr(0, open)
			draw_string(font, Vector2(x, y + 30), piece, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color("3b3430"))
			if open < 0:
				break
			x += font.get_string_size(piece, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x + 6
			var key := rest.substr(open + 1, rest.find("}", open) - open - 1)
			var bw: float = _blank_w.get(key, 120.0)
			var box := Rect2(Vector2(x, y - 7), Vector2(bw, CARD_H + 6))
			draw_rect(box, Color(_tint(key), 0.12))
			draw_rect(box, _tint(key), false, 2.0)
			x += bw + 6
			rest = rest.substr(rest.find("}", open) + 1)
	var sig := tr(str(config.get("signature", "")))
	if not sig.is_empty():
		draw_string(font, Vector2(PAPER.position.x, PAPER.end.y - 18), sig, HORIZONTAL_ALIGNMENT_RIGHT, PAPER.size.x - 40, 26, Color("7a4a26"))
	BoardArt.wood_box(self, TRAY)
