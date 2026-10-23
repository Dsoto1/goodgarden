class_name CameraRig
extends Node3D
## Controlled, elevated three-quarter follow camera. The child never has to
## steer it: zones and modes reframe it gently (conversation, activity close-up,
## chapel, vistas). Reduced motion swaps glides for cuts.

## Over-the-shoulder three-quarter view that shows the horizon, as in the
## mockup's play screens, tilted down enough that the ground around the child
## (paths, people, the next thing to tap) is easy to see. Interiors push a
## higher framing (see Region zones).
const DEFAULT_FRAMING := {"pitch": 22.0, "distance": 9.0, "yaw": 0.0, "height": 1.5, "fov": 52.0}
## How far the view leans toward where the child is walking to.
const LOOK_AHEAD := 2.0

var target: Node3D
var camera: Camera3D
## What the see-through keeps in view (the child, or what is being framed).
var see_through_target := Vector3.ZERO
## Off while the map renders the valley from above.
static var see_through_on := true
var _zones: Array[Dictionary] = []
var _focus: Dictionary = {} # {"point": Vector3, "pitch", "distance", "yaw"}
var _look := Vector3.ZERO
var _params := DEFAULT_FRAMING.duplicate()


func _ready() -> void:
	add_to_group("camera_rig")
	camera = Camera3D.new()
	camera.fov = DEFAULT_FRAMING["fov"]
	# A near plane well away from the lens keeps depth precise far into the
	# scene. Tablets and browsers often have coarse depth buffers, and with a
	# near plane of 0.3 m, window glass, shutters and beams a few centimetres off
	# a wall flickered at village distances. The camera never frames anything
	# closer than about 3 m.
	camera.near = 0.8
	camera.far = 400.0
	add_child(camera)
	camera.make_current()


func push_zone(framing: Dictionary) -> void:
	_zones.append(framing)


func pop_zone(framing: Dictionary) -> void:
	_zones.erase(framing)


## Frames a point for conversation or activity. Cleared with release_focus().
func focus_on(point: Vector3, distance: float, pitch: float, yaw := 0.0) -> void:
	_focus = {"point": point, "distance": distance, "pitch": pitch, "yaw": yaw}


func release_focus() -> void:
	_focus = {}


func snap() -> void:
	_update(1.0, true)


func _process(delta: float) -> void:
	_update(delta, Settings.get_value("reduced_motion"))


## Spring arm: if a wall stands between the child and the camera, move in.
func _clearance(from: Vector3, offset: Vector3) -> float:
	if not is_inside_tree() or not _focus.is_empty():
		return 1.0
	var query := PhysicsRayQueryParameters3D.create(from, from + offset, MeshKit.LAYER_OBSTACLE)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return 1.0
	return clampf((from.distance_to(hit.position) - 0.4) / offset.length(), 0.25, 1.0)


func _update(delta: float, instant: bool) -> void:
	var goal := DEFAULT_FRAMING.duplicate()
	for z in _zones:
		goal.merge(z, true)
	var look_goal := target.global_position + Vector3(0, goal["height"], 0) if target else Vector3.ZERO
	# Walking somewhere: lean the view a little toward the destination, so the
	# child sees where they're going, not just themselves.
	if target is Player and _focus.is_empty():
		var dest: Variant = (target as Player).walk_goal()
		if dest != null:
			var ahead: Vector3 = dest - target.global_position
			ahead.y = 0.0
			look_goal += ahead.limit_length(LOOK_AHEAD)
	if not _focus.is_empty():
		goal.merge(_focus, true)
		look_goal = _focus["point"]
	var k := 1.0 if instant else 1.0 - exp(-delta * 4.0)
	for key: String in ["pitch", "distance", "yaw", "fov"]:
		_params[key] = lerpf(_params[key], goal[key], k)
	_look = _look.lerp(look_goal, 1.0 if instant else 1.0 - exp(-delta * 6.0))
	var pitch: float = deg_to_rad(_params["pitch"])
	var offset: Vector3 = Vector3(0, sin(pitch), cos(pitch)) * float(_params["distance"])
	offset = offset.rotated(Vector3.UP, deg_to_rad(_params["yaw"]))
	var at := _look + offset * _clearance(_look, offset)
	# Out in the hills, keep the camera above the slope behind the child.
	if Terrain.outside(at.x, at.z) > 0.0:
		at.y = maxf(at.y, Terrain.height(at.x, at.z) + 1.5)
	camera.global_position = at
	camera.fov = _params["fov"]
	camera.look_at(_look, Vector3.UP)
	# Tell the storybook shaders what to keep in view (see-through cutaway):
	# the child, or the people and work being framed.
	see_through_target = target.global_position + Vector3(0, goal["height"], 0) if target and _focus.is_empty() else _look
	RenderingServer.global_shader_parameter_set(&"gg_view_from", camera.global_position)
	RenderingServer.global_shader_parameter_set(&"gg_view_to", see_through_target)


## Turns the see-through cutaway on or off (off for the map's view from above).
static func set_see_through(on: bool) -> void:
	see_through_on = on
	RenderingServer.global_shader_parameter_set(&"gg_see_through", 1.0 if on else 0.0)
