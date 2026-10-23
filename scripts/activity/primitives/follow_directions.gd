extends ActivityStep
## Map primitive: a squared map of the valley with landmarks drawn in (home,
## the mill, the chapel...) and a little walker. Each direction ("Go 3
## squares east") is read aloud; the child moves the walker square by square
## and sets it down where the direction ends. Younger children see an arrow
## and dots with each direction; older ones read compass words alone.
##
## Control of error: the walker only stays where the direction ends. Set
## down anywhere else, it hops back to where it started that direction, and
## the child is told which way, or how many squares, to look at again.
##
## Config:
##   grid: [cols, rows]                 (default [8, 5])
##   places: [{"icon": String, "at": [c, r], "name": String}]
##   start: [c, r]
##   steps: [{"dir": "north"|"south"|"east"|"west", "n": int}]
##   arrows: bool                       arrows and dots with each direction (default true)
## Feedback keys: "wrong_way", "count_again", "arrived", "all_good"; "{place}"
## is the landmark where the walk ends.
## Result: {"steps": int, "end": [c, r]}

const CELL := 80.0
const DIRS := {"north": Vector2i(0, -1), "south": Vector2i(0, 1), "east": Vector2i(1, 0), "west": Vector2i(-1, 0)}

var grid := Vector2i(8, 5)
var origin := Vector2.ZERO
var walker: DragPiece
var at := Vector2i.ZERO
var step_index := -1
var steps: Array = []
var _trail: Array[Vector2i] = []


func _build() -> void:
	var g: Array = config.get("grid", [8, 5])
	grid = Vector2i(int(g[0]), int(g[1]))
	origin = Vector2(maxf(30.0, (BOARD_SIZE.x - grid.x * CELL) / 2.0 - 100), 40)
	steps = config.get("steps", [])
	var s: Array = config.get("start", [0, 0])
	at = Vector2i(int(s[0]), int(s[1]))
	_trail.append(at)
	walker = DragPiece.create("figure:child", Vector2(44, 58), {"shape": "child", "color": "cloth_red"})
	walker.position = cell_center(at) - walker.size / 2.0
	walker.home = walker.position
	walker.dropped.connect(_on_dropped)
	walker.tapped.connect(func(_p: DragPiece) -> void: _say_step())
	add_child(walker)
	_next_step()


func cell_center(c: Vector2i) -> Vector2:
	return origin + (Vector2(c) + Vector2(0.5, 0.5)) * CELL


func cell_at(point: Vector2) -> Vector2i:
	var c := ((point - origin) / CELL).floor()
	return Vector2i(clampi(int(c.x), 0, grid.x - 1), clampi(int(c.y), 0, grid.y - 1))


func target() -> Vector2i:
	if step_index < 0 or step_index >= steps.size():
		return at
	var st: Dictionary = steps[step_index]
	return at + DIRS[str(st["dir"])] * int(st["n"])


func direction_text(i: int) -> String:
	var st: Dictionary = steps[i]
	var n := int(st["n"])
	return tr("Go %d %s %s.") % [n, tr("square") if n == 1 else tr("squares"), tr(str(st["dir"]))]


func place_at(c: Vector2i) -> String:
	for p: Dictionary in config.get("places", []):
		if Vector2i(int(p["at"][0]), int(p["at"][1])) == c:
			return tr(str(p.get("name", p["icon"])))
	return ""


func _next_step() -> void:
	step_index += 1
	queue_redraw()
	if step_index >= steps.size():
		var place := place_at(at)
		prompt_changed.emit(tr(str(config.get("feedback", {}).get("all_good", "You followed every direction. You're at the {place}!"))).replace("{place}", place))
		AudioService.play("step")
		walker.draggable = false
		finish({"steps": steps.size(), "end": [at.x, at.y]})
		return
	_say_step()


func _say_step() -> void:
	if step_index >= steps.size():
		return
	var text := direction_text(step_index)
	prompt_changed.emit(text + " " + tr("Move the walker, one square at a time."))
	AudioService.narrate(text, true)


func _on_dropped(p: DragPiece) -> void:
	var c := cell_at(p.center())
	var goal := target()
	if c == goal:
		at = c
		_trail.append(at)
		tween_to(p, cell_center(at) - p.size / 2.0, 0.12)
		AudioService.play("place")
		var place := place_at(at)
		if not place.is_empty() and step_index < steps.size() - 1:
			prompt_changed.emit(tr(str(config.get("feedback", {}).get("arrived", "Here's the {place}."))).replace("{place}", place))
		_next_step()
		return
	observed.emit("mismatch", {"step": config.get("id", "")})
	var d: Vector2i = DIRS[str(steps[step_index]["dir"])]
	var moved := c - at
	var along := moved.x * d.x + moved.y * d.y
	var across := absi(moved.x * d.y) + absi(moved.y * d.x)
	if across == 0 and along > 0:
		say("count_again", "Right way! Now count the squares again, one at a time.")
	else:
		say("wrong_way", "Look at which way to go. Which way is %s on the map?" % tr(str(steps[step_index]["dir"])))
	reject(p, cell_center(at) - p.size / 2.0)


func reset_step() -> void:
	at = _trail[0]
	_trail = [at]
	step_index = -1
	walker.draggable = true
	walker.position = cell_center(at) - walker.size / 2.0
	_next_step()


func show_hint() -> void:
	if step_index < steps.size():
		Sparkle.burst(self, cell_center(target()))
		prompt_changed.emit(tr("Count with me, one square at a time... it's here."))


func supports_hint() -> bool:
	return true


func _draw() -> void:
	# The parchment map and its squares.
	var map := Rect2(origin, Vector2(grid) * CELL)
	BoardArt._fill(self, BoardArt._round_rect(map.grow(16), 10), Color("efe2c2"))
	for x in grid.x + 1:
		draw_line(origin + Vector2(x * CELL, 0), origin + Vector2(x * CELL, map.size.y), Color(0.55, 0.42, 0.25, 0.35), 1.5)
	for y in grid.y + 1:
		draw_line(origin + Vector2(0, y * CELL), origin + Vector2(map.size.x, y * CELL), Color(0.55, 0.42, 0.25, 0.35), 1.5)
	# The way walked so far, as footprints.
	for i in range(1, _trail.size()):
		draw_line(cell_center(_trail[i - 1]), cell_center(_trail[i]), Color("8a5a3a"), 4.0)
	var font := UiStyle.font()
	for p: Dictionary in config.get("places", []):
		var c := Vector2i(int(p["at"][0]), int(p["at"][1]))
		var r := Rect2(origin + Vector2(c) * CELL + Vector2(14, 4), Vector2(CELL - 28, CELL - 28))
		Icon.draw(self, str(p["icon"]), r)
		draw_string(font, origin + Vector2(c) * CELL + Vector2(-6, CELL - 6), tr(str(p.get("name", ""))), HORIZONTAL_ALIGNMENT_CENTER, CELL + 12, 16, Color("5a3d28"))
	# A compass rose: north is always up.
	var rose := Vector2(map.end.x + 100, origin.y + 80)
	for k: Array in [["N", Vector2(0, -1)], ["S", Vector2(0, 1)], ["E", Vector2(1, 0)], ["W", Vector2(-1, 0)]]:
		var v: Vector2 = k[1]
		draw_colored_polygon(PackedVector2Array([rose + v * 46, rose + v.orthogonal() * 9, rose - v.orthogonal() * 9]), Color("b8392f") if k[0] == "N" else Color("8a5a3a"))
		draw_string(font, rose + v * 66 + Vector2(-10, 9), str(k[0]), HORIZONTAL_ALIGNMENT_CENTER, 20, 24, Color("3b3430"))
	# The direction now: an arrow and a dot for each square (younger).
	if step_index >= 0 and step_index < steps.size() and config.get("arrows", true):
		var st: Dictionary = steps[step_index]
		var d := Vector2(DIRS[str(st["dir"])])
		var box := Vector2(map.end.x + 100, origin.y + 250)
		draw_colored_polygon(PackedVector2Array([box + d * 40, box + d.orthogonal() * 24 - d * 6, box - d.orthogonal() * 24 - d * 6]), Color("4f7a3a"))
		draw_line(box - d * 40, box, Color("4f7a3a"), 12.0)
		for k in int(st["n"]):
			draw_circle(Vector2(box.x - 60 + (k % 5) * 30, box.y + 70 + (k / 5) * 26), 9, Color("b8392f"))
