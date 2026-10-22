extends ActivityStep
## Observe-and-record primitive: a nature notebook. A picture (a bean leaf
## with a ladybird and an ant) has details too small to see at a glance; a
## magnifying glass shows them close up wherever the child moves it. Each
## question asks them to look for something and count it, and each answer is
## written into the notebook page beside the picture.
##
## Control of error: the details are really there under the glass; a wrong
## count is met with "Look again", not a mark.
##
## Config:
##   questions: [{"ask": String, "about": "spots"|"legs", "choices": [int]}]
##   spots: int        the ladybird's spots (default 5)
## The ant always has six legs. Feedback keys: "look_again", "noted",
## "all_good".
## Result: {"notes": [{"about": String, "count": int}]}

const PICTURE := Rect2(40, 30, 560, 380)
const LENS_R := 80.0
const ZOOM := 3.2
const LADYBIRD := Vector2(330, 190) # in picture space (board units)
const ANT := Vector2(470, 300)

var questions: Array = []
var question_index := -1
var notes: Array[Dictionary] = []
var lens: DragPiece
var _view: Control
var _zoom: Control


func _build() -> void:
	questions = config.get("questions", [{"ask": "How many spots does the ladybird have?", "about": "spots", "choices": [3, 4, 5, 6]}])
	_view = Control.new()
	_view.size = Vector2(LENS_R * 2, LENS_R * 2)
	_view.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(func() -> void: _view.draw_circle(_view.size / 2.0, LENS_R, Color.WHITE))
	add_child(_view)
	_zoom = Control.new()
	_zoom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_zoom.draw.connect(_draw_zoomed)
	_view.add_child(_zoom)
	lens = DragPiece.create("lens", Vector2(LENS_R * 2 + 20, LENS_R * 2 + 70))
	lens.home = Vector2(640, 260)
	lens.position = lens.home
	add_child(lens)
	_next_question()


func answer_of(about: String) -> int:
	return 6 if about == "legs" else int(config.get("spots", 5))


func _next_question() -> void:
	question_index += 1
	queue_redraw()
	if question_index >= questions.size():
		say("all_good", "Your notebook page is full of things you noticed.")
		AudioService.play("step")
		actions_changed.emit([])
		finish({"notes": notes.duplicate()})
		return
	var q: Dictionary = questions[question_index]
	prompt_changed.emit(tr(str(q["ask"])) + " " + tr("Move the magnifying glass to look closely."))
	var actions: Array = []
	for c: Variant in q.get("choices", []):
		var n := int(c)
		actions.append({"label": str(n), "callback": func() -> void: choose(n)})
	actions_changed.emit(actions)


## The child picks a count.
func choose(n: int) -> void:
	if is_done or question_index >= questions.size():
		return
	var q: Dictionary = questions[question_index]
	var about := str(q["about"])
	if n != answer_of(about):
		observed.emit("look_again", {"step": config.get("id", "")})
		say("look_again", "Look again, slowly, with the glass. Count each one as you see it.")
		return
	notes.append({"about": about, "count": n})
	AudioService.play("place")
	prompt_changed.emit(tr(str(config.get("feedback", {}).get("noted", "Yes, {n}! I'll write that in the notebook."))).replace("{n}", str(n)))
	actions_changed.emit([])
	await get_tree().create_timer(1.6).timeout
	if is_inside_tree():
		_next_question()


func _process(delta: float) -> void:
	super(delta)
	# The view follows the glass: it shows the picture magnified about its centre.
	var centre := lens.position + Vector2(LENS_R + 10, LENS_R + 10)
	_view.position = centre - Vector2(LENS_R, LENS_R)
	_zoom.position = Vector2.ZERO
	_zoom.size = _view.size
	_zoom.set_meta(&"centre", centre)
	_zoom.queue_redraw()


func reset_step() -> void:
	tween_to(lens, lens.home)


func show_hint() -> void:
	if question_index < questions.size():
		var about := str(questions[question_index]["about"])
		var target := LADYBIRD if about == "spots" else ANT
		tween_to(lens, PICTURE.position + target - Vector2(LENS_R + 10, LENS_R + 10))
		prompt_changed.emit(tr("Here, look through the glass. Count slowly."))


func supports_hint() -> bool:
	return true


func supports_reset() -> bool:
	return false


func _draw() -> void:
	_draw_scene(self, PICTURE.position, 1.0)
	# The notebook page: what has been noticed so far.
	var page := Rect2(620, 30, 340, 200)
	draw_rect(page, Color("fbf5e8"))
	draw_rect(page, Color("c9a86e"), false, 2.0)
	for k in 6:
		draw_line(Vector2(page.position.x + 14, page.position.y + 56 + k * 26), Vector2(page.end.x - 14, page.position.y + 56 + k * 26), Color(0.4, 0.55, 0.75, 0.3), 1.0)
	var font := UiStyle.font()
	draw_string(font, page.position + Vector2(14, 34), tr("My nature notebook"), HORIZONTAL_ALIGNMENT_LEFT, page.size.x - 28, 22, Color("7a4a26"))
	for i in notes.size():
		var n := notes[i]
		var line := tr("The ladybird has %d spots.") % n["count"] if n["about"] == "spots" else tr("The ant has %d legs.") % n["count"]
		draw_string(font, page.position + Vector2(14, 76 + i * 26), line, HORIZONTAL_ALIGNMENT_LEFT, page.size.x - 28, 20, Color("3b3430"))


func _draw_zoomed() -> void:
	var centre: Vector2 = _zoom.get_meta(&"centre", Vector2.ZERO)
	# Picture point under the glass's centre ends up at the view's centre.
	var origin := _view.size / 2.0 - (centre - PICTURE.position) * ZOOM
	_zoom.draw_rect(Rect2(Vector2.ZERO, _view.size), Color("e8f0d8"))
	_draw_scene(_zoom, origin, ZOOM)


## The bean leaf, the ladybird and the ant, drawn at scale `k` with the
## picture's top-left at `at`. At scale 1 the spots and legs are tiny; under
## the glass they are clear.
func _draw_scene(ci: CanvasItem, at: Vector2, k: float) -> void:
	var p := func(v: Vector2) -> Vector2: return at + v * k
	if k == 1.0:
		BoardArt._fill(ci, BoardArt._round_rect(Rect2(at, PICTURE.size), 16), Color("e8f0d8"))
	# The leaf: a broad heart shape with a midrib and veins.
	var leaf := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		var r := 1.0 - 0.35 * pow(maxf(0.0, -sin(a)), 3.0)
		leaf.append(p.call(Vector2(280, 200) + Vector2(cos(a) * 230 * r, sin(a) * 160 * r)))
	ci.draw_colored_polygon(leaf, Color("7fb04a"))
	ci.draw_line(p.call(Vector2(60, 200)), p.call(Vector2(510, 200)), Color("5f8a3f"), 3.0 * k)
	for v in 6:
		var x := 120 + v * 65
		ci.draw_line(p.call(Vector2(x, 200)), p.call(Vector2(x + 40, 110 + (v % 2) * 20)), Color("6a9a45"), 2.0 * k)
		ci.draw_line(p.call(Vector2(x, 200)), p.call(Vector2(x + 40, 290 - (v % 2) * 20)), Color("6a9a45"), 2.0 * k)
	# The ladybird: red shell, black head, tiny black spots.
	ci.draw_circle(p.call(LADYBIRD), 11 * k, Color("c8322a"))
	ci.draw_circle(p.call(LADYBIRD + Vector2(-11, 0)), 5 * k, Color("2a2420"))
	ci.draw_line(p.call(LADYBIRD + Vector2(-7, 0)), p.call(LADYBIRD + Vector2(11, 0)), Color("2a2420"), maxf(0.5, 0.6 * k))
	var spots := int(config.get("spots", 5))
	for i in spots:
		var a := TAU * i / spots + 0.4
		ci.draw_circle(p.call(LADYBIRD + Vector2(cos(a) * 6 + 1, sin(a) * 6)), 1.3 * k, Color("2a2420"))
	# The ant: three body parts and six thin legs.
	for part: Array in [[Vector2(-7, 0), 3.0], [Vector2(0, 0), 2.2], [Vector2(6, 0), 2.6]]:
		ci.draw_circle(p.call(ANT + part[0]), float(part[1]) * k, Color("3a2a22"))
	for leg in 3:
		for side: float in [-1.0, 1.0]:
			var from := ANT + Vector2(-2 + leg * 2, 0)
			ci.draw_line(p.call(from), p.call(from + Vector2(-3 + leg * 3, side * 6)), Color("3a2a22"), maxf(0.4, 0.5 * k))
