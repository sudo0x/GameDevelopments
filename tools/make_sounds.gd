extends SceneTree
## Makes every sound effect from scratch with math, like the free tool sfxr, and saves them as
## WAV files in assets/audio/effects/. Nothing is downloaded, so there's no license to worry about.
##
## Usage:
##   godot --headless --path <project> --script tools/make_sounds.gd
##   then run --import so Godot picks up the new files.
##
## A sound is a list of numbers telling the speaker how to move, RATE of them per second.
## Each recipe below adds "layers" into that list: a wave (sine, square, triangle or noise)
## that slides from one pitch to another, fades in quickly and fades out.
## To change a sound, edit its recipe and run this again. To replace one with a better file,
## just save that file over it (and delete its recipe, so this doesn't overwrite it).

const RATE := 22050
const FOLDER := "res://assets/audio/effects/"

## A few musical notes, in Hz, so chords are in tune.
const C4 := 261.6
const E4 := 329.6
const G4 := 392.0
const A4 := 440.0
const C5 := 523.3
const E5 := 659.3
const G5 := 784.0
const B5 := 987.8
const C6 := 1046.5
const E6 := 1318.5

var _samples := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FOLDER))
	for recipe in get_method_list():
		var method: String = recipe["name"]
		if method.begins_with("sound_"):
			_make(method.trim_prefix("sound_"), Callable(self, method))
	quit()


# --- Farming ---------------------------------------------------------------

## A soft dig into earth: a crunch of noise over a low thump.
func sound_till() -> float:
	layer(0.0, 0.12, 2000, 700, "noise", 0.5)
	layer(0.0, 0.10, 120, 70, "sine", 0.5)
	return 0.6


## A pour: a hiss with three little bubbles.
func sound_water() -> float:
	layer(0.0, 0.30, 5000, 3000, "noise", 0.18, 0.04)
	for i in 3:
		layer(0.04 + i * 0.07, 0.05, 700 + i * 120, 1100 + i * 150, "sine", 0.35)
	return 0.5


## A small pat of soil.
func sound_plant() -> float:
	layer(0.0, 0.08, 320, 200, "sine", 0.5)
	layer(0.0, 0.05, 900, 500, "noise", 0.25)
	return 0.5


## A rewarding pop, then a bright little note.
func sound_harvest() -> float:
	layer(0.0, 0.07, 400, 1000, "sine", 0.6)
	layer(0.06, 0.10, C6, C6, "square", 0.15)
	return 0.6


# --- Healing ---------------------------------------------------------------

## The most important sound: three soft tones rising together, with sparkles fading out.
func sound_cleanse() -> float:
	layer(0.0, 0.9, C5, E5, "sine", 0.35, 0.05, 1.5)
	layer(0.0, 0.9, E5, G5, "sine", 0.3, 0.05, 1.5)
	layer(0.0, 0.9, G5, C6, "sine", 0.25, 0.05, 1.5)
	_sparkles(0.1, 0.8, 8, 0.12)
	return 0.75


## The shrine: a big slow chord, then the same chord an octave up, ringing out.
func sound_shrine() -> float:
	for note in [C4, E4, G4, C5]:
		layer(0.0, 2.2, note, note, "sine", 0.22, 0.25, 1.2)
	for note in [C5, E5, G5, C6]:
		layer(0.6, 1.8, note, note, "sine", 0.16, 0.2, 1.5)
	_sparkles(0.6, 2.0, 14, 0.1)
	return 0.8


## A sparkly three-note chime, for digging something up.
func sound_find() -> float:
	var notes := [G5, B5, E6]
	for i in notes.size():
		layer(i * 0.08, 0.35, notes[i], notes[i], "triangle", 0.4, 0.002, 2.0)
	return 0.65


# --- Combat ----------------------------------------------------------------

## A quick whoosh.
func sound_swing() -> float:
	layer(0.0, 0.16, 3500, 700, "noise", 0.45, 0.04)
	return 0.5


## A dull thud.
func sound_hit() -> float:
	layer(0.0, 0.10, 1500, 300, "noise", 0.45)
	layer(0.0, 0.12, 160, 60, "sine", 0.7)
	return 0.7


## The shadow breaking apart: a falling hiss and a sinking tone.
func sound_defeat() -> float:
	layer(0.0, 0.55, 3000, 200, "noise", 0.35, 0.01, 1.2)
	layer(0.0, 0.50, 420, 80, "sine", 0.4, 0.01, 1.2)
	return 0.65


## A low, falling buzz.
func sound_hurt() -> float:
	layer(0.0, 0.22, 320, 120, "square", 0.3)
	layer(0.0, 0.08, 1200, 400, "noise", 0.3)
	return 0.6


# --- World -----------------------------------------------------------------

## A chop or chip on wood or stone.
func sound_gather() -> float:
	layer(0.0, 0.05, 2200, 1200, "noise", 0.45)
	layer(0.0, 0.09, 190, 110, "sine", 0.6)
	return 0.6


## A wooden thunk.
func sound_place() -> float:
	layer(0.0, 0.14, 150, 80, "sine", 0.7)
	layer(0.0, 0.05, 700, 400, "noise", 0.3)
	return 0.65


## A lighter lift, going up.
func sound_pick_up() -> float:
	layer(0.0, 0.10, 300, 650, "sine", 0.5)
	layer(0.06, 0.06, 650, 650, "triangle", 0.2)
	return 0.55


## A lid closing, then two coins.
func sound_ship() -> float:
	layer(0.0, 0.10, 130, 80, "sine", 0.6)
	layer(0.0, 0.04, 900, 500, "noise", 0.25)
	layer(0.10, 0.08, B5, B5, "square", 0.15)
	layer(0.16, 0.22, E6, E6, "square", 0.15, 0.002, 2.0)
	return 0.6


## Coins: "ding-ding".
func sound_buy() -> float:
	layer(0.0, 0.07, B5, B5, "square", 0.2)
	layer(0.06, 0.25, E6, E6, "square", 0.2, 0.002, 2.0)
	return 0.55


## Two hammer taps.
func sound_craft() -> float:
	for i in 2:
		layer(i * 0.16, 0.05, 2600, 1800, "noise", 0.35)
		layer(i * 0.16, 0.08, 230, 150, "sine", 0.55)
	return 0.6


## A calm, falling pair of notes, like settling down for the night.
func sound_sleep() -> float:
	layer(0.0, 0.5, A4, A4, "sine", 0.35, 0.05, 1.5)
	layer(0.3, 0.9, E4, E4, "sine", 0.35, 0.05, 1.5)
	return 0.5


# --- Menus -----------------------------------------------------------------

## A tiny tick.
func sound_click() -> float:
	layer(0.0, 0.025, 1300, 1100, "square", 0.25)
	return 0.3


func sound_menu_open() -> float:
	layer(0.0, 0.09, 380, 720, "sine", 0.4)
	layer(0.0, 0.04, 3000, 2000, "noise", 0.08)
	return 0.4


func sound_menu_close() -> float:
	layer(0.0, 0.09, 720, 380, "sine", 0.4)
	layer(0.0, 0.04, 2000, 3000, "noise", 0.08)
	return 0.4


# --- The synthesizer -------------------------------------------------------

## Adds one wave into the sound. It starts at `start` seconds, lasts `length`, slides from
## `from_hz` to `to_hz`, fades in over `attack` seconds, then fades out; a higher `curve`
## fades out faster at first, which sounds more like ringing.
func layer(start: float, length: float, from_hz: float, to_hz: float, wave: String, volume: float, attack: float = 0.004, curve: float = 1.0) -> void:
	var first := int(start * RATE)
	var count := int(length * RATE)
	if _samples.size() < first + count:
		_samples.resize(first + count)
	var phase := 0.0
	var held := 0.0
	for i in count:
		var t := float(i) / count
		var hz := lerpf(from_hz, to_hz, t)
		var before := phase
		phase = fmod(phase + hz / RATE, 1.0)
		var value := 0.0
		match wave:
			"sine":
				value = sin(TAU * phase)
			"square":
				value = 1.0 if phase < 0.5 else -1.0
			"triangle":
				value = 4.0 * absf(phase - 0.5) - 1.0
			"noise":
				# A new random value once per cycle: low pitches rumble, high ones hiss.
				if phase < before:
					held = _rng.randf_range(-1.0, 1.0)
				value = held
		var seconds := float(i) / RATE
		var envelope := minf(seconds / attack, 1.0) * pow(1.0 - t, curve)
		_samples[first + i] += value * envelope * volume


## Short, high, random twinkles between `from` and `to` seconds.
func _sparkles(from: float, to: float, count: int, volume: float) -> void:
	for i in count:
		var at := lerpf(from, to, float(i) / count) + _rng.randf_range(0.0, 0.05)
		var hz := _rng.randf_range(1800.0, 3200.0)
		layer(at, 0.08, hz, hz * 1.05, "sine", volume * lerpf(1.0, 0.4, float(i) / count))


func _make(sound_name: String, recipe: Callable) -> void:
	_samples = PackedFloat32Array()
	# Seeded by name, so running this again makes exactly the same sounds.
	_rng.seed = hash(sound_name)
	var peak_wanted: float = recipe.call()
	var peak := 0.0
	for value in _samples:
		peak = maxf(peak, absf(value))
	var gain := peak_wanted / peak if peak > 0.0 else 1.0
	var bytes := PackedByteArray()
	bytes.resize(_samples.size() * 2)
	for i in _samples.size():
		bytes.encode_s16(i * 2, int(clampf(_samples[i] * gain, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	var path := FOLDER + sound_name + ".wav"
	stream.save_to_wav(ProjectSettings.globalize_path(path))
	print("saved %s (%.2f s)" % [path, float(_samples.size()) / RATE])
