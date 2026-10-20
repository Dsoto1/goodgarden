extends Node
## AudioService: ambience, gentle interface sounds and read-aloud narration.
##
## Every sound is synthesized at runtime, so the slice ships with no
## third-party audio. Ambience crossfades between places; the Chapel has its
## own quiet pad so it is aurally distinct from task gameplay. Narration uses
## the platform text-to-speech voice when read-aloud is on; captions always show.

signal narration_unavailable

const MIX_RATE := 22050
const BUSES := ["Ambience", "Effects", "Voice"]

var _ambience_players: Array[AudioStreamPlayer] = []
var _active_ambience := 0
var _ambience_name := ""
var _effects: Array[AudioStreamPlayer] = []
var _next_effect := 0
var _cache := {}
var _voice_id := ""


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
	return {"outdoor": -10.0, "interior": -16.0, "chapel": -8.0}.get(ambience, -12.0)


# --- Effects --------------------------------------------------------------

## Short, soft cues: "place", "return", "page", "complete", "step".
func play(effect: String) -> void:
	var p := _effects[_next_effect]
	_next_effect = (_next_effect + 1) % _effects.size()
	p.stream = _stream(effect)
	p.play()


# --- Narration ------------------------------------------------------------

## Speaks `text` if read-aloud is enabled, or always when `force` is true
## (the child pressed "Hear it"). Returns false when no voice is available.
func narrate(text: String, force: bool = false) -> bool:
	if not (force or Settings.get_value("read_aloud")):
		return false
	if _voice_id.is_empty():
		narration_unavailable.emit()
		return false
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, _voice_id, int(Settings.get_value("volume_voice") * Settings.get_value("volume_master") * 100.0))
	return true


func stop_narration() -> void:
	if _tts_supported():
		DisplayServer.tts_stop()


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

func _stream(sound: String) -> AudioStreamWAV:
	if not _cache.has(sound):
		_cache[sound] = _synthesize(sound)
	return _cache[sound]


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
