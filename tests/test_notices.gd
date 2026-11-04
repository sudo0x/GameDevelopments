extends SceneTree
## Notices take turns on one line instead of replacing each other.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func seconds(hud: Node, time: float) -> void:
	# Runs the HUD's clock directly, so the test doesn't depend on frame timing.
	var steps := int(time * 60.0)
	for i in steps:
		hud._process(1.0 / 60.0)


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var hud: Node = main.get_node("HUD")
	hud.set_process(false)

	gs.notice.emit("A")
	check("shows at once when free", hud.latest_notice() == "A" and hud.notice_label.modulate.a == 1.0)
	gs.notice.emit("B")
	gs.notice.emit("C")
	check("later ones wait, A still showing", hud.latest_notice() == "A" and hud._waiting_notices == ["B", "C"])
	gs.notice.emit("B")
	check("a waiting one isn't queued twice", hud._waiting_notices == ["B", "C"])
	seconds(hud, 1.6)
	check("B gets its turn, quicker while others wait", hud.latest_notice() == "B")
	seconds(hud, 1.6)
	check("then C", hud.latest_notice() == "C" and hud._waiting_notices.is_empty())
	seconds(hud, 1.0)
	check("the last one stays up for its full time", hud.notice_label.modulate.a == 1.0)
	gs.notice.emit("C")
	check("repeating the one showing just keeps it up", hud._waiting_notices.is_empty() and hud.latest_notice() == "C")
	seconds(hud, 3.2)
	check("then fades", hud.notice_label.modulate.a < 0.05)

	# A burst never lags far behind: the oldest waiting ones are dropped.
	for i in 8:
		gs.notice.emit("burst %d" % i)
	check("at most 4 wait", hud._waiting_notices.size() == 4 and hud._waiting_notices[3] == "burst 7")
	check("the first of the burst shows", hud.latest_notice() == "burst 0")
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
