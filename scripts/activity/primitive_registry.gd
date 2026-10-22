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
	"sequence_cards": "res://scripts/activity/primitives/sequence_cards.gd",
	"build_word": "res://scripts/activity/primitives/build_word.gd",
	"label_pictures": "res://scripts/activity/primitives/label_pictures.gd",
	"measure_with_units": "res://scripts/activity/primitives/measure_with_units.gd",
	"pour_to_line": "res://scripts/activity/primitives/pour_to_line.gd",
	"pay_with_coins": "res://scripts/activity/primitives/pay_with_coins.gd",
	"look_closely": "res://scripts/activity/primitives/look_closely.gd",
	"continue_pattern": "res://scripts/activity/primitives/continue_pattern.gd",
}


static func has(primitive: String) -> bool:
	return PRIMITIVES.has(primitive)


static func create(primitive: String) -> ActivityStep:
	var script: GDScript = load(PRIMITIVES[primitive])
	return script.new()
