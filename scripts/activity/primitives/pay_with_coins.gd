extends ActivityStep
## Money primitive: buying at a stall. Each thing to buy sits on the counter
## with its price; the child counts coins from their purse onto the dish and
## presses Pay. Younger children have only 1-coins and count them out one by
## one; older children have 1-, 2- and 5-coins, may pay with more and count
## the change they get back.
##
## Control of error: Pay with too little and the shopkeeper says what is
## still needed; too much and the change comes back, counted aloud.
##
## Honesty (optional, "mistaken_change"): on the last purchase the shopkeeper
## gives back one coin too many, and asks the child to check. Saying so is
## thanked warmly; it is a moment to practise honesty, never scored.
##
## Config:
##   buy: [{"item": String, "price": int, "icon"?: String}]
##   purse: [int]            coin values in the purse (default enough 1s)
##   mistaken_change: bool   (default false)
## Feedback keys: "short", "change", "paid", "honest", "all_good"; "{n}" and
## "{item}" are filled in.
## Result: {"bought": [String], "spent": int, "honest": bool}

const DISH := Vector2(500, 250)
const PURSE := Rect2(140, 400, 720, 120)

var buy: Array = []
var buy_index := -1
var coins: Array[DragPiece] = []
var dish: DropSlot
var spent := 0
var bought: Array[String] = []
var honest := false
var _awaiting_honesty := false


func _build() -> void:
	buy = config.get("buy", [{"item": "bun", "price": 3}])
	dish = DropSlot.create("coin_any", Vector2(200, 120))
	dish.capacity = 99
	dish.show_outline = false
	dish.set_center(DISH)
	add_child(dish)
	var purse: Array = config.get("purse", [])
	if purse.is_empty():
		var total := 0
		for b: Dictionary in buy:
			total += int(b["price"])
		for i in total + 2:
			purse.append(1)
	for v: Variant in purse:
		_add_coin(int(v))
	_next_item()


func _add_coin(value: int) -> DragPiece:
	var c := DragPiece.create("coin:%d" % value, Vector2(54, 54) if value >= 5 else Vector2(46, 46), {"value": value})
	add_child(c)
	coins.append(c)
	c.dropped.connect(_on_dropped)
	c.grabbed.connect(_on_grabbed)
	c.tapped.connect(func(_p: DragPiece) -> void: AudioService.narrate(_coin_name(value), true))
	_lay_purse()
	c.position = c.home
	return c


func _coin_name(value: int) -> String:
	return tr("one coin") if value == 1 else tr("a %d-coin") % value


## Coins in the purse sit in a neat row (left to right, smallest first).
func _lay_purse() -> void:
	var loose: Array[DragPiece] = []
	for c in coins:
		if c.placed_in == null and c.draggable:
			loose.append(c)
	loose.sort_custom(func(a: DragPiece, b: DragPiece) -> bool: return int(a.data["value"]) < int(b.data["value"]))
	var gap := minf(62.0, (PURSE.size.x - 40) / maxf(loose.size(), 1))
	for i in loose.size():
		loose[i].home = PURSE.position + Vector2(24 + i * gap, (PURSE.size.y - loose[i].size.y) / 2.0)
		if not loose[i].dragging:
			tween_to(loose[i], loose[i].home, 0.15)


func current() -> Dictionary:
	return buy[buy_index] if buy_index >= 0 and buy_index < buy.size() else {}


func price() -> int:
	return int(current().get("price", 0))


func on_dish() -> int:
	var n := 0
	for c in dish.contents:
		n += int(c.data["value"])
	return n


func _next_item() -> void:
	buy_index += 1
	queue_redraw()
	if buy_index >= buy.size():
		say("all_good", "You bought everything, and counted every coin.")
		AudioService.play("step")
		actions_changed.emit([])
		finish({"bought": bought.duplicate(), "spent": spent, "honest": honest})
		return
	var item := str(current()["item"])
	prompt_changed.emit(tr(str(config.get("prompt", "The {item} costs {n}. Put that many coins on the dish, then press Pay."))).replace("{item}", tr(item)).replace("{n}", str(price())))
	AudioService.narrate(tr("The %s costs %d.") % [tr(item), price()])
	actions_changed.emit([{"label": tr("Pay"), "primary": true, "icon": "yes", "callback": pay}])


func _on_grabbed(p: DragPiece) -> void:
	if p.placed_in is DropSlot:
		(p.placed_in as DropSlot).take(p)
	queue_redraw()


func _on_dropped(p: DragPiece) -> void:
	if dish.near(p.center(), snap_tolerance * 0.6):
		dish.put(p)
		AudioService.play("place")
		_lay_dish()
		AudioService.narrate(str(on_dish()))
	else:
		_lay_purse()
		tween_to(p, p.home)
	queue_redraw()


func _lay_dish() -> void:
	for i in dish.contents.size():
		var c := dish.contents[i]
		var spot := DISH + Vector2(-70 + (i % 6) * 28, -18 + (i / 6) * 26)
		tween_to(c, spot - c.size / 2.0, 0.12)


## The Pay button.
func pay() -> void:
	if is_done or _awaiting_honesty:
		return
	var given := on_dish()
	if given < price():
		observed.emit("short_payment", {"step": config.get("id", "")})
		say_fill("short", "That's {n} so far. The {item} costs more: count again and add some.", given)
		return
	var change := given - price()
	spent += price()
	bought.append(str(current()["item"]))
	# The coins are the shopkeeper's now.
	for c in dish.contents.duplicate():
		dish.take(c)
		coins.erase(c)
		c.queue_free()
	var last := buy_index == buy.size() - 1
	var mistake: bool = last and config.get("mistaken_change", false)
	var back := change + (1 if mistake else 0)
	_give_change(back)
	AudioService.play("step")
	if mistake:
		_awaiting_honesty = true
		prompt_changed.emit(tr("Here is your change. Can you count it? Is it right?"))
		actions_changed.emit([
			{"label": tr("Yes, it's right"), "callback": func() -> void: _check_change(false)},
			{"label": tr("That's one too many"), "callback": func() -> void: _check_change(true)},
		])
		return
	if change > 0:
		say_fill("change", "Thank you! That's {n} too many, so here are {n} back.", change)
	else:
		say_fill("paid", "Exactly right. Here is your {item}. Thank you!", 0)
	await get_tree().create_timer(1.6).timeout
	if is_inside_tree():
		_next_item()


## Change comes back as coins, largest first.
func _give_change(amount: int) -> void:
	var left := amount
	for v: int in [5, 2, 1]:
		while left >= v:
			left -= v
			var c := _add_coin(v)
			c.position = DISH - c.size / 2.0
			tween_to(c, c.home, 0.35)


func _check_change(said_too_many: bool) -> void:
	_awaiting_honesty = false
	if said_too_many:
		honest = true
		# The extra coin goes back to the shopkeeper.
		for c in coins:
			if int(c.data["value"]) == 1 and c.placed_in == null:
				coins.erase(c)
				c.queue_free()
				break
		_lay_purse()
		say("honest", "Oh! You're right, I gave you one too many. Thank you for telling me. That's honest of you.")
	else:
		say("count_again", "Let's count it together. One too many! Thank you, I'll take that one back.")
	await get_tree().create_timer(2.4).timeout
	if is_inside_tree():
		_next_item()


func say_fill(key: String, fallback: String, n: int) -> void:
	prompt_changed.emit(tr(str(config.get("feedback", {}).get(key, fallback))).replace("{n}", str(n)).replace("{item}", tr(str(current().get("item", "")))))


func reset_step() -> void:
	for c in dish.contents.duplicate():
		dish.take(c)
	_lay_purse()
	queue_redraw()


func show_hint() -> void:
	var need := price() - on_dish()
	if need > 0:
		prompt_changed.emit(tr("The %s costs %d. You have %d on the dish. Put %d more.") % [tr(str(current()["item"])), price(), on_dish(), need])
	else:
		prompt_changed.emit(tr("That's enough. Press Pay."))


func supports_hint() -> bool:
	return true


func _draw() -> void:
	# The counter, the item with its price tag, and the dish.
	BoardArt._fill(self, BoardArt._round_rect(Rect2(60, 70, 300, 230), 14), Color("c79a62"))
	BoardArt.wood_box(self, PURSE)
	BoardArt.bowl(self, DISH, 100, Color("e9dcc0"))
	var item := current()
	if item.is_empty():
		return
	Icon.draw(self, str(item.get("icon", item["item"])), Rect2(90, 90, 150, 150))
	var tag := Rect2(250, 120, 90, 90)
	draw_rect(tag, Color("fbf5e8"))
	draw_rect(tag, Color("8a5a3a"), false, 2.0)
	draw_string(UiStyle.font(), Vector2(tag.position.x, tag.position.y + 52), str(price()), HORIZONTAL_ALIGNMENT_CENTER, tag.size.x, 44, Color("3b3430"))
	# Dots under the number: count them if the numeral is new.
	for k in price():
		draw_circle(Vector2(tag.position.x + 14 + (k % 5) * 15, tag.position.y + 66 + (k / 5) * 12), 4, Color("b8392f"))
	draw_string(UiStyle.font(), Vector2(60, 290), tr(str(item["item"])), HORIZONTAL_ALIGNMENT_CENTER, 300, 28, Color("3b3430"))
