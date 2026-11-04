extends Node
## Plays every sound in the game, and keeps the volume settings.
## Game code asks for a sound by name, `Audio.play(&"harvest")`, and this finds the file:
## assets/audio/effects/<name>.wav (or .ogg) and assets/audio/music/<name>.ogg.
## A sound with no file yet plays nothing, so every sound can be wired before it exists.
## The full list, with what each one is for, is in docs/18_...

## Every effect the game asks for. A name not listed here is a mistake in the code.
const EFFECTS: Array[StringName] = [
	&"till", &"water", &"plant", &"harvest",
	&"cleanse", &"shrine", &"find",
	&"swing", &"hit", &"defeat", &"hurt",
	&"gather", &"place", &"pick_up", &"ship", &"buy", &"craft", &"sleep",
	&"click", &"menu_open", &"menu_close",
]
const MUSIC: Array[StringName] = [&"title", &"farm"]
## Used when a track has no file of its own yet.
const MUSIC_FALLBACK: Dictionary[StringName, StringName] = {&"title": &"farm"}

const EFFECTS_FOLDER := "res://assets/audio/effects/"
const MUSIC_FOLDER := "res://assets/audio/music/"
## Separate from the save, so New Game keeps your volume, and every farm shares it.
const SETTINGS_PATH := "user://settings.cfg"
## Effects that can play at once: more would only be noise.
const VOICES := 8
## Each effect plays a little higher or lower each time, so repeats don't sound robotic.
const PITCH_SPREAD := 0.08
const MUSIC_FADE_SECONDS := 1.0

## 0 to 1, saved in settings.cfg.
var music_volume := 0.8
var effects_volume := 0.8
## The last effect asked for, even with no file: lets tests check sounds are wired.
var last_requested: StringName
var current_music: StringName

var _effects: Dictionary[StringName, AudioStream] = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _music_player: AudioStreamPlayer
var _headless := DisplayServer.get_name() == "headless"


func _ready() -> void:
	# Menus pause the game, and their clicks must still play.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in EFFECTS:
		_effects[id] = _find(EFFECTS_FOLDER, id, ["wav", "ogg"])
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = &"Effects"
		add_child(voice)
		_voices.append(voice)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Music"
	add_child(_music_player)
	# Every button in the game clicks, without each menu having to ask.
	get_tree().node_added.connect(_on_node_added)
	load_settings()


func play(id: StringName) -> void:
	assert(EFFECTS.has(id), "Unknown sound: %s" % id)
	last_requested = id
	var stream: AudioStream = _effects.get(id)
	if not stream:
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	voice.stream = stream
	voice.pitch_scale = randf_range(1.0 - PITCH_SPREAD, 1.0 + PITCH_SPREAD)
	# With no window (the tests), nothing can be heard, and a test quitting mid-sound
	# leaves Godot's playback object behind as a leak error.
	if not _headless:
		voice.play()


## Fades to another track. Asking for the one already playing does nothing.
func play_music(id: StringName) -> void:
	assert(MUSIC.has(id), "Unknown music: %s" % id)
	var stream := _find(MUSIC_FOLDER, id, ["ogg"])
	if not stream and MUSIC_FALLBACK.has(id):
		id = MUSIC_FALLBACK[id]
		stream = _find(MUSIC_FOLDER, id, ["ogg"])
	if id == current_music:
		return
	current_music = id
	var tween := create_tween()
	if _music_player.playing:
		tween.tween_property(_music_player, "volume_db", -40.0, MUSIC_FADE_SECONDS / 2.0)
	tween.tween_callback(func() -> void:
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		if stream and not _headless:
			_music_player.play()
		else:
			_music_player.stop())


## Which sounds still have no file, for the sound list doc and for you.
func missing() -> Array[StringName]:
	var names: Array[StringName] = []
	for id in EFFECTS:
		if not _effects[id]:
			names.append(id)
	for id in MUSIC:
		if not _find(MUSIC_FOLDER, id, ["ogg"]):
			names.append(id)
	return names


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	save_settings()


func set_effects_volume(value: float) -> void:
	effects_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	save_settings()


func load_settings() -> void:
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) == OK:
		music_volume = clampf(file.get_value("audio", "music", music_volume), 0.0, 1.0)
		effects_volume = clampf(file.get_value("audio", "effects", effects_volume), 0.0, 1.0)
	_apply_volumes()


func save_settings() -> void:
	var file := ConfigFile.new()
	file.set_value("audio", "music", music_volume)
	file.set_value("audio", "effects", effects_volume)
	file.save(SETTINGS_PATH)


func _apply_volumes() -> void:
	_set_bus(&"Music", music_volume)
	_set_bus(&"Effects", effects_volume)


## Volume is felt on a curve, not a straight line, so 50% is converted to decibels.
func _set_bus(bus_name: StringName, volume: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_mute(bus, volume <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))


func _find(folder: String, id: StringName, extensions: Array[String]) -> AudioStream:
	for extension in extensions:
		var path := "%s%s.%s" % [folder, id, extension]
		if ResourceLoader.exists(path):
			return load(path)
	return null


func _on_node_added(node: Node) -> void:
	# A button moved to another parent is added again, so it may already click.
	var click := play.bind(&"click")
	if node is BaseButton and not (node as BaseButton).pressed.is_connected(click):
		(node as BaseButton).pressed.connect(click)
