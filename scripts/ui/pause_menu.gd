class_name PauseMenu
extends ModalPanel
## Pause anywhere. The world stops while this is open.


func show_menu() -> void:
	open(460)
	get_tree().paused = true
	content.add_child(UiStyle.label(tr("Resting for a moment"), "HeadingLabel"))
	for item: Array in [
		[tr("Keep playing"), close, true],
		[tr("Settings"), func() -> void: _sub("open_settings"), false],
		[tr("For grown-ups"), func() -> void: _sub("open_parents"), false],
		[tr("Save and go to the title"), func() -> void:
			close()
			get_tree().call_group("main", "quit_to_title"), false],
	]:
		var b := UiStyle.button(item[0], item[2])
		b.pressed.connect(item[1])
		content.add_child(b)
		if item[2]:
			b.call_deferred("grab_focus")


func _sub(method: String) -> void:
	close()
	get_tree().call_group("main", method)


func close() -> void:
	get_tree().paused = false
	super.close()
