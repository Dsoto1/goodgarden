class_name PieceArt
extends RefCounted
## Draws every manipulative and its matching outline ("shadow") from code, so
## pieces and outlines always agree. Shapes are distinct in silhouette, not
## only in colour, so matching never depends on colour vision alone.

const OUTLINE := Color(0.25, 0.18, 0.12, 0.55)
const INK := Color("3b3430")


## Draws `kind` filling `r` (for samples pinned to a bin or label).
static func draw_at(ci: CanvasItem, kind: String, r: Rect2, outline := false) -> void:
	ci.draw_set_transform(r.position)
	draw(ci, kind, r.size, outline)
	ci.draw_set_transform(Vector2.ZERO)


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
		"card_seed", "card_sprout", "card_sapling", "card_blossom", "card_apples":
			_growth_card(ci, kind, size, outline, str(data.get("label", "")))
		"tadpole":
			_shape(ci, _ellipse(c + Vector2(-size.x * 0.12, 0), Vector2(size.x * 0.2, size.y * 0.24), 14), Color("4a4a3e"), outline)
			_shape(ci, PackedVector2Array([c + Vector2(0, -size.y * 0.1), c + Vector2(size.x * 0.42, -size.y * 0.02), c + Vector2(size.x * 0.42, size.y * 0.06), c + Vector2(0, size.y * 0.1)]), Color("5e5e50"), outline)
		"minnow":
			_shape(ci, _ellipse(c + Vector2(-size.x * 0.05, 0), Vector2(size.x * 0.3, size.y * 0.18), 16), Color("8fa3ad"), outline)
			_shape(ci, PackedVector2Array([c + Vector2(size.x * 0.22, 0), c + Vector2(size.x * 0.44, -size.y * 0.2), c + Vector2(size.x * 0.44, size.y * 0.2)]), Color("7a8f99"), outline)
			if not outline:
				ci.draw_circle(c + Vector2(-size.x * 0.22, -size.y * 0.04), 2.0, INK)
		"water_snail":
			_shape(ci, _ellipse(c + Vector2(size.x * 0.05, size.y * 0.18), Vector2(size.x * 0.36, size.y * 0.1), 12), Color("8a7a5a"), outline)
			_shape(ci, _ellipse(c + Vector2(0, -size.y * 0.02), Vector2(size.x * 0.22, size.y * 0.26), 16), Color("6b5a3e"), outline)
			if not outline:
				ci.draw_arc(c + Vector2(0, -size.y * 0.02), size.y * 0.13, 0, TAU * 0.8, 10, Color("a8936a"), 2.0)
		"duckling":
			_shape(ci, _ellipse(c + Vector2(size.x * 0.06, size.y * 0.1), Vector2(size.x * 0.3, size.y * 0.24), 16), Color("f2d24e"), outline)
			_shape(ci, _ellipse(c + Vector2(-size.x * 0.2, -size.y * 0.16), Vector2(size.x * 0.15, size.y * 0.17), 14), Color("f2d24e"), outline)
			_shape(ci, PackedVector2Array([c + Vector2(-size.x * 0.33, -size.y * 0.16), c + Vector2(-size.x * 0.46, -size.y * 0.1), c + Vector2(-size.x * 0.33, -size.y * 0.06)]), Color("e08a2e"), outline)
			if not outline:
				ci.draw_circle(c + Vector2(-size.x * 0.22, -size.y * 0.2), 1.8, INK)
		"rabbit":
			_shape(ci, _ellipse(c + Vector2(size.x * 0.08, size.y * 0.12), Vector2(size.x * 0.3, size.y * 0.22), 16), Color("a8927a"), outline)
			_shape(ci, _ellipse(c + Vector2(-size.x * 0.2, -size.y * 0.06), Vector2(size.x * 0.14, size.y * 0.15), 14), Color("a8927a"), outline)
			for e: float in [-0.26, -0.16]:
				_shape(ci, _ellipse(c + Vector2(size.x * e, -size.y * 0.32), Vector2(size.x * 0.04, size.y * 0.15), 10), Color("b8a28a"), outline)
			if not outline:
				ci.draw_circle(c + Vector2(size.x * 0.36, size.y * 0.08), 4.0, Color("f3ede4"))
		"ladybird":
			_shape(ci, _ellipse(c, Vector2(size.x * 0.28, size.y * 0.26), 16), Color("d8442e"), outline)
			_shape(ci, _ellipse(c + Vector2(-size.x * 0.28, 0), Vector2(size.x * 0.1, size.y * 0.12), 10), Color("2e2a28"), outline)
			if not outline:
				ci.draw_line(c + Vector2(-size.x * 0.18, 0), c + Vector2(size.x * 0.28, 0), Color("2e2a28"), 1.5)
				for d: Vector2 in [Vector2(-0.06, -0.12), Vector2(0.12, 0.1), Vector2(0.12, -0.12), Vector2(-0.06, 0.12)]:
					ci.draw_circle(c + d * size, 2.5, Color("2e2a28"))
		"worm":
			var pts := PackedVector2Array()
			for i in 12:
				var t := i / 11.0
				pts.append(c + Vector2((t - 0.5) * size.x * 0.8, sin(t * TAU) * size.y * 0.14 - size.y * 0.04))
			for i in range(11, -1, -1):
				var t := i / 11.0
				pts.append(c + Vector2((t - 0.5) * size.x * 0.8, sin(t * TAU) * size.y * 0.14 + size.y * 0.06))
			_shape(ci, pts, Color("d58a7e"), outline)
		"butterfly":
			for side: float in [-1.0, 1.0]:
				_shape(ci, _ellipse(c + Vector2(side * size.x * 0.18, -size.y * 0.1), Vector2(size.x * 0.17, size.y * 0.2), 12), Color("e8a33c"), outline)
				_shape(ci, _ellipse(c + Vector2(side * size.x * 0.14, size.y * 0.16), Vector2(size.x * 0.12, size.y * 0.14), 12), Color("d0782a"), outline)
			_shape(ci, _rect(Rect2(c.x - 2, c.y - size.y * 0.25, 4, size.y * 0.5)), Color("3b3430"), outline)
		"bee":
			_shape(ci, _ellipse(c + Vector2(0, size.y * 0.05), Vector2(size.x * 0.26, size.y * 0.2), 14), Color("f2c14e"), outline)
			if not outline:
				for x: float in [-0.08, 0.06]:
					ci.draw_line(c + Vector2(size.x * x, -size.y * 0.12), c + Vector2(size.x * x, size.y * 0.24), Color("3b3430"), 3.0)
				for side: float in [-1.0, 1.0]:
					ci.draw_circle(c + Vector2(side * size.x * 0.1, -size.y * 0.2), size.y * 0.12, Color(1, 1, 1, 0.75))
		"swallow":
			_shape(ci, PackedVector2Array([c + Vector2(-size.x * 0.44, -size.y * 0.1), c + Vector2(0, size.y * 0.02), c + Vector2(size.x * 0.44, -size.y * 0.1), c + Vector2(size.x * 0.1, size.y * 0.12), c + Vector2(size.x * 0.06, size.y * 0.36), c + Vector2(0, size.y * 0.2), c + Vector2(-size.x * 0.06, size.y * 0.36), c + Vector2(-size.x * 0.1, size.y * 0.12)]), Color("2f4a6e"), outline)
		"pressed_daisy":
			for i in 8:
				var a := TAU * i / 8.0
				_shape(ci, _ellipse(c + Vector2(cos(a), sin(a)) * size.x * 0.22, Vector2(size.x * 0.13, size.x * 0.07), 10), Color("fbf8f0"), outline)
			_shape(ci, _ellipse(c, Vector2(size.x * 0.12, size.x * 0.12), 12), Color("f2c14e"), outline)
		"pressed_violet":
			for i in 5:
				var a := TAU * i / 5.0 - PI / 2.0
				_shape(ci, _ellipse(c + Vector2(cos(a), sin(a)) * size.x * 0.18, Vector2(size.x * 0.14, size.x * 0.14), 10), Color("8a6abf"), outline)
			_shape(ci, _ellipse(c, Vector2(size.x * 0.07, size.x * 0.07), 8), Color("f2c14e"), outline)
		"pressed_leaf":
			var leaf := PackedVector2Array()
			for i in 13:
				var t := i / 12.0
				leaf.append(c + Vector2((t - 0.5) * size.x * 0.8, -sin(t * PI) * size.y * 0.3))
			for i in range(11, 0, -1):
				var t := i / 12.0
				leaf.append(c + Vector2((t - 0.5) * size.x * 0.8, sin(t * PI) * size.y * 0.3))
			_shape(ci, leaf, Color("6f9a52"), outline)
		"heart":
			var hp := PackedVector2Array()
			for i in 24:
				var t := TAU * i / 24.0
				hp.append(c + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * size.x / 40.0)
			_shape(ci, hp, Color("d8584a"), outline)
		"water_drop":
			var drop := PackedVector2Array()
			for i in 17:
				var a := PI * 0.15 + (PI * 1.7) * i / 16.0
				drop.append(c + Vector2(sin(a) * size.y * 0.36, -cos(a) * size.y * 0.36 + size.y * 0.1))
			drop.append(c + Vector2(0, -size.y * 0.48))
			_shape(ci, drop, Color("5f9fd0"), outline)
			if not outline:
				ci.draw_circle(c + Vector2(-size.y * 0.1, size.y * 0.05), size.y * 0.08, Color("d6ecf8"))
		"hay":
			# A small bundle of hay tied in the middle.
			for k in 5:
				var y := c.y + (k - 2) * size.y * 0.13
				_shape(ci, _rect(Rect2(size.x * 0.06, y - size.y * 0.08, size.x * 0.88, size.y * 0.16)), Color("e2c56f") if k % 2 else Color("d4b259"), outline)
			if not outline:
				ci.draw_rect(Rect2(c.x - 2, size.y * 0.15, 4, size.y * 0.7), Color("8a5a3a"))
		"grain":
			_shape(ci, _ellipse(c, Vector2(size.x * 0.28, size.y * 0.36), 12), Color("c9a25a"), outline)
			if not outline:
				ci.draw_line(c + Vector2(0, -size.y * 0.28), c + Vector2(0, size.y * 0.28), Color("a8823f"), 1.5)
		"pebble":
			# A small grey stone, the kind that hides among grain.
			_shape(ci, PackedVector2Array([c + Vector2(-size.x * 0.34, size.y * 0.1), c + Vector2(-size.x * 0.2, -size.y * 0.3), c + Vector2(size.x * 0.22, -size.y * 0.32), c + Vector2(size.x * 0.36, 0), c + Vector2(size.x * 0.18, size.y * 0.32), c + Vector2(-size.x * 0.22, size.y * 0.3)]), Color("8f8a82"), outline)
		"chaff":
			# Light, papery husks and bits of straw.
			_shape(ci, PackedVector2Array([c + Vector2(-size.x * 0.42, size.y * 0.1), c + Vector2(-size.x * 0.1, -size.y * 0.3), c + Vector2(size.x * 0.42, -size.y * 0.1), c + Vector2(size.x * 0.1, size.y * 0.32)]), Color("e8ddc0"), outline)
			if not outline:
				ci.draw_line(c + Vector2(-size.x * 0.3, size.y * 0.05), c + Vector2(size.x * 0.3, -size.y * 0.08), Color("b9a07a"), 1.5)
		"flour_scoop", "flour_scoop_big":
			# A little wooden scoop heaped with flour.
			_shape(ci, PackedVector2Array([c + Vector2(-size.x * 0.4, -size.y * 0.05), c + Vector2(size.x * 0.4, -size.y * 0.05), c + Vector2(size.x * 0.3, size.y * 0.4), c + Vector2(-size.x * 0.3, size.y * 0.4)]), Color("b07a4f"), outline)
			_shape(ci, _ellipse(c + Vector2(0, -size.y * 0.08), Vector2(size.x * 0.4, size.y * 0.24), 14), Color("f8f3e8"), outline)
			if not outline:
				# One dot per small scoop it weighs, to match the dots on the stone.
				var dots := 2 if kind == "flour_scoop_big" else 1
				for i in dots:
					ci.draw_circle(c + Vector2((i - (dots - 1) / 2.0) * size.x * 0.22, size.y * 0.2), size.y * 0.08, Color("f3e6d2"))
		"loaf_round":
			_shape(ci, _ellipse(c, Vector2(size.x * 0.46, size.y * 0.44), 20), Color("c98a3e"), outline)
			if not outline:
				for k in 3:
					var y := c.y + (k - 1) * size.y * 0.22
					ci.draw_line(Vector2(c.x - size.x * 0.25, y), Vector2(c.x + size.x * 0.25, y - 4), Color("e8b874"), 3.0)
		"loaf_long":
			_shape(ci, _ellipse(c, Vector2(size.x * 0.48, size.y * 0.4), 20), Color("d09048"), outline)
			if not outline:
				for k in 4:
					var x := c.x + (k - 1.5) * size.x * 0.2
					ci.draw_line(Vector2(x - 6, c.y + size.y * 0.18), Vector2(x + 6, c.y - size.y * 0.18), Color("eebd72"), 3.0)
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
		ci.draw_string(font, Vector2(-45, size.y - 2), label, HORIZONTAL_ALIGNMENT_CENTER, size.x + 90, 15, col)


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
			# The mustard plant grown great: slender green stems branching from a
			# lobed-leaf base, each tipped with a cluster of small yellow flowers.
			var foot := Vector2(cx, h * 0.98)
			var tips: Array[Vector2] = [Vector2(cx, h * 0.12), Vector2(cx - size.x * 0.36, h * 0.24), Vector2(cx + size.x * 0.38, h * 0.22), Vector2(cx - size.x * 0.22, h * 0.08), Vector2(cx + size.x * 0.2, h * 0.1), Vector2(cx - size.x * 0.42, h * 0.46), Vector2(cx + size.x * 0.42, h * 0.44)]
			var stem := Color("6b9a3c")
			_shape(ci, _limb(foot, tips[0], 4.0), stem, outline)
			for k in range(1, tips.size()):
				var fork := Vector2(cx, lerpf(h * 0.62, h * 0.32, (k - 1) / 5.0))
				_shape(ci, _limb(fork, tips[k], 2.5), stem, outline)
			for side: float in [-1.0, 1.0]:
				for k in 2:
					_shape(ci, _ellipse(Vector2(cx + side * size.x * (0.14 + k * 0.12), h * (0.9 - k * 0.1)), Vector2(size.x * (0.14 - k * 0.03), h * 0.035), 12), Color("5f8a3f"), outline)
			for t: Vector2 in tips:
				_shape(ci, _ellipse(t + Vector2(0, 2), Vector2(size.x * 0.1, h * 0.05), 12), color.lightened(0.1) if outline else Color("e8c22e"), outline)
				if not outline:
					for p: Vector2 in [Vector2(-4, 0), Vector2(4, 1), Vector2(0, -3), Vector2(-2, 4), Vector2(3, 5)]:
						ci.draw_circle(t + p, 2.2, Color("f4d64a"))
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


## A stem as a thin polygon from `a` to `b`, tapering towards `b`.
static func _limb(a: Vector2, b: Vector2, width: float) -> PackedVector2Array:
	var n := (b - a).orthogonal().normalized()
	return PackedVector2Array([a + n * width / 2.0, b + n * width / 4.0, b - n * width / 4.0, a - n * width / 2.0])


## Picture cards for how an apple tree grows, from seed to apples.
static func _growth_card(ci: CanvasItem, kind: String, size: Vector2, outline: bool, label: String) -> void:
	var r := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	_shape(ci, _rect(r), Color("fbf3dc"), outline)
	if outline:
		return
	# The name sits on the card itself, dark on cream, so it reads anywhere.
	if not label.is_empty():
		ci.draw_string(UiStyle.font(), Vector2(r.position.x, r.end.y - 8), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, Color("5a3d28"))
	var c := Vector2(r.get_center().x, r.position.y + (r.size.y - 26) / 2.0)
	var ground := r.end.y - 22 - (24 if not label.is_empty() else 0)
	ci.draw_rect(Rect2(r.position.x + 6, ground, r.size.x - 12, 16), Color("8a6446"))
	match kind:
		"card_seed":
			ci.draw_colored_polygon(_ellipse(Vector2(c.x, ground + 6), Vector2(9, 6), 12), Color("6b4a2e"))
		"card_sprout":
			ci.draw_line(Vector2(c.x, ground), Vector2(c.x, ground - 26), Color("5f8a3f"), 3.0)
			for side: float in [-1.0, 1.0]:
				ci.draw_colored_polygon(_ellipse(Vector2(c.x + side * 9, ground - 26), Vector2(9, 5), 10), Color("7fb04a"))
		"card_sapling", "card_blossom", "card_apples":
			var big := kind != "card_sapling"
			var trunk_h := 54.0 if big else 40.0
			ci.draw_rect(Rect2(c.x - (5 if big else 3), ground - trunk_h, 10 if big else 6, trunk_h), Color("7a5a3a"))
			var crown := Vector2(c.x, ground - trunk_h - (18 if big else 10))
			ci.draw_colored_polygon(_ellipse(crown, Vector2(40, 30) if big else Vector2(22, 18), 18), Color("6f9a52"))
			var dots := [Vector2(-22, -8), Vector2(10, -16), Vector2(24, 4), Vector2(-6, 10), Vector2(-28, 8), Vector2(4, -2)]
			if kind == "card_blossom":
				for d: Vector2 in dots:
					ci.draw_circle(crown + d, 5.0, Color("f6d4dc"))
			elif kind == "card_apples":
				for d: Vector2 in dots:
					ci.draw_circle(crown + d, 6.0, Color("d8442e"))


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
		# Painted like a wooden toy: the colour, a soft highlight toward the
		# top-left where the light falls, and a darker rim.
		ci.draw_colored_polygon(pts, fill)
		if pts.size() >= 6:
			var mid := Vector2.ZERO
			for q in pts:
				mid += q
			mid /= pts.size()
			var shine := PackedVector2Array()
			for q in pts:
				shine.append(mid + (q - mid) * 0.62 + (q - mid).length() * Vector2(-0.12, -0.16))
			ci.draw_colored_polygon(shine, Color(fill.lightened(0.35), 0.38))
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, fill.darkened(0.35), 2.0, true)


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
