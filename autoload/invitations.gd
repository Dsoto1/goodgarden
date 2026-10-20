extends Node
## InvitationService: each day may bring a letter (usually from Miriam) that
## offers direction without obligation. Reading it adds it to the Journal.

signal delivered(invitation_id: String)
signal opened(invitation_id: String)

## Today's letter, waiting at the cottage until it is read. Empty when none.
var pending_id := ""


func deliver(invitation_id: String) -> void:
	pending_id = invitation_id
	if not invitation_id.is_empty():
		delivered.emit(invitation_id)


func has_unread() -> bool:
	return not pending_id.is_empty()


func current() -> Dictionary:
	return Content.get_invitation(pending_id)


## Opens an invitation: remembers it was read and journals it. Returns its data.
func open(invitation_id: String) -> Dictionary:
	var data := Content.get_invitation(invitation_id)
	if data.is_empty():
		push_warning("Invitations: unknown invitation '%s'" % invitation_id)
		return data
	WorldState.set_fact("invitation.%s.read" % invitation_id, true)
	Journal.add("invitation", str(data.get("body", "")), invitation_id)
	if invitation_id == pending_id:
		pending_id = ""
	opened.emit(invitation_id)
	return data


## The most recent invitation the child has read, for re-reading from the HUD.
func latest_read() -> String:
	var latest := ""
	for e in Journal.entries():
		if e["kind"] == "invitation":
			latest = e["ref"]
	return latest


func reset() -> void:
	pending_id = ""


func to_save() -> Dictionary:
	return {"pending_id": pending_id}


func from_save(data: Dictionary) -> void:
	pending_id = str(data.get("pending_id", ""))
