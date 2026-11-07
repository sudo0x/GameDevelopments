extends SceneTree
## Sound: volume channels, settings saved apart from the farm, sounds wired to actions,
## and the settings menu on the title screen. No sound files exist yet, so it checks what
## was asked for (Audio.last_requested), not what was heard.
var fails := 0


func check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		fails += 1


func press(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await physics_frame
	var r := InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)
	Input.flush_buffered_events()
	await physics_frame


func _initialize() -> void:
	_run()


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var audio: Node = root.get_node("Audio")
	await process_frame
	for bus in ["Music", "Effects"]:
		check(bus + " channel exists", AudioServer.get_bus_index(bus) > 0)
	var missing: Array = audio.missing()
	print("sounds with no file yet: ", missing.size())
	check("missing list only names real sounds", missing.all(func(id: StringName) -> bool: return audio.EFFECTS.has(id) or audio.MUSIC.has(id)))
	# A sound with a file plays on the Effects channel. A tiny made-up sound stands in for one.
	var beep := AudioStreamWAV.new()
	beep.data = PackedByteArray([0, 0, 0, 0])
	audio._effects[&"harvest"] = beep
	audio.play(&"harvest")
	var playing: Array = audio._voices.filter(func(v: AudioStreamPlayer) -> bool: return v.stream == beep)
	check("a sound with a file plays on Effects", playing.size() == 1 and playing[0].bus == &"Effects")
	audio._effects[&"harvest"] = null

	# Volume: saved in its own file, and New Game doesn't reset it.
	audio.set_music_volume(0.5)
	var music_bus := AudioServer.get_bus_index("Music")
	check("half volume is about -6 dB", absf(AudioServer.get_bus_volume_db(music_bus) + 6.02) < 0.1)
	audio.set_effects_volume(0.0)
	check("0 mutes", AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")))
	check("settings file written", FileAccess.file_exists("user://settings.cfg"))
	audio.music_volume = 1.0
	audio.load_settings()
	check("settings load back", is_equal_approx(audio.music_volume, 0.5) and audio.effects_volume == 0.0)
	gs.start_new_game()
	gs.show_story = false
	check("New Game keeps the volume", is_equal_approx(audio.music_volume, 0.5))
	audio.set_effects_volume(0.8)

	# Title: music, and the settings menu.
	var title: Node = load("res://scenes/ui/title_screen.tscn").instantiate()
	root.add_child(title)
	await process_frame
	var has_title: bool = not audio._music_versions(&"title").is_empty()
	check("title plays its own music, or farm until it exists", audio.current_music == (&"title" if has_title else &"farm"))
	# Every version of farm plays in turn, and with several, none loops on its own.
	audio.play_music(&"farm")
	var tracks: Array = audio._playlist
	print("farm versions: ", tracks.size())
	if tracks.size() > 1:
		check("versions don't loop alone", tracks.all(func(s: AudioStream) -> bool: return not s.get("loop")))
		var first: AudioStream = audio.current_track()
		audio._on_music_finished()
		check("the next version follows", audio.current_track() != first)
		for i in tracks.size() - 1:
			audio._on_music_finished()
		check("and it wraps around", audio.current_track() == first)
	elif tracks.size() == 1:
		check("a single version loops", tracks[0].get("loop"))
	var menu: Node = title.get_node("SettingsMenu")
	title.get_node("Center/Box/Settings").pressed.emit()
	await process_frame
	check("settings open", menu.visible and not title.get_node("Center").visible)
	check("buttons click", audio.last_requested == &"click")
	check("shows the volume", menu._music_value.text == "50%" and menu._effects_value.text == "80%")
	menu.find_child("MusicUp", true, false).pressed.emit()
	check("+ raises music", is_equal_approx(audio.music_volume, 0.6) and menu._music_value.text == "60%")
	for i in 8:
		menu.find_child("EffectsDown", true, false).pressed.emit()
	check("- stops at Off", audio.effects_volume == 0.0 and menu._effects_value.text == "Off")
	for i in 12:
		menu.find_child("EffectsUp", true, false).pressed.emit()
	check("+ stops at 100%", is_equal_approx(audio.effects_volume, 1.0) and menu._effects_value.text == "100%")
	await press("ui_cancel")
	check("Esc closes it", not menu.visible and title.get_node("Center").visible)
	title.queue_free()
	await process_frame

	# In the game: each action asks for its sound.
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var farm: Node = main.get_node("Farm")
	var player: Node = main.get_node("World/Player")
	player.global_position = farm.ground.to_global(farm.ground.map_to_local(Vector2i(18, 12)))
	for i in 5:
		await physics_frame
	var steps := [["tool_1", "till"], ["tool_2", "water"], ["tool_3", "plant"]]
	for step: Array in steps:
		await press(step[0])
		await press("use_tool")
		check(step[1] + " sound", audio.last_requested == StringName(step[1]))
	gs.holy_water = 1
	farm.healing.cleanse(Vector2i(38, 13))
	check("cleanse sound", audio.last_requested == &"cleanse")
	gs.request_shop()
	await process_frame
	check("menu opens with a sound", audio.last_requested == &"menu_open")
	gs.money = 100
	var shop: Node = main.find_child("ShopMenu", true, false)
	shop._buttons[0].pressed.emit()
	check("buying", audio.last_requested == &"buy" and gs.seed_count(gs.CROPS[0]) > 0)
	shop.close()
	check("menu closes with a sound", audio.last_requested == &"menu_close")
	main.get_node("World/ShippingBox/Interact").interact(player)
	check("shipping", audio.last_requested == &"ship")
	player.hurt(1, Vector2.LEFT)
	check("getting hurt", audio.last_requested == &"hurt")
	print("FAILS: %d" % fails)
	quit(1 if fails > 0 else 0)
