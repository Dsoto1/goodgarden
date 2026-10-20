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
var _moved := false


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


func _draw() -> void:
	PieceArt.draw(self, kind, size, false, data)


func _gui_input(event: InputEvent) -> void:
	if not draggable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			_moved = false
			_press_pos = get_global_mouse_position()
			_grab_offset = get_parent().get_local_mouse_position() - position
			z_index = 10
			move_to_front()
			AudioService.play("place")
			grabbed.emit(self)
		elif dragging:
			dragging = false
			z_index = 0
			if _moved:
				dropped.emit(self)
			else:
				tapped.emit(self)
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		if get_global_mouse_position().distance_to(_press_pos) > 6.0:
			_moved = true
		var parent_size: Vector2 = get_parent().size if get_parent() is Control else ActivityStep.BOARD_SIZE
		var p: Vector2 = get_parent().get_local_mouse_position() - _grab_offset
		position = p.clamp(-size / 2.0, parent_size - size / 2.0)
		accept_event()
