extends ActivityStep
## Pouring primitive, after Montessori practical-life pouring: a jug and a
## row of glasses (or dishes), each with a line to fill to. Holding the jug
## over a glass tips it and pours; letting go stops. The child watches the
## water rise and stops at the line: control of movement, and judging an
## amount by eye.
##
## Control of error: the line is on the glass. Pour past it and the glass is
## too full (the extra shows above the line); tap the glass to pour it back
## into the jug and try again. Nothing is marked wrong.
##
## Config:
##   lines: [float]     fill line for each glass, 0..1 of its height (a glass
##                      per entry; default three at 0.6)
##   labels: [String]   optional word under each glass ("half", "full")
##   tolerance: float   how close to the line counts (default 0.06)
##   rate: float        how fast the jug pours, glass-heights per second
##                      (default 0.35)
##   liquid: "water" | "milk" | "grain"   (default "water")
## Feedback keys: "too_full", "just_right", "all_good".
## Result: {"glasses": int, "pour_backs": int}

const GLASS := Vector2(90, 150)
const BASE_Y := 420.0

var glasses: Array[Control] = []
var levels: Array[float] = []
var lines: Array[float] = []
var jug: DragPiece
var pour_backs := 0
var _pouring_into := -1
var _jug_home := Vector2(780, 250)


func _build() -> void:
	for l: Variant in config.get("lines", [0.6, 0.6, 0.6]):
		lines.append(float(l))
	var n := lines.size()
	var spread := 620.0 / n
	for i in n:
		var g := Control.new()
		g.size = GLASS
		g.position = Vector2(60 + spread * (i + 0.5) - GLASS.x / 2.0, BASE_Y - GLASS.y)
		g.mouse_filter = Control.MOUSE_FILTER_STOP
		var index := i
		g.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
				pour_back(index))
		add_child(g)
		glasses.append(g)
		levels.append(0.0)
	jug = DragPiece.create("jug", Vector2(120, 150))
	jug.home = _jug_home
	jug.position = jug.home
	jug.pivot_offset = Vector2(60, 75)
	jug.dropped.connect(func(_p: DragPiece) -> void: _stop_pouring())
	add_child(jug)
	queue_redraw()


func _liquid_color() -> Color:
	match str(config.get("liquid", "water")):
		"milk":
			return Color("f6f1e4")
		"grain":
			return Color("e0b45a")
	return Color(0.45, 0.68, 0.86, 0.85)


func _process(delta: float) -> void:
	super(delta)
	if is_done:
		return
	var over := -1
	if jug.dragging:
		# The spout is the jug's top-left corner: it pours into the glass below it.
		var spout := jug.position + Vector2(10, 20)
		for i in glasses.size():
			var g := glasses[i]
			if spout.x > g.position.x - 20 and spout.x < g.position.x + g.size.x + 20 and spout.y < g.position.y + 30 and spout.y > g.position.y - 160:
				over = i
				break
	if over != _pouring_into:
		_pouring_into = over
		jug.rotation = -0.7 if over >= 0 and not reduced_motion else 0.0
		if over >= 0:
			AudioService.play("place")
	if over >= 0:
		levels[over] = minf(levels[over] + float(config.get("rate", 0.35)) * delta, 1.0)
		queue_redraw()


func _stop_pouring() -> void:
	_pouring_into = -1
	jug.rotation = 0.0
	tween_to(jug, jug.home)
	_check()


## Tapping a glass pours what's in it back into the jug.
func pour_back(i: int) -> void:
	if is_done or levels[i] <= 0.0:
		return
	if absf(levels[i] - lines[i]) <= _tol():
		return # just right: leave it
	pour_backs += 1
	observed.emit("self_correction", {"step": config.get("id", "")})
	levels[i] = 0.0
	AudioService.play("return")
	prompt_changed.emit(tr("Poured back. Try again, and stop at the line."))
	queue_redraw()


func _tol() -> float:
	return float(config.get("tolerance", 0.06))


func is_right(i: int) -> bool:
	return absf(levels[i] - lines[i]) <= _tol()


func _check() -> void:
	var too_full := false
	for i in glasses.size():
		if levels[i] > lines[i] + _tol():
			too_full = true
	if too_full:
		say("too_full", "Oops, that glass is too full: the water is over the line. Tap the glass to pour it back.")
		return
	for i in glasses.size():
		if not is_right(i):
			if levels[i] > 0.0:
				say("not_yet", "Not quite to the line yet. Pour a little more.")
			return
	say("all_good", "Every glass is filled to its line, and not a drop spilled.")
	AudioService.play("step")
	finish({"glasses": glasses.size(), "pour_backs": pour_backs})


func reset_step() -> void:
	for i in levels.size():
		levels[i] = 0.0
	pour_backs = 0
	prompt_changed.emit(tr(str(config.get("prompt", ""))))
	queue_redraw()


func show_hint() -> void:
	for i in glasses.size():
		if not is_right(i):
			if levels[i] > lines[i]:
				prompt_changed.emit(tr("This glass is too full. Tap it to pour it back."))
			else:
				prompt_changed.emit(tr("Hold the jug over this glass. Watch the water, and let go when it reaches the line."))
			Sparkle.burst(self, glasses[i].position + Vector2(GLASS.x / 2.0, GLASS.y * (1.0 - lines[i])))
			return


func supports_hint() -> bool:
	return true


func _draw() -> void:
	# A tray under the glasses catches drips.
	BoardArt._fill(self, BoardArt._round_rect(Rect2(40, BASE_Y - 4, 680, 34), 10), Color("9c7049"))
	var font := UiStyle.font()
	var labels: Array = config.get("labels", [])
	for i in glasses.size():
		var r := Rect2(glasses[i].position, GLASS)
		# The liquid, then the glass over it.
		var h := r.size.y * levels[i]
		if h > 0.0:
			draw_rect(Rect2(r.position.x + 6, r.end.y - h, r.size.x - 12, h), _liquid_color())
		draw_rect(Rect2(r.position.x + 4, r.position.y, r.size.x - 8, r.size.y), Color(1, 1, 1, 0.18))
		draw_line(r.position + Vector2(4, 0), Vector2(r.position.x + 4, r.end.y), Color(1, 1, 1, 0.8), 3.0)
		draw_line(Vector2(r.end.x - 4, r.position.y), Vector2(r.end.x - 4, r.end.y), Color(1, 1, 1, 0.8), 3.0)
		draw_line(Vector2(r.position.x + 4, r.end.y), Vector2(r.end.x - 4, r.end.y), Color(1, 1, 1, 0.8), 3.0)
		# The line to fill to: a painted mark, green once the level is right.
		var ly := r.end.y - r.size.y * lines[i]
		draw_line(Vector2(r.position.x - 6, ly), Vector2(r.end.x + 6, ly), Color("4f7a3a") if is_right(i) else Color("b8392f"), 3.0)
		if levels[i] > lines[i] + _tol():
			# Too full: drips over the side.
			for k in 3:
				draw_circle(Vector2(r.end.x + 2, r.position.y + 20 + k * 22), 4, _liquid_color())
		if i < labels.size():
			draw_string(font, Vector2(r.position.x - 20, r.end.y + 48), tr(str(labels[i])), HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 40, 22, Color("3b3430"))
