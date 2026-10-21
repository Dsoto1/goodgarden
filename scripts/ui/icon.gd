class_name Icon
extends RefCounted
## Small hand-drawn interface icons (book, map, gear, sun, letter, seedling),
## drawn in code so they scale crisply at any text size.

const INK := Color("5a3d28")


static func draw(ci: CanvasItem, kind: String, r: Rect2, color := INK) -> void:
	var c := r.get_center()
	var s := minf(r.size.x, r.size.y)
	match kind:
		"journal":
			for side: float in [-1.0, 1.0]:
				var page := PackedVector2Array([c + Vector2(0, -0.3) * s, c + Vector2(side * 0.42, -0.36) * s, c + Vector2(side * 0.42, 0.3) * s, c + Vector2(0, 0.36) * s])
				ci.draw_colored_polygon(page, Color("f3e3c0"))
				ci.draw_polyline(page + PackedVector2Array([page[0]]), color, 2.0)
				for i in 3:
					var y := -0.15 + i * 0.13
					ci.draw_line(c + Vector2(side * 0.1, y) * s, c + Vector2(side * 0.33, y - 0.02) * s, Color(color, 0.6), 1.5)
			ci.draw_line(c + Vector2(0, -0.3) * s, c + Vector2(0, 0.36) * s, color, 2.0)
		"map":
			var pts := PackedVector2Array()
			for i in 4:
				pts.append(c + Vector2(-0.42 + i * 0.28, -0.32 + (i % 2) * 0.08) * s)
			for i in range(3, -1, -1):
				pts.append(c + Vector2(-0.42 + i * 0.28, 0.32 + (i % 2) * 0.08) * s)
			ci.draw_colored_polygon(pts, Color("e9d8a6"))
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), color, 2.0)
			for i in [1, 2]:
				ci.draw_line(pts[i], pts[7 - i], Color(color, 0.6), 1.5)
			ci.draw_circle(c + Vector2(-0.18, -0.05) * s, 0.07 * s, Color("6f9a52"))
			ci.draw_line(c + Vector2(0.05, 0.12) * s, c + Vector2(0.26, -0.1) * s, Color("c9483c"), 2.0)
		"settings":
			var teeth := 8
			var gear := PackedVector2Array()
			for i in teeth * 2:
				var a := TAU * i / (teeth * 2)
				var rad := (0.4 if i % 2 == 0 else 0.3) * s
				gear.append(c + Vector2(cos(a), sin(a)) * rad)
			ci.draw_colored_polygon(gear, Color("b9a07a"))
			ci.draw_polyline(gear + PackedVector2Array([gear[0]]), color, 2.0)
			ci.draw_circle(c, 0.13 * s, Color("f3e3c0"))
			ci.draw_arc(c, 0.13 * s, 0, TAU, 16, color, 2.0)
		"sun":
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * 0.3 * s, c + Vector2(cos(a), sin(a)) * 0.45 * s, Color("e8a33c"), 2.5)
			ci.draw_circle(c, 0.24 * s, Color("f2c14e"))
		"letter":
			var env := Rect2(c - Vector2(0.42, 0.28) * s, Vector2(0.84, 0.56) * s)
			ci.draw_rect(env, Color("f6ead0"))
			ci.draw_rect(env, color, false, 2.0)
			ci.draw_polyline(PackedVector2Array([env.position, c + Vector2(0, 0.06) * s, Vector2(env.end.x, env.position.y)]), color, 2.0)
			ci.draw_circle(c + Vector2(0, 0.08) * s, 0.08 * s, Color("c9483c"))
		"seedling":
			ci.draw_line(c + Vector2(0, 0.38) * s, c + Vector2(0, -0.05) * s, Color("4f7a3a"), 3.0)
			for side: float in [-1.0, 1.0]:
				var leaf := PackedVector2Array()
				for i in 9:
					var t := i / 8.0
					leaf.append(c + Vector2(side * (0.05 + 0.32 * t), -0.05 - 0.22 * t - 0.12 * sin(t * PI)) * s)
				for i in range(8, -1, -1):
					var t := i / 8.0
					leaf.append(c + Vector2(side * (0.05 + 0.32 * t), -0.05 - 0.22 * t + 0.06 * sin(t * PI)) * s)
				ci.draw_colored_polygon(leaf, Color("7fb35a"))
			ci.draw_rect(Rect2(c + Vector2(-0.22, 0.3) * s, Vector2(0.44, 0.12) * s), Color("8a5a3a"))


## A square, labelled icon button like the mockup's Journal / Map / Settings tiles.
class Tile:
	extends Button
	var kind := ""
	var caption := ""

	func _init(icon_kind: String, label: String) -> void:
		kind = icon_kind
		caption = label
		custom_minimum_size = Vector2(78, 84)
		tooltip_text = label

	func _draw() -> void:
		var font := get_theme_font("font", "Label")
		var fsize := int(get_theme_font_size("font_size", "Label") * 0.7)
		Icon.draw(self, kind, Rect2(Vector2(10, 6), Vector2(size.x - 20, size.y - 30)))
		draw_string(font, Vector2(0, size.y - 9), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, fsize, Icon.INK)


## Draws one icon inside a fixed-size control.
class Glyph:
	extends Control
	var kind := ""

	func _init(icon_kind: String, edge := 34.0) -> void:
		kind = icon_kind
		custom_minimum_size = Vector2(edge, edge)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		Icon.draw(self, kind, Rect2(Vector2.ZERO, size))
