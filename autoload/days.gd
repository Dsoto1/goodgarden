extends Node
## Day/SeasonService: which day of the season it is and what that day offers.
##
## A day definition (content/days/day_NNN.json) references an Invitation,
## where NPCs stand, the primary activity and free-work suggestions. Days past
## the authored content use day 0, the "free day" template. Missing a day of
## play costs nothing: the season advances only when the child rests.
##
## The days run in weeks: day 1 is a Monday. Monday to Friday each have a
## letter and three jobs; Saturday is a free day (no letter, open play and
## free work); Sunday is the day of rest, with no jobs and the neighbours
## gathered at the Chapel. Twelve weeks make the 60 guided days of a season.

signal day_started(day: int)

const WEEKDAYS := ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
## Where the neighbours stand on a Sunday past the authored days.
const SUNDAY_NPCS := {"miriam": "chapel_miriam", "tobias": "chapel_tobias", "ruth": "chapel_ruth", "amos": "chapel_amos"}

var current_day := 1


func definition() -> Dictionary:
	var def := Content.get_day(current_day)
	if is_sunday() and int(def.get("day", 0)) != current_day:
		def = def.duplicate()
		def["npcs"] = SUNDAY_NPCS
	return def


## "monday" .. "sunday" for `day` (today by default). Day 1 is a Monday.
func weekday(day := -1) -> String:
	return WEEKDAYS[((current_day if day < 0 else day) - 1) % 7]


## The weekday's name for showing and reading aloud ("Monday").
func weekday_name(day := -1) -> String:
	return tr(weekday(day).capitalize())


func is_sunday() -> bool:
	return weekday() == "sunday"


## Which week of the season it is, from 1.
func week() -> int:
	return (current_day - 1) / 7 + 1


func start_day(day: int) -> void:
	current_day = day
	Invitations.deliver(str(definition().get("invitation", "")))
	day_started.emit(day)


func end_day() -> void:
	Observations.record("day_rested")
	start_day(current_day + 1)


## Season name for the HUD chip ("Spring" until the calendar says otherwise).
func season() -> String:
	return str(definition().get("season", "Spring"))


## Where an NPC should stand today, as an anchor id placed by a region.
func npc_anchor(npc_id: String) -> String:
	return str(definition().get("npcs", {}).get(npc_id, ""))


func reset() -> void:
	current_day = 1


func to_save() -> Dictionary:
	return {"current_day": current_day}


func from_save(data: Dictionary) -> void:
	current_day = int(data.get("current_day", 1))
