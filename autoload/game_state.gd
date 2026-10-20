extends Node
## GameState: what the child is doing right now, so input and camera know who
## owns the moment. Modes stack, e.g. a pause menu opened during an activity.

signal mode_changed(mode: Mode)

enum Mode { TITLE, EXPLORE, DIALOGUE, ACTIVITY, REFLECTION, MENU, TRANSITION }

var _stack: Array[Mode] = [Mode.TITLE]


func mode() -> Mode:
	return _stack.back()


func is_exploring() -> bool:
	return mode() == Mode.EXPLORE


func reset(to: Mode) -> void:
	_stack = [to]
	mode_changed.emit(to)


func push_mode(m: Mode) -> void:
	_stack.append(m)
	mode_changed.emit(m)


## Pops `m` if it is on top; tolerant of being called twice.
func pop_mode(m: Mode) -> void:
	if _stack.size() > 1 and _stack.back() == m:
		_stack.pop_back()
		mode_changed.emit(mode())
	elif _stack.has(m) and _stack.size() > 1:
		_stack.erase(m)
		mode_changed.emit(mode())
