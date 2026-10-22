extends Node
## ActivityRunner: turns an ActivityDefinition into a running workspace.
##
## The runner owns the lifecycle shared by every activity: checking
## prerequisites, opening the reusable workspace, recording observations,
## applying world effects, journaling and autosaving. Workspaces and
## primitives never write world state themselves, so a gardening row, a table
## setting and a Scripture material all finish the same way.

signal activity_started(def: ActivityDefinition)
## `completed` is false when the child set the work aside to finish later.
signal activity_finished(def: ActivityDefinition, completed: bool)

const WORKSPACE_SCENE := "res://scenes/activities/activity_workspace.tscn"

## Where workspaces are shown; Main assigns its activity CanvasLayer.
var host: Node
var current: ActivityDefinition
var workspace: ActivityWorkspace
var _started_msec := 0


func is_running() -> bool:
	return current != null


func can_start(activity_id: String) -> bool:
	var def := Content.get_activity(activity_id)
	if def == null or is_running():
		return false
	if def.replay == "once" and WorldState.has_fact(completion_fact(def.id)):
		return false
	return WorldState.matches(def.prerequisites)


func start(activity_id: String) -> bool:
	if not can_start(activity_id):
		push_warning("ActivityRunner: cannot start '%s' now" % activity_id)
		return false
	current = Content.get_activity(activity_id).at_level(str(Settings.get_value("work_level")))
	_started_msec = Time.get_ticks_msec()
	GameState.push_mode(GameState.Mode.REFLECTION if current.is_reflection() else GameState.Mode.ACTIVITY)
	Observations.record("activity_started", current.id)
	workspace = load(WORKSPACE_SCENE).instantiate()
	workspace.observed.connect(_on_observed)
	workspace.finished.connect(_on_workspace_finished)
	(host if host else get_tree().root).add_child(workspace)
	workspace.run(current)
	activity_started.emit(current)
	return true


## Child chose to stop for now. Nothing is lost or penalized; the work simply
## is not applied to the world yet.
func set_aside() -> void:
	if is_running():
		_finish(false, {})


func _on_workspace_finished(results: Dictionary) -> void:
	_finish(true, results)


func _finish(completed: bool, results: Dictionary) -> void:
	var def := current
	var seconds := int((Time.get_ticks_msec() - _started_msec) / 1000.0)
	if completed:
		var tokens := {"day": Days.current_day, "activity": def.id}
		for step_id: String in results:
			for key: String in results[step_id]:
				tokens["%s.%s" % [step_id, key]] = results[step_id][key]
		WorldState.apply_effects(def.world_effects, tokens)
		WorldState.increment(completion_fact(def.id))
		WorldState.set_fact("activity.%s.last_day" % def.id, Days.current_day)
		Observations.record("activity_completed", def.id, {"seconds": seconds})
		if not def.journal_line.is_empty():
			Journal.add("work", tr(def.journal_line), def.id)
		_offer_real_world_invitation(def)
	else:
		Observations.record("activity_set_aside", def.id, {"seconds": seconds})
	if is_instance_valid(workspace):
		workspace.queue_free()
	workspace = null
	current = null
	GameState.pop_mode(GameState.Mode.REFLECTION if def.is_reflection() else GameState.Mode.ACTIVITY)
	activity_finished.emit(def, completed)
	if completed:
		SaveService.autosave()


func _offer_real_world_invitation(def: ActivityDefinition) -> void:
	if def.real_world_invitation.is_empty() or not Settings.get_value("real_world_invitations"):
		return
	var rwi := Content.get_real_world(def.real_world_invitation)
	if not rwi.is_empty():
		Journal.add("real_world", tr(str(rwi.get("text", ""))), def.real_world_invitation)


func _on_observed(kind: String, data: Dictionary) -> void:
	if current:
		Observations.record(kind, current.id, data)


static func completion_fact(activity_id: String) -> String:
	return "activity.%s.completed" % activity_id
