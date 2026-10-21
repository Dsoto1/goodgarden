class_name ConfirmCard
extends ModalPanel
## A gentle two-choice question ("Rest until morning?").


func ask(message: String, yes_text: String, no_text: String, on_yes: Callable) -> void:
	open(520)
	content.add_child(UiStyle.label(message, "PromptLabel"))
	var no := UiStyle.button(no_text, false, "back")
	no.pressed.connect(close)
	var yes := UiStyle.button(yes_text, true, "yes")
	yes.pressed.connect(func() -> void:
		close()
		on_yes.call())
	# The safe answer starts selected, so a stray key press never says yes.
	add_buttons([no, yes], 0)
	AudioService.narrate("%s  %s%s%s" % [message, yes_text, tr(" Or: "), no_text])
