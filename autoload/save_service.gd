extends Node
## SaveService: versioned, offline save of world facts and the child's journey.
##
## The schema is versioned from day one. When the shape changes, bump
## SCHEMA_VERSION and add a migration from the previous version; old saves are
## upgraded step by step on load rather than discarded.

signal saved(path: String)
signal loaded(path: String)

const SCHEMA_VERSION := 2
const DEFAULT_PATH := "user://saves/garden_1.json"

## Tests point this at a scratch file.
var path := DEFAULT_PATH
## World registers a callable returning {"position": [x,y,z], "facing": float}.
var player_provider: Callable
## Player state read from the last load, applied by World when it spawns.
var loaded_player: Dictionary = {}

## version -> Callable(Dictionary) -> Dictionary, upgrading from that version.
var _migrations := {
	0: _migrate_0_to_1,
	1: _migrate_1_to_2,
}


func has_save() -> bool:
	return FileAccess.file_exists(path)


func autosave() -> void:
	save_game()


func save_game() -> bool:
	var data := snapshot()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: could not write %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	saved.emit(path)
	return true


func snapshot() -> Dictionary:
	var player := {}
	if player_provider.is_valid():
		player = player_provider.call()
	return {
		"schema_version": SCHEMA_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"days": Days.to_save(),
		"world": WorldState.to_save(),
		"invitations": Invitations.to_save(),
		"journal": Journal.to_save(),
		"observations": Observations.to_save(),
		"discovery": Discovery.to_save(),
		"player": player,
	}


func load_game() -> bool:
	if not has_save():
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("SaveService: %s is not a valid save" % path)
		return false
	var data := migrate(parsed)
	if data.is_empty():
		return false
	restore(data)
	loaded.emit(path)
	return true


func restore(data: Dictionary) -> void:
	Days.from_save(data.get("days", {}))
	WorldState.from_save(data.get("world", {}))
	Invitations.from_save(data.get("invitations", {}))
	Journal.from_save(data.get("journal", []))
	Observations.from_save(data.get("observations", []))
	Discovery.from_save(data.get("discovery", {}))
	loaded_player = data.get("player", {})


## Upgrades older saves to SCHEMA_VERSION. Returns {} for saves from the future.
func migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("schema_version", 0))
	if version > SCHEMA_VERSION:
		push_error("SaveService: save is from a newer version (%d)" % version)
		return {}
	while version < SCHEMA_VERSION:
		data = _migrations[version].call(data)
		version += 1
		data["schema_version"] = version
	return data


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(path)


## Resets every service for a brand-new garden.
func new_game() -> void:
	Days.reset()
	WorldState.reset()
	Invitations.reset()
	Journal.reset()
	Observations.reset()
	Discovery.reset()
	loaded_player = {}


## Pre-release prototype saves kept facts under "flags" and had no player block.
func _migrate_0_to_1(data: Dictionary) -> Dictionary:
	if data.has("flags") and not data.has("world"):
		data["world"] = data["flags"]
		data.erase("flags")
	if not data.has("player"):
		data["player"] = {}
	return data


## Test builds before the Monday-to-Sunday week numbered the later days
## differently, so a save past day 5 may point at the wrong letter. The world
## facts say how far the child really got: resume on the first week-2 day
## whose work isn't done yet (or the free Saturday after it all), with that
## day's letter waiting. Animals were "stroked" then; now they are petted.
func _migrate_1_to_2(data: Dictionary) -> Dictionary:
	var world: Dictionary = data.get("world", {})
	for key: String in world.keys():
		if key.begins_with("animals.") and key.ends_with(".stroked_day"):
			world[key.replace(".stroked_day", ".petted_day")] = world[key]
			world.erase(key)
	var days: Dictionary = data.get("days", {})
	if int(days.get("current_day", 1)) <= 5:
		return data
	var resume := 13 # all of week 2 done: the free Saturday
	for step: Array in [[8, "village.flour_day"], [9, "village.baked_day"], [10, "orchard.planted"], [11, "valley.pond_day"]]:
		if not world.has(step[1]):
			resume = step[0]
			break
	if resume == 13 and str(world.get("npc.ruth.card", "")) != "given":
		resume = 12
	days["current_day"] = resume
	data["days"] = days
	data["invitations"] = {"pending_id": "" if resume == 13 else "inv_day_%03d" % resume}
	return data
