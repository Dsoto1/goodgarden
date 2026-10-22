class_name DragPiece
extends Control
## A concrete material the child can pick up and move: a seed, a peg, a plate,
## a wooden figure. Works the same for mouse and touch (touch arrives as
## emulated mouse events). The owning step decides what a drop means.

signal grabbed(piece: DragPiece)
signal dropped(piece: DragPiece)
## Pressed and released without moving: used to lay figures down / stand them up.
signal tapped(piece: DragPiece)

var kind := ""
## Extra drawing data (label, color) for PieceArt.
var data: Dictionary = {}
var draggable := true
var dragging := false
## Where the piece rests when not placed; steps update this.
var home := Vector2.ZERO
## Whatever slot/hole the piece currently sits in, if any.
var placed_in: Variant = null
var lying := false

var _grab_offset := Vector2.ZERO
var _press_pos := Vector2.ZERO
var _press_position := Vector2.ZERO
var _moved := false

## Small pieces (a seed, a fork) can be picked up from a little around them:
## at least this many board units across, for small fingers.
const MIN_TOUCH := 64.0
## A press that moves less than this (in pixels) is a tap, not a drag.
const TAP_SLOP := 16.0


static func create(piece_kind: String, piece_size: Vector2, piece_data: Dictionary = {}) -> DragPiece:
	var p := DragPiece.new()
	p.kind = piece_kind
	p.data = piece_data
	p.size = piece_size
	p.pivot_offset = piece_size / 2.0
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return p


func center() -> Vector2:
	return position + size / 2.0


func set_center(c: Vector2) -> void:
	position = c - size / 2.0


func set_lying(value: bool) -> void:
	lying = value
	rotation = PI / 2.0 if lying else 0.0


func _has_point(point: Vector2) -> bool:
	var grow := (Vector2(MIN_TOUCH, MIN_TOUCH) - size).max(Vector2.ZERO) / 2.0
	return Rect2(-grow, size + grow * 2.0).has_point(point)


func _draw() -> void:
	# A soft shadow on the table; it grows and drifts while the piece is lifted.
	# Felt figures lie flat on the felt, so they only cast one while held.
	if kind.begins_with("figure:") and not dragging:
		PieceArt.draw(self, kind, size, false, data)
		return
	var foot := size.y * (0.8 if not str(data.get("label", "")).is_empty() else 0.9)
	var lift := 7.0 if dragging else 0.0
	var r := Vector2(size.x * 0.42, maxf(4.0, size.y * 0.1)) * (1.15 if dragging else 1.0)
	var shadow := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		shadow.append(Vector2(size.x / 2.0 + lift * 0.6 + cos(a) * r.x, foot + lift + sin(a) * r.y))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.12 if dragging else 0.18))
	PieceArt.draw(self, kind, size, false, data)


## A little lift when picked up, and a settle when set down.
func _lift(up: bool) -> void:
	var goal := Vector2.ONE * (1.08 if up else 1.0)
	if Settings.get_value("reduced_motion"):
		scale = goal
	else:
		create_tween().tween_property(self, "scale", goal, 0.1)
	queue_redraw()


## A small bounce when a piece lands in its place.
func settle() -> void:
	if Settings.get_value("reduced_motion"):
		return
	scale = Vector2.ONE * 1.14
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _gui_input(event: InputEvent) -> void:
	if not draggable:
		return
	# Positions come from the event (not the hardware mouse) so touch, mouse and
	# the gamepad's virtual cursor all drive pieces the same way.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			_moved = false
			_press_pos = event.global_position
			_press_position = position
			_grab_offset = _to_parent(event.global_position) - position
			z_index = 10
			move_to_front()
			_lift(true)
			AudioService.play("place")
			grabbed.emit(self)
		elif dragging:
			dragging = false
			z_index = 0
			_lift(false)
			if _moved:
				dropped.emit(self)
			else:
				# A tap that wobbled a little doesn't nudge the piece.
				position = _press_position
				tapped.emit(self)
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		if event.global_position.distance_to(_press_pos) > TAP_SLOP:
			_moved = true
		var parent_size: Vector2 = get_parent().size if get_parent() is Control else ActivityStep.BOARD_SIZE
		var p: Vector2 = _to_parent(event.global_position) - _grab_offset
		position = p.clamp(-size / 2.0, parent_size - size / 2.0)
		accept_event()


func _to_parent(viewport_point: Vector2) -> Vector2:
	return (get_parent() as CanvasItem).get_global_transform_with_canvas().affine_inverse() * viewport_point
