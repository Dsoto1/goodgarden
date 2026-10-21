extends ActivityStep
## Measure primitive: a balance scale. A weight sits in one pan; the child
## adds scoops to the other until the beam hangs level. Heavier, lighter and
## "the same" are seen, not counted.
##
## Control of error: the beam itself tips toward the heavier side, so the
## child can see whether to add a scoop or take one out.
##
## Config:
##   weight: int            what the weight in the left pan weighs, in small scoops (default 4)
##   scoops: [{"kind": "flour_scoop", "weight": 1, "count": 3}, ...]
##                          the supply; big scoops weigh more, so the child may
##                          overshoot and take one out (default: weight + 2 small scoops)
##   weight_label, supply_label: text
## Feedback keys: "heavy" (too many), "all_good".
## Result: {"scoops": int}

const PIVOT := Vector2(500, 150)
const ARM := 210.0
const HANG := 150.0

var pan: DropSlot
var pieces: Array[DragPiece] = []
var _weight := 4
var _angle := 0.0
var _supply := Vector2(820, 470)
var _hinting := false


func _build() -> void:
	_weight = int(config.get("weight", 4))
	pan = DropSlot.create("scoop", Vector2(200, 120))
	pan.capacity = 99
	pan.show_outline = false
	pan.set_center(_pan_center(1.0, 0.0))
	add_child(pan)
	var specs: Array = config.get("scoops", [{"kind": "flour_scoop", "weight": 1, "count": _weight + 2}])
	var i := 0
	for spec: Dictionary in specs:
		for k in int(spec.get("count", 1)):
			var w := int(spec.get("weight", 1))
			var p := DragPiece.create(str(spec.get("kind", "flour_scoop")), Vector2(34, 28) * (1.0 + (w - 1) * 0.35))
			p.set_meta(&"weight", w)
			p.home = _supply + Vector2((i % 4 - 1.5) * 42.0, -22.0 + (i / 4) * 36.0) - p.size / 2.0
			i += 1
			p.position = p.home
			p.dropped.connect(_on_dropped)
			p.grabbed.connect(_on_grabbed)
			add_child(p)
			pieces.append(p)
	set_process(true)
	queue_redraw()


## Where a pan hangs, for side -1 (left) or 1 (right), with the beam at `angle`.
func _pan_center(side: float, angle: float) -> Vector2:
	return PIVOT + Vector2(side * ARM, 0).rotated(angle) + Vector2(0, HANG)


## What is in the pan, in small scoops.
func load_weight() -> int:
	var w := 0
	for p in pan.contents:
		w += int(p.get_meta(&"weight", 1))
	return w


func _target_angle() -> float:
	# Positive turns the beam clockwise: the right (scoop) side goes down.
	return clampf((load_weight() - _weight) * 0.07, -0.28, 0.28)


func _process(delta: float) -> void:
	var goal := _target_angle()
	if absf(goal - _angle) < 0.001:
		return
	_angle = goal if reduced_motion else lerpf(_angle, goal, minf(delta * 5.0, 1.0))
	pan.set_center(_pan_center(1.0, _angle))
	_layout()
	queue_redraw()


func reset_step() -> void:
	pan.contents.clear()
	for p in pieces:
		p.placed_in = null
		tween_to(p, p.home)
	prompt_changed.emit(tr(str(config.get("prompt", ""))))
	queue_redraw()


func show_hint() -> void:
	super.show_hint()
	_hinting = true
	queue_redraw()


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in == pan:
		pan.take(p)
		_layout()


func _on_dropped(p: DragPiece) -> void:
	if not pan.near(p.center(), snap_tolerance * 0.6):
		tween_to(p, p.home)
		return
	pan.put(p)
	AudioService.play("place")
	_hinting = false
	_layout()
	var n := load_weight()
	if n == _weight:
		for q in pieces:
			q.draggable = false
		say("all_good", "The beam is level. Both sides weigh the same!")
		AudioService.play("step")
		finish({"scoops": pan.contents.size()})
	elif n > _weight:
		observed.emit("overfilled", {"step": config.get("id", "")})
		say("heavy", "Now the scoop side is lower. It's too heavy. Take one out.")
	queue_redraw()


func _layout() -> void:
	var c := pan.center()
	for i in pan.contents.size():
		var spot := c + Vector2((i % 4 - 1.5) * 40.0, -30.0 - (i / 4) * 30.0)
		pan.contents[i].position = spot - pan.contents[i].size / 2.0


func _draw() -> void:
	var font := UiStyle.font()
	var wood := Color("8a5a3a")
	# The stand and the beam.
	draw_rect(Rect2(PIVOT + Vector2(-10, 0), Vector2(20, 330)), wood)
	draw_rect(Rect2(PIVOT + Vector2(-80, 320), Vector2(160, 22)), wood)
	var left := PIVOT + Vector2(-ARM, 0).rotated(_angle)
	var right := PIVOT + Vector2(ARM, 0).rotated(_angle)
	draw_line(left, right, Color("6b4630"), 12.0)
	draw_circle(PIVOT, 14, Color("e0a73a"))
	# A pointer that hangs straight down only when the beam is level.
	draw_line(PIVOT, PIVOT + Vector2(0, 70).rotated(_angle), Color("3b3430"), 4.0)
	draw_line(PIVOT + Vector2(-16, 74), PIVOT + Vector2(16, 74), Color("f3e6d2"), 3.0)
	for side: float in [-1.0, 1.0]:
		var top := left if side < 0 else right
		var c := _pan_center(side, _angle)
		for dx: float in [-80.0, 80.0]:
			draw_line(top, c + Vector2(dx, 0), Color("c9b38a"), 2.0)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-95, 0), c + Vector2(95, 0), c + Vector2(70, 26), c + Vector2(-70, 26)]), Color("c9a874"))
	# The weight: a stone with dots, one for each scoop it balances.
	var lc := _pan_center(-1.0, _angle)
	var stone := Rect2(lc + Vector2(-60, -70), Vector2(120, 70))
	draw_rect(stone, Color("9a958c"))
	draw_rect(stone, Color("6c675f"), false, 3.0)
	for i in _weight:
		draw_circle(stone.get_center() + Vector2((i - (_weight - 1) / 2.0) * 22.0, 0), 7, Color("f3e6d2"))
	draw_string(font, lc + Vector2(-100, 60), tr(str(config.get("weight_label", "the stone"))), HORIZONTAL_ALIGNMENT_CENTER, 200, 18, Color("f3e6d2"))
	# The supply: an open flour sack.
	draw_rect(Rect2(_supply + Vector2(-90, -55), Vector2(180, 110)), Color("efe4cf"))
	draw_rect(Rect2(_supply + Vector2(-90, -55), Vector2(180, 110)), Color("b9a07a"), false, 3.0)
	draw_string(font, _supply + Vector2(-100, 80), tr(str(config.get("supply_label", "flour"))), HORIZONTAL_ALIGNMENT_CENTER, 200, 18, Color("f3e6d2"))
	if _hinting:
		draw_arc(_pan_center(1.0, _angle) + Vector2(0, -20), 110, 0, TAU, 32, Color(1, 0.95, 0.7), 4.0)
