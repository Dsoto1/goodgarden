class_name BookPanel
extends ModalPanel
## The chapel library: choose a book from the shelf and turn its pages.
## Each page can be read aloud. Nothing is tracked or scored; reading is the
## child's own.

var _books: Array = []
var _book: Dictionary = {}
var _page := 0


func show_shelf() -> void:
	_books = Content.get_world("library").get("books", [])
	open(640)
	_render_shelf()


func _render_shelf() -> void:
	_clear()
	content.add_child(UiStyle.label(tr("Choose a book"), "HeadingLabel"))
	for b: Dictionary in _books:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		content.add_child(row)
		var cover := ColorRect.new()
		cover.color = Palette.color(str(b.get("cover", "cloth_cream")))
		cover.custom_minimum_size = Vector2(40, 56)
		row.add_child(cover)
		var pick := UiStyle.button(tr(str(b.get("title", ""))))
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.pressed.connect(func() -> void: open_book(b))
		row.add_child(pick)
	var done := UiStyle.button(tr("Put the books back"), true)
	done.pressed.connect(close)
	add_buttons([done])


func open_book(book: Dictionary) -> void:
	_book = book
	_page = 0
	_render_page()


func page_count() -> int:
	return _book.get("pages", []).size()


func page() -> int:
	return _page


func turn(by: int) -> void:
	_page = clampi(_page + by, 0, page_count() - 1)
	_render_page()


func _render_page() -> void:
	_clear()
	content.add_child(UiStyle.label(tr(str(_book.get("title", ""))), "HeadingLabel"))
	var text := tr(str(_book["pages"][_page]))
	var words := UiStyle.label(text, "LetterLabel")
	words.custom_minimum_size = Vector2(0, 170)
	content.add_child(words)
	var foot := "%d / %d" % [_page + 1, page_count()]
	if _page == page_count() - 1 and not str(_book.get("source", "")).is_empty():
		foot += "    " + str(_book["source"])
	content.add_child(UiStyle.label(foot, "SmallLabel"))
	AudioService.narrate(text)
	var shelf := UiStyle.button(tr("Shelf"))
	shelf.pressed.connect(func() -> void:
		AudioService.stop_narration()
		_render_shelf())
	var read := UiStyle.button(tr("Read to me"))
	read.pressed.connect(func() -> void: AudioService.narrate(text, true))
	var back := UiStyle.button(tr("Back"))
	back.disabled = _page == 0
	back.pressed.connect(func() -> void: turn(-1))
	var last := _page == page_count() - 1
	var next := UiStyle.button(tr("The end") if last else tr("Turn the page"), true)
	next.pressed.connect(func() -> void:
		if last:
			_render_shelf()
		else:
			turn(1))
	add_buttons([shelf, read, back, next])


func _clear() -> void:
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
