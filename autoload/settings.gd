extends Node
## AccessibilitySettings plus the few grown-up preferences.
##
## Stored per device in user://settings.json, separate from the save file, so a
## child's comfort settings (text size, read-aloud, reduced motion) survive
## starting a new garden.

signal changed(key: String)

const PATH := "user://settings.json"
const DEFAULTS := {
	"text_scale": 1.0, # 1.0 .. 1.6
	"read_aloud": false, # speak prompts and narration with the system voice when available
	"reduced_motion": false,
	"volume_master": 0.8,
	"volume_ambience": 0.7,
	"volume_effects": 0.7,
	"volume_voice": 1.0,
	"snap_tolerance": 56.0, # pixels; generous by default for small fingers
	"real_world_invitations": true,
	"session_minutes": 0, # 0 = no gentle rest reminder
}

## Tests turn this off so they never touch the developer's real settings file.
var persist := true

var _values: Dictionary = DEFAULTS.duplicate(true)


func _ready() -> void:
	load_settings()


func get_value(key: String) -> Variant:
	return _values.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant) -> void:
	assert(DEFAULTS.has(key), "Unknown setting: %s" % key)
	if _values.get(key) == value:
		return
	_values[key] = value
	changed.emit(key)
	save_settings()


func reset_to_defaults() -> void:
	_values = DEFAULTS.duplicate(true)
	for key: String in DEFAULTS:
		changed.emit(key)
	save_settings()


func load_settings() -> void:
	if not persist or not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		for key: String in DEFAULTS:
			if parsed.has(key) and typeof(parsed[key]) == typeof(DEFAULTS[key]):
				_values[key] = parsed[key]
			elif parsed.has(key) and DEFAULTS[key] is float and parsed[key] is int:
				_values[key] = float(parsed[key])


func save_settings() -> void:
	if not persist:
		return
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_values, "\t"))
