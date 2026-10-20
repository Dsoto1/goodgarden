class_name ConfirmCard
extends ModalPanel
## A gentle two-choice question ("Rest until morning?").


func ask(message: String, yes_text: String, no_text: String, on_yes: Callable) -> void:
	open(520)
	content.add_child(UiStyle.label(message, "PromptLabel"))
	var no := UiStyle.button(no_text)
	no.pressed.connect(close)
	var yes := UiStyle.button(yes_text, true)
	yes.pressed.connect(func() -> void:
		close()
		on_yes.call())
	add_buttons([no, yes])
	AudioService.narrate(message)
