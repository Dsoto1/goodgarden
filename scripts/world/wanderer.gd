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
var _face_player := 0.0 # seconds left to stand still, turned toward the child
var _visit_until := -1.0 # while visiting (hens at scattered grain), when to go home
var _usual_home: Vector3
var _usual_radius := 0.0


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


## Stands still for `seconds`, turned toward the child (while being stroked).
func pause_for(seconds: float) -> void:
	_face_player = seconds
	_wait = maxf(_wait, seconds)
	_target = position


## Comes to potter about near `world_pos` for `seconds`, then wanders home.
func visit(world_pos: Vector3, seconds: float, r := 0.6) -> void:
	if _visit_until < 0.0:
		_usual_home = home
		_usual_radius = radius
	_visit_until = _t + seconds
	home = world_pos - global_position + position
	radius = r
	_target = home + Vector3(_rng.randf_range(-r, r), 0, _rng.randf_range(-r, r))
	_wait = _rng.randf_range(0.0, 0.6)


func is_visiting() -> bool:
	return _visit_until >= 0.0


func _process(delta: float) -> void:
	_t += delta
	if gait == "flutter":
		_flutter(delta)
		return
	if _visit_until >= 0.0 and _t > _visit_until:
		_visit_until = -1.0
		home = _usual_home
		radius = _usual_radius
		_target = home
	if _face_player > 0.0:
		_face_player -= delta
		_turn_to_player(delta)
		_settle(delta)
		return
	if not talk_dialogue_id.is_empty() and Dialogue.active_id == talk_dialogue_id:
		var player := _turn_to_player(delta)
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
		_settle(delta)
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
	elif model is FarmAnimal:
		(model as FarmAnimal).set_moving(true, speed)
	elif gait == "hop":
		model.rotation.x = 0.0
		model.position.y = absf(sin(_t * 10.0)) * 0.06
	else:
		model.rotation.x = 0.0
		model.position.y = absf(sin(_t * 8.0)) * 0.02


func _turn_to_player(delta: float) -> Node3D:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		var to_player := player.global_position - global_position
		rotation.y = lerp_angle(rotation.y, atan2(-to_player.x, -to_player.z), minf(delta * 6.0, 1.0))
	return player


## Standing still: people breathe, farm animals stop walking, and hens at
## scattered grain peck at the ground.
func _settle(delta: float) -> void:
	if model is CharacterModel:
		model.animate(delta, 0.0)
	elif model is FarmAnimal:
		(model as FarmAnimal).set_moving(false)
	else:
		model.position.y = 0.0
		var peck: bool = is_visiting() and not Settings.get_value("reduced_motion")
		model.rotation.x = -maxf(sin(_t * 7.0 + _rng.seed % 5), 0.0) * 0.5 if peck else 0.0


func _flutter(delta: float) -> void:
	position = home + Vector3(sin(_t * 0.7 + home.x) * radius, 0.6 + sin(_t * 1.3) * 0.25, cos(_t * 0.5 + home.z) * radius)
	rotation.y += delta * 0.6
	var flap := sin(_t * 18.0) * 0.9
	for i in 2:
		var wing := model.get_node_or_null("Wing%d" % i) as Node3D
		if wing:
			wing.rotation.z = flap * (1.0 if i == 0 else -1.0)
