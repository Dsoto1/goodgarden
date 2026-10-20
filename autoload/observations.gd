extends Node
## LearningObservationService: a local, offline log of what the child chose
## and did, for grown-ups who want to observe rather than hover.
##
## Deliberately records work, not worth: activities chosen and revisited,
## self-corrections, help requested, time spent retelling. It never scores
## prayer or Scripture and never infers faith, virtue or obedience.

signal recorded(entry: Dictionary)

const MAX_ENTRIES := 2000

var _entries: Array[Dictionary] = []


func record(kind: String, activity_id: String = "", data: Dictionary = {}) -> void:
	var entry := {
		"time": int(Time.get_unix_time_from_system()),
		"day": Days.current_day,
		"kind": kind,
		"activity": activity_id,
		"data": data,
	}
	_entries.append(entry)
	if _entries.size() > MAX_ENTRIES:
		_entries.pop_front()
	recorded.emit(entry)


func entries() -> Array[Dictionary]:
	return _entries


func count(kind: String, activity_id: String = "") -> int:
	var n := 0
	for e in _entries:
		if e["kind"] == kind and (activity_id.is_empty() or e["activity"] == activity_id):
			n += 1
	return n


## Plain-language notes for the grown-ups' page, e.g.
## "Set the Table: completed 2 times (1 by choice after the first time)."
func summarize() -> PackedStringArray:
	var lines := PackedStringArray()
	var by_activity := {}
	for e in _entries:
		if e["activity"].is_empty():
			continue
		var stats: Dictionary = by_activity.get_or_add(e["activity"], {
			"started": 0, "completed": 0, "set_aside": 0, "self_corrections": 0,
			"help": 0, "read_aloud": 0, "seconds": 0, "retell_seconds": 0,
		})
		match e["kind"]:
			"activity_started": stats["started"] += 1
			"activity_completed":
				stats["completed"] += 1
				stats["seconds"] += int(e["data"].get("seconds", 0))
			"activity_set_aside": stats["set_aside"] += 1
			"self_correction": stats["self_corrections"] += 1
			"help_requested": stats["help"] += 1
			"read_aloud_requested": stats["read_aloud"] += 1
			"retold": stats["retell_seconds"] += int(e["data"].get("seconds", 0))
	for activity_id: String in by_activity:
		var s: Dictionary = by_activity[activity_id]
		var def := Content.get_activity(activity_id)
		var title: String = def.title if def else activity_id
		var parts := PackedStringArray()
		if def and def.is_reflection():
			# Report only that the material was chosen and how long it was used.
			parts.append("chosen %d time%s" % [s["started"], _plural(s["started"])])
			if s["retell_seconds"] > 0:
				parts.append("about %d min spent retelling with the figures" % ceili(s["retell_seconds"] / 60.0))
		elif s["completed"] == 0:
			parts.append("started %d time%s" % [s["started"], _plural(s["started"])])
		else:
			parts.append("completed %d time%s" % [s["completed"], _plural(s["completed"])])
			if s["completed"] > 1:
				parts.append("returned to it by choice %d time%s" % [s["completed"] - 1, _plural(s["completed"] - 1)])
			if s["self_corrections"] > 0:
				parts.append("noticed and fixed %d thing%s on their own" % [s["self_corrections"], _plural(s["self_corrections"])])
			if s["set_aside"] > 0:
				parts.append("set it aside to finish later %d time%s" % [s["set_aside"], _plural(s["set_aside"])])
		if s["help"] > 0:
			parts.append("asked to be shown %d time%s" % [s["help"], _plural(s["help"])])
		if s["read_aloud"] > 0:
			parts.append("asked to hear instructions read aloud %d time%s" % [s["read_aloud"], _plural(s["read_aloud"])])
		lines.append("%s: %s." % [title, ", ".join(parts)])
	var marked := count("real_world_marked")
	if marked > 0:
		lines.append("Marked %d real-world invitation%s as tried." % [marked, _plural(marked)])
	return lines


static func _plural(n: int) -> String:
	return "" if n == 1 else "s"


func reset() -> void:
	_entries.clear()


func to_save() -> Array:
	return _entries.duplicate(true)


func from_save(data: Array) -> void:
	_entries.clear()
	for e: Variant in data:
		if e is Dictionary:
			e["day"] = int(e.get("day", 0))
			_entries.append(e)
