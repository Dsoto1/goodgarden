class_name Interactable
extends Area3D
## Something the child can approach and use: a letter, a garden bed, a person,
## a shelf. Keyboard/gamepad use the nearest one; mouse/touch can tap it
## directly and the avatar walks over first. A soft floating marker shows
## which thing is in reach, so the HUD stays nearly empty.

signal triggered

## Verb phrase for the prompt, e.g. "Read the letter".
@export var prompt := "Look"
## Horizontal distance from which the child can use it.
@export var reach := 2.0
@export var enabled := true
## WorldState conditions that must hold for this to be offered.
var conditions: Array = []
## What happens on use. Regions assign this when they build the object.
var action: Callable
## Optional point the camera frames during an activity started here.
var focus_point: Vector3

var _marker: Node3D
var _marker_height := 1.6
var _marker_time := 0.0


static func create(parent: Node3D, pos: Vector3, prompt_text: String, on_use: Callable, radius := 0.8, marker_height := 1.6) -> Interactable:
	var it := Interactable.new()
	it.prompt = prompt_text
	it.action = on_use
	it.position = pos
	parent.add_child(it)
	it.set_shape(radius, marker_height)
	return it


func _ready() -> void:
	collision_layer = MeshKit.LAYER_INTERACTABLE
	collision_mask = 0
	monitoring = false
	monitorable = true
	Interaction.register(self)
	if focus_point == Vector3.ZERO:
		focus_point = global_position


func _exit_tree() -> void:
	Interaction.unregister(self)


func set_shape(radius: float, marker_height: float) -> void:
	var shape := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = radius
	shape.shape = s
	shape.position.y = radius * 0.6
	add_child(shape)
	_marker_height = marker_height
	_marker = Node3D.new()
	_marker.position.y = marker_height
	_marker.visible = false
	add_child(_marker)
	var gem := MeshKit.sphere(_marker, 0.12, Vector3.ZERO, "marker", Vector3(0.8, 1.3, 0.8), 4, 2)
	gem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func is_available() -> bool:
	return enabled and is_visible_in_tree() and WorldState.matches(conditions)


func trigger() -> void:
	triggered.emit()
	if action.is_valid():
		action.call()


func set_highlighted(on: bool) -> void:
	if _marker:
		_marker.visible = on


## Where the avatar should stand to use this, approaching from `from`.
func approach_point(from: Vector3) -> Vector3:
	var to := from - global_position
	to.y = 0.0
	if to.length() < 0.01:
		to = Vector3(0, 0, 1)
	return global_position + to.normalized() * minf(reach * 0.7, to.length())


func _process(delta: float) -> void:
	if _marker and _marker.visible and not Settings.get_value("reduced_motion"):
		_marker_time += delta
		_marker.position.y = _marker_height + sin(_marker_time * 2.4) * 0.06
		_marker.rotation.y += delta * 1.2
