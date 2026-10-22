class_name DoneSeal
extends Control
## A clear, calm sign that a piece of work is finished: a green seal with a
## tick, "Done!" and the work's name, with the gentle three-note chime. It
## acknowledges the work rather than rewarding it (no stars, no score), and is
## only shown for practical work, never after a story in the Chapel.

const SHOW_SECONDS := 2.6

var title := ""
var _t := 0.0


static func show_for(parent: Control, work_title: String) -> DoneSeal:
	var seal := DoneSeal.new()
	seal.title = work_title
	seal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(seal)
	return seal


func _ready() -> void:
	AudioService.play("complete")
	AudioService.narrate(tr("Done!") + " " + title)
	if Settings.get_value("reduced_motion"):
		_t = 0.35 # skip the grow-in


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t > SHOW_SECONDS:
		queue_free()


func _draw() -> void:
	var grow := clampf(_t / 0.35, 0.0, 1.0)
	var fade := 1.0 - clampf((_t - (SHOW_SECONDS - 0.5)) / 0.5, 0.0, 1.0)
	var ease_in := 1.0 - pow(1.0 - grow, 3.0)
	var scale_now := lerpf(0.7, 1.0, ease_in)
	var alpha := ease_in * fade
	# Centred on the screen (the overlay layer it sits in has no size of its own).
	var screen := get_viewport_rect().size
	var c := Vector2(screen.x / 2.0, screen.y * 0.42)
	var r := 74.0 * scale_now
	draw_circle(c + Vector2(0, 6), r + 6, Color(0, 0, 0, 0.18 * alpha))
	draw_circle(c, r + 6, Color(1, 1, 1, 0.95 * alpha))
	draw_circle(c, r, Color(0.36, 0.56, 0.27, alpha))
	draw_arc(c, r - 9, 0, TAU, 48, Color(1, 1, 1, 0.35 * alpha), 3.0)
	var tick := PackedVector2Array([c + Vector2(-0.42, 0.02) * r, c + Vector2(-0.12, 0.32) * r, c + Vector2(0.44, -0.3) * r])
	draw_polyline(tick, Color(1, 1, 1, alpha), 0.16 * r, true)
	var font := UiStyle.font()
	var banner := Rect2(c.x - 210, c.y + r + 18, 420, 84)
	draw_style_box(_banner_box(alpha), banner)
	draw_string(font, Vector2(banner.position.x, banner.position.y + 38), tr("Done!"), HORIZONTAL_ALIGNMENT_CENTER, banner.size.x, 34, Color(0.25, 0.4, 0.18, alpha))
	draw_string(font, Vector2(banner.position.x, banner.position.y + 70), title, HORIZONTAL_ALIGNMENT_CENTER, banner.size.x, 22, Color(0.35, 0.24, 0.16, alpha))


func _banner_box(alpha: float) -> StyleBoxFlat:
	var box := UiStyle.card(Color(0.98, 0.95, 0.86, alpha), 18)
	box.border_color = Color(0.43, 0.6, 0.32, alpha)
	box.shadow_color = Color(0, 0, 0, 0.2 * alpha)
	return box
