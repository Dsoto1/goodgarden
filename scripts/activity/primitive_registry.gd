class_name PrimitiveRegistry
extends RefCounted
## Maps the "primitive" names used in activity JSON to reusable step scenes.
##
## Adding a new kind of manipulation means writing one ActivityStep subclass and
## registering it here; every activity in every location can then use it.

const PRIMITIVES := {
	"space_along_line": "res://scripts/activity/primitives/space_along_line.gd",
	"count_into_slots": "res://scripts/activity/primitives/count_into_slots.gd",
	"match_to_outline": "res://scripts/activity/primitives/match_to_outline.gd",
	"story_figures": "res://scripts/activity/primitives/story_figures.gd",
	"sort_into_bins": "res://scripts/activity/primitives/sort_into_bins.gd",
	"balance_scale": "res://scripts/activity/primitives/balance_scale.gd",
}


static func has(primitive: String) -> bool:
	return PRIMITIVES.has(primitive)


static func create(primitive: String) -> ActivityStep:
	var script: GDScript = load(PRIMITIVES[primitive])
	return script.new()
