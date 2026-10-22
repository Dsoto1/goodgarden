class_name Icon
extends RefCounted
## Small hand-drawn interface icons, drawn in code so they scale crisply at
## any text size. Buttons carry one beside their words (see IconButton), so a
## child who can't read yet can still tell "yes" from "not yet".

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
		"yes":
			# A green tick.
			ci.draw_circle(c, 0.44 * s, Color("dcebc8"))
			ci.draw_polyline(PackedVector2Array([c + Vector2(-0.22, 0.0) * s, c + Vector2(-0.06, 0.17) * s, c + Vector2(0.24, -0.18) * s]), Color("4f7a3a"), maxf(2.5, s * 0.12))
		"table":
			# A plate with a cup beside it: setting the table.
			ci.draw_circle(c + Vector2(-0.08, 0.04) * s, 0.3 * s, Color("fbf5e8"))
			ci.draw_arc(c + Vector2(-0.08, 0.04) * s, 0.3 * s, 0, TAU, 24, color, 1.5)
			ci.draw_arc(c + Vector2(-0.08, 0.04) * s, 0.18 * s, 0, TAU, 20, Color("c9a86e"), 1.5)
			ci.draw_rect(Rect2(c + Vector2(0.26, -0.2) * s, Vector2(0.16, 0.2) * s), Color("6f9fc0"))
			ci.draw_rect(Rect2(c + Vector2(0.26, -0.2) * s, Vector2(0.16, 0.2) * s), color, false, 1.5)
		"hen":
			# A brown hen with a red comb, pecking at grain.
			ci.draw_circle(c + Vector2(0.04, 0.06) * s, 0.24 * s, Color("c98a4e"))
			ci.draw_circle(c + Vector2(-0.2, -0.16) * s, 0.13 * s, Color("c98a4e"))
			ci.draw_arc(c + Vector2(0.1, 0.06) * s, 0.13 * s, -0.4, 2.2, 10, Color("8a5a32"), maxf(1.5, s * 0.06))
			ci.draw_circle(c + Vector2(-0.23, -0.18) * s, 0.025 * s, color)
			ci.draw_circle(c + Vector2(-0.2, -0.31) * s, 0.06 * s, Color("c8463a"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.32, -0.18) * s, c + Vector2(-0.44, -0.12) * s, c + Vector2(-0.32, -0.1) * s]), Color("e0a73a"))
			for x: float in [-0.36, -0.26, -0.42]:
				ci.draw_circle(c + Vector2(x, 0.38) * s, 0.025 * s, Color("e0a73a"))
		"water":
			# A watering can, pouring.
			ci.draw_rect(Rect2(c + Vector2(-0.3, -0.12) * s, Vector2(0.4, 0.38) * s), Color("6f9fc0"))
			ci.draw_rect(Rect2(c + Vector2(-0.3, -0.12) * s, Vector2(0.4, 0.38) * s), color, false, 1.5)
			ci.draw_line(c + Vector2(0.1, 0.12) * s, c + Vector2(0.38, -0.14) * s, Color("5f8aa8"), maxf(2.0, s * 0.08))
			ci.draw_arc(c + Vector2(-0.1, -0.12) * s, 0.14 * s, PI, TAU, 10, color, 1.5)
			for k in 3:
				ci.draw_circle(c + Vector2(0.42 + k * 0.02, -0.02 + k * 0.12) * s, 0.03 * s, Color("5f93b8"))
		"bread":
			# A round loaf with scored lines.
			var loaf := PackedVector2Array()
			for i in 18:
				var a := PI + PI * i / 17.0
				loaf.append(c + Vector2(cos(a) * 0.4, sin(a) * 0.3 + 0.12) * s)
			ci.draw_colored_polygon(loaf, Color("d9a15c"))
			ci.draw_line(c + Vector2(-0.4, 0.12) * s, c + Vector2(0.4, 0.12) * s, Color("a8733e"), 2.0)
			for x: float in [-0.16, 0.0, 0.16]:
				ci.draw_line(c + Vector2(x - 0.05, -0.02) * s, c + Vector2(x + 0.05, -0.12) * s, Color("a8733e"), 1.5)
		"heart":
			# Petting an animal: a small heart.
			ci.draw_circle(c + Vector2(-0.14, -0.06) * s, 0.17 * s, Color("e07a8a"))
			ci.draw_circle(c + Vector2(0.14, -0.06) * s, 0.17 * s, Color("e07a8a"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.3, 0.0) * s, c + Vector2(0.3, 0.0) * s, c + Vector2(0, 0.36) * s]), Color("e07a8a"))
		"tree":
			# A young apple tree.
			ci.draw_rect(Rect2(c + Vector2(-0.05, 0.02) * s, Vector2(0.1, 0.36) * s), Color("7b5338"))
			ci.draw_circle(c + Vector2(0, -0.12) * s, 0.28 * s, Color("7fb35a"))
			for p: Vector2 in [Vector2(-0.12, -0.16), Vector2(0.1, -0.04), Vector2(0.06, -0.26)]:
				ci.draw_circle(c + p * s, 0.05 * s, Color("c8463a"))
		"card":
			# A folded card with a heart.
			ci.draw_rect(Rect2(c + Vector2(-0.3, -0.36) * s, Vector2(0.6, 0.72) * s), Color("fbf5e8"))
			ci.draw_rect(Rect2(c + Vector2(-0.3, -0.36) * s, Vector2(0.6, 0.72) * s), color, false, 1.5)
			ci.draw_circle(c + Vector2(-0.07, -0.03) * s, 0.08 * s, Color("e07a8a"))
			ci.draw_circle(c + Vector2(0.07, -0.03) * s, 0.08 * s, Color("e07a8a"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.15, 0.0) * s, c + Vector2(0.15, 0.0) * s, c + Vector2(0, 0.17) * s]), Color("e07a8a"))
		"pig":
			# A round pink pig, side on.
			ci.draw_circle(c + Vector2(0.04, 0.04) * s, 0.3 * s, Color("e9a8a8"))
			ci.draw_circle(c + Vector2(-0.26, -0.04) * s, 0.17 * s, Color("e9a8a8"))
			ci.draw_circle(c + Vector2(-0.4, 0.0) * s, 0.07 * s, Color("d98a8a"))
			for x: float in [-0.43, -0.37]:
				ci.draw_circle(c + Vector2(x, 0.0) * s, 0.015 * s, color)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.3, -0.18) * s, c + Vector2(-0.2, -0.3) * s, c + Vector2(-0.16, -0.16) * s]), Color("d98a8a"))
			ci.draw_circle(c + Vector2(-0.27, -0.08) * s, 0.025 * s, color)
			for x: float in [-0.12, 0.2]:
				ci.draw_rect(Rect2(c + Vector2(x - 0.04, 0.26) * s, Vector2(0.08, 0.12) * s), Color("d98a8a"))
			ci.draw_arc(c + Vector2(0.38, -0.04) * s, 0.06 * s, 0, PI * 1.5, 8, Color("d98a8a"), maxf(1.5, s * 0.04))
		"cat":
			# A sitting ginger cat.
			ci.draw_circle(c + Vector2(0, 0.14) * s, 0.24 * s, Color("e0a35a"))
			ci.draw_circle(c + Vector2(0, -0.18) * s, 0.17 * s, Color("e0a35a"))
			for side: float in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(side * 0.16, -0.24) * s, c + Vector2(side * 0.14, -0.42) * s, c + Vector2(side * 0.04, -0.32) * s]), Color("e0a35a"))
				ci.draw_circle(c + Vector2(side * 0.06, -0.2) * s, 0.025 * s, color)
			ci.draw_arc(c + Vector2(0.3, 0.2) * s, 0.12 * s, -PI * 0.5, PI * 0.6, 10, Color("c98a45"), maxf(2.0, s * 0.06))
		"dog":
			# A little pug, sitting.
			ci.draw_circle(c + Vector2(0, 0.14) * s, 0.24 * s, Color("e6cfa6"))
			ci.draw_circle(c + Vector2(0, -0.16) * s, 0.19 * s, Color("e6cfa6"))
			ci.draw_circle(c + Vector2(0, -0.1) * s, 0.1 * s, Color("5a3f30"))
			for side: float in [-1.0, 1.0]:
				ci.draw_circle(c + Vector2(side * 0.17, -0.26) * s, 0.07 * s, Color("5a3f30"))
				ci.draw_circle(c + Vector2(side * 0.08, -0.2) * s, 0.025 * s, color)
		"cow":
			# A black-and-white cow's face.
			ci.draw_circle(c + Vector2(0, -0.04) * s, 0.28 * s, Color("f6f1e4"))
			ci.draw_circle(c + Vector2(-0.12, -0.14) * s, 0.1 * s, Color("3b3430"))
			ci.draw_rect(Rect2(c + Vector2(-0.2, 0.08) * s, Vector2(0.4, 0.2) * s), Color("e9a8a8"))
			for side: float in [-1.0, 1.0]:
				ci.draw_circle(c + Vector2(side * 0.1, 0.18) * s, 0.025 * s, color)
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(side * 0.22, -0.24) * s, c + Vector2(side * 0.42, -0.3) * s, c + Vector2(side * 0.26, -0.16) * s]), Color("f6f1e4"))
				ci.draw_circle(c + Vector2(side * 0.1, -0.06) * s, 0.025 * s, color)
		"letters":
			# Three little letter tiles: the moveable alphabet.
			var font := UiStyle.font()
			for k in 3:
				var tile := Rect2(c + Vector2(-0.44 + k * 0.3, -0.16 + (k % 2) * 0.08) * s, Vector2(0.27, 0.3) * s)
				ci.draw_rect(tile, Color("f6ecd6"))
				ci.draw_rect(tile, Color("c9a86e"), false, 1.5)
				ci.draw_string(font, tile.position + Vector2(0, tile.size.y * 0.82), ["a", "b", "c"][k], HORIZONTAL_ALIGNMENT_CENTER, tile.size.x, int(tile.size.y * 0.8), Color("2f5fa8") if k == 0 else Color("b8392f"))
		"bun":
			# A round bun with a shiny top.
			ci.draw_circle(c + Vector2(0, 0.06) * s, 0.34 * s, Color("d9963f"))
			ci.draw_circle(c + Vector2(-0.1, -0.04) * s, 0.14 * s, Color("eebd72"))
			ci.draw_arc(c + Vector2(0, 0.06) * s, 0.34 * s, PI * 0.1, PI * 0.9, 12, Color("a8662a"), maxf(1.5, s * 0.04))
		"jam":
			# A jar of red jam with a cloth lid.
			ci.draw_rect(Rect2(c + Vector2(-0.22, -0.14) * s, Vector2(0.44, 0.5) * s), Color("b8392f"))
			ci.draw_rect(Rect2(c + Vector2(-0.22, -0.14) * s, Vector2(0.44, 0.5) * s), color, false, 1.5)
			ci.draw_rect(Rect2(c + Vector2(-0.28, -0.3) * s, Vector2(0.56, 0.16) * s), Color("efe4cf"))
			ci.draw_rect(Rect2(c + Vector2(-0.12, 0.02) * s, Vector2(0.24, 0.16) * s), Color("fbf5e8"))
		"egg":
			var shell := PackedVector2Array()
			for i in 24:
				var a := TAU * i / 24.0
				shell.append(c + Vector2(cos(a) * 0.26, sin(a) * (0.34 if sin(a) < 0 else 0.3) + 0.04) * s)
			ci.draw_colored_polygon(shell, Color("f3e3c8"))
			ci.draw_polyline(shell + PackedVector2Array([shell[0]]), color, 1.5)
		"nut":
			# A hazelnut: a round brown nut with a pale cap.
			ci.draw_circle(c + Vector2(0, 0.08) * s, 0.28 * s, Color("a8733e"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.3, -0.06) * s, c + Vector2(0, -0.32) * s, c + Vector2(0.3, -0.06) * s]), Color("d9b98a"))
			ci.draw_line(c + Vector2(0, -0.32) * s, c + Vector2(0.04, -0.42) * s, Color("7b5338"), maxf(1.5, s * 0.04))
		"fig":
			# A purple fig with a little stalk.
			var body := PackedVector2Array()
			for i in 24:
				var a := TAU * i / 24.0
				var w := 0.3 if sin(a) > 0 else 0.3 - 0.14 * absf(sin(a))
				body.append(c + Vector2(cos(a) * w, sin(a) * 0.32 + 0.06) * s)
			ci.draw_colored_polygon(body, Color("7a4a7a"))
			ci.draw_line(c + Vector2(0, -0.26) * s, c + Vector2(0.04, -0.4) * s, Color("5f8a3f"), maxf(2.0, s * 0.05))
		"measure":
			# A stack of three blocks beside a little plant.
			for k in 3:
				var blk := Rect2(c + Vector2(0.04, 0.22 - k * 0.22) * s, Vector2(0.24, 0.2) * s)
				ci.draw_rect(blk, Color("e0b77a"))
				ci.draw_rect(blk, Color("9c7049"), false, 1.5)
			ci.draw_line(c + Vector2(-0.2, 0.42) * s, c + Vector2(-0.2, -0.36) * s, Color("5f8a3f"), maxf(2.0, s * 0.06))
			for k in 3:
				var side := -1.0 if k % 2 == 0 else 1.0
				ci.draw_circle(c + Vector2(-0.2 + side * 0.09, 0.2 - k * 0.22) * s, 0.07 * s, Color("7fb04a"))
		"coin":
			# Two coins, one stamped 1 and one 5.
			ci.draw_circle(c + Vector2(-0.12, 0.08) * s, 0.26 * s, Color("c98a4e"))
			ci.draw_circle(c + Vector2(0.14, -0.08) * s, 0.26 * s, Color("e0b64c"))
			ci.draw_arc(c + Vector2(0.14, -0.08) * s, 0.2 * s, 0, TAU, 18, Color("a8862a"), maxf(1.5, s * 0.04))
			ci.draw_string(UiStyle.font(), c + Vector2(0.02, 0.06) * s, "5", HORIZONTAL_ALIGNMENT_CENTER, 0.24 * s, int(0.3 * s), Color("6b5418"))
		"lens":
			# A magnifying glass.
			ci.draw_line(c + Vector2(0.12, 0.12) * s, c + Vector2(0.38, 0.38) * s, Color("8a5a3a"), maxf(3.0, s * 0.1))
			ci.draw_circle(c + Vector2(-0.08, -0.08) * s, 0.24 * s, Color(0.85, 0.93, 1.0))
			ci.draw_arc(c + Vector2(-0.08, -0.08) * s, 0.26 * s, 0, TAU, 24, Color("b8913a"), maxf(2.0, s * 0.07))
		"pot":
			# A round cooking pot with two ears.
			ci.draw_rect(Rect2(c + Vector2(-0.3, -0.12) * s, Vector2(0.6, 0.42) * s), Color("5a5550"))
			ci.draw_rect(Rect2(c + Vector2(-0.34, -0.18) * s, Vector2(0.68, 0.08) * s), Color("75706a"))
			for side: float in [-1.0, 1.0]:
				ci.draw_arc(c + Vector2(side * 0.36, -0.02) * s, 0.07 * s, 0, TAU, 10, Color("75706a"), maxf(2.0, s * 0.05))
		"pan":
			# A frying pan with a long handle.
			ci.draw_circle(c + Vector2(-0.1, 0.04) * s, 0.26 * s, Color("5a5550"))
			ci.draw_circle(c + Vector2(-0.1, 0.04) * s, 0.2 * s, Color("75706a"))
			ci.draw_line(c + Vector2(0.14, 0.04) * s, c + Vector2(0.46, -0.14) * s, Color("8a5a3a"), maxf(3.0, s * 0.08))
		"cup":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.24, -0.22) * s, c + Vector2(0.24, -0.22) * s, c + Vector2(0.18, 0.3) * s, c + Vector2(-0.18, 0.3) * s]), Color("e9dcc0"))
			ci.draw_rect(Rect2(c + Vector2(-0.24, -0.26) * s, Vector2(0.48, 0.06) * s), Color("8fb6d6"))
		"mug":
			ci.draw_rect(Rect2(c + Vector2(-0.24, -0.24) * s, Vector2(0.4, 0.52) * s), Color("8fb6d6"))
			ci.draw_arc(c + Vector2(0.18, 0.02) * s, 0.12 * s, -PI / 2.0, PI / 2.0, 10, Color("6a8fb0"), maxf(3.0, s * 0.07))
		"lid":
			# A pot lid with a knob.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.4, 0.14) * s, c + Vector2(-0.24, -0.06) * s, c + Vector2(0.24, -0.06) * s, c + Vector2(0.4, 0.14) * s]), Color("75706a"))
			ci.draw_circle(c + Vector2(0, -0.12) * s, 0.07 * s, Color("8a5a3a"))
		"log":
			ci.draw_rect(Rect2(c + Vector2(-0.36, -0.14) * s, Vector2(0.66, 0.3) * s), Color("8a5a3a"))
			ci.draw_circle(c + Vector2(0.3, 0.01) * s, 0.15 * s, Color("d9b98a"))
			ci.draw_arc(c + Vector2(0.3, 0.01) * s, 0.08 * s, 0, TAU, 12, Color("a8733e"), maxf(1.5, s * 0.03))
		"bug":
			# A beetle: round shell, head and six legs.
			for k in 3:
				for side: float in [-1.0, 1.0]:
					ci.draw_line(c + Vector2(0, -0.06 + k * 0.12) * s, c + Vector2(side * 0.3, -0.12 + k * 0.16) * s, Color("3a2a22"), maxf(1.5, s * 0.03))
			ci.draw_circle(c + Vector2(0, 0.04) * s, 0.2 * s, Color("4f7a3a"))
			ci.draw_circle(c + Vector2(0, -0.22) * s, 0.09 * s, Color("3a2a22"))
			ci.draw_line(c + Vector2(0, -0.14) * s, c + Vector2(0, 0.24) * s, Color("2f4a22"), maxf(1.5, s * 0.03))
		"web":
			for k in 8:
				var a := TAU * k / 8.0
				ci.draw_line(c, c + Vector2(cos(a), sin(a)) * 0.4 * s, Color("8a8a8a"), maxf(1.0, s * 0.02))
			for ring in 3:
				ci.draw_arc(c, (0.12 + ring * 0.12) * s, 0, TAU, 8, Color("8a8a8a"), maxf(1.0, s * 0.02))
		"fox":
			# A fox's face: orange triangle head, white cheeks, pointed ears.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.34, -0.16) * s, c + Vector2(0.34, -0.16) * s, c + Vector2(0, 0.34) * s]), Color("d9733a"))
			for side: float in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(side * 0.34, -0.16) * s, c + Vector2(side * 0.3, -0.42) * s, c + Vector2(side * 0.1, -0.16) * s]), Color("d9733a"))
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(side * 0.3, -0.12) * s, c + Vector2(side * 0.06, -0.02) * s, c + Vector2(0, 0.3) * s]), Color("f6ecdc"))
				ci.draw_circle(c + Vector2(side * 0.12, -0.06) * s, 0.035 * s, Color("2a2420"))
			ci.draw_circle(c + Vector2(0, 0.3) * s, 0.05 * s, Color("2a2420"))
		"weed":
			for k in 5:
				var a := -PI / 2.0 + (k - 2) * 0.4
				ci.draw_line(c + Vector2(0, 0.3) * s, c + Vector2(0, 0.3) * s + Vector2(cos(a), sin(a)) * 0.6 * s, Color("6a8a3a"), maxf(2.0, s * 0.06))
			ci.draw_line(c + Vector2(-0.3, 0.32) * s, c + Vector2(0.3, 0.32) * s, Color("8a5a3a"), maxf(2.0, s * 0.05))
		"flower":
			ci.draw_line(c + Vector2(0, 0.06) * s, c + Vector2(0, 0.42) * s, Color("5f8a3f"), maxf(2.0, s * 0.05))
			for k in 5:
				var a := TAU * k / 5.0 - PI / 2.0
				ci.draw_circle(c + Vector2(0, -0.08) * s + Vector2(cos(a), sin(a)) * 0.16 * s, 0.11 * s, Color("d9473c") if k % 2 == 0 else Color("f2c14e"))
			ci.draw_circle(c + Vector2(0, -0.08) * s, 0.08 * s, Color("f6e3a0"))
		"leaf":
			# A maple leaf.
			var leaf := PackedVector2Array()
			for k in 10:
				var a := TAU * k / 10.0 - PI / 2.0
				leaf.append(c + Vector2(cos(a), sin(a)) * (0.4 if k % 2 == 0 else 0.18) * s)
			ci.draw_colored_polygon(leaf, Color("d9733a"))
			ci.draw_line(c, c + Vector2(0, 0.44) * s, Color("8a4a2a"), maxf(1.5, s * 0.04))
		"acorn":
			ci.draw_circle(c + Vector2(0, 0.08) * s, 0.24 * s, Color("a8733e"))
			ci.draw_rect(Rect2(c + Vector2(-0.28, -0.2) * s, Vector2(0.56, 0.16) * s), Color("7b5338"))
			ci.draw_line(c + Vector2(0, -0.2) * s, c + Vector2(0.06, -0.36) * s, Color("5a3d28"), maxf(2.0, s * 0.05))
		"stone":
			ci.draw_colored_polygon(_oval(c + Vector2(-0.14, 0.1) * s, Vector2(0.24, 0.16) * s), Color("b7aea0"))
			ci.draw_colored_polygon(_oval(c + Vector2(0.22, -0.12) * s, Vector2(0.14, 0.1) * s), Color("9a9184"))
		"bird":
			# A little round songbird.
			ci.draw_circle(c + Vector2(0, 0.06) * s, 0.24 * s, Color("8a5a3a"))
			ci.draw_circle(c + Vector2(0.18, -0.16) * s, 0.13 * s, Color("8a5a3a"))
			ci.draw_circle(c + Vector2(0.06, 0.12) * s, 0.14 * s, Color("d9733a"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.3, -0.18) * s, c + Vector2(0.42, -0.14) * s, c + Vector2(0.3, -0.1) * s]), Color("e0b64c"))
			ci.draw_circle(c + Vector2(0.21, -0.19) * s, 0.025 * s, Color("2a2420"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.2, 0.0) * s, c + Vector2(-0.44, -0.12) * s, c + Vector2(-0.36, 0.1) * s]), Color("6a4a2e"))
		"shapes":
			# A square, a triangle and a circle.
			ci.draw_rect(Rect2(c + Vector2(-0.4, 0.02) * s, Vector2(0.32, 0.32) * s), Color("5f8fd0"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.04, 0.34) * s, c + Vector2(0.4, 0.34) * s, c + Vector2(0.22, 0.02) * s]), Color("d9473c"))
			ci.draw_circle(c + Vector2(-0.02, -0.2) * s, 0.16 * s, Color("e0b64c"))
		"window":
			ci.draw_rect(Rect2(c + Vector2(-0.34, -0.36) * s, Vector2(0.68, 0.72) * s), Color("8a5a3a"))
			for k in 4:
				var pane: Color = [Color("8fb6d6"), Color("e0b64c"), Color("d9473c"), Color("6fa84f")][k]
				ci.draw_rect(Rect2(c + Vector2(-0.28 + (k % 2) * 0.3, -0.3 + (k / 2) * 0.32) * s, Vector2(0.26, 0.28) * s), pane)
		"note":
			# A slip of paper with lines of writing.
			ci.draw_rect(Rect2(c + Vector2(-0.3, -0.38) * s, Vector2(0.6, 0.76) * s), Color("fbf5e8"))
			ci.draw_rect(Rect2(c + Vector2(-0.3, -0.38) * s, Vector2(0.6, 0.76) * s), color, false, 1.5)
			for k in 4:
				ci.draw_line(c + Vector2(-0.2, -0.22 + k * 0.16) * s, c + Vector2(0.2 - (k % 2) * 0.1, -0.22 + k * 0.16) * s, Color("3b3430"), maxf(1.5, s * 0.04))
		"plank":
			# A saw over a plank.
			ci.draw_rect(Rect2(c + Vector2(-0.42, 0.14) * s, Vector2(0.84, 0.18) * s), Color("c79a62"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.3, -0.04) * s, c + Vector2(0.3, -0.24) * s, c + Vector2(0.32, -0.12) * s, c + Vector2(-0.28, 0.06) * s]), Color("a3a8ae"))
			ci.draw_rect(Rect2(c + Vector2(0.28, -0.32) * s, Vector2(0.16, 0.2) * s), Color("8a5a3a"))
		"birdhouse":
			ci.draw_rect(Rect2(c + Vector2(-0.24, -0.08) * s, Vector2(0.48, 0.42) * s), Color("c79a62"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.34, -0.06) * s, c + Vector2(0, -0.4) * s, c + Vector2(0.34, -0.06) * s]), Color("b8392f"))
			ci.draw_circle(c + Vector2(0, 0.1) * s, 0.08 * s, Color("3b3430"))
		"scales":
			# A balance: a post, a beam and two pans.
			ci.draw_line(c + Vector2(0, -0.34) * s, c + Vector2(0, 0.36) * s, Color("8a5a3a"), maxf(2.0, s * 0.06))
			ci.draw_line(c + Vector2(-0.38, -0.26) * s, c + Vector2(0.38, -0.26) * s, Color("8a5a3a"), maxf(2.0, s * 0.05))
			for side: float in [-1.0, 1.0]:
				ci.draw_line(c + Vector2(side * 0.38, -0.26) * s, c + Vector2(side * 0.38, 0.0) * s, color, 1.5)
				ci.draw_arc(c + Vector2(side * 0.38, 0.0) * s, 0.14 * s, 0, PI, 10, Color("b8913a"), maxf(2.0, s * 0.05))
			ci.draw_line(c + Vector2(-0.16, 0.36) * s, c + Vector2(0.16, 0.36) * s, Color("8a5a3a"), maxf(2.0, s * 0.06))
		"todo":
			# An empty ring, waiting for its tick.
			ci.draw_arc(c, 0.36 * s, 0, TAU, 32, Color("b89a78"), maxf(2.0, s * 0.08), true)
		"back":
			# A soft arrow curling back: "not yet", "go back".
			ci.draw_circle(c, 0.44 * s, Color("efe4cf"))
			_arrow(ci, c, s, -1.0, color)
		"next":
			ci.draw_circle(c, 0.44 * s, Color("dcebc8"))
			_arrow(ci, c, s, 1.0, Color("4f7a3a"))
		"speaker":
			var cone := PackedVector2Array([c + Vector2(-0.36, -0.1) * s, c + Vector2(-0.2, -0.1) * s, c + Vector2(0.0, -0.3) * s, c + Vector2(0.0, 0.3) * s, c + Vector2(-0.2, 0.1) * s, c + Vector2(-0.36, 0.1) * s])
			ci.draw_colored_polygon(cone, color)
			for k in 2:
				ci.draw_arc(c + Vector2(0.02, 0) * s, (0.16 + k * 0.14) * s, -0.9, 0.9, 10, color, maxf(1.5, s * 0.06))
		"pause":
			for x: float in [-0.14, 0.14]:
				ci.draw_rect(Rect2(c + Vector2(x - 0.07, -0.26) * s, Vector2(0.14, 0.52) * s), color)
		"restart":
			ci.draw_arc(c, 0.28 * s, 0.6, TAU - 0.3, 20, color, maxf(2.0, s * 0.09))
			var tip := c + Vector2(cos(0.6), sin(0.6)) * 0.28 * s
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(0.14, -0.04) * s, tip + Vector2(-0.12, -0.08) * s, tip + Vector2(0.02, 0.16) * s]), color)
		"hint":
			# A lightbulb: "show me".
			ci.draw_circle(c + Vector2(0, -0.08) * s, 0.26 * s, Color("f2c14e"))
			ci.draw_arc(c + Vector2(0, -0.08) * s, 0.26 * s, 0, TAU, 20, color, 1.5)
			ci.draw_rect(Rect2(c + Vector2(-0.12, 0.18) * s, Vector2(0.24, 0.18) * s), Color("b9a07a"))
			ci.draw_rect(Rect2(c + Vector2(-0.12, 0.18) * s, Vector2(0.24, 0.18) * s), color, false, 1.5)
		"door":
			# A door with a knob: "finish later", "go to the title".
			var d := Rect2(c - Vector2(0.24, 0.4) * s, Vector2(0.48, 0.8) * s)
			ci.draw_rect(d, Color("b07a4f"))
			ci.draw_rect(d, color, false, 2.0)
			ci.draw_circle(c + Vector2(0.12, 0.04) * s, 0.05 * s, Color("f2c14e"))
		"box":
			# A wooden box with its lid: "put the story away".
			ci.draw_rect(Rect2(c + Vector2(-0.38, -0.08) * s, Vector2(0.76, 0.44) * s), Color("c49a6c"))
			ci.draw_rect(Rect2(c + Vector2(-0.38, -0.08) * s, Vector2(0.76, 0.44) * s), color, false, 2.0)
			ci.draw_rect(Rect2(c + Vector2(-0.44, -0.26) * s, Vector2(0.88, 0.16) * s), Color("7b5338"))
		"wonder":
			# A little sparkle for wondering questions.
			var star := PackedVector2Array()
			for i in 8:
				var a := TAU * i / 8.0 - PI / 2.0
				star.append(c + Vector2(cos(a), sin(a)) * (0.42 if i % 2 == 0 else 0.14) * s)
			ci.draw_colored_polygon(star, Color("f2c14e"))
			ci.draw_polyline(star + PackedVector2Array([star[0]]), color, 1.5)
		"talk":
			# A speech bubble: "tell it myself", "talk".
			var bubble := Rect2(c - Vector2(0.4, 0.3) * s, Vector2(0.8, 0.5) * s)
			ci.draw_rect(bubble, Color("fbf5e8"))
			ci.draw_rect(bubble, color, false, 2.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.18, 0.2) * s, c + Vector2(-0.02, 0.2) * s, c + Vector2(-0.26, 0.4) * s]), color)
		"hand":
			# A pointing hand: "do this".
			ci.draw_circle(c + Vector2(-0.08, 0.1) * s, 0.24 * s, Color("e9c9a4"))
			ci.draw_rect(Rect2(c + Vector2(-0.06, -0.42) * s, Vector2(0.14, 0.42) * s), Color("e9c9a4"))
			ci.draw_arc(c + Vector2(-0.08, 0.1) * s, 0.24 * s, 0, TAU, 18, color, 1.5)
		"up":
			ci.draw_circle(c, 0.44 * s, Color("efe4cf"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -0.28) * s, c + Vector2(0.22, 0.0) * s, c + Vector2(-0.22, 0.0) * s]), color)
			ci.draw_rect(Rect2(c + Vector2(-0.07, -0.02) * s, Vector2(0.14, 0.28) * s), color)
		"lock":
			# For grown-ups.
			ci.draw_arc(c + Vector2(0, -0.08) * s, 0.16 * s, PI, TAU, 12, color, maxf(2.0, s * 0.07))
			ci.draw_rect(Rect2(c + Vector2(-0.24, -0.08) * s, Vector2(0.48, 0.42) * s), Color("b9a07a"))
			ci.draw_rect(Rect2(c + Vector2(-0.24, -0.08) * s, Vector2(0.48, 0.42) * s), color, false, 2.0)
		"home":
			ci.draw_rect(Rect2(c + Vector2(-0.28, -0.04) * s, Vector2(0.56, 0.4) * s), Color("f2e6cf"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.4, -0.02) * s, c + Vector2(0, -0.4) * s, c + Vector2(0.4, -0.02) * s]), Color("b8584a"))
			ci.draw_rect(Rect2(c + Vector2(-0.07, 0.14) * s, Vector2(0.14, 0.22) * s), Color("7b5338"))
		"chapel":
			ci.draw_rect(Rect2(c + Vector2(-0.24, -0.06) * s, Vector2(0.48, 0.42) * s), Color("e3d6bd"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.3, -0.04) * s, c + Vector2(0, -0.3) * s, c + Vector2(0.3, -0.04) * s]), Color("8a7f8e"))
			ci.draw_line(c + Vector2(0, -0.46) * s, c + Vector2(0, -0.28) * s, Color("e0a73a"), 2.0)
			ci.draw_line(c + Vector2(-0.07, -0.4) * s, c + Vector2(0.07, -0.4) * s, Color("e0a73a"), 2.0)
			ci.draw_rect(Rect2(c + Vector2(-0.07, 0.14) * s, Vector2(0.14, 0.22) * s), Color("7b5338"))
		"village":
			for k in 2:
				var o := Vector2(-0.18 + k * 0.34, 0.06 - k * 0.1)
				ci.draw_rect(Rect2(c + (o + Vector2(-0.15, -0.02)) * s, Vector2(0.3, 0.3) * s), Color("f2e6cf"))
				ci.draw_colored_polygon(PackedVector2Array([c + (o + Vector2(-0.2, 0.0)) * s, c + (o + Vector2(0, -0.22)) * s, c + (o + Vector2(0.2, 0.0)) * s]), Color("d07a3a") if k == 0 else Color("4f8a5a"))
		"river":
			for k in 3:
				var y := -0.2 + k * 0.2
				var wave := PackedVector2Array()
				for i in 9:
					wave.append(c + Vector2(-0.38 + i * 0.095, y + sin(i * 1.2) * 0.05) * s)
				ci.draw_polyline(wave, Color("5f93b8"), maxf(2.0, s * 0.07))
		"moon":
			ci.draw_circle(c, 0.32 * s, Color("f2c14e"))
			ci.draw_circle(c + Vector2(0.14, -0.1) * s, 0.28 * s, Color("fbf5e8"))
		"book":
			ci.draw_rect(Rect2(c - Vector2(0.3, 0.38) * s, Vector2(0.6, 0.76) * s), Color("b8584a"))
			ci.draw_rect(Rect2(c - Vector2(0.3, 0.38) * s, Vector2(0.6, 0.76) * s), color, false, 2.0)
			ci.draw_line(c + Vector2(-0.2, -0.38) * s, c + Vector2(-0.2, 0.38) * s, color, 1.5)
		"sheep":
			for p: Vector3 in [Vector3(-0.15, 0, 0.18), Vector3(0.1, -0.06, 0.2), Vector3(0.2, 0.06, 0.17), Vector3(-0.02, 0.08, 0.18)]:
				ci.draw_circle(c + Vector2(p.x, p.y) * s, p.z * s, Color("f6f1e4"))
			ci.draw_circle(c + Vector2(-0.32, -0.04) * s, 0.1 * s, Color("3b3430"))
			for x: float in [-0.12, 0.14]:
				ci.draw_line(c + Vector2(x, 0.2) * s, c + Vector2(x, 0.36) * s, Color("3b3430"), 2.0)
		"mill":
			# A water wheel.
			ci.draw_circle(c, 0.36 * s, Color("b07a4f"))
			ci.draw_circle(c, 0.24 * s, Color("efe4cf"))
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * 0.08 * s, c + Vector2(cos(a), sin(a)) * 0.4 * s, Color("7b5338"), maxf(1.5, s * 0.05))
			ci.draw_circle(c, 0.08 * s, Color("7b5338"))
		"fish":
			var body := PackedVector2Array()
			for i in 16:
				var a := TAU * i / 16.0
				body.append(c + Vector2(cos(a) * 0.3 - 0.05, sin(a) * 0.14) * s)
			ci.draw_colored_polygon(body, Color("6f9fc0"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.22, 0) * s, c + Vector2(0.42, -0.16) * s, c + Vector2(0.42, 0.16) * s]), Color("5f8aa8"))
			ci.draw_circle(c + Vector2(-0.22, -0.03) * s, 0.03 * s, color)
		"bridge":
			ci.draw_rect(Rect2(c + Vector2(-0.42, -0.08) * s, Vector2(0.84, 0.14) * s), Color("b7aea0"))
			ci.draw_arc(c + Vector2(0, 0.3) * s, 0.24 * s, PI, TAU, 14, Color("8f877b"), maxf(2.0, s * 0.08))
			ci.draw_line(c + Vector2(-0.42, 0.3) * s, c + Vector2(0.42, 0.3) * s, Color("5f93b8"), maxf(2.0, s * 0.08))
		"child":
			# The child: a round face under a mop of brown hair.
			ci.draw_circle(c + Vector2(0, 0.04) * s, 0.3 * s, Color("e9c9a4"))
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.34, 0.0) * s, c + Vector2(-0.3, -0.26) * s, c + Vector2(0, -0.36) * s, c + Vector2(0.3, -0.26) * s, c + Vector2(0.34, 0.0) * s, c + Vector2(0.1, -0.12) * s, c + Vector2(-0.12, -0.1) * s]), Color("5a3a24"))
			for x: float in [-0.1, 0.1]:
				ci.draw_circle(c + Vector2(x, 0.06) * s, 0.035 * s, color)
		"sun_book":
			ci.draw_rect(Rect2(c - Vector2(0.3, 0.38) * s, Vector2(0.6, 0.76) * s), Color("5f93b8"))
			ci.draw_circle(c + Vector2(0, -0.04) * s, 0.16 * s, Color("f2c14e"))


static func _arrow(ci: CanvasItem, c: Vector2, s: float, dir: float, color: Color) -> void:
	var tail_from := c + Vector2(-0.24 * dir, 0) * s
	var tail_to := c + Vector2(0.04 * dir, 0) * s
	ci.draw_line(tail_from, tail_to, color, maxf(2.5, s * 0.12))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.28 * dir, 0) * s, c + Vector2(0.0, -0.22) * s, c + Vector2(0.0, 0.22) * s]), color)


## A button with an icon drawn to the left of its words. A clear placeholder
## texture reserves the icon's space in the button's own layout; the icon is
## then drawn over it.
class IconButton:
	extends Button
	const EDGE := 30
	static var _blank: ImageTexture
	var kind := ""

	func _init(icon_kind: String, label: String) -> void:
		kind = icon_kind
		text = label
		if _blank == null:
			var img := Image.create(EDGE, EDGE, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_blank = ImageTexture.create_from_image(img)
		icon = _blank
		icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_theme_constant_override("h_separation", 10)

	func _draw() -> void:
		var box := get_theme_stylebox("normal")
		var left := box.get_margin(SIDE_LEFT) if box else 12.0
		Icon.draw(self, kind, Rect2(Vector2(left, (size.y - EDGE) / 2.0), Vector2(EDGE, EDGE)))


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
		# Large text still fits the tile: the caption shrinks to its width.
		while fsize > 10 and font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > size.x - 6:
			fsize -= 1
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


static func _oval(c: Vector2, r: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts
