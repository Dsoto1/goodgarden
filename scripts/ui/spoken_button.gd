class_name SpokenButton
extends Node
## Lets a child who can't read yet hear what a button says. Holding a button
## for a moment speaks its words without pressing it; resting the mouse on
## it, or moving to it with keys or a gamepad, speaks them too. Attached to
## every button in the game by AudioService.

const HOLD := 0.55
const DWELL := 0.5

var _button: BaseButton
var _held_since := -1 # msec the press began, or -1
var _hover := -1.0


static func attach(b: BaseButton) -> void:
	if b.has_meta(&"spoken_button"):
		return
	b.set_meta(&"spoken_button", true)
	var helper := SpokenButton.new()
	helper._button = b
	b.add_child.call_deferred(helper, false, Node.INTERNAL_MODE_BACK)


## The words a button stands for: its "spoken" meta, its text, or its tooltip.
static func words(b: BaseButton) -> String:
	if b.has_meta(&"spoken"):
		return str(b.get_meta(&"spoken"))
	var t := ""
	if b is Button:
		t = (b as Button).text.strip_edges()
	return t if not t.is_empty() else b.tooltip_text


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button.button_down.connect(func() -> void:
		_held_since = Time.get_ticks_msec()
		_hover = -1.0)
	_button.button_up.connect(func() -> void: _held_since = -1)
	_button.mouse_entered.connect(func() -> void:
		_hover = 0.0 if AudioService.pointer_is_mouse() else -1.0)
	_button.mouse_exited.connect(func() -> void:
		_hover = -1.0
		_held_since = -1)
	_button.focus_entered.connect(func() -> void:
		if AudioService.navigated_recently():
			_speak(false))


func _process(delta: float) -> void:
	# Timed by the clock from the moment of the press, not by adding up frame
	# times: on a slow frame, a quick tap must still be a tap.
	if _held_since >= 0:
		if Time.get_ticks_msec() - _held_since >= HOLD * 1000.0:
			_held_since = -1
			_speak(true)
			# A long hold is for listening: cancel the press so letting go
			# doesn't also choose.
			if not _button.disabled:
				_button.disabled = true
				_button.set_deferred("disabled", false)
	elif _hover >= 0.0:
		_hover += delta
		if _hover >= DWELL:
			_hover = -1.0
			_speak(false)


func _speak(force: bool) -> void:
	var w := words(_button)
	if not w.is_empty() and _button.is_visible_in_tree():
		AudioService.narrate(w, force)
