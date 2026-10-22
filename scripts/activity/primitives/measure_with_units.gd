extends ActivityStep
## Measure-and-compare primitive: a few things of different heights (bean
## plants) stand in a row, each with a column beside it, and a box of equal
## wooden blocks waits to the side. The child stacks blocks beside each one
## until the stack is as tall as it is, so its height becomes a number of
## blocks: measuring with a unit before a ruler. Then they compare.
##
## Control of error: a block that would make a stack taller than its plant
## won't stay; it slides back, and the stack and the plant's top can be seen
## side by side.
##
## Config:
##   heights: [int]       each plant's height, in blocks
##   unit: float          block size in board units (default 40)
##   question: "tallest" (tap the tallest plant; default) or "difference"
##                        (how many blocks taller is the tallest than the
##                        shortest? answered with number buttons)
##   spare: int           extra blocks in the box (default 2)
## Feedback keys: "too_tall", "measured", "wrong_tallest", "wrong_difference",
## "all_good"; "{n}" becomes a count.
## Result: {"heights": [int], "tallest": int (index), "difference": int}

const BASE_Y := 450.0
const BOX := Rect2(820, 120, 150, 330)

var heights: Array[int] = []
var columns: Array[DropSlot] = []
var blocks: Array[DragPiece] = []
var measured := false
var _unit := 40.0
var _plants: Array[Control] = []


func _build() -> void:
	for h: Variant in config.get("heights", [3, 5, 4]):
		heights.append(int(h))
	_unit = float(config.get("unit", 40.0))
	var n := heights.size()
	var spread := 700.0 / n
	for i in n:
		var x := 60.0 + spread * (i + 0.5)
		# The plant, tappable once it is time to compare.
		var plant := Control.new()
		plant.position = Vector2(x - 50, BASE_Y - heights[i] * _unit - 30)
		plant.size = Vector2(70, heights[i] * _unit + 30)
		plant.mouse_filter = Control.MOUSE_FILTER_STOP
		var index := i
		plant.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
				choose_tallest(index))
		add_child(plant)
		_plants.append(plant)
		var col := DropSlot.create("unit_block", Vector2(_unit + 8, heights[i] * _unit), {"index": i})
		col.capacity = heights[i]
		col.show_outline = false
		col.position = Vector2(x + 26, BASE_Y - heights[i] * _unit)
		add_child(col)
		columns.append(col)
	var total := 0
	for h in heights:
		total += h
	total += int(config.get("spare", 2))
	for i in total:
		var b := DragPiece.create("unit_block", Vector2(_unit, _unit))
		var per_row := maxi(1, int((BOX.size.x - 20) / (_unit + 6)))
		b.home = BOX.position + Vector2(12 + (i % per_row) * (_unit + 6), BOX.size.y - 14 - _unit - (i / per_row) * (_unit + 4))
		b.position = b.home
		b.dropped.connect(_on_dropped)
		b.grabbed.connect(_on_grabbed)
		add_child(b)
		blocks.append(b)
	queue_redraw()


func reset_step() -> void:
	if measured:
		return
	for col in columns:
		col.contents.clear()
	for b in blocks:
		b.placed_in = null
		tween_to(b, b.home)
	prompt_changed.emit(tr(str(config.get("prompt", ""))))
	queue_redraw()


func show_hint() -> void:
	if measured:
		if str(config.get("question", "tallest")) == "tallest":
			prompt_changed.emit(tr("Look at the numbers on the stacks. Which number is the biggest?"))
		else:
			prompt_changed.emit(tr("Count the blocks the tallest stack has more than the shortest one."))
		return
	for col in columns:
		if not col.is_full():
			prompt_changed.emit(tr("Put a block on this stack. Is it as tall as the plant yet?"))
			Sparkle.burst(self, col.position + Vector2(col.size.x / 2.0, col.size.y - col.contents.size() * _unit - _unit / 2.0))
			return


func supports_reset() -> bool:
	return not measured


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		# Only the top block of a stack can be lifted off.
		var col: DropSlot = p.placed_in
		if col.contents.back() != p:
			return
		col.take(p)
		queue_redraw()


func _on_dropped(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		_lay_stack(p.placed_in)
		return
	var target: DropSlot = null
	for col in columns:
		if col.near(p.center(), snap_tolerance * 0.6):
			target = col
			break
	if target == null:
		tween_to(p, p.home)
		return
	if target.is_full():
		observed.emit("overfilled", {"step": config.get("id", "")})
		say_n("too_tall", "That stack is already as tall as the plant. One more block would be taller!", target.capacity)
		reject(p, p.home)
		return
	target.put(p)
	AudioService.play("place")
	AudioService.narrate(_count_word(target.contents.size()))
	_lay_stack(target)
	queue_redraw()
	if target.is_full():
		say_n("measured", "This plant is {n} blocks tall.", target.capacity)
	for col in columns:
		if not col.is_full():
			return
	_all_measured()


## Blocks sit one on another, from the soil up.
func _lay_stack(col: DropSlot) -> void:
	for k in col.contents.size():
		tween_to(col.contents[k], Vector2(col.position.x + 4, BASE_Y - (k + 1) * _unit), 0.12)


func _all_measured() -> void:
	measured = true
	for b in blocks:
		b.draggable = false
	queue_redraw()
	if str(config.get("question", "tallest")) == "tallest":
		prompt_changed.emit(tr(str(config.get("ask_tallest", "Every plant is measured. Which one is the tallest? Tap it."))))
	else:
		var answer := tallest_height() - shortest_height()
		prompt_changed.emit(tr(str(config.get("ask_difference", "How many blocks taller is the tallest plant than the shortest one?"))))
		var choices: Array[int] = [answer]
		for d: int in [-1, 1, 2, -2]:
			if choices.size() < 4 and answer + d > 0 and not answer + d in choices:
				choices.append(answer + d)
		choices.sort()
		var actions: Array = []
		for c in choices:
			actions.append({"label": str(c), "callback": func() -> void: answer_difference(c)})
		actions_changed.emit(actions)


func tallest_height() -> int:
	return heights.max()


func shortest_height() -> int:
	return heights.min()


## The child taps a plant they think is tallest.
func choose_tallest(index: int) -> void:
	if not measured or is_done or str(config.get("question", "tallest")) != "tallest":
		return
	if heights[index] == tallest_height():
		_done()
	else:
		observed.emit("compare_retry", {"step": config.get("id", "")})
		say_n("wrong_tallest", "That one is {n} blocks tall. Is there a stack with more blocks?", heights[index])


func answer_difference(n: int) -> void:
	if not measured or is_done:
		return
	if n == tallest_height() - shortest_height():
		actions_changed.emit([])
		_done()
	else:
		observed.emit("compare_retry", {"step": config.get("id", "")})
		say_n("wrong_difference", "Not quite. The tallest has {n} blocks. How many more is that than the shortest?", tallest_height())


func _done() -> void:
	say("all_good", "Yes! You measured every plant and compared them.")
	AudioService.play("step")
	finish({"heights": heights.duplicate(), "tallest": heights.find(tallest_height()), "difference": tallest_height() - shortest_height()})


func say_n(key: String, fallback: String, n: int) -> void:
	prompt_changed.emit(tr(str(config.get("feedback", {}).get(key, fallback))).replace("{n}", str(n)))


func _count_word(n: int) -> String:
	var words := ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"]
	return tr(words[n]) if n < words.size() else str(n)


func _draw() -> void:
	BoardArt.soil_row(self, Rect2(30, BASE_Y - 6, 770, 60))
	BoardArt.wood_box(self, BOX)
	var font := UiStyle.font()
	for i in heights.size():
		var col := columns[i]
		var x := col.position.x - 26
		_bean_plant(Vector2(x, BASE_Y), heights[i] * _unit)
		# Where the stack goes: a faint dashed column beside the plant.
		if not col.is_full():
			var r := Rect2(col.position + Vector2(2, 0), Vector2(_unit, col.size.y))
			var y := r.position.y
			while y < r.end.y:
				for edge: float in [r.position.x, r.end.x]:
					draw_line(Vector2(edge, y), Vector2(edge, minf(y + 8, r.end.y)), Color(0.25, 0.18, 0.12, 0.35), 2.0)
				y += 14
			draw_line(Vector2(r.position.x, BASE_Y), Vector2(r.end.x, BASE_Y), Color(0.25, 0.18, 0.12, 0.5), 2.0)
		if col.is_full():
			var tag := Vector2(col.position.x + col.size.x / 2.0, BASE_Y - heights[i] * _unit - 22)
			draw_circle(tag, 18, Color("fbf5e8"))
			draw_arc(tag, 18, 0, TAU, 24, Color("8a5a3a"), 2.0)
			draw_string(font, tag + Vector2(-18, 9), str(heights[i]), HORIZONTAL_ALIGNMENT_CENTER, 36, 26, Color("3b3430"))


## A bean plant of height `h` (board units) climbing a cane from the soil.
func _bean_plant(base: Vector2, h: float) -> void:
	var top := base + Vector2(0, -h)
	draw_line(base + Vector2(-6, 0), top + Vector2(-6, -4), Color("b08a5a"), 4.0)
	var stem := PackedVector2Array()
	for k in 13:
		var t := k / 12.0
		stem.append(base.lerp(top, t) + Vector2(sin(t * 9.0) * 6.0, 0))
	draw_polyline(stem, Color("5f8a3f"), 5.0)
	var leaves := int(h / 34.0) + 1
	for k in leaves:
		var at := base.lerp(top, (k + 0.6) / (leaves + 0.4))
		var side := -1.0 if k % 2 == 0 else 1.0
		var leaf := PackedVector2Array()
		for j in 9:
			var a := TAU * j / 9.0
			leaf.append(at + Vector2(side * 16 + cos(a) * 15, sin(a) * 8))
		draw_colored_polygon(leaf, Color("7fb04a"))
	draw_circle(top, 5, Color("7fb04a"))
