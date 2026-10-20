extends Node
## InteractionService: finds the interactable the child is closest to and
## facing, and routes keyboard, gamepad, mouse and touch to the same call.

signal focus_changed(target: Interactable)
signal interacted(target: Interactable)

var focused: Interactable
var _all: Array[Interactable] = []


func register(target: Interactable) -> void:
	if not _all.has(target):
		_all.append(target)


func unregister(target: Interactable) -> void:
	_all.erase(target)
	if focused == target:
		_set_focus(null)


## Called by the player each physics frame while exploring.
func update_focus(from: Vector3, facing: Vector3) -> void:
	var best: Interactable = null
	var best_score := INF
	for target in _all:
		if not target.is_available():
			continue
		var to := target.global_position - from
		to.y = 0.0
		var dist := to.length()
		if dist > target.reach:
			continue
		# Prefer what the child faces, but never ignore something right beside them.
		var facing_penalty := 0.0
		if dist > 0.3 and facing.length() > 0.1:
			facing_penalty = (1.0 - facing.normalized().dot(to / dist)) * 0.8
		var score := dist + facing_penalty
		if score < best_score:
			best_score = score
			best = target
	_set_focus(best)


func clear_focus() -> void:
	_set_focus(null)


func interact_focused() -> void:
	if focused and focused.is_available():
		interact(focused)


func interact(target: Interactable) -> void:
	if not GameState.is_exploring():
		return
	interacted.emit(target)
	target.trigger()


func _set_focus(target: Interactable) -> void:
	if target == focused:
		return
	if is_instance_valid(focused):
		focused.set_highlighted(false)
	focused = target
	if focused:
		focused.set_highlighted(true)
	focus_changed.emit(focused)
