class_name BoardArt
extends RefCounted
## Shared drawings for the things on a work board that aren't pieces: a row of
## soil, a cloth sack, a woven basket, a bowl, a baking stone. Painted in the
## same style as the pieces (soft light from the top-left, darker rims).


static func _round_rect(r: Rect2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [r.position + Vector2(radius, radius), Vector2(r.end.x - radius, r.position.y + radius), r.end - Vector2(radius, radius), Vector2(r.position.x + radius, r.end.y - radius)]
	for k in 4:
		for i in 7:
			var a := PI + k * PI / 2.0 + (PI / 2.0) * i / 6.0
			pts.append(corners[k] + Vector2(cos(a), sin(a)) * radius)
	return pts


static func _fill(ci: CanvasItem, pts: PackedVector2Array, color: Color, rim := 2.5) -> void:
	ci.draw_colored_polygon(pts, color)
	ci.draw_polyline(pts + PackedVector2Array([pts[0]]), color.darkened(0.35), rim, true)


## A raised row of dark, crumbly soil.
static func soil_row(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_colored_polygon(_round_rect(r.grow(6), 18), Color(0, 0, 0, 0.16))
	_fill(ci, _round_rect(r, 18), Color("6b4630"))
	ci.draw_colored_polygon(_round_rect(Rect2(r.position + Vector2(8, 6), Vector2(r.size.x - 16, r.size.y * 0.35)), 12), Color("7d553b"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in int(r.size.x / 9.0):
		var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		ci.draw_circle(p, rng.randf_range(2.0, 4.5), Color("5a3a27") if i % 3 else Color("8a6446"))


## A cloth sack standing open, its neck folded down.
static func sack(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	var body := PackedVector2Array()
	for i in 25:
		var t := i / 24.0
		var a := PI * t
		body.append(Vector2(c.x - cos(a) * r.size.x * (0.46 + 0.04 * sin(a)), r.position.y + 26 + sin(a) * (r.size.y - 26)))
	body.append(Vector2(c.x + r.size.x * 0.4, r.position.y + 18))
	body.append(Vector2(c.x - r.size.x * 0.4, r.position.y + 18))
	ci.draw_colored_polygon(_shadow(body, 6), Color(0, 0, 0, 0.16))
	_fill(ci, body, Color("efe4cf"))
	# The folded-down neck and a couple of cloth creases.
	_fill(ci, _round_rect(Rect2(c.x - r.size.x * 0.44, r.position.y + 8, r.size.x * 0.88, 24), 10), Color("e2d3b4"))
	for x: float in [-0.2, 0.18]:
		ci.draw_line(Vector2(c.x + r.size.x * x, r.position.y + 44), Vector2(c.x + r.size.x * (x + 0.04), r.end.y - 14), Color("d9c7a3"), 2.0)


## A round woven basket, open at the top.
static func basket(ci: CanvasItem, r: Rect2) -> void:
	var c := r.get_center()
	var bowl := PackedVector2Array()
	for i in 25:
		var a := PI * i / 24.0
		bowl.append(Vector2(c.x - cos(a) * r.size.x * 0.5, r.position.y + 20 + sin(a) * (r.size.y - 20)))
	ci.draw_colored_polygon(_shadow(bowl, 6), Color(0, 0, 0, 0.16))
	_fill(ci, bowl, Color("b07a4f"))
	# Weave: rows of little offset stitches.
	for row in int((r.size.y - 30) / 16.0):
		var y := r.position.y + 34 + row * 16
		var half := r.size.x * 0.5 * sqrt(maxf(0.0, 1.0 - pow((y - r.position.y - 20) / (r.size.y - 20), 2)))
		var x := c.x - half + 6 + (row % 2) * 9
		while x < c.x + half - 10:
			ci.draw_line(Vector2(x, y), Vector2(x + 12, y + 3), Color("8a5a3a"), 2.0)
			x += 18
	# The rim.
	ci.draw_colored_polygon(_ellipse(Vector2(c.x, r.position.y + 20), Vector2(r.size.x * 0.5, 14)), Color("c49a6c"))
	ci.draw_colored_polygon(_ellipse(Vector2(c.x, r.position.y + 21), Vector2(r.size.x * 0.44, 9)), Color("6b4630"))


## A wide bowl or tray seen from above, filled with `inside`.
static func bowl(ci: CanvasItem, c: Vector2, radius: float, inside: Color) -> void:
	ci.draw_circle(c + Vector2(5, 9), radius + 6, Color(0, 0, 0, 0.16))
	ci.draw_circle(c, radius + 4, Color("8a6a4a"))
	ci.draw_circle(c, radius, Color("c49a6c"))
	ci.draw_circle(c, radius - 12, inside.darkened(0.1))
	ci.draw_circle(c + Vector2(-3, -3), radius - 14, inside)
	ci.draw_arc(c, radius - 2, PI * 1.05, PI * 1.6, 12, Color(1, 1, 1, 0.35), 3.0)


## A flat baking stone, speckled.
static func stone_floor(ci: CanvasItem, r: Rect2) -> void:
	_fill(ci, _round_rect(r, 10), Color("8f7f70"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 120:
		ci.draw_circle(r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y), rng.randf_range(1.5, 3.5), Color("7d6e60") if i % 2 else Color("a09080"))
	ci.draw_rect(Rect2(r.position.x, r.end.y - 10, r.size.x, 10), Color("6f6154"))


static func _ellipse(c: Vector2, r: Vector2, n := 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts


static func _shadow(pts: PackedVector2Array, offset: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p + Vector2(offset * 0.6, offset))
	return out


## A linen cloth where loose pieces wait, with a stitched border.
static func cloth(ci: CanvasItem, r: Rect2) -> void:
	var pts := _round_rect(r, 16)
	ci.draw_colored_polygon(_shadow(pts, 5), Color(0, 0, 0, 0.12))
	_fill(ci, pts, Color("e9dcc0"), 2.0)
	var inner := _round_rect(r.grow(-10), 10)
	for i in inner.size():
		if i % 2 == 0:
			ci.draw_line(inner[i], inner[(i + 1) % inner.size()], Color("c8b48e"), 2.0)
	var y := r.position.y + 22
	while y < r.end.y - 16:
		ci.draw_line(Vector2(r.position.x + 18, y), Vector2(r.end.x - 18, y), Color(0.6, 0.5, 0.35, 0.08), 1.0)
		y += 8


## A wooden material box, open, with a lip and grain.
static func wood_box(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_colored_polygon(_shadow(_round_rect(r.grow(8), 10), 7), Color(0, 0, 0, 0.18))
	_fill(ci, _round_rect(r.grow(8), 10), Color("7b5338"))
	_fill(ci, _round_rect(r, 6), Color("c49a6c"), 1.5)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 10)), Color(0, 0, 0, 0.1))
	var y := r.position.y + 22
	var k := 0
	while y < r.end.y - 6:
		var pts := PackedVector2Array()
		for x in range(int(r.position.x) + 6, int(r.end.x) - 4, 30):
			pts.append(Vector2(x, y + sin(x * 0.02 + k) * 2.0))
		ci.draw_polyline(pts, Color("b5875a"), 1.5, true)
		y += 24
		k += 1


## A wooden feeding trough on two legs.
static func trough(ci: CanvasItem, c: Vector2) -> void:
	ci.draw_colored_polygon(_ellipse(c + Vector2(6, 64), Vector2(70, 10)), Color(0, 0, 0, 0.16))
	for x: float in [-50.0, 50.0]:
		_fill(ci, _round_rect(Rect2(c + Vector2(x - 7, 30), Vector2(14, 34)), 3), Color("6b4630"), 1.5)
	var outer := PackedVector2Array([c + Vector2(-74, -36), c + Vector2(74, -36), c + Vector2(58, 40), c + Vector2(-58, 40)])
	_fill(ci, outer, Color("9a6a46"))
	for k in 3:
		var y := c.y - 14 + k * 20
		ci.draw_line(Vector2(c.x - 66 + k * 4, y), Vector2(c.x + 66 - k * 4, y), Color("7b5338"), 2.0)
	var inner := PackedVector2Array([c + Vector2(-62, -28), c + Vector2(62, -28), c + Vector2(52, 28), c + Vector2(-52, 28)])
	ci.draw_colored_polygon(inner, Color("5e3b26"))
	ci.draw_line(c + Vector2(-74, -36), c + Vector2(74, -36), Color("b8875e"), 4.0)


## Bricks laid around an arch, following its curve.
static func brick_arch(ci: CanvasItem, center: Vector2, radius: Vector2, thickness: float) -> void:
	for i in 17:
		var a0 := PI + PI * i / 17.0
		var a1 := PI + PI * (i + 1) / 17.0
		var q := PackedVector2Array([
			center + Vector2(cos(a0) * radius.x, sin(a0) * radius.y),
			center + Vector2(cos(a1) * radius.x, sin(a1) * radius.y),
			center + Vector2(cos(a1) * (radius.x + thickness), sin(a1) * (radius.y + thickness)),
			center + Vector2(cos(a0) * (radius.x + thickness), sin(a0) * (radius.y + thickness)),
		])
		_fill(ci, q, Color("b8584a") if i % 2 else Color("c46a55"), 1.5)
