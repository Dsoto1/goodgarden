class_name Player
extends CharacterBody3D
## The child's avatar. Moves with keys/stick relative to the camera, or walks
## to wherever the child taps/clicks. Tapping a thing walks over and uses it.
## No jumping, running or stamina: calm, forgiving movement.

const SPEED := 3.4
const ACCEL := 14.0
const ARRIVE_DISTANCE := 0.25

var model: CharacterModel
var camera: Camera3D
var _walk_target: Variant = null # Vector3 or null
var _pending_use: Interactable
var _pointer_held := false
var _stuck_time := 0.0
var _dest_marker: MeshInstance3D


func _ready() -> void:
	add_to_group("player")
	collision_layer = MeshKit.LAYER_PLAYER
	collision_mask = MeshKit.LAYER_GROUND | MeshKit.LAYER_OBSTACLE
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.1
	shape.shape = capsule
	shape.position.y = 0.56
	add_child(shape)
	model = CharacterModel.new().build({
		"skin": "skin_2", "hair": "hair_brown", "hair_style": "curly",
		"shirt": "cloth_gold", "pants": "cloth_green", "height": 0.82,
	})
	add_child(model)
	# Child of the player but top-level, so it stays where it was placed in the world.
	_dest_marker = MeshKit.cylinder(self, 0.35, 0.35, 0.02, Vector3.ZERO, "marker", 16)
	_dest_marker.top_level = true
	_dest_marker.visible = false
	_dest_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	GameState.mode_changed.connect(func(_m: GameState.Mode) -> void:
		if not GameState.is_exploring():
			stop())


func facing() -> Vector3:
	return -global_transform.basis.z


func stop() -> void:
	_walk_target = null
	_pending_use = null
	_pointer_held = false
	_dest_marker.visible = false
	velocity = Vector3.ZERO


func walk_to(point: Vector3, use: Interactable = null) -> void:
	_walk_target = Vector3(point.x, global_position.y, point.z)
	_pending_use = use
	_stuck_time = 0.0
	_dest_marker.visible = use == null
	_dest_marker.global_position = Vector3(point.x, 0.03, point.z)


func teleport(point: Vector3, facing_y: float) -> void:
	stop()
	global_position = point
	rotation.y = facing_y
	velocity = Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.is_exploring():
		return
	if event.is_action_pressed("interact"):
		Interaction.interact_focused()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer_held = event.pressed
		if event.pressed:
			_pointer_at(event.position, true)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _pointer_held:
		_pointer_at(event.position, false)


## Taps on things walk over and use them; taps or drags on ground walk there.
func _pointer_at(screen_pos: Vector2, is_press: bool) -> void:
	if camera == null:
		return
	var from := camera.project_ray_origin(screen_pos)
	var query := PhysicsRayQueryParameters3D.create(from, from + camera.project_ray_normal(screen_pos) * 200.0)
	query.collide_with_areas = true
	query.collision_mask = MeshKit.LAYER_GROUND | MeshKit.LAYER_INTERACTABLE
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var target: Interactable = hit.collider as Interactable
	if target and is_press and target.is_available():
		var dist := Vector2(target.global_position.x - global_position.x, target.global_position.z - global_position.z).length()
		if dist <= target.reach:
			Interaction.interact(target)
		else:
			walk_to(target.approach_point(global_position), target)
		_pointer_held = false
	elif target == null:
		walk_to(hit.position)


func _physics_process(delta: float) -> void:
	var desired := Vector3.ZERO
	if GameState.is_exploring():
		var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input.length() > 0.1:
			_walk_target = null
			_pending_use = null
			_dest_marker.visible = false
			var yaw := camera.global_rotation.y if camera else 0.0
			desired = Vector3(input.x, 0, input.y).rotated(Vector3.UP, yaw) * SPEED
		elif _walk_target != null:
			var to: Vector3 = _walk_target - global_position
			to.y = 0.0
			if to.length() < ARRIVE_DISTANCE:
				_arrive()
			else:
				desired = to.normalized() * SPEED * clampf(to.length() / 0.8, 0.35, 1.0)
	var horizontal := Vector3(velocity.x, 0, velocity.z).move_toward(desired, ACCEL * delta)
	velocity = Vector3(horizontal.x, velocity.y - 20.0 * delta, horizontal.z)
	move_and_slide()
	if is_on_floor():
		velocity.y = 0.0
	if horizontal.length() > 0.2:
		rotation.y = lerp_angle(rotation.y, atan2(-horizontal.x, -horizontal.z), minf(delta * 10.0, 1.0))
	_check_stuck(delta, desired)
	model.animate(delta, Vector3(velocity.x, 0, velocity.z).length(), Settings.get_value("reduced_motion"))
	if GameState.is_exploring():
		Interaction.update_focus(global_position, facing())
	elif Interaction.focused:
		Interaction.clear_focus()


func _arrive() -> void:
	var use := _pending_use
	stop()
	if use and use.is_available():
		var to := use.global_position - global_position
		rotation.y = atan2(-to.x, -to.z)
		Interaction.interact(use)


## Tap-to-walk into a wall should not leave the avatar pushing forever.
func _check_stuck(delta: float, desired: Vector3) -> void:
	if _walk_target == null or desired.length() < 0.1:
		_stuck_time = 0.0
		return
	if get_real_velocity().length() < SPEED * 0.15:
		_stuck_time += delta
		if _stuck_time > 0.6:
			if _pending_use and global_position.distance_to(_pending_use.global_position) <= _pending_use.reach + 0.6:
				_arrive()
			else:
				stop()
	else:
		_stuck_time = 0.0


func save_state() -> Dictionary:
	return {"position": [global_position.x, global_position.y, global_position.z], "facing": rotation.y}
