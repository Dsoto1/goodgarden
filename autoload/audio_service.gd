extends Node
## AudioService: ambience, gentle interface sounds, footsteps, sounds placed
## in the world, and read-aloud narration.
##
## Recorded sounds (CC0, see assets/third_party/audio/) are used where they
## exist; anything else is synthesized at runtime, so a missing file is never
## silent. Ambience crossfades between places; the Chapel keeps its own quiet
## synthesized pad so it is aurally distinct from task gameplay. Narration uses
## the platform text-to-speech voice when read-aloud is on; captions always show.

signal narration_unavailable

const MIX_RATE := 22050
const BUSES := ["Ambience", "Effects", "Voice"]
const AUDIO_DIR := "res://assets/third_party/audio/"
## Recorded sounds by name. A name with several files picks one at random each
## time, so repeated sounds (placing pieces, footsteps) don't sound mechanical.
const FILES := {
	"place": ["kenney/place_1", "kenney/place_2", "kenney/place_3", "kenney/place_4", "kenney/place_5"],
	"return": ["kenney/return"],
	"step": ["kenney/step_done"],
	"page": ["freesound/page_1", "freesound/page_2"],
	"outdoor": ["freesound/amb_meadow"],
	"interior": ["freesound/amb_stove"],
	"foot_grass": ["kenney/foot_grass_1", "kenney/foot_grass_2", "kenney/foot_grass_3", "kenney/foot_grass_4", "kenney/foot_grass_5"],
	"foot_wood": ["kenney/foot_wood_1", "kenney/foot_wood_2", "kenney/foot_wood_3", "kenney/foot_wood_4", "kenney/foot_wood_5"],
	"foot_stone": ["kenney/foot_stone_1", "kenney/foot_stone_2", "kenney/foot_stone_3", "kenney/foot_stone_4", "kenney/foot_stone_5"],
	"river": ["freesound/loop_river"],
	"waterfall": ["freesound/loop_waterfall"],
	"fountain": ["freesound/loop_fountain"],
	"sheep": ["freesound/sheep_1", "freesound/sheep_2", "freesound/sheep_3", "freesound/sheep_4"],
	"hens": ["freesound/hen_1", "freesound/hen_2"],
}
## How loud each recorded sound plays (dB), so they sit gently together.
const LEVELS := {"place": -6.0, "return": -9.0, "step": -8.0, "page": -6.0, "foot_grass": -17.0, "foot_wood": -15.0, "foot_stone": -18.0}
## Looping sounds, so their streams repeat seamlessly.
const LOOPS := ["outdoor", "interior", "river", "waterfall", "fountain"]

var _ambience_players: Array[AudioStreamPlayer] = []
var _active_ambience := 0
var _ambience_name := ""
var _effects: Array[AudioStreamPlayer] = []
var _next_effect := 0
var _cache := {}
var _voice_id := ""
var _last_nav_msec := -10000
var _pointer_is_mouse := true
var _told_no_voice := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name: String in BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Ambience"
		p.volume_db = -80.0
		add_child(p)
		_ambience_players.append(p)
	for i in 4:
		var p := AudioStreamPlayer.new()
		p.bus = "Effects"
		add_child(p)
		_effects.append(p)
	Settings.changed.connect(func(_key: String) -> void: _apply_volumes())
	_apply_volumes()
	var voices := DisplayServer.tts_get_voices_for_language(TranslationServer.get_locale().left(2)) if _tts_supported() else PackedStringArray()
	if voices.size() > 0:
		_voice_id = voices[0]
	# Every button can be heard: hold it, rest the mouse on it, or move to it.
	get_tree().node_added.connect(func(n: Node) -> void:
		if n is BaseButton:
			SpokenButton.attach(n))


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_pointer_is_mouse = event.device != InputEvent.DEVICE_ID_EMULATION
	elif event is InputEventScreenTouch:
		_pointer_is_mouse = false
	for action: String in ["ui_left", "ui_right", "ui_up", "ui_down", "ui_focus_next", "ui_focus_prev"]:
		if event.is_action_pressed(action):
			_last_nav_msec = Time.get_ticks_msec()


## True when the pointer is a real mouse (not a finger on a touch screen).
func pointer_is_mouse() -> bool:
	return _pointer_is_mouse


## True just after the child moved between buttons with keys or a gamepad.
func navigated_recently() -> bool:
	return Time.get_ticks_msec() - _last_nav_msec < 400


# --- Ambience -------------------------------------------------------------

## "outdoor", "interior", "chapel", or "" for silence. Crossfades over `seconds`.
func set_ambience(ambience: String, seconds: float = 2.0) -> void:
	if ambience == _ambience_name:
		return
	_ambience_name = ambience
	var old := _ambience_players[_active_ambience]
	_active_ambience = 1 - _active_ambience
	var new := _ambience_players[_active_ambience]
	var tween := create_tween().set_parallel(true)
	tween.tween_property(old, "volume_db", -80.0, seconds)
	if not ambience.is_empty():
		new.stream = _stream(ambience)
		new.volume_db = -80.0
		new.play()
		tween.tween_property(new, "volume_db", _ambience_level(ambience), seconds)


func current_ambience() -> String:
	return _ambience_name


func _ambience_level(ambience: String) -> float:
	return {"outdoor": -6.0, "interior": -10.0, "chapel": -8.0}.get(ambience, -12.0)


# --- Effects --------------------------------------------------------------

## Short, soft cues: "place", "return", "page", "complete", "step", and
## footsteps ("foot_grass", "foot_wood", "foot_stone").
func play(effect: String) -> void:
	var p := _effects[_next_effect]
	_next_effect = (_next_effect + 1) % _effects.size()
	p.stream = _stream(effect)
	p.volume_db = LEVELS.get(effect, 0.0) if has_recording(effect) else 0.0
	# A touch of pitch variety keeps repeated taps and steps natural.
	p.pitch_scale = randf_range(0.94, 1.06) if effect == "place" or effect.begins_with("foot_") else 1.0
	p.play()


## True when `sound` has a recording (rather than a synthesized stand-in).
func has_recording(sound: String) -> bool:
	return not _recorded(sound).is_empty()


## A recorded stream for a sound placed in the world (river, sheep, ...), or
## null when there is no recording. Each call may pick a different variant.
func world_stream(sound: String) -> AudioStream:
	var options := _recorded(sound)
	if options.is_empty() and sound == "purr":
		return _stream(sound) # a purr synthesizes well
	return null if options.is_empty() else options.pick_random()


# --- Narration ------------------------------------------------------------

## Speaks `text` if read-aloud is enabled, or always when `force` is true
## (the child pressed "Hear it"). Returns false when no voice is available.
func narrate(text: String, force: bool = false) -> bool:
	if not (force or Settings.get_value("read_aloud")):
		return false
	if _voice_id.is_empty():
		if not _told_no_voice:
			_told_no_voice = true
			narration_unavailable.emit()
		return false
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, _voice_id, int(Settings.get_value("volume_voice") * Settings.get_value("volume_master") * 100.0))
	return true


func stop_narration() -> void:
	if _tts_supported():
		DisplayServer.tts_stop()


## True while the voice is still speaking.
func is_speaking() -> bool:
	return _tts_supported() and not _voice_id.is_empty() and DisplayServer.tts_is_speaking()


func can_narrate() -> bool:
	return not _voice_id.is_empty()


func _tts_supported() -> bool:
	return DisplayServer.get_name() != "headless" and ProjectSettings.get_setting("audio/general/text_to_speech", false)


func _apply_volumes() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(Settings.get_value("volume_master"), 0.0001)))
	for pair: Array in [["Ambience", "volume_ambience"], ["Effects", "volume_effects"], ["Voice", "volume_voice"]]:
		var idx := AudioServer.get_bus_index(pair[0])
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(Settings.get_value(pair[1]), 0.0001)))


# --- Synthesis ------------------------------------------------------------

func _stream(sound: String) -> AudioStream:
	var options := _recorded(sound)
	if not options.is_empty():
		return options.pick_random()
	if not _cache.has(sound):
		_cache[sound] = _synthesize(sound)
	return _cache[sound]


## The loaded recordings for `sound` (empty if it has none).
func _recorded(sound: String) -> Array:
	var key := "rec:" + sound
	if not _cache.has(key):
		var loaded := []
		for f: String in FILES.get(sound, []):
			var path := AUDIO_DIR + f + ".ogg"
			if ResourceLoader.exists(path):
				var stream: AudioStream = load(path)
				if stream is AudioStreamOggVorbis:
					(stream as AudioStreamOggVorbis).loop = sound in LOOPS
				loaded.append(stream)
		_cache[key] = loaded
	return _cache[key]


func _synthesize(sound: String) -> AudioStreamWAV:
	match sound:
		"place":
			return _wav(_tone([660.0], 0.12, 0.25), false)
		"return":
			return _wav(_tone([392.0], 0.16, 0.18), false)
		"step":
			return _wav(_tone([523.25, 659.25], 0.35, 0.18), false)
		"complete":
			# Three soft rising notes: an acknowledgement, not a reward fanfare.
			var s := PackedFloat32Array()
			for f: float in [523.25, 659.25, 783.99]:
				s.append_array(_tone([f], 0.32, 0.2))
			return _wav(s, false)
		"page":
			return _wav(_noise_burst(0.18, 0.12), false)
		"outdoor":
			return _wav(_outdoor_loop(8.0), true)
		"interior":
			return _wav(_wind(6.0, 0.03), true)
		"purr":
			return _wav(_purr(2.4), false)
		"chapel":
			return _wav(_pad([110.0, 165.0, 220.0, 277.25, 330.0], 8.0), true)
	push_warning("AudioService: unknown sound '%s'" % sound)
	return _wav(PackedFloat32Array([0.0]), false)


func _tone(freqs: Array, seconds: float, amp: float) -> PackedFloat32Array:
	var n := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / MIX_RATE
		var env := minf(t / 0.01, 1.0) * exp(-t * 7.0 / seconds)
		var v := 0.0
		for f: float in freqs:
			v += sin(TAU * f * t) + 0.25 * sin(TAU * f * 2.0 * t)
		out[i] = v * env * amp / freqs.size()
	return out


## A cat's purr: low rumbling noise pulsing about 26 times a second, over
## two slow breaths.
func _purr(seconds: float) -> PackedFloat32Array:
	var n := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var lp := 0.0
	var lp2 := 0.0
	for i in n:
		var t := float(i) / MIX_RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.05)
		lp2 = lerpf(lp2, lp, 0.1)
		var breath := sin(PI * fmod(t, seconds / 2.0) / (seconds / 2.0))
		var pulse := pow(0.5 + 0.5 * sin(TAU * 26.0 * t), 3.0)
		out[i] = lp2 * pulse * breath * 2.2
	return out


func _noise_burst(seconds: float, amp: float) -> PackedFloat32Array:
	var n := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var lp := 0.0
	for i in n:
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.3)
		out[i] = lp * amp * sin(PI * float(i) / n)
	return out


## Soft low-passed noise with a slow swell; the loop seam is crossfaded.
func _wind(seconds: float, amp: float) -> PackedFloat32Array:
	var n := int(seconds * MIX_RATE)
	var fade := MIX_RATE / 2
	var raw := PackedFloat32Array()
	raw.resize(n + fade)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var lp := 0.0
	for i in raw.size():
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.02)
		var swell := 0.6 + 0.4 * sin(TAU * float(i) / n)
		raw[i] = lp * swell * amp * 6.0
	for i in fade:
		var w := float(i) / fade
		raw[i] = raw[i] * w + raw[n + i] * (1.0 - w)
	return raw.slice(0, n)


func _outdoor_loop(seconds: float) -> PackedFloat32Array:
	var out := _wind(seconds, 0.04)
	# A few gentle two-note bird calls at fixed points in the loop.
	for start: float in [1.1, 3.7, 6.2]:
		var call := _tone([2637.0], 0.09, 0.05)
		call.append_array(_tone([3135.96], 0.12, 0.04))
		var offset := int(start * MIX_RATE)
		for i in call.size():
			if offset + i < out.size():
				out[offset + i] += call[i]
	return out


## Sustained chord whose frequencies complete whole cycles in `seconds`, so it loops seamlessly.
func _pad(freqs: Array, seconds: float) -> PackedFloat32Array:
	var n := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / MIX_RATE
		var v := 0.0
		for k in freqs.size():
			var breathe := 0.7 + 0.3 * sin(TAU * t / seconds * (k % 2 + 1) + k)
			v += sin(TAU * freqs[k] * t) * breathe
		out[i] = v * 0.06 / freqs.size() * 3.0
	return out


func _wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav
