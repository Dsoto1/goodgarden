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
## Lit while a piece is held near enough to land here.
var glow := false:
	set(value):
		if value != glow:
			glow = value
			queue_redraw()


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
	var fresh := not contents.has(piece)
	if fresh:
		contents.append(piece)
	piece.placed_in = self
	glow = false
	if fresh:
		piece.settle()
		if is_full() and get_parent():
			Sparkle.burst(get_parent(), center())
	queue_redraw()


func take(piece: DragPiece) -> void:
	contents.erase(piece)
	if piece.placed_in == self:
		piece.placed_in = null
	queue_redraw()


func _draw() -> void:
	if glow:
		var g := PackedVector2Array()
		for i in 28:
			var a := TAU * i / 28.0
			g.append(size / 2.0 + Vector2(cos(a) * (size.x / 2.0 + 10.0), sin(a) * (size.y / 2.0 + 10.0)))
		draw_colored_polygon(g, Color(1.0, 0.93, 0.6, 0.28))
		draw_polyline(g + PackedVector2Array([g[0]]), Color(1.0, 0.9, 0.5, 0.8), 3.0, true)
	if show_outline and contents.size() < capacity:
		PieceArt.draw(self, accepts, size, true, data)
