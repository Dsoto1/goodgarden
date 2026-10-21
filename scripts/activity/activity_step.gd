class_name ActivityStep
extends Control
## Base class for a reusable manipulation primitive (one "step" of an activity).
##
## A step is given its JSON config and builds itself on the workspace board
## (BOARD_SIZE design units, scaled to fit any screen). It reports progress
## through signals and never touches world state: the ActivityRunner decides
## what completing an activity means.

## Finished; `result` becomes available to later steps and to world effects
## as $<step_id>.<key> tokens.
signal completed(result: Dictionary)
## Learning observation for grown-ups, e.g. ("self_correction", {...}).
signal observed(kind: String, data: Dictionary)
## The guiding text for the child changed (feedback, next instruction).
signal prompt_changed(text: String)
## Step-specific buttons: [{"label": String, "callback": Callable, "primary": bool}].
signal actions_changed(actions: Array)

const BOARD_SIZE := Vector2(1000, 560)

var config: Dictionary
## Results of earlier steps keyed by step id, plus "pieces" handed over.
var context: Dictionary
## Workspace-provided helpers: snap tolerance in board units.
var snap_tolerance := 40.0
var reduced_motion := false
var is_done := false


func _init() -> void:
	size = BOARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS


## Build the step's pieces. Called once after the node is in the tree.
func begin(step_config: Dictionary, step_context: Dictionary) -> void:
	config = step_config
	context = step_context
	# The step's prompt first, so anything the step says while building (a
	# story's opening line) is what the child sees, not an empty prompt.
	prompt_changed.emit(tr(str(config.get("prompt", ""))))
	_build()


## Override: construct pieces and slots.
func _build() -> void:
	pass


## Override: put everything back to how it started (the "Start over" button).
func reset_step() -> void:
	pass


## Override: show the child one next move ("Show me"). Default shows the hint text.
func show_hint() -> void:
	var hint := str(config.get("hint", ""))
	if not hint.is_empty():
		prompt_changed.emit(tr(hint))


## Whether the workspace should offer Start over / Show me for this step.
func supports_reset() -> bool:
	return true


func supports_hint() -> bool:
	return config.has("hint")


## Pieces the next step may keep using (e.g. story figures to be put away).
func handoff() -> Array[DragPiece]:
	return []


func finish(result: Dictionary = {}) -> void:
	if is_done:
		return
	is_done = true
	completed.emit(result)


## Feedback text from config with a built-in fallback.
func say(key: String, fallback: String) -> void:
	prompt_changed.emit(tr(str(config.get("feedback", {}).get(key, fallback))))


func tween_to(piece: Control, pos: Vector2, seconds := 0.25) -> void:
	if reduced_motion:
		piece.position = pos
		return
	var t := create_tween()
	t.tween_property(piece, "position", pos, seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Gentle "doesn't fit" shake, then slide home.
func reject(piece: DragPiece, home: Vector2) -> void:
	AudioService.play("return")
	if reduced_motion:
		piece.position = home
		return
	var t := create_tween()
	var p := piece.position
	t.tween_property(piece, "position", p + Vector2(10, 0), 0.05)
	t.tween_property(piece, "position", p - Vector2(10, 0), 0.08)
	t.tween_property(piece, "position", p, 0.05)
	t.tween_property(piece, "position", home, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func vec(value: Variant, fallback := Vector2.ZERO) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback
