class_name MapPanel
extends ModalPanel
## Illustrated overhead map. Only places the child has walked to can be
## travelled to; Bellhaven appears as a far-off promise.


## A picture for each place, so places can be found without reading.
const PLACE_ICONS := {"home": "home", "garden": "seedling", "village": "village", "chapel": "chapel"}


func show_map() -> void:
	open(820, Color("f3e6c4"))
	content.add_child(UiStyle.label(tr("The Valley"), "HeadingLabel"))
	AudioService.narrate(tr("The map. Choose a place to go."))
	var drawing := MapDrawing.new()
	drawing.custom_minimum_size = Vector2(760, 420)
	content.add_child(drawing)
	for entry: Dictionary in Content.get_world("regions").get("regions", []):
		if not entry.get("on_map", false):
			continue
		var pos := ActivityStep.vec(entry.get("map_pos"), Vector2(0.5, 0.5)) * drawing.custom_minimum_size
		var id := str(entry["id"])
		if not entry.get("reachable", true):
			var far := UiStyle.label(tr("%s (far away)") % tr(str(entry["name"])), "SmallLabel")
			far.position = pos + Vector2(-90, 34)
			far.size = Vector2(180, 30)
			far.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			drawing.add_child(far)
		elif Discovery.is_discovered(id):
			var b := UiStyle.button(tr(str(entry["name"])), false, PLACE_ICONS.get(id, "hand"))
			b.pressed.connect(func() -> void:
				close()
				get_tree().call_group("main", "travel_to", id))
			drawing.add_child(b)
			b.reset_size()
			b.position = pos - b.size / 2.0
		else:
			var q := UiStyle.label("?", "HeadingLabel")
			q.position = pos - Vector2(8, 20)
			drawing.add_child(q)
	var done := UiStyle.button(tr("Close the map"), true, "yes")
	done.pressed.connect(close)
	add_buttons([done])


class MapDrawing:
	extends Control

	func _draw() -> void:
		var s := size
		draw_rect(Rect2(Vector2.ZERO, s), Color("efe0bb"))
		# River, roads and a few trees, roughly matching the valley.
		var river := PackedVector2Array([Vector2(0, s.y * 0.6), Vector2(s.x * 0.4, s.y * 0.57), Vector2(s.x, s.y * 0.62)])
		draw_polyline(river, Color("8fb6d0"), 14.0, true)
		var road := PackedVector2Array([Vector2(s.x * 0.3, s.y * 0.8), Vector2(s.x * 0.45, s.y * 0.8), Vector2(s.x * 0.45, s.y * 0.5), Vector2(s.x * 0.5, s.y * 0.38), Vector2(s.x * 0.5, s.y * 0.15), Vector2(s.x * 0.72, s.y * 0.06)])
		draw_polyline(road, Color("c9a874"), 6.0, true)
		draw_line(Vector2(s.x * 0.45, s.y * 0.44), Vector2(s.x * 0.2, s.y * 0.38), Color("c9a874"), 6.0)
		draw_line(Vector2(s.x * 0.45, s.y * 0.76), Vector2(s.x * 0.6, s.y * 0.76), Color("c9a874"), 6.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		for i in 30:
			var p := Vector2(rng.randf() * s.x, rng.randf() * s.y)
			draw_circle(p, 8, Color("9fbf7a"))
		# Bellhaven towers on the horizon.
		var b := Vector2(s.x * 0.72, s.y * 0.06)
		for k in 3:
			draw_rect(Rect2(b + Vector2(-24 + k * 18, -10), Vector2(10, 26)), Color("9a8f86"))
		draw_rect(Rect2(Vector2.ZERO, s), Color("b08d58"), false, 4.0)
