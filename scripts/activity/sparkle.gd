class_name Sparkle
extends Node2D
## A brief ring of little stars where a place has just been filled: a quiet
## "there", never a reward. Skipped when motion is reduced.

const LIFE := 0.6

var _t := 0.0


static func burst(parent: Node, at: Vector2) -> void:
	if Settings.get_value("reduced_motion"):
		return
	var s := Sparkle.new()
	s.position = at
	s.z_index = 20
	parent.add_child(s)


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	var fade := 1.0 - k
	draw_arc(Vector2.ZERO, 30.0 + k * 34.0, 0, TAU, 32, Color(1.0, 0.92, 0.6, 0.5 * fade), 3.0)
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		var p := Vector2(cos(a), sin(a)) * (36.0 + k * 40.0)
		var r := 6.0 * fade + 1.0
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.35, 0), p + Vector2(0, r), p + Vector2(-r * 0.35, 0)]), Color(1.0, 0.95, 0.7, fade))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-r, 0), p + Vector2(0, r * 0.35), p + Vector2(r, 0), p + Vector2(0, -r * 0.35)]), Color(1.0, 0.95, 0.7, fade))
