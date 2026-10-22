extends ActivityStep
## Label-the-pictures primitive, after the Montessori picture-and-label
## cards: a row of pictures (a bun, a jar of jam, an egg), an empty label
## place under each, and the labels waiting in a tray. Two levels:
##   - "first_sound": each label is one letter tile. The child listens to
##     the picture's name and finds the letter for its first sound
##     ("b" under the bun).
##   - "word": each label is a whole written word. The child reads it (tap a
##     label to hear its sounds one by one, then blend them) and lays it
##     under its picture.
##
## Tapping a picture says its name. A label only settles under the picture it
## names; any other slides back, and its sounds are said again. Once every
## picture has its label, each is read aloud in turn.
##
## Config:
##   items: [String]          the names, e.g. ["bun", "jam", "egg"]
##   pictures: {item: icon}   Icon kind for each (default: the name)
##   mode: "first_sound" | "word"   (default "word")
##   extra: [String]          extra labels that name no picture here
## Feedback keys: "wrong", "all_good"; "{word}" becomes the label's word.
## Result: {"labels": [String]}

const SOUNDS := preload("res://scripts/activity/primitives/build_word.gd").SOUNDS
const PICTURE := Vector2(150, 150)

var items: Array[String] = []
var places: Array[DropSlot] = []
var labels: Array[DragPiece] = []
var _pictures: Array[Control] = []


func _build() -> void:
	for it: Variant in config.get("items", ["bun", "jam", "egg"]):
		items.append(str(it).to_lower())
	var gap := (BOARD_SIZE.x - 80) / items.size()
	for i in items.size():
		var x := 40 + gap * (i + 0.5)
		var pic := Control.new()
		pic.position = Vector2(x - PICTURE.x / 2.0, 40)
		pic.size = PICTURE
		pic.mouse_filter = Control.MOUSE_FILTER_STOP
		var word := items[i]
		pic.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
				AudioService.narrate(word, true))
		pic.draw.connect(func() -> void: _draw_picture(pic, word))
		add_child(pic)
		_pictures.append(pic)
		var place := DropSlot.create(_label_kind(word), _label_size(), {"word": word})
		place.show_outline = false
		place.set_center(Vector2(x, 240))
		add_child(place)
		places.append(place)
	var all: Array[String] = items.duplicate()
	for e: Variant in config.get("extra", []):
		all.append(str(e).to_lower())
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(all))
	for k in range(all.size() - 1, 0, -1):
		var j := rng.randi() % (k + 1)
		var tmp := all[k]
		all[k] = all[j]
		all[j] = tmp
	var tray_gap := minf(_label_size().x + 30, (BOARD_SIZE.x - 120) / all.size())
	var x0 := (BOARD_SIZE.x - tray_gap * all.size()) / 2.0 + tray_gap / 2.0
	for i in all.size():
		var p := DragPiece.create(_label_kind(all[i]), _label_size(), {"word": all[i]})
		p.home = Vector2(x0 + i * tray_gap, 450) - p.size / 2.0
		p.position = p.home
		p.dropped.connect(_on_dropped)
		p.grabbed.connect(_on_grabbed)
		p.tapped.connect(_say_label)
		add_child(p)
		labels.append(p)
	queue_redraw()


func first_sound_mode() -> bool:
	return str(config.get("mode", "word")) == "first_sound"


## A label's piece kind: a letter tile for its first sound, or a word card.
func _label_kind(word: String) -> String:
	return ("letter:" + word[0]) if first_sound_mode() else ("word:" + word)


func _label_size() -> Vector2:
	return Vector2(76, 88) if first_sound_mode() else Vector2(140, 64)


## What a label says when tapped: a letter's sound, or a word's sounds one by
## one (the child blends them; the whole word comes when it is placed).
func _say_label(p: DragPiece) -> void:
	var word := str(p.data["word"])
	if first_sound_mode():
		AudioService.narrate(_sound(word[0]), true)
	else:
		var parts: Array[String] = []
		for ch in word:
			parts.append(_sound(ch))
		AudioService.narrate(", ".join(parts), true)


func _sound(ch: String) -> String:
	return str(SOUNDS.get(ch, ch)).get_slice(",", 0)


func reset_step() -> void:
	for place in places:
		place.contents.clear()
		place.queue_redraw()
	for p in labels:
		p.placed_in = null
		p.draggable = true
		tween_to(p, p.home)
	prompt_changed.emit(tr(str(config.get("prompt", ""))))
	queue_redraw()


func show_hint() -> void:
	for i in places.size():
		if places[i].contents.is_empty():
			var word := items[i]
			if first_sound_mode():
				prompt_changed.emit(tr("Listen: %s. The first sound is \"%s\".") % [word, _sound(word[0])])
				AudioService.narrate("%s. %s" % [word, _sound(word[0])], true)
			else:
				prompt_changed.emit(tr("Listen: %s. Find the card that says %s.") % [word, word])
				AudioService.narrate(word, true)
			return


func supports_hint() -> bool:
	return true


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		(p.placed_in as DropSlot).take(p)
		queue_redraw()


func _on_dropped(p: DragPiece) -> void:
	var target: DropSlot = null
	for place in places:
		if place.near(p.center(), snap_tolerance * 0.6) and place.contents.is_empty():
			target = place
			break
	if target == null:
		tween_to(p, p.home)
		return
	if p.kind != target.accepts:
		observed.emit("mismatch", {"step": config.get("id", "")})
		var text := tr(str(config.get("feedback", {}).get("wrong", "Listen to the picture's name again. Does it start with that sound?" if first_sound_mode() else "That card says {word}. Which picture is that?")))
		prompt_changed.emit(text.replace("{word}", str(p.data["word"])))
		_say_label(p)
		reject(p, p.home)
		return
	target.put(p)
	p.draggable = false
	tween_to(p, target.position, 0.12)
	AudioService.play("place")
	var word := str(target.data["word"])
	AudioService.narrate(("%s... %s" % [_sound(word[0]), word]) if first_sound_mode() else word)
	queue_redraw()
	for place in places:
		if place.contents.is_empty():
			return
	_all_labelled()


func _all_labelled() -> void:
	say("all_good", "Every picture has its label.")
	AudioService.play("step")
	# Read the row back, left to right.
	AudioService.narrate(", ".join(items) + "!")
	finish({"labels": items.duplicate()})


func _draw() -> void:
	# The tray the labels wait in.
	BoardArt.wood_box(self, Rect2(60, 400, 880, 100))
	# Each empty label place: a blank card under its picture.
	for place in places:
		if place.contents.is_empty():
			var r := Rect2(place.position + Vector2(2, 2), place.size - Vector2(4, 4))
			draw_rect(r, Color(1, 1, 1, 0.12))
			draw_rect(r, Color(0.25, 0.18, 0.12, 0.55), false, 2.0)


func _draw_picture(pic: Control, word: String) -> void:
	var r := Rect2(Vector2.ZERO, pic.size)
	BoardArt._fill(pic, BoardArt._round_rect(r, 14), Color("fbf5e8"))
	Icon.draw(pic, str(config.get("pictures", {}).get(word, word)), r.grow(-22))
	Icon.draw(pic, "speaker", Rect2(Vector2(r.size.x - 34, 6), Vector2(28, 28)))
