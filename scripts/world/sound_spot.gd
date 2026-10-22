class_name SoundSpot
extends Node3D
## A sound that belongs to a place: the river, the waterfall, the fountain,
## sheep in the fold. It fades with distance, so the child hears the water
## grow as they walk toward it. A looping spot plays all the time; a calling
## spot (sheep, hens) plays one of its recordings now and then.

var sound := ""
var player: AudioStreamPlayer3D
var _pause := Vector2.ZERO
var _wait := 0.0


## Adds a looping sound at `pos` (parent-local). `reach` is roughly how far
## away it can still be heard, in metres.
static func looping(parent: Node3D, sound_name: String, pos: Vector3, reach: float, level_db := 0.0) -> SoundSpot:
	return _make(parent, sound_name, pos, reach, level_db, Vector2.ZERO)


## Adds a spot that calls every `pause.x` to `pause.y` seconds.
static func calling(parent: Node3D, sound_name: String, pos: Vector3, reach: float, pause: Vector2, level_db := 0.0) -> SoundSpot:
	return _make(parent, sound_name, pos, reach, level_db, pause)


static func _make(parent: Node3D, sound_name: String, pos: Vector3, reach: float, level_db: float, pause: Vector2) -> SoundSpot:
	var spot := SoundSpot.new()
	spot.name = "Sound_" + sound_name
	spot.sound = sound_name
	spot.position = pos
	spot._pause = pause
	spot.player = AudioStreamPlayer3D.new()
	spot.player.bus = "Ambience"
	spot.player.volume_db = level_db
	spot.player.max_distance = reach
	spot.player.unit_size = reach / 3.0
	# No distance low-pass: water lives in the high frequencies, and the
	# filter muffled the river even right beside it.
	spot.player.attenuation_filter_db = 0.0
	spot.player.panning_strength = 0.6
	spot.add_child(spot.player)
	parent.add_child(spot)
	return spot


func _ready() -> void:
	if is_looping():
		player.stream = AudioService.world_stream(sound)
		if player.stream:
			# Start each loop at a different point so neighbouring spots don't echo.
			player.play(randf() * maxf(player.stream.get_length() - 1.0, 0.0))
	else:
		_wait = randf_range(1.0, _pause.y)


func is_looping() -> bool:
	return _pause == Vector2.ZERO


func _process(delta: float) -> void:
	if is_looping():
		return
	_wait -= delta
	if _wait <= 0.0:
		_wait = randf_range(_pause.x, _pause.y)
		var stream := AudioService.world_stream(sound)
		if stream:
			player.stream = stream
			player.pitch_scale = randf_range(0.95, 1.05)
			player.play()


## Plays one recording of `sound_name` once at `pos` (parent-local), then
## tidies itself away. Silent when the sound has no recording.
static func once(parent: Node3D, sound_name: String, pos: Vector3, reach: float, level_db := 0.0) -> void:
	var stream := AudioService.world_stream(sound_name)
	if stream == null:
		return
	var spot := _make(parent, sound_name, pos, reach, level_db, Vector2(INF, INF))
	spot.set_process(false)
	spot.player.stream = stream
	spot.player.pitch_scale = randf_range(0.95, 1.05)
	spot.player.finished.connect(spot.queue_free)
	spot.player.play.call_deferred()
