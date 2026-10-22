class_name ContentValidator
extends RefCounted
## Automated checks for authored content (docs/design/CONTENT_PIPELINE.md):
## missing ids, broken references, impossible prerequisites, unknown effect
## operations, missing narration files, and untracked third-party assets.
## Run from the test suite or with tools/validate_content.tscn.

const KNOWN_SURFACES := ["soil_bed", "wood_table", "atrium_felt"]
const KNOWN_EFFECT_OPS := ["set", "increment", "clear"]
const CONDITION_KEYS := ["fact", "day", "day_at_least", "weekday", "any", "not"]
const THIRD_PARTY_DIR := "res://assets/third_party"

var errors := PackedStringArray()


func run() -> PackedStringArray:
	errors = Content.load_errors.duplicate()
	var region_ids := _check_regions()
	for id: String in Content.activities:
		_check_activity(Content.activities[id], region_ids)
	for number: int in Content.days:
		_check_day(Content.days[number])
	for id: String in Content.dialogue:
		_check_dialogue(Content.dialogue[id])
	for id: String in Content.invitations:
		var inv: Dictionary = Content.invitations[id]
		_require_text(inv, "body", "invitation %s" % id)
		if inv.has("suggests") and Content.get_activity(str(inv["suggests"])) == null:
			errors.append("invitation %s suggests unknown activity '%s'" % [id, inv["suggests"]])
		_check_jobs(inv, id)
	for id: String in Content.real_world:
		_require_text(Content.real_world[id], "text", "real-world invitation %s" % id)
	for item: Dictionary in Content.get_world("atrium_shelf").get("items", []):
		var def := Content.get_activity(str(item.get("activity", "")))
		if def == null:
			errors.append("atrium shelf lists unknown activity '%s'" % item.get("activity", ""))
		elif not def.is_reflection():
			errors.append("atrium shelf item '%s' must be a reflection-mode activity" % def.id)
	_check_looks()
	_check_third_party()
	return errors


## A letter's jobs: each says what to do, and how to know it is done (an
## activity finished today, or conditions). Reflection never counts as a job.
func _check_jobs(inv: Dictionary, id: String) -> void:
	var jobs: Array = inv.get("tasks", [])
	if jobs.size() > 3:
		errors.append("invitation %s asks for %d jobs (three at most)" % [id, jobs.size()])
	for i in jobs.size():
		var job: Dictionary = jobs[i]
		var where := "invitation %s job %d" % [id, i + 1]
		_require_text(job, "text", where)
		if not str(job.get("icon", "")) in TodaysWork.ICONS:
			errors.append("%s needs an icon, one of %s" % [where, TodaysWork.ICONS])
		if job.has("activity"):
			var def := Content.get_activity(str(job["activity"]))
			if def == null:
				errors.append("%s names unknown activity '%s'" % [where, job["activity"]])
			elif def.is_reflection():
				errors.append("%s is a story; quiet time is never a job" % where)
		elif job.has("done_when"):
			_check_conditions(job["done_when"], where)
		else:
			errors.append("%s needs an activity or done_when" % where)


## Every colour named in a character look must exist in the palette.
func _check_looks() -> void:
	var looks := []
	var chars: Dictionary = Content.get_world("characters").get("characters", {})
	for id: String in chars:
		if chars[id].has("look"):
			looks.append([id, chars[id]["look"]])
	for i in Content.get_world("characters").get("villagers", []).size():
		looks.append(["villager %d" % i, Content.get_world("characters")["villagers"][i]])
	const COLOR_KEYS := ["skin", "hair", "beard", "eyes", "shirt", "pants", "skirt", "apron", "vest", "belt", "collar", "shoes", "hat_color", "hat_band", "backpack", "brows"]
	for entry: Array in looks:
		for key: String in COLOR_KEYS:
			if entry[1].has(key) and not Palette.COLORS.has(str(entry[1][key])):
				errors.append("look %s: '%s' uses unknown palette colour '%s'" % [entry[0], key, entry[1][key]])


func _check_regions() -> Array:
	var ids := []
	for r: Dictionary in Content.get_world("regions").get("regions", []):
		ids.append(r.get("id", ""))
		if not ResourceLoader.exists(str(r.get("scene", ""))):
			errors.append("region %s: scene '%s' not found" % [r.get("id", "?"), r.get("scene", "")])
	return ids


func _check_activity(def: ActivityDefinition, region_ids: Array) -> void:
	errors.append_array(def.validate())
	var where := "activity %s" % def.id
	if def.surface not in KNOWN_SURFACES:
		errors.append("%s: unknown surface '%s'" % [where, def.surface])
	if not def.location.is_empty() and def.location not in region_ids:
		errors.append("%s: location '%s' is not a region" % [where, def.location])
	if not def.real_world_invitation.is_empty() and Content.get_real_world(def.real_world_invitation).is_empty():
		errors.append("%s: unknown real-world invitation '%s'" % [where, def.real_world_invitation])
	_check_conditions(def.prerequisites, where)
	for condition: Dictionary in def.prerequisites:
		# A prerequisite that the activity's own effects can never satisfy is fine;
		# one that names another activity's completion must point at a real activity.
		var fact := str(condition.get("fact", ""))
		if fact.begins_with("activity.") and Content.get_activity(fact.get_slice(".", 1)) == null:
			errors.append("%s: prerequisite refers to unknown activity in '%s'" % [where, fact])
	var seen := []
	for i in def.steps.size():
		var step: Dictionary = def.steps[i]
		if step.has("slots_from") and str(step["slots_from"]) not in seen:
			errors.append("%s/%s: slots_from '%s' must name an earlier step" % [where, step.get("id", i), step["slots_from"]])
		if step.get("pieces_from_previous", false) and i == 0:
			errors.append("%s/%s: pieces_from_previous on the first step" % [where, step.get("id", i)])
		if str(step.get("prompt", "")).is_empty() and step.get("primitive") != "story_figures":
			errors.append("%s/%s: step has no prompt for the child" % [where, step.get("id", i)])
		_check_audio(step, where)
		seen.append(str(step.get("id", "")))
	for line: Dictionary in def.intro + def.outro:
		_check_audio(line, where)
		var speaker := str(line.get("speaker", ""))
		if not speaker.is_empty() and not _is_character(speaker):
			errors.append("%s: unknown speaker '%s'" % [where, speaker])
	for effect: Dictionary in def.world_effects:
		if str(effect.get("op", "set")) not in KNOWN_EFFECT_OPS:
			errors.append("%s: unknown effect op '%s'" % [where, effect.get("op")])
		if str(effect.get("fact", "")).is_empty():
			errors.append("%s: an effect has no fact key" % where)
		for token in _tokens(effect.get("value")):
			var step_id := token.get_slice(".", 0)
			if token != "day" and token != "activity" and step_id not in seen:
				errors.append("%s: effect token '$%s' does not match a step" % [where, token])
	if def.is_reflection() and def.steps.any(func(s: Dictionary) -> bool: return s.has("score")):
		errors.append("%s: reflection activities must not be scored" % where)


func _check_day(day: Dictionary) -> void:
	var where := "day %s" % day.get("day", "?")
	var inv := str(day.get("invitation", ""))
	if not inv.is_empty() and Content.get_invitation(inv).is_empty():
		errors.append("%s: unknown invitation '%s'" % [where, inv])
	var ids: Array = day.get("free_work", []) + day.get("chapel", [])
	if day.has("primary_activity"):
		ids.append(day["primary_activity"])
	for id: Variant in ids:
		if Content.get_activity(str(id)) == null:
			errors.append("%s: unknown activity '%s'" % [where, id])
	for npc: String in day.get("npcs", {}):
		if not _is_character(npc):
			errors.append("%s: unknown npc '%s'" % [where, npc])


func _check_dialogue(d: Dictionary) -> void:
	var where := "dialogue %s" % d.get("id", "?")
	var nodes: Dictionary = d.get("nodes", {})
	if d.get("entries", []).is_empty():
		errors.append("%s: has no entries" % where)
	for entry: Dictionary in d.get("entries", []):
		if not nodes.has(str(entry.get("start", ""))):
			errors.append("%s: entry starts at missing node '%s'" % [where, entry.get("start", "")])
		_check_conditions(entry.get("when", []), where)
	for node_id: String in nodes:
		var n: Dictionary = nodes[node_id]
		_require_text(n, "text", "%s/%s" % [where, node_id])
		if n.has("mood") and not CharacterModel.MOODS.has(str(n["mood"])):
			errors.append("%s/%s: unknown mood '%s'" % [where, node_id, n["mood"]])
		var nexts := [str(n.get("next", ""))]
		var actions: Array = n.get("actions", []).duplicate()
		for c: Dictionary in n.get("choices", []):
			nexts.append(str(c.get("next", "")))
			actions.append_array(c.get("actions", []))
			_require_text(c, "text", "%s/%s choice" % [where, node_id])
		for next: String in nexts:
			if not next.is_empty() and not nodes.has(next):
				errors.append("%s/%s: next node '%s' is missing" % [where, node_id, next])
		for a: Dictionary in actions:
			if a.get("op") == "start_activity" and Content.get_activity(str(a.get("id", ""))) == null:
				errors.append("%s/%s: starts unknown activity '%s'" % [where, node_id, a.get("id", "")])
	if not _is_character(str(d.get("speaker", ""))):
		errors.append("%s: unknown speaker '%s'" % [where, d.get("speaker", "")])


func _check_conditions(conditions: Array, where: String) -> void:
	for c: Variant in conditions:
		if not c is Dictionary or not CONDITION_KEYS.any(func(k: String) -> bool: return c.has(k)):
			errors.append("%s: unrecognized condition %s" % [where, c])
			continue
		if c.has("any"):
			_check_conditions(c["any"], where)
		if c.has("not"):
			_check_conditions([c["not"]], where)


func _check_audio(entry: Dictionary, where: String) -> void:
	if entry.has("audio") and not ResourceLoader.exists(str(entry["audio"])):
		errors.append("%s: narration audio '%s' not found" % [where, entry["audio"]])


func _check_third_party() -> void:
	var manifest_path := THIRD_PARTY_DIR.path_join("manifest.json")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not parsed is Dictionary:
		errors.append("third-party manifest missing or invalid: %s" % manifest_path)
		return
	var listed := {}
	for a: Dictionary in parsed.get("assets", []):
		for field: String in ["path", "source", "license", "creator"]:
			if str(a.get(field, "")).is_empty():
				errors.append("third-party manifest entry %s is missing '%s'" % [a.get("path", "?"), field])
		var base := str(a.get("path", ""))
		var files: Array = a.get("files", [])
		if files.is_empty():
			listed[base] = true # a single-file entry
		for f: Variant in files:
			var full := base.path_join(str(f))
			listed[full] = true
			if not FileAccess.file_exists(full):
				errors.append("third-party manifest lists a missing file: %s" % full)
	for file in _files_under(THIRD_PARTY_DIR):
		if file.get_file() == "manifest.json" or file.ends_with(".import"):
			continue
		if not listed.has(file):
			errors.append("untracked third-party asset: %s" % file)
	_check_props()


## Every catalogued prop must point at a model that exists and is tracked.
func _check_props() -> void:
	for id: String in Props.catalog().get("props", {}):
		var path := Props.scene_path(id)
		if not ResourceLoader.exists(path):
			errors.append("prop '%s': model %s not found" % [id, path])


func _files_under(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f in dir.get_files():
		out.append(dir_path.path_join(f))
	for d in dir.get_directories():
		out.append_array(_files_under(dir_path.path_join(d)))
	return out


func _require_text(d: Dictionary, key: String, where: String) -> void:
	if str(d.get(key, "")).strip_edges().is_empty():
		errors.append("%s: missing '%s' text" % [where, key])


func _is_character(id: String) -> bool:
	return Content.get_world("characters").get("characters", {}).has(id)


static func _tokens(value: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if value is String and value.begins_with("$"):
		out.append(value.substr(1))
	elif value is Dictionary:
		for v: Variant in value.values():
			out.append_array(_tokens(v))
	elif value is Array:
		for v: Variant in value:
			out.append_array(_tokens(v))
	return out
