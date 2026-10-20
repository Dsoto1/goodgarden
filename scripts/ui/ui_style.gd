class_name UiStyle
extends RefCounted
## Storybook UI theme, built in code so text size follows the accessibility
## setting everywhere. Buttons are large (generous touch targets) with a clear
## focus ring for keyboard and gamepad.

const INK := Color("3b3430")
const PAPER := Color("fbf5e8")
const PAPER_EDGE := Color("d9c6a2")
const LEAF := Color("6f9a52")
const LEAF_DARK := Color("4f7a3a")


static func build_theme(text_scale: float) -> Theme:
	var t := Theme.new()
	t.default_font_size = roundi(22 * text_scale)
	t.set_color("font_color", "Label", INK)
	_variation(t, "PromptLabel", "Label", roundi(27 * text_scale))
	_variation(t, "SmallLabel", "Label", roundi(17 * text_scale))
	_variation(t, "TitleLabel", "Label", roundi(44 * text_scale))
	_variation(t, "HeadingLabel", "Label", roundi(30 * text_scale))
	_variation(t, "LetterLabel", "Label", roundi(26 * text_scale))

	t.set_stylebox("normal", "Button", _button_box(PAPER, PAPER_EDGE))
	t.set_stylebox("hover", "Button", _button_box(Color("fffaf0"), Color("c9a86e")))
	t.set_stylebox("pressed", "Button", _button_box(Color("efe3c6"), Color("b08d58")))
	t.set_stylebox("disabled", "Button", _button_box(Color("e9e4da"), Color("d6d0c4")))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(4)
	focus.border_color = Color("f1cf55")
	focus.set_corner_radius_all(14)
	focus.set_expand_margin_all(3)
	t.set_stylebox("focus", "Button", focus)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(INK, 0.4))

	t.set_type_variation("PrimaryButton", "Button")
	t.set_stylebox("normal", "PrimaryButton", _button_box(LEAF, LEAF_DARK))
	t.set_stylebox("hover", "PrimaryButton", _button_box(Color("7fae60"), LEAF_DARK))
	t.set_stylebox("pressed", "PrimaryButton", _button_box(LEAF_DARK, LEAF_DARK))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(state, "PrimaryButton", Color.WHITE)

	t.set_stylebox("panel", "PanelContainer", card(PAPER, 18))
	t.set_stylebox("panel", "Panel", card(PAPER, 18))
	t.set_color("font_color", "CheckBox", INK)
	t.set_color("font_color", "CheckButton", INK)
	t.set_color("font_hover_color", "CheckButton", INK)
	t.set_color("font_pressed_color", "CheckButton", INK)
	t.set_color("font_focus_color", "CheckButton", INK)
	t.set_color("font_hover_pressed_color", "CheckButton", INK)
	t.set_stylebox("focus", "CheckButton", focus)
	t.set_stylebox("focus", "HSlider", focus)
	return t


static func _variation(t: Theme, name: String, base: String, font_size: int) -> void:
	t.set_type_variation(name, base)
	t.set_font_size("font_size", name, font_size)


static func _button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(3)
	s.set_corner_radius_all(14)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.shadow_color = Color(0, 0, 0, 0.15)
	s.shadow_size = 3
	s.shadow_offset = Vector2(0, 2)
	return s


static func card(fill: Color, radius := 18) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = fill.darkened(0.18)
	s.set_border_width_all(3)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(20)
	s.shadow_color = Color(0, 0, 0, 0.25)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	return s


static func button(text: String, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(64, 60)
	if primary:
		b.theme_type_variation = "PrimaryButton"
	return b


static func label(text: String, variation := "") -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not variation.is_empty():
		l.theme_type_variation = variation
	return l


## A centered modal card on a soft dimmed backdrop. Returns the content VBox.
static func modal(parent: Control, width := 640.0, fill := PAPER) -> VBoxContainer:
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.08, 0.06, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var card_panel := PanelContainer.new()
	card_panel.add_theme_stylebox_override("panel", card(fill, 22))
	card_panel.custom_minimum_size.x = width
	center.add_child(card_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	card_panel.add_child(box)
	return box
