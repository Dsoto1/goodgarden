extends Node
## DialogueService: runs small, data-authored conversations.
##
## A dialogue file lists entry points guarded by WorldState conditions; the
## first matching entry starts the conversation, so characters naturally
## remember what the child has done. Nodes may carry actions that run when the
## node is shown or a choice is picked. Activities requested by dialogue start
## after the conversation closes, so the two never overlap.

signal conversation_started(dialogue_id: String)
## {"speaker": id, "name": display name, "text": String, "choices": Array[String],
##  "reply": String}. "reply" is what the child says to move on (the Next
## button): a greeting the first time they meet a grown-up each day, a goodbye
## on the last line ("Let's begin!" when work together follows), or a node's
## own "reply" ("You're welcome, Ruth!"). Choices on a first meeting begin
## with "Hello!".
signal line_shown(line: Dictionary)
signal conversation_ended(dialogue_id: String)

var active_id := ""
var _data: Dictionary
var _node: Dictionary
var _queued_activity := ""
var _first_line := false


func is_active() -> bool:
	return not active_id.is_empty()


func start(dialogue_id: String) -> bool:
	if is_active():
		return false
	var data := Content.get_dialogue(dialogue_id)
	if data.is_empty():
		push_warning("Dialogue: unknown dialogue '%s'" % dialogue_id)
		return false
	var start_node := ""
	for entry: Dictionary in data.get("entries", []):
		if WorldState.matches(entry.get("when", [])):
			start_node = entry["start"]
			break
	if start_node.is_empty():
		return false
	active_id = dialogue_id
	_data = data
	_queued_activity = ""
	GameState.push_mode(GameState.Mode.DIALOGUE)
	conversation_started.emit(dialogue_id)
	_first_line = true
	_show(start_node)
	return true


## Moves past a line without choices.
func advance() -> void:
	if not is_active():
		return
	if _node.get("choices", []).size() > 0:
		return
	if _first_line:
		_mark_greeted()
	var next := str(_node.get("next", ""))
	if next.is_empty():
		end()
	else:
		_show(next)


func choose(index: int) -> void:
	if not is_active():
		return
	var choices: Array = _node.get("choices", [])
	if index < 0 or index >= choices.size():
		return
	var choice: Dictionary = choices[index]
	if _first_line:
		_mark_greeted()
	_run_actions(choice.get("actions", []))
	var next := str(choice.get("next", ""))
	if next.is_empty():
		end()
	else:
		_show(next)


func end() -> void:
	if not is_active():
		return
	var finished := active_id
	active_id = ""
	_node = {}
	GameState.pop_mode(GameState.Mode.DIALOGUE)
	conversation_ended.emit(finished)
	if not _queued_activity.is_empty():
		var activity := _queued_activity
		_queued_activity = ""
		ActivityRunner.start(activity)


func current_line() -> Dictionary:
	return _line_for(_node) if is_active() else {}


func _show(node_id: String) -> void:
	var nodes: Dictionary = _data.get("nodes", {})
	if not nodes.has(node_id):
		push_warning("Dialogue: '%s' has no node '%s'" % [active_id, node_id])
		end()
		return
	_node = nodes[node_id]
	_run_actions(_node.get("actions", []))
	line_shown.emit(_line_for(_node))


## Manners are part of every conversation: the child greets each grown-up the
## first time they meet that day, and says goodbye when the talk is done.
func _reply_for(node: Dictionary, speaker: String) -> String:
	if speaker == "narrator" or speaker.is_empty() or not node.get("choices", []).is_empty():
		return tr(str(node.get("reply", "")))
	var name := character_name(speaker)
	var greet := _first_line and not _greeted_today(speaker)
	if node.has("reply"):
		return (tr("Hello!") + " " if greet else "") + tr(str(node["reply"]))
	if greet:
		return tr("Hello, %s!") % name
	if str(node.get("next", "")).is_empty():
		# Work together comes next, so it isn't goodbye yet.
		return tr("Let's begin!") if not _queued_activity.is_empty() else tr("Goodbye, %s!") % name
	return ""


func _greeted_today(speaker: String) -> bool:
	return int(WorldState.get_fact("npc.%s.greeted_day" % speaker, 0)) == Days.current_day


func _mark_greeted() -> void:
	_first_line = false
	var speaker := str(_node.get("speaker", _data.get("speaker", "")))
	if speaker != "narrator" and not speaker.is_empty():
		WorldState.set_fact("npc.%s.greeted_day" % speaker, Days.current_day)


func _line_for(node: Dictionary) -> Dictionary:
	var speaker := str(node.get("speaker", _data.get("speaker", "")))
	var choices: Array[String] = []
	# A grown-up who opens with a question still gets a greeting first.
	var greet := _first_line and speaker != "narrator" and not speaker.is_empty() and not _greeted_today(speaker)
	for c: Dictionary in node.get("choices", []):
		choices.append((tr("Hello!") + " " if greet else "") + tr(str(c.get("text", ""))))
	return {
		"speaker": speaker,
		"name": character_name(speaker),
		"text": tr(str(node.get("text", ""))),
		"mood": str(node.get("mood", "smile")),
		"choices": choices,
		"reply": _reply_for(node, speaker),
	}


func _run_actions(actions: Array) -> void:
	for action: Dictionary in actions:
		match action.get("op", ""):
			"start_activity":
				_queued_activity = str(action.get("id", ""))
			"set_fact", "set", "increment", "clear":
				var effect := action.duplicate()
				effect["op"] = "set" if action["op"] == "set_fact" else action["op"]
				WorldState.apply_effects([effect], {"day": Days.current_day})
			var unknown:
				push_warning("Dialogue: unknown action '%s'" % unknown)


static func character_name(speaker_id: String) -> String:
	var characters: Dictionary = Content.get_world("characters").get("characters", {})
	return str(characters.get(speaker_id, {}).get("name", speaker_id.capitalize()))
