class_name TitleScreen
extends Control
## Storybook title card: continue the garden or begin a new one.

signal continue_pressed
signal new_pressed
signal settings_pressed


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	col.custom_minimum_size.x = 420
	center.add_child(col)
	var title := UiStyle.label(tr("The Good Garden"), "TitleLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("fbf5e8"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	title.add_theme_constant_override("shadow_offset_y", 3)
	col.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 20
	col.add_child(spacer)
	if SaveService.has_save():
		var cont := UiStyle.button(tr("Continue my garden"), true)
		cont.pressed.connect(func() -> void: continue_pressed.emit())
		col.add_child(cont)
		cont.call_deferred("grab_focus")
	var fresh := UiStyle.button(tr("Begin a new garden"), not SaveService.has_save())
	fresh.pressed.connect(func() -> void: new_pressed.emit())
	col.add_child(fresh)
	if not SaveService.has_save():
		fresh.call_deferred("grab_focus")
	var settings := UiStyle.button(tr("Settings"))
	settings.pressed.connect(func() -> void: settings_pressed.emit())
	col.add_child(settings)


func _draw() -> void:
	var s := size
	for i in 24:
		var t := i / 23.0
		draw_rect(Rect2(0, s.y * t, s.x, s.y / 23.0 + 1), Color("8fc0e6").lerp(Color("f6e3c0"), t))
	draw_circle(Vector2(s.x * 0.78, s.y * 0.22), 60, Color("fff3c4"))
	_hill(s, 0.62, 0.35, Color("9cc47a"))
	_hill(s, 0.72, 0.6, Color("86b265"))
	_hill(s, 0.82, 0.15, Color("6f9a52"))
	# A little cottage on the near hill.
	var c := Vector2(s.x * 0.22, s.y * 0.78)
	draw_rect(Rect2(c - Vector2(40, 30), Vector2(80, 50)), Color("f2e6cf"))
	draw_colored_polygon(PackedVector2Array([c + Vector2(-52, -28), c + Vector2(0, -70), c + Vector2(52, -28)]), Color("b8584a"))
	draw_rect(Rect2(c + Vector2(-9, -6), Vector2(18, 26)), Color("7b5338"))


func _hill(s: Vector2, y: float, phase: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 41:
		var x := s.x * i / 40.0
		pts.append(Vector2(x, s.y * y + sin(i / 40.0 * TAU + phase * 6.0) * s.y * 0.04))
	pts.append(Vector2(s.x, s.y))
	pts.append(Vector2(0, s.y))
	draw_colored_polygon(pts, col)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
