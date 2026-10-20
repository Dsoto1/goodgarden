extends Node
## Scene entry point: godot --headless --path . res://tools/validate_content.tscn


func _ready() -> void:
	var errors := ContentValidator.new().run()
	for e in errors:
		printerr("CONTENT: ", e)
	print("Content validation: %d activities, %d days, %d dialogues; %d problem(s)." % [Content.activities.size(), Content.days.size(), Content.dialogue.size(), errors.size()])
	get_tree().quit(1 if errors.size() > 0 else 0)
