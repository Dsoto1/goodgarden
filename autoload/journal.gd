extends Node
## JournalService: the child's own record of invitations received, work done
## and optional real-world invitations. Written in the child's voice, never graded.

signal entry_added(entry: Dictionary)
signal changed

var _entries: Array[Dictionary] = []


func add(kind: String, text: String, ref: String = "") -> void:
	# The same invitation or real-world prompt is only journaled once per day.
	if kind != "work" and has_entry(kind, ref, Days.current_day):
		return
	var entry := {"day": Days.current_day, "kind": kind, "text": text, "ref": ref, "tried": false}
	_entries.append(entry)
	entry_added.emit(entry)
	changed.emit()


func has_entry(kind: String, ref: String, day: int = -1) -> bool:
	for e in _entries:
		if e["kind"] == kind and e["ref"] == ref and (day < 0 or e["day"] == day):
			return true
	return false


## Children may tick a real-world invitation as tried. Not ticking it costs nothing.
func mark_tried(entry: Dictionary, tried: bool) -> void:
	if entry.get("tried") == tried:
		return
	entry["tried"] = tried
	if tried:
		Observations.record("real_world_marked", "", {"ref": entry["ref"]})
	changed.emit()


func entries() -> Array[Dictionary]:
	return _entries


func days_with_entries() -> Array[int]:
	var out: Array[int] = []
	for e in _entries:
		if not out.has(e["day"]):
			out.append(e["day"])
	out.sort()
	return out


func entries_for_day(day: int) -> Array[Dictionary]:
	return _entries.filter(func(e: Dictionary) -> bool: return e["day"] == day)


func reset() -> void:
	_entries.clear()
	changed.emit()


func to_save() -> Array:
	return _entries.duplicate(true)


func from_save(data: Array) -> void:
	_entries.clear()
	for e: Variant in data:
		if e is Dictionary:
			e["day"] = int(e.get("day", 0))
			_entries.append(e)
	changed.emit()
