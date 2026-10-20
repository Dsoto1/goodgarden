extends Node
## WorldStateService: the persistent facts the world remembers.
##
## Facts describe the world, not checklist flags: "garden.bed_1" holds the crop,
## hole count and the day it was planted, so regions can derive what to show
## (seeds, sprouts, seedlings) on any later day.
##
## Keys are dotted strings by convention: "<place>.<thing>" or "npc.<id>.<flag>".

signal fact_changed(key: String, value: Variant)

var _facts: Dictionary = {}


func set_fact(key: String, value: Variant) -> void:
	if _facts.get(key) == value and _facts.has(key):
		return
	_facts[key] = value
	fact_changed.emit(key, value)


func get_fact(key: String, default: Variant = null) -> Variant:
	return _facts.get(key, default)


func has_fact(key: String) -> bool:
	return _facts.has(key)


func increment(key: String, by: int = 1) -> int:
	var value := int(_facts.get(key, 0)) + by
	set_fact(key, value)
	return value


func clear_fact(key: String) -> void:
	if _facts.erase(key):
		fact_changed.emit(key, null)


func reset() -> void:
	var keys := _facts.keys()
	_facts.clear()
	for key: String in keys:
		fact_changed.emit(key, null)


## True when every condition holds. Conditions are authored in content JSON:
##   {"fact": "garden.bed_1", "exists": true}
##   {"fact": "home.table_set", "equals": true}
##   {"fact": "chapel.good_samaritan.visits", "at_least": 2}
##   {"fact": "home.table_set_day", "is_today": true}   (fact holds a day number)
##   {"day_at_least": 2}  {"day": 1}
##   {"any": [ ...conditions... ]}  {"not": {...condition...}}
func matches(conditions: Array) -> bool:
	for condition: Variant in conditions:
		if not _matches_one(condition):
			return false
	return true


func _matches_one(c: Dictionary) -> bool:
	if c.has("any"):
		for sub: Variant in c["any"]:
			if _matches_one(sub):
				return true
		return false
	if c.has("not"):
		return not _matches_one(c["not"])
	if c.has("day"):
		return Days.current_day == int(c["day"])
	if c.has("day_at_least"):
		return Days.current_day >= int(c["day_at_least"])
	if c.has("fact"):
		var key: String = c["fact"]
		if c.has("exists"):
			return has_fact(key) == bool(c["exists"])
		if c.has("equals"):
			return has_fact(key) and get_fact(key) == c["equals"]
		if c.has("at_least"):
			return float(get_fact(key, 0)) >= float(c["at_least"])
		if c.has("is_today"):
			return (has_fact(key) and int(get_fact(key)) == Days.current_day) == bool(c["is_today"])
		return has_fact(key)
	push_warning("WorldState: unrecognized condition %s" % [c])
	return false


## Applies authored effects:
##   {"op": "set", "fact": "garden.bed_1", "value": {"crop": "beans", "planted_day": "$day"}}
##   {"op": "increment", "fact": "chapel.good_samaritan.visits"}
##   {"op": "clear", "fact": "..."}
## String values beginning with "$" are looked up in `tokens` (e.g. $day, $result.holes).
func apply_effects(effects: Array, tokens: Dictionary = {}) -> void:
	for effect: Dictionary in effects:
		var key: String = effect.get("fact", "")
		match effect.get("op", "set"):
			"set":
				set_fact(key, resolve_tokens(effect.get("value", true), tokens))
			"increment":
				increment(key, int(effect.get("by", 1)))
			"clear":
				clear_fact(key)
			var unknown:
				push_warning("WorldState: unknown effect op '%s'" % unknown)


static func resolve_tokens(value: Variant, tokens: Dictionary) -> Variant:
	if value is String and value.begins_with("$"):
		return tokens.get(value.substr(1), value)
	if value is Dictionary:
		var out := {}
		for k: Variant in value:
			out[k] = resolve_tokens(value[k], tokens)
		return out
	if value is Array:
		return value.map(func(v: Variant) -> Variant: return resolve_tokens(v, tokens))
	return value


func to_save() -> Dictionary:
	return _facts.duplicate(true)


func from_save(data: Dictionary) -> void:
	reset()
	for key: String in data:
		set_fact(key, data[key])
