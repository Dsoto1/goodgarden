class_name InvitationCard
extends ModalPanel
## A letter, usually from Miriam. Opening it keeps it in the Journal.


func show_invitation(invitation_id: String, mark_read := true) -> void:
	var data := Invitations.open(invitation_id) if mark_read else Content.get_invitation(invitation_id)
	open(640, Color("fbf3dc"))
	var body := UiStyle.label(tr(str(data.get("body", ""))), "LetterLabel")
	content.add_child(body)
	var sig := UiStyle.label("— %s" % tr(str(data.get("signature", ""))), "LetterLabel")
	sig.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(sig)
	var hear := UiStyle.button(tr("Hear it"))
	hear.pressed.connect(func() -> void:
		Observations.record("read_aloud_requested", "", {"invitation": invitation_id})
		AudioService.narrate(body.text, true))
	var keep := UiStyle.button(tr("Keep it in my journal"), true)
	keep.pressed.connect(close)
	add_buttons([hear, keep])
	AudioService.narrate(body.text)
