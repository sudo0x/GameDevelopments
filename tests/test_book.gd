extends SceneTree
## The old book: it opens from the bag or key B, pages appear as land heals and stay when the
## curse takes it back, and every page fits a phone.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func wait(frames: int) -> void:
	for i in frames:
		await process_frame


func press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await process_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	Input.flush_buffered_events()
	await process_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var progress: Node = root.get_node("Progress")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await wait(4)
	var hud: Node = main.get_node("HUD")
	var controls: Node = main.get_node("HUD/TouchControls")
	var book: Control = main.get_node("HUD/BookMenu")
	var bag: Control = main.get_node("HUD/BagMenu")
	var pages: Array = load("res://scripts/ui/book_pages.gd").PAGES

	check("a new game starts with 3 pages", progress.book_pages == 3)

	# Key B.
	await press("book")
	check("B opens the book", book.visible and paused)
	check("it opens on the newest page", book.page == 2)
	check("no page past the last found", book._next.disabled)
	await press("ui_left")
	check("Left turns back", book.page == 1 and book._title.text == pages[1][1])
	check("keyboard text names the key", book._text.text.contains("use R"))
	await press("ui_right")
	await press("ui_right")
	check("Right stops at the last found page", book.page == 2)
	await press("book")
	check("B closes it", not book.visible and not paused)
	await wait(2)

	# From the bag.
	await press("inventory")
	check("the bag offers the book", bag.book_button.visible)
	bag.book_button.pressed.emit()
	await wait(2)
	check("Book swaps the bag for the book", book.visible and not bag.visible and paused)
	await press("ui_cancel")
	check("Esc closes it", not book.visible and not paused)
	await wait(2)

	# Healing reveals pages, once, and they stay.
	var notices: Array[String] = []
	gs.notice.connect(func(text: String) -> void: notices.append(text))
	progress.set_healed_percent(0.5)
	check("a little healing reveals nothing", progress.book_pages == 3 and notices.is_empty())
	progress.set_healed_percent(1.0)
	check("healing reveals a page", progress.book_pages == 4)
	check("it says so", notices.size() == 1 and notices[0].contains("old book"))
	progress.set_healed_percent(1.5)
	check("it only says so once", notices.size() == 1)
	progress.set_healed_percent(0.0)
	check("the curse can't take a page back", progress.book_pages == 4)
	progress.set_healed_percent(100.0)
	check("all pages can be found", progress.book_pages == pages.size())

	var last := -1.0
	var ordered := true
	for entry: Array in pages:
		ordered = ordered and entry[0] >= last
		last = entry[0]
	check("pages are in order", ordered)

	# Every page fits a phone, and clears the buttons left showing.
	controls.set_active(true)
	await wait(2)
	book.open()
	await wait(3)
	var fits := true
	var keys := true
	for i in pages.size():
		book.page = i
		book._refresh()
		await wait(3)
		var rect: Rect2 = book.get_global_rect()
		var ok: bool = rect.size.y <= 360.0 and rect.position.y >= 0.0 and rect.end.x <= 501.0
		if not ok:
			print("page ", i, " is too big: ", rect)
		fits = fits and ok
		for word: String in ["Space", "{", "press "]:
			keys = keys and not book._text.text.contains(word)
	check("every page fits", fits)
	check("phone pages name no keys", keys)
	book.page = 1
	book._refresh()
	check("phone text names the big button", book._text.text.contains("the big button"))
	book.close()

	print("ALL PASS" if fails == 0 else "%d FAILED" % fails)
	quit(fails)
