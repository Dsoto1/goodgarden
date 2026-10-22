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
	# The day's jobs, under the letter: the work it asks for and the small
	# everyday ones. The same list stays in the corner of the screen.
	var spoken := body.text
	var jobs := TodaysWork.jobs(data)
	if jobs.size() > 1:
		var heading := UiStyle.label(tr("Today's jobs:"), "LetterLabel")
		heading.add_theme_color_override("font_color", Color("7a4a26"))
		content.add_child(heading)
		spoken += "\n" + heading.text
		for j: Dictionary in jobs:
			var row := TodaysWork.row(j, "LetterLabel", 36)
			content.add_child(row)
			spoken += "\n" + tr(j["text"])
	var hear := UiStyle.button(tr("Hear it"))
	hear.pressed.connect(func() -> void:
		Observations.record("read_aloud_requested", "", {"invitation": invitation_id})
		AudioService.narrate(spoken, true))
	var keep := UiStyle.button(tr("Keep it in my journal"), true)
	keep.pressed.connect(close)
	add_buttons([hear, keep])
	AudioService.narrate(spoken)
