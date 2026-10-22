extends ActivityStep
## Build-a-word primitive, after the Montessori moveable alphabet: a picture
## (a hen), a row of places for its letters, and a box of wooden letters. The
## child listens for each sound in the word and puts the letter that makes it
## in its place. Vowels are blue and consonants red, as in the classroom
## material. Words are built one after another; each finished word is read
## back sound by sound ("h, e, n: hen!") and laid on the shelf as a sign.
##
## Nothing depends on reading already: tapping the picture says the word,
## tapping a letter says its sound, and "Show me" sounds out the next letter.
##
## Control of error: a letter only settles in a place whose sound it makes;
## any other slides back to the box, and the word is said again slowly.
##
## Config:
##   words: [String]         short, sound-by-sound words, e.g. ["hen", "cat"]
##   pictures: {word: icon}  Icon kind drawn for each word (default: the word)
##   show_letters: bool      faint letters in each place to match (default
##                           true; false asks the child to listen alone)
##   extra_letters: int      extra letters in the box that aren't needed
##                           (default 0)
## Feedback keys: "wrong", "word_done", "all_good"; "{word}" becomes the word.
## Result: {"words": [String]}

## How each letter sounds on its own, spelled so a reading voice says the
## sound rather than the letter's name ("hh", not "aitch").
const SOUNDS := {
	"a": "a, as in apple", "b": "buh", "c": "kuh", "d": "duh", "e": "eh", "f": "fff", "g": "guh", "h": "hh",
	"i": "ih", "j": "juh", "k": "kuh", "l": "lll", "m": "mmm", "n": "nnn", "o": "o, as in on", "p": "puh",
	"q": "kwuh", "r": "rrr", "s": "sss", "t": "tuh", "u": "uh", "v": "vvv", "w": "wuh", "x": "ks", "y": "yuh", "z": "zzz",
}
const TILE := Vector2(76, 88)
const BOX := Rect2(60, 400, 880, 140)

var words: Array[String] = []
var word_index := -1
var slots: Array[DropSlot] = []
var tiles: Array[DragPiece] = []
var finished: Array[String] = []
var _picture: Control
var _hint_tile: DragPiece


func _build() -> void:
	for w: Variant in config.get("words", ["hen"]):
		words.append(str(w).to_lower())
	_picture = Control.new()
	_picture.position = Vector2(60, 40)
	_picture.size = Vector2(220, 220)
	_picture.mouse_filter = Control.MOUSE_FILTER_STOP
	_picture.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and word_index < words.size():
			say_word())
	_picture.draw.connect(_draw_picture)
	add_child(_picture)
	_next_word()


func current_word() -> String:
	return words[word_index] if word_index >= 0 and word_index < words.size() else ""


## Says the word whole, as the picture does when tapped.
func say_word() -> void:
	AudioService.narrate(current_word(), true)


## Says the word slowly, one sound at a time, then whole.
func sound_out(word: String) -> String:
	var parts: Array[String] = []
	for ch in word:
		parts.append(str(SOUNDS.get(ch, ch)).get_slice(",", 0))
	return ", ".join(parts) + "... " + word + "!"


func _next_word() -> void:
	for s in slots:
		s.queue_free()
	for t in tiles:
		t.queue_free()
	slots.clear()
	tiles.clear()
	word_index += 1
	_picture.queue_redraw()
	if word_index >= words.size():
		say("all_good", "Every sign has its name. Well done!")
		AudioService.play("step")
		finish({"words": finished.duplicate()})
		return
	var word := current_word()
	var show_letters: bool = config.get("show_letters", true)
	var row_w := word.length() * (TILE.x + 14) - 14
	var x0 := 330.0 + (640.0 - row_w) / 2.0
	for i in word.length():
		var slot := DropSlot.create("letter:" + word[i], TILE, {"index": i})
		slot.show_outline = show_letters
		slot.position = Vector2(x0 + i * (TILE.x + 14), 110)
		add_child(slot)
		slots.append(slot)
	# The letters the word needs, plus any extra, shuffled into the box.
	var letters: Array[String] = []
	for ch in word:
		letters.append(ch)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(word)
	var spare := "abcdefghilmnoprstu"
	for k in int(config.get("extra_letters", 0)):
		var ch := spare[rng.randi() % spare.length()]
		while ch in word:
			ch = spare[rng.randi() % spare.length()]
		letters.append(ch)
	for k in range(letters.size() - 1, 0, -1):
		var j := rng.randi() % (k + 1)
		var tmp := letters[k]
		letters[k] = letters[j]
		letters[j] = tmp
	var gap := minf(TILE.x + 24, (BOX.size.x - 40) / letters.size())
	var bx := BOX.position.x + (BOX.size.x - gap * letters.size()) / 2.0 + (gap - TILE.x) / 2.0
	for i in letters.size():
		var t := DragPiece.create("letter:" + letters[i], TILE, {"letter": letters[i]})
		t.home = Vector2(bx + i * gap, BOX.position.y + (BOX.size.y - TILE.y) / 2.0)
		t.position = t.home
		t.dropped.connect(_on_dropped)
		t.grabbed.connect(_on_grabbed)
		t.tapped.connect(func(p: DragPiece) -> void: AudioService.narrate(str(SOUNDS.get(str(p.data["letter"]), p.data["letter"])), true))
		add_child(t)
		tiles.append(t)
	prompt_changed.emit(tr(str(config.get("prompt", "Listen to the word. Which sounds do you hear? Put each letter in its place."))))
	say_word()
	queue_redraw()


func reset_step() -> void:
	for s in slots:
		s.contents.clear()
		s.queue_redraw()
	for t in tiles:
		t.placed_in = null
		t.draggable = true
		tween_to(t, t.home)
	prompt_changed.emit(tr(str(config.get("prompt", ""))))


func show_hint() -> void:
	for s in slots:
		if s.contents.is_empty():
			var letter := s.accepts.substr(7)
			for t in tiles:
				if t.placed_in == null and str(t.data["letter"]) == letter:
					_hint_tile = t
					break
			prompt_changed.emit(tr("Listen: %s. The next sound is \"%s\".") % [current_word(), str(SOUNDS[letter]).get_slice(",", 0)])
			AudioService.narrate(str(SOUNDS[letter]).get_slice(",", 0), true)
			queue_redraw()
			return


func supports_hint() -> bool:
	return true


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		(p.placed_in as DropSlot).take(p)
	AudioService.narrate(str(SOUNDS.get(str(p.data["letter"]), "")).get_slice(",", 0))


func _on_dropped(p: DragPiece) -> void:
	var target: DropSlot = null
	for s in slots:
		if s.near(p.center(), snap_tolerance * 0.6) and s.contents.is_empty():
			target = s
			break
	if target == null:
		tween_to(p, p.home)
		return
	if not target.fits(p):
		observed.emit("mismatch", {"step": config.get("id", ""), "word": current_word()})
		var text := tr(str(config.get("feedback", {}).get("wrong", "Listen again: {word}. That sound goes somewhere else.")))
		prompt_changed.emit(text.replace("{word}", current_word()))
		AudioService.narrate(sound_out(current_word()), true)
		reject(p, p.home)
		return
	target.put(p)
	p.draggable = false
	tween_to(p, target.position, 0.12)
	AudioService.play("place")
	if p == _hint_tile:
		_hint_tile = null
	queue_redraw()
	for s in slots:
		if s.contents.is_empty():
			return
	_word_done()


func _word_done() -> void:
	var word := current_word()
	finished.append(word)
	var text := tr(str(config.get("feedback", {}).get("word_done", "{word}! You made the word.")))
	prompt_changed.emit(text.replace("{word}", word.capitalize()))
	AudioService.narrate(sound_out(word), true)
	AudioService.play("step")
	Sparkle.burst(self, slots[slots.size() / 2].center())
	queue_redraw()
	await get_tree().create_timer(2.4).timeout
	if is_inside_tree() and not is_done:
		_next_word()


func _draw() -> void:
	# The alphabet box: a shallow wooden tray with a lip.
	BoardArt.wood_box(self, BOX)
	# The shelf of finished signs, each a little plank with its word.
	var font := UiStyle.font()
	for i in finished.size():
		var r := Rect2(340 + i * 150, 270, 130, 54)
		BoardArt._fill(self, BoardArt._round_rect(r, 8), Color("c79a62"))
		draw_string(font, Vector2(r.position.x, r.position.y + 38), finished[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 30, Color("4a2f20"))
	# Without ghost letters each place is still shown, blank: the child can
	# see how many sounds to listen for.
	if not config.get("show_letters", true):
		for slot in slots:
			if slot.contents.is_empty():
				var r := Rect2(slot.position + Vector2(2, 2), TILE - Vector2(4, 4))
				draw_rect(r, Color(1, 1, 1, 0.12))
				draw_rect(r, Color(0.25, 0.18, 0.12, 0.55), false, 2.0)
	if _hint_tile and is_instance_valid(_hint_tile):
		draw_arc(_hint_tile.position + TILE / 2.0, TILE.y * 0.7, 0, TAU, 32, Color(1, 0.95, 0.7), 4.0)


func _draw_picture() -> void:
	var r := Rect2(Vector2.ZERO, _picture.size)
	BoardArt._fill(_picture, BoardArt._round_rect(r, 14), Color("fbf5e8"))
	var word := current_word()
	if word.is_empty():
		return
	var kind := str(config.get("pictures", {}).get(word, word))
	Icon.draw(_picture, kind, r.grow(-30))
	# A small speaker: tap the picture to hear the word.
	Icon.draw(_picture, "speaker", Rect2(Vector2(r.size.x - 44, 8), Vector2(36, 36)))
