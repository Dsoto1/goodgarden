class_name MapPanel
extends ModalPanel
## The valley map, like the concept art's "World Map (Fast Travel)": the real
## valley seen from high above, warmed into an old parchment map, with a
## picture card for each place. A card for somewhere the child has been is a
## button that travels there; places not yet found show a soft "?", and
## Bellhaven is far away. Small badges name landmarks (hold to hear them), and
## a marker shows where the child is now.

const VIEW := Vector2(880, 500)
## Where each place's card stands in the world (the region's own spot).
const PLACE_ICONS := {"home": "home", "garden": "seedling", "village": "village", "chapel": "chapel", "bellhaven": "chapel"}
## Landmarks: [name, icon, world position].
const LANDMARKS := [
	["The Mill", "mill", Vector3(-21, 0, -9.8)],
	["The Sheepfold", "sheep", Vector3(27.5, 0, -22.5)],
	["The Fishing Spot", "fish", Vector3(-32.5, 0, -19.5)],
	["The Bridge", "bridge", Vector3(5.5, 0, -14.0)],
]

var _camera: Camera3D
var _view: SubViewport
var _picture: TextureRect
var _pins: Control
var _taken: Array[Rect2] = [] # cards already placed, so neighbours don't cover each other


func show_map() -> void:
	open(VIEW.x + 60, Color("efe0bb"))
	# Seen from above, the whole valley shows: no see-through hole round the child.
	CameraRig.set_see_through(false)
	closed.connect(func() -> void: CameraRig.set_see_through(true))
	var top := HBoxContainer.new()
	content.add_child(top)
	var title := UiStyle.label(tr("The Valley"), "HeadingLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close_x := UiStyle.button("", false, "back")
	close_x.set_meta(&"spoken", tr("Close the map"))
	close_x.pressed.connect(close)
	top.add_child(close_x)
	AudioService.narrate(tr("The map. Tap a place to go there."))

	var frame := Control.new()
	frame.custom_minimum_size = VIEW
	content.add_child(frame)
	_view = SubViewport.new()
	_view.size = Vector2i(VIEW)
	_view.world_3d = get_viewport().world_3d
	_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	_view.msaa_3d = Viewport.MSAA_2X
	frame.add_child(_view)
	_camera = Camera3D.new()
	_camera.fov = 42.0
	_view.add_child(_camera)
	_camera.position = Vector3(0, 74, 40)
	_camera.look_at(Vector3(0, 0, -19))
	_camera.far = 600.0
	_camera.current = true
	var main := get_tree().get_first_node_in_group("main")
	var world: World = main.world if main else null
	if world and world.environment:
		# Clearer air than at ground level, so the map isn't lost in haze.
		var env: Environment = world.environment.duplicate()
		env.fog_density = 0.0006
		_camera.environment = env

	_picture = TextureRect.new()
	_picture.texture = _view.get_texture()
	_picture.size = VIEW
	_picture.material = _parchment()
	frame.add_child(_picture)
	_pins = Control.new()
	_pins.size = VIEW
	_pins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_pins)
	_place_pins(world)

	var done := UiStyle.button(tr("Close the map"), true, "yes")
	done.pressed.connect(close)
	add_buttons([done])


## Screen spot in the map picture for a world position (clamped inside it).
func map_point(world_pos: Vector3) -> Vector2:
	var p := _camera.unproject_position(world_pos)
	return p.clamp(Vector2(40, 30), VIEW - Vector2(40, 30))


func _place_pins(world: World) -> void:
	for l: Array in LANDMARKS:
		var badge := Button.new()
		badge.flat = true
		badge.focus_mode = Control.FOCUS_NONE
		badge.custom_minimum_size = Vector2(40, 40)
		badge.set_meta(&"spoken", tr(str(l[0])))
		badge.tooltip_text = tr(str(l[0]))
		badge.pressed.connect(func() -> void: AudioService.narrate(tr(str(l[0])), true))
		var art := Badge.new(str(l[1]))
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		badge.add_child(art)
		_pins.add_child(badge)
		badge.size = badge.custom_minimum_size
		badge.position = map_point(l[2]) - badge.size / 2.0
	for entry: Dictionary in Content.get_world("regions").get("regions", []):
		if not entry.get("on_map", false):
			continue
		var id := str(entry["id"])
		var o: Array = entry.get("origin", [0, 0, 0])
		var at := map_point(Vector3(float(o[0]), float(o[1]), float(o[2])))
		var pin: Control
		if not entry.get("reachable", true):
			pin = _card(PLACE_ICONS.get(id, "hand"), tr("%s (far away)") % tr(str(entry["name"])), false)
		elif Discovery.is_discovered(id):
			var b := UiStyle.button(tr(str(entry["name"])), false, PLACE_ICONS.get(id, "hand"))
			b.pressed.connect(func() -> void:
				close()
				get_tree().call_group("main", "travel_to", id))
			pin = b
		else:
			pin = _card("", "?", false)
		_pins.add_child(pin)
		pin.reset_size()
		pin.position = _free_spot(at - Vector2(pin.size.x / 2.0, pin.size.y + 6), pin.size)
		_taken.append(Rect2(pin.position, pin.size))
		if entry.get("reachable", true):
			_pins.add_child(_stake(at))
	if world and world.player:
		var you := YouAreHere.new()
		you.position = map_point(world.player.global_position)
		_pins.add_child(you)


## Nudges a card off any card already placed (places close together, like
## home and the garden, get their cards side by side). With large text the
## cards are big, so it tries further spots too, and if none is fully clear
## takes the one that overlaps least.
func _free_spot(want: Vector2, card: Vector2) -> Vector2:
	var shifts: Array[Vector2] = [Vector2.ZERO]
	for k: float in [0.6, 1.1, 1.6]:
		shifts.append_array([Vector2(-card.x * k, 0), Vector2(card.x * k, 0)])
	for k: float in [1.0, 2.0]:
		shifts.append_array([Vector2(0, -(card.y + 6) * k), Vector2(0, (card.y + 18) * k)])
	shifts.append_array([Vector2(-card.x * 0.6, -card.y - 6), Vector2(card.x * 0.6, -card.y - 6), Vector2(-card.x * 0.6, card.y + 18), Vector2(card.x * 0.6, card.y + 18)])
	var best := want
	var best_overlap := INF
	for shift: Vector2 in shifts:
		var spot: Vector2 = (want + shift).clamp(Vector2(4, 4), VIEW - card - Vector2(4, 4))
		var r := Rect2(spot, card)
		var overlap := 0.0
		for t in _taken:
			overlap += t.grow(4).intersection(r).get_area()
		if overlap == 0.0:
			return spot
		if overlap < best_overlap:
			best_overlap = overlap
			best = spot
	return best


## A little stake under a card, pointing at the exact spot.
func _stake(at: Vector2) -> Control:
	var s := Stake.new()
	s.position = at
	return s


func _card(icon_kind: String, text: String, _active: bool) -> Control:
	var panel := PanelContainer.new()
	var box := UiStyle.card(Color("fbf3dc"), 10)
	box.set_content_margin_all(6)
	box.content_margin_left = 10
	box.content_margin_right = 12
	panel.add_theme_stylebox_override("panel", box)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	if not icon_kind.is_empty():
		row.add_child(Icon.Glyph.new(icon_kind, 26))
	var l := UiStyle.label(text, "SmallLabel")
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(l)
	return panel


## The painted map: warmer, a touch richer, darkened and burnt at the edges
## like old parchment.
func _parchment() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	float g = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(g), c, 1.25);
	c = pow(c, vec3(1.12));
	c *= vec3(1.05, 1.0, 0.88);
	float paper = noise(UV * vec2(90.0, 52.0)) * 0.03 + noise(UV * vec2(12.0, 7.0)) * 0.04;
	c = mix(c, vec3(0.93, 0.86, 0.68), 0.04 + paper);
	vec2 d = abs(UV - 0.5) * 2.0;
	float edge = max(d.x, d.y) + (noise(UV * 26.0) - 0.5) * 0.06;
	c = mix(c, vec3(0.55, 0.38, 0.22), smoothstep(0.86, 1.0, edge) * 0.65);
	COLOR = vec4(c, 1.0 - smoothstep(0.985, 1.0, edge));
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


## A small round badge with a picture, for a landmark.
class Badge:
	extends Control
	var kind := ""

	func _init(icon_kind: String) -> void:
		kind = icon_kind
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c + Vector2(2, 3), 19, Color(0, 0, 0, 0.2))
		draw_circle(c, 19, Color("8fb27a"))
		draw_arc(c, 19, 0, TAU, 24, Color("5a3d28"), 2.0)
		Icon.draw(self, kind, Rect2(c - Vector2(14, 14), Vector2(28, 28)))


class Stake:
	extends Control

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_line(Vector2(0, -8), Vector2(0, 0), Color("8a5a3a"), 3.0)
		draw_circle(Vector2.ZERO, 4.0, Color("c9483c"))


## The child's marker: their face in a ring that gently pulses.
class YouAreHere:
	extends Control
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.0 if Settings.get_value("reduced_motion") else (sin(_t * 3.0) * 0.5 + 0.5)
		draw_circle(Vector2.ZERO, 24 + pulse * 6, Color(1.0, 0.93, 0.6, 0.35))
		draw_circle(Vector2.ZERO, 20, Color("fbf3dc"))
		draw_arc(Vector2.ZERO, 20, 0, TAU, 24, Color("c9483c"), 3.0)
		Icon.draw(self, "child", Rect2(Vector2(-16, -16), Vector2(32, 32)))
