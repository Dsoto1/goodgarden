class_name PieceArt
extends RefCounted
## Draws every manipulative and its matching outline ("shadow") from code, so
## pieces and outlines always agree. Shapes are distinct in silhouette, not
## only in colour, so matching never depends on colour vision alone.

const OUTLINE := Color(0.25, 0.18, 0.12, 0.55)
const INK := Color("3b3430")


static func draw(ci: CanvasItem, kind: String, size: Vector2, outline: bool, data: Dictionary = {}) -> void:
	var c := size / 2.0
	if kind.begins_with("figure:"):
		_figure(ci, size, outline, data)
		return
	match kind:
		"bread_roll":
			_shape(ci, _ellipse(c, Vector2(size.x * 0.46, size.y * 0.42), 16), Color("d9963f"), outline)
			if not outline:
				ci.draw_circle(c + Vector2(-size.x * 0.1, -size.y * 0.12), size.y * 0.16, Color("eebd72"))
				ci.draw_line(c + Vector2(-size.x * 0.2, size.y * 0.05), c + Vector2(size.x * 0.2, -size.y * 0.1), Color("a8662a"), 2.0)
		"bean_seed":
			_shape(ci, _ellipse(c, Vector2(size.x * 0.45, size.y * 0.4), 14), Color("8a3b2e"), outline)
			if not outline:
				ci.draw_circle(c + Vector2(-size.x * 0.12, -size.y * 0.05), size.y * 0.12, Color("f3e6d2"))
		"marker_peg":
			_shape(ci, PackedVector2Array([Vector2(c.x - 5, size.y * 0.25), Vector2(c.x + 5, size.y * 0.25), Vector2(c.x + 5, size.y * 0.85), Vector2(c.x, size.y), Vector2(c.x - 5, size.y * 0.85)]), Color("c49a6c"), outline)
			_shape(ci, PackedVector2Array([Vector2(c.x - 5, 0), Vector2(c.x + size.x * 0.45, size.y * 0.1), Vector2(c.x - 5, size.y * 0.22)]), Color("e8c15a"), outline)
		"spacing_stick":
			_shape(ci, _rect(Rect2(0, size.y * 0.2, size.x, size.y * 0.6)), Color("d6ad7a"), outline)
			if not outline:
				for x: float in [2.0, size.x - 2.0]:
					ci.draw_line(Vector2(x, 0), Vector2(x, size.y), INK, 3.0)
				for i in range(1, 4):
					ci.draw_line(Vector2(size.x * i / 4.0, size.y * 0.25), Vector2(size.x * i / 4.0, size.y * 0.45), Color(INK, 0.5), 1.5)
		"plate":
			_shape(ci, _ellipse(c, c * 0.95, 28), Color("f5efe2"), outline)
			if not outline:
				ci.draw_arc(c, size.x * 0.32, 0, TAU, 28, Color("c9b99c"), 2.0)
		"bowl_small":
			_shape(ci, _ellipse(c, c * 0.9, 22), Color("8fb0d8"), outline)
			if not outline:
				ci.draw_arc(c, size.x * 0.3, 0, TAU, 22, Color("6d8fc0"), 2.0)
		"cup":
			_shape(ci, _rect(Rect2(size.x * 0.12, size.y * 0.15, size.x * 0.62, size.y * 0.75)), Color("6d8fc0"), outline)
			var handle := _ellipse(Vector2(size.x * 0.78, size.y * 0.5), Vector2(size.x * 0.16, size.y * 0.18), 10)
			if outline:
				_dashed(ci, handle)
			else:
				ci.draw_polyline(handle + PackedVector2Array([handle[0]]), Color("6d8fc0"), 5.0)
		"fork":
			_utensil(ci, size, outline, "fork")
		"spoon":
			_utensil(ci, size, outline, "spoon")
		"knife":
			_utensil(ci, size, outline, "knife")
		"napkin":
			_shape(ci, PackedVector2Array([Vector2(size.x * 0.1, size.y * 0.05), Vector2(size.x * 0.9, size.y * 0.05), Vector2(size.x * 0.9, size.y * 0.95), Vector2(size.x * 0.1, size.y * 0.95)]), Color("c96f5a"), outline)
			if not outline:
				ci.draw_line(Vector2(size.x * 0.1, size.y * 0.05), Vector2(size.x * 0.9, size.y * 0.95), Color("a85646"), 2.0)
		"coin":
			_shape(ci, _ellipse(c, c * 0.9, 16), Color("e0b64c"), outline)
		_:
			_shape(ci, _rect(Rect2(Vector2.ZERO, size)), Color("cccccc"), outline)


static func _figure(ci: CanvasItem, size: Vector2, outline: bool, data: Dictionary) -> void:
	var body_color: Color = Palette.color(str(data.get("color", "cloth_cream")))
	var label := str(data.get("label", ""))
	var label_h := 18.0 if not label.is_empty() else 0.0
	var h := size.y - label_h
	var cx := size.x / 2.0
	if data.get("shape", "") == "donkey":
		var body := _ellipse(Vector2(cx, h * 0.55), Vector2(size.x * 0.38, h * 0.18), 16)
		_shape(ci, body, Color("9a9088"), outline)
		_shape(ci, _ellipse(Vector2(cx - size.x * 0.36, h * 0.35), Vector2(size.x * 0.13, h * 0.1), 12), Color("9a9088"), outline)
		for x: float in [-0.25, -0.1, 0.12, 0.27]:
			_shape(ci, _rect(Rect2(cx + size.x * x - 3, h * 0.65, 6, h * 0.3)), Color("7d746d"), outline)
	elif _parable_shape(ci, str(data.get("shape", "")), size, h, outline, body_color):
		pass
	elif data.get("shape", "") == "building":
		_shape(ci, _rect(Rect2(size.x * 0.12, h * 0.4, size.x * 0.76, h * 0.58)), body_color, outline)
		_shape(ci, PackedVector2Array([Vector2(size.x * 0.05, h * 0.42), Vector2(cx, h * 0.08), Vector2(size.x * 0.95, h * 0.42)]), Palette.color("roof_red"), outline)
	else:
		# Wooden peg figure: rounded body and a round head (smaller for a child).
		var small: bool = data.get("shape", "") == "child"
		var top := h * (0.56 if small else 0.38)
		var half := size.x * (0.26 if small else 0.3)
		var body := PackedVector2Array()
		for i in 9:
			var a := PI + PI * i / 8.0
			body.append(Vector2(cx + cos(a) * half, top + 6 + sin(a) * 10))
		body.append(Vector2(cx + half * 1.2, h * 0.98))
		body.append(Vector2(cx - half * 1.2, h * 0.98))
		_shape(ci, body, body_color, outline)
		var head_r := h * (0.13 if small else 0.16)
		_shape(ci, _ellipse(Vector2(cx, top - head_r + 2), Vector2(head_r, head_r), 16), Color("e9c9a4"), outline)
		if not outline and data.has("accent"):
			ci.draw_rect(Rect2(cx - half, lerpf(top, h, 0.38), half * 2.0, 6), Palette.color(str(data["accent"])))
	if not label.is_empty():
		# Labels may be wider than the figure; centre them under it in the storybook serif.
		var font := UiStyle.font()
		var col := Color(INK, 0.6) if outline else Color("f6f1e4")
		ci.draw_string(font, Vector2(-30, size.y - 2), label, HORIZONTAL_ALIGNMENT_CENTER, size.x + 60, 15, col)


## Objects from the parables, drawn on the same figure card as the people.
## Returns false when `shape` is not one of them.
static func _parable_shape(ci: CanvasItem, shape: String, size: Vector2, h: float, outline: bool, color: Color) -> bool:
	var cx := size.x / 2.0
	match shape:
		"seed":
			# The tiniest of seeds, on a little felt mat so small hands can lift it.
			_shape(ci, _ellipse(Vector2(cx, h * 0.8), Vector2(size.x * 0.34, h * 0.08), 16), Color("d9cbb0"), outline)
			_shape(ci, _ellipse(Vector2(cx, h * 0.78), Vector2(3.5, 3.5), 10), Color("6b4a2e"), outline)
		"sprout":
			_shape(ci, _ellipse(Vector2(cx, h * 0.92), Vector2(size.x * 0.3, h * 0.06), 14), Color("6b4a2e"), outline)
			_shape(ci, _rect(Rect2(cx - 2, h * 0.55, 4, h * 0.36)), Color("6b9a3c"), outline)
			for side: float in [-1.0, 1.0]:
				_shape(ci, _ellipse(Vector2(cx + side * 9, h * 0.55), Vector2(9, 5), 12), Color("7fb04a"), outline)
		"bush":
			# The mustard plant grown great: a thick stem, wide branches, yellow flowers.
			_shape(ci, _rect(Rect2(cx - 4, h * 0.55, 8, h * 0.43)), Color("7a5a3a"), outline)
			for c: Vector3 in [Vector3(-0.22, 0.42, 0.22), Vector3(0.22, 0.42, 0.22), Vector3(0.0, 0.26, 0.26), Vector3(-0.12, 0.12, 0.17), Vector3(0.14, 0.13, 0.17)]:
				_shape(ci, _ellipse(Vector2(cx + size.x * c.x, h * c.y + 6), Vector2(size.x * c.z * 1.25, size.x * c.z), 16), color, outline)
			if not outline:
				for p: Vector2 in [Vector2(-0.25, 0.3), Vector2(0.2, 0.25), Vector2(0.0, 0.12), Vector2(0.3, 0.45), Vector2(-0.3, 0.5), Vector2(0.06, 0.38)]:
					ci.draw_circle(Vector2(cx + size.x * p.x, h * p.y + 6), 2.6, Color("f0c93a"))
		"bird":
			_shape(ci, _ellipse(Vector2(cx, h * 0.62), Vector2(size.x * 0.28, h * 0.11), 14), color, outline)
			_shape(ci, _ellipse(Vector2(cx - size.x * 0.24, h * 0.52), Vector2(size.x * 0.12, size.x * 0.12), 12), color, outline)
			_shape(ci, PackedVector2Array([Vector2(cx - size.x * 0.36, h * 0.5), Vector2(cx - size.x * 0.48, h * 0.53), Vector2(cx - size.x * 0.36, h * 0.56)]), Color("e0a73a"), outline)
			_shape(ci, PackedVector2Array([Vector2(cx + size.x * 0.22, h * 0.6), Vector2(cx + size.x * 0.46, h * 0.5), Vector2(cx + size.x * 0.3, h * 0.68)]), color.darkened(0.2), outline)
			if not outline:
				ci.draw_circle(Vector2(cx - size.x * 0.27, h * 0.5), 1.8, INK)
		"flour":
			# Three measures of flour in a wide bowl.
			for x: float in [-0.2, 0.0, 0.2]:
				_shape(ci, _ellipse(Vector2(cx + size.x * x, h * 0.66), Vector2(size.x * 0.16, h * 0.1), 12), Color("f4efe3"), outline)
			_bowl(ci, cx, h, size, outline)
		"leaven":
			_shape(ci, _ellipse(Vector2(cx, h * 0.84), Vector2(size.x * 0.26, h * 0.05), 14), Color("b9a07a"), outline)
			_shape(ci, _ellipse(Vector2(cx, h * 0.78), Vector2(size.x * 0.12, h * 0.05), 12), Color("d8c39a"), outline)
		"sheep":
			_sheep(ci, Vector2(cx, h * 0.62), size.x * 0.34, outline)
		"flock":
			# The ninety-nine, shown as a little huddle of sheep.
			for p: Vector3 in [Vector3(-0.2, 0.5, 0.2), Vector3(0.2, 0.52, 0.2), Vector3(0.0, 0.66, 0.24), Vector3(-0.24, 0.78, 0.2), Vector3(0.24, 0.8, 0.2)]:
				_sheep(ci, Vector2(cx + size.x * p.x, h * p.y), size.x * p.z, outline)
		"dough":
			# The whole bowl, risen: the dough swells high above the rim.
			_shape(ci, _ellipse(Vector2(cx, h * 0.52), Vector2(size.x * 0.44, h * 0.26), 20), Color("f1e2c4"), outline)
			_bowl(ci, cx, h, size, outline)
		"loaves":
			# Five small round barley loaves in a little basket.
			_basket_shape(ci, Vector2(cx, h * 0.78), size.x * 0.42, h * 0.16, color, outline)
			for p: Vector2 in [Vector2(-0.24, 0.62), Vector2(0.0, 0.6), Vector2(0.24, 0.62), Vector2(-0.12, 0.5), Vector2(0.12, 0.5)]:
				_shape(ci, _ellipse(Vector2(cx + size.x * p.x, h * p.y), Vector2(size.x * 0.13, h * 0.06), 12), Color("d9a65c"), outline)
		"fish":
			# Two small fish lying on a cloth.
			_shape(ci, _ellipse(Vector2(cx, h * 0.76), Vector2(size.x * 0.46, h * 0.16), 16), color, outline)
			for y: float in [0.68, 0.82]:
				var at := Vector2(cx - 2, h * y)
				_shape(ci, _ellipse(at, Vector2(size.x * 0.24, h * 0.05), 14), Color("8fa3ad"), outline)
				_shape(ci, PackedVector2Array([at + Vector2(size.x * 0.2, 0), at + Vector2(size.x * 0.36, -h * 0.05), at + Vector2(size.x * 0.36, h * 0.05)]), Color("7a8f99"), outline)
				if not outline:
					ci.draw_circle(at + Vector2(-size.x * 0.15, -1), 1.5, INK)
		"crowd":
			# A great crowd: rows of little people, the farther ones smaller.
			var palette := [color, Palette.color("cloth_green"), Palette.color("cloth_red"), Palette.color("cloth_gold"), Palette.color("cloth_tan")]
			var rows := [[0.32, 0.05, 5], [0.52, 0.065, 4], [0.76, 0.08, 3]]
			for r in rows.size():
				var row: Array = rows[r]
				var n: int = row[2]
				for k in n:
					var x: float = cx + (k - (n - 1) / 2.0) * size.x * 0.84 / n
					var y: float = h * float(row[0])
					var rr: float = h * float(row[1])
					_shape(ci, _ellipse(Vector2(x, y + rr * 1.6), Vector2(rr * 0.95, rr * 1.2), 10), palette[(k + r * 2) % palette.size()], outline)
					_shape(ci, _ellipse(Vector2(x, y), Vector2(rr * 0.7, rr * 0.7), 10), Color("e9c9a4"), outline)
		"baskets":
			# Twelve baskets full of the pieces left over: three rows of four.
			for r in 3:
				for k in 4:
					var at := Vector2(cx + (k - 1.5) * size.x * 0.23, h * (0.42 + r * 0.2))
					_basket_shape(ci, at, size.x * 0.1, h * 0.06, color, outline)
					if not outline:
						ci.draw_circle(at + Vector2(-2, -h * 0.05), 3.0, Color("d9a65c"))
						ci.draw_circle(at + Vector2(3, -h * 0.05), 2.5, Color("d9a65c"))
		"net":
			# A fishing net, gathered in a heap, with cork floats along its edge.
			var heap := _ellipse(Vector2(cx, h * 0.7), Vector2(size.x * 0.44, h * 0.2), 18)
			_shape(ci, heap, color, outline)
			if not outline:
				var mesh := color.darkened(0.35)
				for k in 7:
					var x := cx - size.x * 0.36 + k * size.x * 0.12
					ci.draw_line(Vector2(x, h * 0.54), Vector2(x + size.x * 0.1, h * 0.86), mesh, 1.2)
					ci.draw_line(Vector2(x + size.x * 0.1, h * 0.54), Vector2(x, h * 0.86), mesh, 1.2)
				for k in 5:
					ci.draw_circle(Vector2(cx - size.x * 0.3 + k * size.x * 0.15, h * 0.53), 3.0, Color("e0a73a"))
		"boat":
			# A small fishing boat of the lake, with its mast and furled sail.
			_shape(ci, _rect(Rect2(cx - 1.5, h * 0.1, 3, h * 0.55)), Color("6b4a2e"), outline)
			_shape(ci, PackedVector2Array([Vector2(cx + 2, h * 0.16), Vector2(cx + size.x * 0.3, h * 0.56), Vector2(cx + 2, h * 0.56)]), Color("efe6d2"), outline)
			var hull := PackedVector2Array([Vector2(size.x * 0.02, h * 0.58), Vector2(size.x * 0.98, h * 0.58), Vector2(size.x * 0.82, h * 0.84), Vector2(size.x * 0.18, h * 0.84)])
			_shape(ci, hull, color, outline)
			if not outline:
				ci.draw_line(Vector2(size.x * 0.06, h * 0.66), Vector2(size.x * 0.94, h * 0.66), color.darkened(0.3), 2.0)
		_:
			return false
	return true


## A woolly sheep: a cloud of a body, a dark face and legs, facing left.
static func _sheep(ci: CanvasItem, at: Vector2, r: float, outline: bool) -> void:
	for x: float in [-0.35, 0.35]:
		_shape(ci, _rect(Rect2(at.x + r * x - 1.5, at.y + r * 0.3, 3, r * 0.7)), Color("3b3430"), outline)
	for c: Vector3 in [Vector3(-0.35, 0.0, 0.55), Vector3(0.0, -0.15, 0.6), Vector3(0.38, 0.0, 0.55), Vector3(0.0, 0.18, 0.6)]:
		_shape(ci, _ellipse(at + Vector2(c.x, c.y) * r, Vector2(c.z, c.z * 0.85) * r, 12), Color("f6f1e4"), outline)
	_shape(ci, _ellipse(at + Vector2(-0.85, -0.2) * r, Vector2(0.3, 0.36) * r, 10), Color("3b3430"), outline)


## A woven basket seen from the side, centred at `at`.
static func _basket_shape(ci: CanvasItem, at: Vector2, half_w: float, half_h: float, color: Color, outline: bool) -> void:
	var pts := PackedVector2Array([at + Vector2(-half_w, -half_h), at + Vector2(half_w, -half_h), at + Vector2(half_w * 0.8, half_h), at + Vector2(-half_w * 0.8, half_h)])
	_shape(ci, pts, color, outline)
	if not outline:
		ci.draw_line(at + Vector2(-half_w * 0.9, 0), at + Vector2(half_w * 0.9, 0), color.darkened(0.3), 1.5)


static func _bowl(ci: CanvasItem, cx: float, h: float, size: Vector2, outline: bool) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		pts.append(Vector2(cx + cos(a) * size.x * 0.46, h * 0.7 + sin(a) * h * 0.24))
	_shape(ci, pts, Color("b0704a"), outline)


static func _utensil(ci: CanvasItem, size: Vector2, outline: bool, kind: String) -> void:
	var cx := size.x / 2.0
	var metal := Color("b9bec6")
	_shape(ci, _rect(Rect2(cx - 3, size.y * 0.4, 6, size.y * 0.58)), metal, outline)
	match kind:
		"fork":
			_shape(ci, _rect(Rect2(cx - size.x * 0.32, size.y * 0.3, size.x * 0.64, size.y * 0.12)), metal, outline)
			for i in 4:
				var x := cx - size.x * 0.32 + i * size.x * 0.64 / 3.0
				_shape(ci, _rect(Rect2(x - 1.5, size.y * 0.02, 3, size.y * 0.3)), metal, outline)
		"spoon":
			_shape(ci, _ellipse(Vector2(cx, size.y * 0.2), Vector2(size.x * 0.36, size.y * 0.2), 14), metal, outline)
		"knife":
			_shape(ci, PackedVector2Array([Vector2(cx - 4, size.y * 0.42), Vector2(cx - 4, size.y * 0.08), Vector2(cx + 5, size.y * 0.02), Vector2(cx + 5, size.y * 0.42)]), metal, outline)


static func _shape(ci: CanvasItem, pts: PackedVector2Array, fill: Color, outline: bool) -> void:
	if outline:
		ci.draw_colored_polygon(pts, Color(OUTLINE, 0.12))
		_dashed(ci, pts)
	else:
		ci.draw_colored_polygon(pts, fill)
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, fill.darkened(0.3), 1.5, true)


static func _dashed(ci: CanvasItem, pts: PackedVector2Array) -> void:
	for i in pts.size():
		ci.draw_dashed_line(pts[i], pts[(i + 1) % pts.size()], OUTLINE, 2.0, 6.0)


static func _ellipse(c: Vector2, r: Vector2, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts


static func _rect(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
