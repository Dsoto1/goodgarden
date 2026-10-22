class_name TodaysWork
extends RefCounted
## The day's jobs, from the letter read today: its main work and a couple of
## small everyday ones (set the table, feed the hens, say hello to a
## neighbour, stroke the lambs). Each job is done when its "activity" was
## finished today, or when its "done_when" conditions hold. Nothing is
## scored: the list only lets a child see what is left and when the day's
## work is finished. Each job carries a small picture ("icon"), so a child
## who can't read yet can still tell the jobs apart.

## The pictures a job may use (drawn by Icon).
const ICONS := ["seedling", "table", "hen", "talk", "sheep", "heart", "bread", "water", "mill", "tree", "fish", "card"]


## Today's letter, once it has been read (empty before, and on free days).
static func letter() -> Dictionary:
	if Invitations.has_unread():
		return {}
	var latest := Invitations.latest_read()
	if latest.is_empty() or not Journal.has_entry("invitation", latest, Days.current_day):
		return {}
	return Content.get_invitation(latest)


## The jobs a letter asks for, each {"text", "icon", "done"}. A letter without a
## "tasks" list has one job: what its summary says.
static func jobs(data: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var list: Array = data.get("tasks", [])
	if list.is_empty() and (data.has("suggests") or data.has("done_when")):
		list = [{"text": data.get("summary", ""), "activity": data.get("suggests", ""), "done_when": data.get("done_when", [])}]
	for job: Dictionary in list:
		out.append({"text": str(job.get("text", "")), "icon": str(job.get("icon", "seedling")), "done": is_done(job)})
	return out


static func is_done(job: Dictionary) -> bool:
	var when: Array = job.get("done_when", [])
	if not when.is_empty():
		return WorldState.matches(when)
	var activity := str(job.get("activity", ""))
	return not activity.is_empty() and int(WorldState.get_fact("activity.%s.last_day" % activity, 0)) == Days.current_day


## Today's jobs (empty before the letter is read, and on free days).
static func today() -> Array[Dictionary]:
	return jobs(letter())


## One job as a row: a ring that becomes a green tick when it is done, its
## picture, and its words (greyed a little once done).
static func row(job: Dictionary, label_type: String, edge: float) -> HBoxContainer:
	edge *= UiStyle.text_scale() # pictures grow with the words
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 6)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(Icon.Glyph.new("yes" if job["done"] else "todo", edge * 0.8))
	var pic := Icon.Glyph.new(job["icon"], edge)
	if job["done"]:
		pic.modulate.a = 0.55
	r.add_child(pic)
	var l := UiStyle.label(TranslationServer.translate(job["text"]), label_type)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if job["done"]:
		l.add_theme_color_override("font_color", Color("6b7f5a"))
	r.add_child(l)
	return r


## True once every job today's letter asked for is finished.
static func all_done() -> bool:
	var list := today()
	return not list.is_empty() and list.all(func(j: Dictionary) -> bool: return j["done"])
