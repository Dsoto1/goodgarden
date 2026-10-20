class_name DropSlot
extends Control
## A place a piece belongs: a hole in the soil, an outline on a placemat, a
## compartment in a material box. Draws the "shadow" of what fits, so the
## material itself corrects mistakes: a fork simply does not settle on a cup.

var accepts := "" # piece kind that fits here
var capacity := 1
var contents: Array[DragPiece] = []
var data: Dictionary = {}
var show_outline := true


static func create(kind: String, slot_size: Vector2, slot_data: Dictionary = {}) -> DropSlot:
	var s := DropSlot.new()
	s.accepts = kind
	s.size = slot_size
	s.data = slot_data
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func center() -> Vector2:
	return position + size / 2.0


func set_center(c: Vector2) -> void:
	position = c - size / 2.0


func is_full() -> bool:
	return contents.size() >= capacity


func fits(piece: DragPiece) -> bool:
	return piece.kind == accepts


## True when `point` (in the parent's space) is close enough to count as a drop here.
func near(point: Vector2, tolerance: float) -> bool:
	return Rect2(position, size).grow(tolerance).has_point(point)


func put(piece: DragPiece) -> void:
	if piece.placed_in is DropSlot and piece.placed_in != self:
		(piece.placed_in as DropSlot).take(piece)
	if not contents.has(piece):
		contents.append(piece)
	piece.placed_in = self
	queue_redraw()


func take(piece: DragPiece) -> void:
	contents.erase(piece)
	if piece.placed_in == self:
		piece.placed_in = null
	queue_redraw()


func _draw() -> void:
	if show_outline and contents.size() < capacity:
		PieceArt.draw(self, accepts, size, true, data)
