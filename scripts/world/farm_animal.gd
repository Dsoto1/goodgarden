class_name FarmAnimal
extends Node3D
## A farm animal from Quaternius's LowPoly Animated Animals (CC0): sheep and
## lambs, cows, the horse, pigs and the village pug. It stands and breathes,
## walks when its Wanderer moves it, and hops for joy when petted. Faces -Z
## like the procedural animals in AnimalModel.

const DIR := "res://assets/third_party/quaternius/farm_animals/"
## file: the model; scale: model units to metres; walk_speed: the ground
## speed (m/s) its walk cycle is drawn for. Sheep, pigs and the pug have no
## walk of their own, so they borrow the cow's (the skeletons share bone names).
const KINDS := {
	"sheep": {"file": "Sheep", "scale": 0.19, "walk_speed": 0.45},
	"lamb": {"file": "Sheep", "scale": 0.12, "walk_speed": 0.3},
	"cow": {"file": "Cow", "scale": 0.24, "walk_speed": 0.7},
	"horse": {"file": "Horse", "scale": 0.25, "walk_speed": 0.9},
	"pig": {"file": "Pig", "scale": 0.16, "walk_speed": 0.4},
	"dog": {"file": "Pug", "scale": 0.17, "walk_speed": 0.5},
}
const IDLE := "Armature|Idle"
const WALK := "Armature|Walk"
const JUMP := "Armature|Jump"

static var _scenes := {}
static var _borrowed_walk: Animation

var kind := ""
var anim: AnimationPlayer
var _moving := false
var _hopping := 0.0


static func is_kind(k: String) -> bool:
	return KINDS.has(k)


static func make(k: String) -> FarmAnimal:
	var spec: Dictionary = KINDS[k]
	var path := DIR + str(spec["file"]) + ".fbx"
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var a := FarmAnimal.new()
	a.kind = k
	a.name = k.capitalize()
	var model: Node3D = (_scenes[path] as PackedScene).instantiate()
	model.scale = Vector3.ONE * float(spec["scale"])
	model.rotation.y = PI # the models face +Z
	a.add_child(model)
	Style.apply(model, {"saturation": 0.95, "wrap": 0.4}, 0.0, "farm_" + str(spec["file"]))
	a.anim = model.find_children("*", "AnimationPlayer", true, false)[0]
	if not a.anim.has_animation(WALK):
		a.anim.get_animation_library("").add_animation(WALK, _walk())
	a.anim.get_animation(IDLE).loop_mode = Animation.LOOP_LINEAR
	a.anim.get_animation(WALK).loop_mode = Animation.LOOP_LINEAR
	return a


## The cow's walk, keeping only its turning joints so it fits any body.
static func _walk() -> Animation:
	if _borrowed_walk == null:
		var cow: Node = (load(DIR + "Cow.fbx") as PackedScene).instantiate()
		var src: Animation = (cow.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer).get_animation(WALK)
		_borrowed_walk = src.duplicate(true)
		for t in range(_borrowed_walk.get_track_count() - 1, -1, -1):
			if _borrowed_walk.track_get_type(t) != Animation.TYPE_ROTATION_3D:
				_borrowed_walk.remove_track(t)
		cow.free()
	return _borrowed_walk


func _ready() -> void:
	# Each animal starts its breathing at a different moment.
	anim.play(IDLE)
	anim.seek(randf() * anim.current_animation_length, true)


## Walking or standing, at `speed` metres a second.
func set_moving(on: bool, speed := 0.0) -> void:
	if _hopping > 0.0:
		return
	if on and not _moving:
		anim.play(WALK, 0.3)
	elif not on and _moving:
		anim.play(IDLE, 0.4)
	_moving = on
	if on:
		anim.speed_scale = clampf(speed / float(KINDS[kind]["walk_speed"]), 0.4, 1.6)
	else:
		anim.speed_scale = 1.0


## A happy little jump, then back to standing.
func hop() -> void:
	anim.speed_scale = 1.0
	anim.play(JUMP, 0.15)
	_hopping = anim.current_animation_length
	_moving = false


func is_hopping() -> bool:
	return _hopping > 0.0


func _process(delta: float) -> void:
	if _hopping > 0.0:
		_hopping -= delta
		if _hopping <= 0.0:
			anim.play(IDLE, 0.3)
