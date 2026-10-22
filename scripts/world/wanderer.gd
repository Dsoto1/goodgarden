class_name Wanderer
extends Node3D
## Gentle ambient movement for villagers and animals: walk to a nearby point,
## pause, repeat. Stays inside its home radius and never chases the player.

@export var speed := 0.8
@export var radius := 3.0
@export var pause_range := Vector2(1.5, 4.0)
## "walk" for people/animals, "hop" for birds, "flutter" for butterflies.
@export var gait := "walk"
## When set, the wanderer stops and faces the child while this dialogue runs.
var talk_dialogue_id := ""

var home: Vector3
var model: Node3D
var _target: Vector3
var _wait := 0.0
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func setup(visual: Node3D, seed_value: int) -> Wanderer:
	model = visual
	add_child(visual)
	_rng.seed = seed_value
	return self


func _ready() -> void:
	home = position
	_target = position
	_wait = _rng.randf_range(0.0, pause_range.y)


## Moves to a new home (in world space) and potters about within `r` of it.
func relocate(world_pos: Vector3, r: float, facing_y := 0.0) -> void:
	global_position = world_pos
	home = position
	_target = position
	radius = r
	rotation.y = facing_y


func _process(delta: float) -> void:
	_t += delta
	if gait == "flutter":
		_flutter(delta)
		return
	if not talk_dialogue_id.is_empty() and Dialogue.active_id == talk_dialogue_id:
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player:
			var to_player := player.global_position - global_position
			rotation.y = lerp_angle(rotation.y, atan2(-to_player.x, -to_player.z), minf(delta * 6.0, 1.0))
		if model is CharacterModel:
			model.look_at_point(player.global_position + Vector3(0, 1.0, 0) if player else null)
			model.set_talking(1.0)
			model.gesture(0.6)
			model.animate(delta, 0.0)
		return
	if model is CharacterModel:
		model.set_talking(0.0)
		model.gesture(0.0)
		model.look_at_point(null)
	if _wait > 0.0:
		_wait -= delta
		if model is CharacterModel:
			model.animate(delta, 0.0)
		return
	var to := _target - position
	to.y = 0.0
	if to.length() < 0.1:
		_wait = _rng.randf_range(pause_range.x, pause_range.y)
		var ang := _rng.randf() * TAU
		_target = home + Vector3(cos(ang), 0, sin(ang)) * _rng.randf_range(0.3, radius)
		return
	var step := to.normalized() * speed * delta
	position += step
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(delta * 5.0, 1.0))
	if model is CharacterModel:
		model.animate(delta, speed)
	elif gait == "hop":
		model.position.y = absf(sin(_t * 10.0)) * 0.06
	else:
		model.position.y = absf(sin(_t * 8.0)) * 0.02


func _flutter(delta: float) -> void:
	position = home + Vector3(sin(_t * 0.7 + home.x) * radius, 0.6 + sin(_t * 1.3) * 0.25, cos(_t * 0.5 + home.z) * radius)
	rotation.y += delta * 0.6
	var flap := sin(_t * 18.0) * 0.9
	for i in 2:
		var wing := model.get_node_or_null("Wing%d" % i) as Node3D
		if wing:
			wing.rotation.z = flap * (1.0 if i == 0 else -1.0)
