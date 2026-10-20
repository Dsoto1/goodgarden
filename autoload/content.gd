extends Node
## ContentDB: loads every authored JSON file under res://content once at boot.
##
## Writers add files; no engine code changes are needed for ordinary content.
## Each folder holds one kind of record, keyed by its "id" field.

const ROOT := "res://content"
const KINDS := ["activities", "days", "dialogue", "invitations", "real_world", "world"]

var activities: Dictionary = {} # id -> ActivityDefinition
var days: Dictionary = {} # day number (int) -> Dictionary
var dialogue: Dictionary = {} # id -> Dictionary
var invitations: Dictionary = {} # id -> Dictionary
var real_world: Dictionary = {} # id -> Dictionary
var world: Dictionary = {} # id -> Dictionary (regions, atrium shelf, ...)

## Problems found while parsing; ContentValidator reports these alongside its own checks.
var load_errors := PackedStringArray()


func _ready() -> void:
	reload()


func reload() -> void:
	load_errors.clear()
	activities.clear()
	days.clear()
	dialogue.clear()
	invitations.clear()
	real_world.clear()
	world.clear()
	for kind: String in KINDS:
		for path in list_json(ROOT.path_join(kind)):
			_ingest(kind, path)


func get_activity(id: String) -> ActivityDefinition:
	return activities.get(id)


func get_day(number: int) -> Dictionary:
	if days.has(number):
		return days[number]
	# Days without authored content fall back to the "free day" template so the
	# world keeps living past the end of written content.
	return days.get(0, {})


func get_invitation(id: String) -> Dictionary:
	return invitations.get(id, {})


func get_dialogue(id: String) -> Dictionary:
	return dialogue.get(id, {})


func get_real_world(id: String) -> Dictionary:
	return real_world.get(id, {})


func get_world(id: String) -> Dictionary:
	return world.get(id, {})


static func list_json(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for file in dir.get_files():
		if file.ends_with(".json"):
			out.append(dir_path.path_join(file))
	out.sort()
	return out


func _ingest(kind: String, path: String) -> void:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		load_errors.append("%s:%d %s" % [path, json.get_error_line(), json.get_error_message()])
		return
	var data: Variant = json.data
	if not data is Dictionary:
		load_errors.append("%s: top level must be an object" % path)
		return
	var id := str(data.get("id", ""))
	if id.is_empty():
		load_errors.append("%s: missing 'id'" % path)
		return
	match kind:
		"activities":
			if activities.has(id):
				load_errors.append("%s: duplicate activity id '%s'" % [path, id])
			activities[id] = ActivityDefinition.from_dict(data)
		"days":
			var number := int(data.get("day", -1))
			if number < 0:
				load_errors.append("%s: missing 'day' number" % path)
			elif days.has(number):
				load_errors.append("%s: duplicate day %d" % [path, number])
			else:
				days[number] = data
		"dialogue":
			dialogue[id] = data
		"invitations":
			invitations[id] = data
		"real_world":
			real_world[id] = data
		"world":
			world[id] = data
