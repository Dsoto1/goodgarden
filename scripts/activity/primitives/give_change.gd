extends ActivityStep
## Selling primitive: the child minds a stall. A customer buys something and
## pays with coins on the dish; the child counts the change back out of the
## cash box onto the counter and presses "Give change". Counting on from the
## price ("three... four, five") is the way in: younger children are paid
## with one 5-coin and give back 1-coins; older ones take bigger coins and
## give change in 1s, 2s and 5s.
##
## Control of error: the customer counts the change as they take it. Too
## little and they say what is still missing; too much and they hand it back.
##
## Honesty (optional, "mistaken_pay"): on the last sale the customer pays one
## coin too many by mistake. The child is asked to check what was paid;
## noticing and giving it back is thanked warmly, never scored.
##
## Config:
##   sales: [{"item": String, "price": int, "paid": [int], "icon"?: String}]
##   cash: [int]               coins in the cash box (default ten 1-coins)
##   mistaken_pay: bool        (default false)
## Feedback keys: "short", "too_much", "right", "honest", "all_good"; "{n}" and
## "{item}" are filled in.
## Result: {"sales": int, "honest": bool}

const DISH := Vector2(560, 150)
const COUNTER := Vector2(560, 330)
const CASH := Rect2(140, 420, 720, 110)

var sales: Array = []
var sale_index := -1
var cash: Array[DragPiece] = []
var counter: DropSlot
var honest := false
var _paid: Array[int] = []
var _awaiting_honesty := false


func _build() -> void:
	sales = config.get("sales", [{"item": "bun", "price": 3, "paid": [5]}])
	counter = DropSlot.create("coin_any", Vector2(260, 110))
	counter.capacity = 99
	counter.show_outline = false
	counter.set_center(COUNTER)
	add_child(counter)
	var box: Array = config.get("cash", [1, 1, 1, 1, 1, 1, 1, 1, 1, 1])
	for v: Variant in box:
		_add_coin(int(v))
	_lay_cash()
	for c in cash:
		c.position = c.home
	_next_sale()


func _add_coin(value: int) -> DragPiece:
	var c := DragPiece.create("coin:%d" % value, Vector2(54, 54) if value >= 5 else Vector2(46, 46), {"value": value})
	add_child(c)
	cash.append(c)
	c.dropped.connect(_on_dropped)
	c.grabbed.connect(_on_grabbed)
	c.tapped.connect(func(_p: DragPiece) -> void: AudioService.narrate(tr("one coin") if value == 1 else tr("a %d-coin") % value, true))
	return c


## Coins left in the cash box sit in a row, smallest first.
func _lay_cash() -> void:
	var loose: Array[DragPiece] = []
	for c in cash:
		if c.placed_in == null:
			loose.append(c)
	loose.sort_custom(func(a: DragPiece, b: DragPiece) -> bool: return int(a.data["value"]) < int(b.data["value"]))
	var gap := minf(60.0, (CASH.size.x - 40) / maxf(loose.size(), 1))
	for i in loose.size():
		loose[i].home = CASH.position + Vector2(24 + i * gap, (CASH.size.y - loose[i].size.y) / 2.0)
		if not loose[i].dragging:
			tween_to(loose[i], loose[i].home, 0.15)


func current() -> Dictionary:
	return sales[sale_index] if sale_index >= 0 and sale_index < sales.size() else {}


func price() -> int:
	return int(current().get("price", 0))


func paid() -> int:
	var n := 0
	for v in _paid:
		n += v
	return n


## What the child has counted out onto the counter.
func on_counter() -> int:
	var n := 0
	for c in counter.contents:
		n += int(c.data["value"])
	return n


func change_due() -> int:
	return paid() - price()


func _next_sale() -> void:
	sale_index += 1
	_paid.clear()
	queue_redraw()
	if sale_index >= sales.size():
		say("all_good", "Every customer has their change, counted right. Thank you for minding the stall!")
		AudioService.play("step")
		actions_changed.emit([])
		finish({"sales": sales.size(), "honest": honest})
		return
	for v: Variant in current().get("paid", [5]):
		_paid.append(int(v))
	var mistake: bool = sale_index == sales.size() - 1 and config.get("mistaken_pay", false)
	if mistake:
		# The customer gives one coin too many without noticing.
		_paid.append(1)
		_awaiting_honesty = true
		queue_redraw()
		prompt_changed.emit(tr("The %s costs %d. Before you give change, count what the customer gave you. Is it right?") % [tr(str(current()["item"])), price()])
		actions_changed.emit([
			{"label": tr("Yes, it's right"), "callback": func() -> void: _check_paid(false)},
			{"label": tr("That's one too many"), "callback": func() -> void: _check_paid(true)},
		])
		return
	_ask_for_change()


func _ask_for_change() -> void:
	var item := tr(str(current()["item"]))
	prompt_changed.emit(tr(str(config.get("prompt", "The {item} costs {price}. The customer gave you {paid}. Count the change onto the counter, then press Give change."))).replace("{item}", item).replace("{price}", str(price())).replace("{paid}", str(paid())))
	AudioService.narrate(tr("The %s costs %d. Here is %d.") % [item, price(), paid()])
	actions_changed.emit([{"label": tr("Give change"), "primary": true, "icon": "yes", "callback": give_change}])


func _check_paid(said_too_many: bool) -> void:
	_awaiting_honesty = false
	_paid.pop_back()
	queue_redraw()
	if said_too_many:
		honest = true
		say("honest", "Oh, I gave you one too many! Thank you for telling me. That's honest of you.")
	else:
		say("count_again", "Let's count it together... one too many! Let's give that one back.")
	actions_changed.emit([])
	await get_tree().create_timer(2.4).timeout
	if is_inside_tree():
		_ask_for_change()


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		(p.placed_in as DropSlot).take(p)


func _on_dropped(p: DragPiece) -> void:
	if counter.near(p.center(), snap_tolerance * 0.6):
		counter.put(p)
		AudioService.play("place")
		_lay_counter()
		AudioService.narrate(str(price() + on_counter()))
	else:
		_lay_cash()
		tween_to(p, p.home)
	queue_redraw()


func _lay_counter() -> void:
	for i in counter.contents.size():
		var c := counter.contents[i]
		tween_to(c, COUNTER + Vector2(-100 + (i % 7) * 32, -16 + (i / 7) * 30) - c.size / 2.0, 0.12)


## The "Give change" button: the customer counts it as they take it.
func give_change() -> void:
	if is_done or _awaiting_honesty:
		return
	var given := on_counter()
	var due := change_due()
	if given < due:
		observed.emit("short_change", {"step": config.get("id", "")})
		say_fill("short", "Let's count on from {price}... That's not quite enough. I need {n} more.", due - given)
		return
	if given > due:
		observed.emit("too_much_change", {"step": config.get("id", "")})
		say_fill("too_much", "That's too much! I only need {n} back. Here, you keep the rest.", due)
		for c in counter.contents.duplicate():
			counter.take(c)
		_lay_cash()
		return
	# Right: the change goes to the customer, the payment into the cash box.
	for c in counter.contents.duplicate():
		counter.take(c)
		cash.erase(c)
		c.queue_free()
	for v in _paid:
		_add_coin(v).position = DISH
	_paid.clear()
	_lay_cash()
	say_fill("right", "{n} back. That's just right, thank you!", due)
	AudioService.play("step")
	actions_changed.emit([])
	await get_tree().create_timer(1.6).timeout
	if is_inside_tree():
		_next_sale()


func say_fill(key: String, fallback: String, n: int) -> void:
	prompt_changed.emit(tr(str(config.get("feedback", {}).get(key, fallback))).replace("{n}", str(n)).replace("{price}", str(price())).replace("{item}", tr(str(current().get("item", "")))))


func reset_step() -> void:
	for c in counter.contents.duplicate():
		counter.take(c)
	_lay_cash()


func show_hint() -> void:
	# Count on from the price to what was paid, one coin at a time.
	var words: Array[String] = [str(price())]
	for k in range(price() + 1, paid() + 1):
		words.append(str(k))
	prompt_changed.emit(tr("Count on from the price: %s. That's %d coins back.") % [", ".join(words), change_due()])


func supports_hint() -> bool:
	return true


func _draw() -> void:
	# The stall counter, the item and its price, the customer's dish.
	BoardArt._fill(self, BoardArt._round_rect(Rect2(40, 40, 300, 280), 14), Color("c79a62"))
	BoardArt.wood_box(self, CASH)
	BoardArt.bowl(self, DISH, 90, Color("e9dcc0"))
	BoardArt._fill(self, BoardArt._round_rect(Rect2(COUNTER - Vector2(150, 70), Vector2(300, 140)), 12), Color("e2c99a"))
	var font := UiStyle.font()
	draw_string(font, Vector2(COUNTER.x - 150, COUNTER.y - 44), tr("change"), HORIZONTAL_ALIGNMENT_CENTER, 300, 22, Color("7a4a26"))
	draw_string(font, Vector2(DISH.x + 100, DISH.y + 8), tr("the customer paid"), HORIZONTAL_ALIGNMENT_LEFT, 240, 22, Color("3b3430"))
	var item := current()
	if item.is_empty():
		return
	Icon.draw(self, str(item.get("icon", item["item"])), Rect2(70, 60, 150, 150))
	var tag := Rect2(230, 90, 90, 90)
	draw_rect(tag, Color("fbf5e8"))
	draw_rect(tag, Color("8a5a3a"), false, 2.0)
	draw_string(font, Vector2(tag.position.x, tag.position.y + 52), str(price()), HORIZONTAL_ALIGNMENT_CENTER, tag.size.x, 44, Color("3b3430"))
	for k in price():
		draw_circle(Vector2(tag.position.x + 14 + (k % 5) * 15, tag.position.y + 66 + (k / 5) * 12), 4, Color("b8392f"))
	draw_string(font, Vector2(40, 290), tr(str(item["item"])), HORIZONTAL_ALIGNMENT_CENTER, 300, 28, Color("3b3430"))
	# The customer's coins on the dish, drawn (they aren't the child's to move).
	for i in _paid.size():
		var v := _paid[i]
		var r := 27.0 if v >= 5 else 23.0
		var at := DISH + Vector2(-(_paid.size() - 1) * 28 + i * 56, 0)
		var metal: Color = {1: Color("c98a4e"), 2: Color("c9ccd1")}.get(v, Color("e0b64c"))
		draw_circle(at, r, metal)
		draw_arc(at, r * 0.78, 0, TAU, 20, metal.darkened(0.25), 2.0)
		draw_string(font, at + Vector2(-r, r * 0.35), str(v), HORIZONTAL_ALIGNMENT_CENTER, r * 2, int(r), metal.darkened(0.55))
