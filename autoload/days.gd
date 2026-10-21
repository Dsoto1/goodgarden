extends Node
## Day/SeasonService: which day of the season it is and what that day offers.
##
## A day definition (content/days/day_NNN.json) references an Invitation,
## where NPCs stand, the primary activity and free-work suggestions. Days past
## the authored content use day 0, the "free day" template. Missing a day of
## play costs nothing: the season advances only when the child rests.

signal day_started(day: int)

var current_day := 1


func definition() -> Dictionary:
	return Content.get_day(current_day)


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
