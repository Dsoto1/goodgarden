class_name PauseMenu
extends ModalPanel
## Pause anywhere. The world stops while this is open.


func show_menu() -> void:
	open(460)
	get_tree().paused = true
	content.add_child(UiStyle.label(tr("Resting for a moment"), "HeadingLabel"))
	AudioService.narrate(tr("Resting for a moment."))
	for item: Array in [
		[tr("Keep playing"), close, true, "next"],
		[tr("Settings"), func() -> void: _sub("open_settings"), false, "settings"],
		[tr("For grown-ups"), func() -> void: _sub("open_parents"), false, "lock"],
		[tr("Save and go to the main menu"), _ask_to_stop, false, "home"],
	] + ([[tr("Save and close the game"), _ask_to_close, false, "door"]] if Main.can_close_itself() else []):
		var b := UiStyle.button(item[0], item[2], item[3])
		b.pressed.connect(item[1])
		content.add_child(b)
		if item[2]:
			b.call_deferred("grab_focus")


func _ask_to_stop() -> void:
	# The answer must not belong to this menu: it is freed as soon as it closes,
	# and a "Yes" tied to it would silently do nothing.
	var main := get_tree().get_first_node_in_group("main")
	var parent := get_parent()
	close()
	var card := ConfirmCard.new()
	parent.add_child(card)
	card.ask(tr("Go to the main menu? Your garden will be saved."), tr("Yes, save and go"), tr("Keep playing"), Callable(main, "quit_to_title"))


func _ask_to_close() -> void:
	var main := get_tree().get_first_node_in_group("main")
	var parent := get_parent()
	close()
	var card := ConfirmCard.new()
	parent.add_child(card)
	card.ask(tr("Close the game? Your garden will be saved."), tr("Yes, save and close"), tr("Keep playing"), Callable(main, "quit_game"))


func _sub(method: String) -> void:
	close()
	get_tree().call_group("main", method)


func close() -> void:
	get_tree().paused = false
	super.close()
