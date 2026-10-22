class_name ActivityDefinition
extends RefCounted
## Typed view over one activity's JSON definition (content/activities/*.json).
##
## Content authors write JSON; systems read this class. Keeping the parse in one
## place means the runner, validator and parent tools agree on what a field
## means. See docs/CONTENT_GUIDE.md for the authoring reference.

enum Mode { TASK, REFLECTION }

var id: String
var title: String
var mode: Mode = Mode.TASK
var location: String
## Free-form readiness hints, e.g. {"ages": [5, 8], "math": "counting_to_12"}.
var readiness: Dictionary
var concepts: PackedStringArray
var formation_themes: PackedStringArray
## Visual style of the close-up work surface ("soil_bed", "wood_table", "atrium_felt").
var surface: String
## WorldState conditions that must hold before the activity is offered.
var prerequisites: Array
## Lines spoken before the first step: [{"speaker": "miriam", "text": "..."}].
var intro: Array
var steps: Array
var outro: Array
## Facts written when the activity is completed; strings may use $tokens.
var world_effects: Array
## "free" (repeat whenever the child chooses) or "once".
var replay: String
var real_world_invitation: String
## Child-facing sentence added to the Journal on completion.
var journal_line: String
## Gentle line shown when the child tries it but it isn't available right now.
var unavailable_text: String
var review_status: String
var source: Dictionary
## Changes for older children (about 8-10): "intro", "outro" and
## "journal_line" replace the usual ones; each step may also carry its own
## "older" settings. See at_level().
var older: Dictionary


static func from_dict(data: Dictionary) -> ActivityDefinition:
	var def := ActivityDefinition.new()
	def.id = str(data.get("id", ""))
	def.title = str(data.get("title", def.id))
	def.mode = Mode.REFLECTION if data.get("mode", "task") == "reflection" else Mode.TASK
	def.location = str(data.get("location", ""))
	def.readiness = data.get("readiness", {})
	def.concepts = PackedStringArray(data.get("concepts", []))
	def.formation_themes = PackedStringArray(data.get("formation_themes", []))
	def.surface = str(data.get("surface", "wood_table"))
	def.prerequisites = data.get("prerequisites", [])
	def.intro = data.get("intro", [])
	def.steps = data.get("steps", [])
	def.outro = data.get("outro", [])
	def.world_effects = data.get("world_effects", [])
	def.replay = str(data.get("replay", "free"))
	def.real_world_invitation = str(data.get("real_world_invitation", ""))
	def.journal_line = str(data.get("journal_line", ""))
	def.unavailable_text = str(data.get("unavailable_text", ""))
	def.review_status = str(data.get("review_status", ""))
	def.source = data.get("source", {})
	def.older = data.get("older", {})
	return def


## This activity as it is offered at a work level ("younger" or "older").
## For older children each step's "older" settings are laid over its usual
## ones, so the same work asks a little more (bigger numbers, fewer helps).
func at_level(level: String) -> ActivityDefinition:
	if level != "older":
		return self
	var def := ActivityDefinition.new()
	for prop: Dictionary in get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			def.set(prop["name"], get(prop["name"]))
	def.steps = []
	for step: Variant in steps:
		var cfg: Dictionary = (step as Dictionary).duplicate(true)
		var extra: Dictionary = cfg.get("older", {})
		cfg.erase("older")
		cfg.merge(extra, true)
		def.steps.append(cfg)
	def.intro = older.get("intro", intro)
	def.outro = older.get("outro", outro)
	def.journal_line = str(older.get("journal_line", journal_line))
	return def


func is_reflection() -> bool:
	return mode == Mode.REFLECTION


## Structural problems only; cross-references are checked by ContentValidator.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("activity is missing an id")
	if steps.is_empty():
		errors.append("%s: has no steps" % id)
	if replay not in ["free", "once"]:
		errors.append("%s: replay must be 'free' or 'once'" % id)
	var step_ids := {}
	for step: Variant in steps:
		if not step is Dictionary:
			errors.append("%s: every step must be an object" % id)
			continue
		var step_id := str(step.get("id", ""))
		if step_id.is_empty():
			errors.append("%s: a step is missing its id" % id)
		elif step_ids.has(step_id):
			errors.append("%s: duplicate step id '%s'" % [id, step_id])
		step_ids[step_id] = true
		if not PrimitiveRegistry.has(str(step.get("primitive", ""))):
			errors.append("%s/%s: unknown primitive '%s'" % [id, step_id, step.get("primitive", "")])
	for line: Variant in intro + outro:
		if not (line is Dictionary and line.has("text")):
			errors.append("%s: intro/outro lines need a 'text' field" % id)
	return errors
