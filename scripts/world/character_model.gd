class_name CharacterModel
extends Node3D
## Storybook person built from rounded primitives: the custom protagonist and
## NPC style called for by ART_DIRECTION (big friendly heads, readable faces,
## simple clothes), with procedural animation. Faces -Z.
##
## A "look" is plain data (see content/world/characters.json):
##   skin, hair, hair_style (short|tousled|curly|bun|braid|long|bald|cropped),
##   beard (color), eyes (iris colour), shirt, sleeves (long|short), pants,
##   skirt, apron, vest, belt, collar, shoes, hat (straw|cap|scarf|hood),
##   hat_color, hat_band, backpack, carry (basket), height (1.0 = adult),
##   head_scale, build (width), age (child|adult|elder)

var _hips: Node3D
var _torso: Node3D
var _head: Node3D
var _legs: Array[Node3D] = []
var _knees: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _elbows: Array[Node3D] = []
var _eyes: Node3D
var _mouth: Node3D
var _phase := 0.0
var _time := 0.0
var _blink := 2.0
var _talk := 0.0
var _gesture := 0.0
var _look_target: Variant = null # Vector3 in world space, or null
var _carrying := false


func build(look: Dictionary) -> CharacterModel:
	var h: float = look.get("height", 1.0)
	var w: float = look.get("build", 1.0)
	var child := h < 0.92
	var body := Node3D.new()
	body.scale = Vector3.ONE * h
	add_child(body)
	var skin: String = look.get("skin", "skin_1")
	var shirt: String = look.get("shirt", "cloth_cream")
	var pants: String = look.get("pants", "cloth_blue")
	var shoes: String = look.get("shoes", "shoe")

	# Legs: thigh and shin on hinged knees so walking bends naturally.
	_hips = Node3D.new()
	_hips.position.y = 0.78
	body.add_child(_hips)
	for side: float in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(0.1 * side * w, 0, 0)
		_hips.add_child(hip)
		MeshKit.capsule(hip, 0.085 * w, 0.42, Vector3(0, -0.2, 0), pants)
		var knee := Node3D.new()
		knee.position.y = -0.38
		hip.add_child(knee)
		MeshKit.capsule(knee, 0.07 * w, 0.4, Vector3(0, -0.18, 0), pants if not look.has("skirt") or child else skin)
		var foot := MeshKit.capsule(knee, 0.065, 0.24, Vector3(0, -0.37, -0.05), shoes, Vector3(PI / 2.0, 0, 0))
		foot.scale = Vector3(1.15, 1.0, 0.8)
		_legs.append(hip)
		_knees.append(knee)

	# Torso: a soft tapered body, belt, collar, optional skirt, apron and vest.
	_torso = Node3D.new()
	_hips.add_child(_torso)
	var chest := MeshKit.capsule(_torso, 0.2 * w, 0.62, Vector3(0, 0.27, 0), shirt)
	chest.scale = Vector3(1.0, 1.0, 0.78)
	if look.has("vest"):
		var vest := MeshKit.capsule(_torso, 0.205 * w, 0.46, Vector3(0, 0.3, 0.005), look["vest"])
		vest.scale = Vector3(1.02, 1.0, 0.8)
	if look.has("skirt"):
		MeshKit.cylinder(_torso, 0.2 * w, 0.36 * w, 0.5 if not child else 0.36, Vector3(0, -0.12 if not child else -0.06, 0), look["skirt"], 12)
	if look.has("apron"):
		var apron := MeshKit.box(_torso, Vector3(0.3 * w, 0.62, 0.03), Vector3(0, -0.02, -0.17 * w), look["apron"])
		apron.rotation.x = 0.08
	MeshKit.cylinder(_torso, 0.205 * w, 0.205 * w, 0.06, Vector3(0, 0.06, 0), look.get("belt", "leather"), 12).scale.z = 0.8
	MeshKit.cylinder(_torso, 0.1, 0.13, 0.05, Vector3(0, 0.58, 0), look.get("collar", shirt), 10)

	# Arms: upper arm and forearm on hinged elbows, with round hands.
	var sleeve_long: bool = look.get("sleeves", "long") == "long"
	for side: float in [-1.0, 1.0]:
		var shoulder := Node3D.new()
		shoulder.position = Vector3(0.24 * side * w, 0.5, 0)
		_torso.add_child(shoulder)
		MeshKit.sphere(shoulder, 0.075, Vector3.ZERO, shirt, Vector3.ONE, 8, 4)
		MeshKit.capsule(shoulder, 0.06, 0.3, Vector3(0, -0.13, 0), shirt)
		var elbow := Node3D.new()
		elbow.position.y = -0.27
		shoulder.add_child(elbow)
		MeshKit.capsule(elbow, 0.052, 0.28, Vector3(0, -0.12, 0), shirt if sleeve_long else skin)
		MeshKit.sphere(elbow, 0.058, Vector3(0, -0.28, 0), skin, Vector3(0.9, 1.1, 0.8), 8, 4)
		_arms.append(shoulder)
		_elbows.append(elbow)

	if look.has("backpack"):
		_backpack(look["backpack"])
	if look.get("carry", "") == "basket":
		_basket()

	# Head: big and friendly (bigger still for children).
	_head = Node3D.new()
	_head.position.y = 0.72
	_head.scale = Vector3.ONE * float(look.get("head_scale", 1.25 if child else 1.05))
	_torso.add_child(_head)
	MeshKit.cylinder(_head, 0.055, 0.065, 0.12, Vector3(0, -0.07, 0), skin, 8)
	var skull := MeshKit.sphere(_head, 0.17, Vector3(0, 0.12, 0), skin, Vector3(1.0, 1.06, 0.98), 14, 8)
	skull.name = "Skull"
	for side: float in [-1.0, 1.0]:
		MeshKit.sphere(_head, 0.04, Vector3(side * 0.165, 0.11, 0.0), skin, Vector3(0.6, 1.0, 0.9), 6, 4)
	_face(look, skin, child)
	_hair(look)
	_hat(look)
	if look.has("beard"):
		var beard := MeshKit.sphere(_head, 0.13, Vector3(0, 0.0, -0.08), look["beard"], Vector3(1.05, 0.9, 0.75), 10, 6)
		beard.name = "Beard"
		MeshKit.capsule(_head, 0.025, 0.14, Vector3(0, 0.06, -0.165), look["beard"], Vector3(0, 0, PI / 2.0))
	_blink = randf_range(1.0, 4.0)
	return self


func _face(look: Dictionary, skin: String, child: bool) -> void:
	_eyes = Node3D.new()
	_eyes.position = Vector3(0, 0.14, -0.145)
	_head.add_child(_eyes)
	var iris: String = look.get("eyes", "iris_brown")
	var eye_size := 0.036 if child else 0.03
	for side: float in [-1.0, 1.0]:
		var eye := Node3D.new()
		eye.position = Vector3(side * 0.062, 0, 0)
		_eyes.add_child(eye)
		MeshKit.sphere(eye, eye_size, Vector3.ZERO, "eye_white", Vector3(1.0, 1.15, 0.5), 10, 6)
		MeshKit.sphere(eye, eye_size * 0.66, Vector3(0, -0.003, -0.012), iris, Vector3(1.0, 1.1, 0.4), 8, 5)
		MeshKit.sphere(eye, eye_size * 0.32, Vector3(0, -0.003, -0.018), "dark", Vector3(1.0, 1.0, 0.4), 6, 4)
		MeshKit.sphere(eye, eye_size * 0.2, Vector3(side * -0.008, 0.01, -0.022), "white", Vector3.ONE, 5, 3)
		var brow := MeshKit.capsule(_head, 0.008, 0.07, Vector3(side * 0.064, 0.205, -0.15), look.get("brows", look.get("hair", "hair_brown")), Vector3(0, 0, PI / 2.0 + side * 0.15))
		brow.name = "Brow"
		MeshKit.sphere(_head, 0.03, Vector3(side * 0.1, 0.07, -0.13), "cheek", Vector3(1.0, 0.65, 0.4), 6, 4)
	MeshKit.sphere(_head, 0.026, Vector3(0, 0.09, -0.17), skin, Vector3(1.0, 0.9, 1.0), 6, 4)
	# A gentle smile: a few dots on an arc. Scaled open while talking.
	_mouth = Node3D.new()
	_mouth.position = Vector3(0, 0.035, -0.158)
	_head.add_child(_mouth)
	for i in 5:
		var t := (i - 2) / 2.0
		MeshKit.sphere(_mouth, 0.011, Vector3(t * 0.03, absf(t) * 0.008, 0), "lips", Vector3.ONE, 5, 3)


func _hair(look: Dictionary) -> void:
	var hair: String = look.get("hair", "hair_brown")
	var style: String = look.get("hair_style", "short")
	if style == "bald":
		MeshKit.sphere(_head, 0.172, Vector3(0, 0.08, 0.04), hair, Vector3(1.03, 0.55, 0.95), 12, 6)
		return
	# Cap of hair over the top and back of the skull.
	MeshKit.sphere(_head, 0.182, Vector3(0, 0.16, 0.03), hair, Vector3(1.02, 0.86, 1.0), 14, 7)
	match style:
		"short", "cropped":
			MeshKit.sphere(_head, 0.1, Vector3(0.03, 0.24, -0.12), hair, Vector3(1.6, 0.5, 0.8), 8, 4)
		"tousled":
			for i in 9:
				var a := TAU * i / 9.0
				MeshKit.sphere(_head, 0.075, Vector3(cos(a) * 0.14, 0.23 + 0.03 * sin(i * 2.3), sin(a) * 0.14 + 0.02), hair, Vector3(1.0, 0.8, 1.0), 7, 4)
			for x: float in [-0.07, 0.0, 0.07]:
				MeshKit.sphere(_head, 0.06, Vector3(x, 0.23, -0.14), hair, Vector3(1.0, 0.7, 0.7), 7, 4)
		"curly":
			for i in 12:
				var a := TAU * i / 12.0
				MeshKit.sphere(_head, 0.07, Vector3(cos(a) * 0.16, 0.18 + 0.06 * sin(i * 1.7), sin(a) * 0.16 + 0.03), hair, Vector3.ONE, 7, 4)
		"bun":
			MeshKit.sphere(_head, 0.085, Vector3(0, 0.3, 0.12), hair, Vector3.ONE, 9, 5)
			MeshKit.sphere(_head, 0.11, Vector3(0, 0.22, -0.11), hair, Vector3(1.5, 0.5, 0.7), 8, 4)
		"braid":
			MeshKit.sphere(_head, 0.11, Vector3(0, 0.22, -0.11), hair, Vector3(1.5, 0.5, 0.7), 8, 4)
			for i in 4:
				MeshKit.sphere(_head, 0.045 - i * 0.004, Vector3(0, 0.02 - i * 0.075, 0.17 + i * 0.01), hair, Vector3.ONE, 7, 4)
		"long":
			MeshKit.sphere(_head, 0.11, Vector3(0, 0.22, -0.11), hair, Vector3(1.5, 0.5, 0.7), 8, 4)
			var back := MeshKit.capsule(_head, 0.15, 0.42, Vector3(0, -0.02, 0.08), hair)
			back.scale = Vector3(1.1, 1.0, 0.6)


func _hat(look: Dictionary) -> void:
	match look.get("hat", ""):
		"straw":
			MeshKit.cylinder(_head, 0.33, 0.33, 0.025, Vector3(0, 0.27, 0), "roof_thatch", 16)
			MeshKit.cylinder(_head, 0.15, 0.18, 0.13, Vector3(0, 0.33, 0), "roof_thatch", 12)
			MeshKit.cylinder(_head, 0.183, 0.183, 0.035, Vector3(0, 0.29, 0), look.get("hat_band", "cloth_green"), 12)
		"cap":
			MeshKit.sphere(_head, 0.19, Vector3(0, 0.2, 0.02), look.get("hat_color", "cloth_blue"), Vector3(1.0, 0.6, 1.0), 12, 6)
			MeshKit.box(_head, Vector3(0.22, 0.02, 0.12), Vector3(0, 0.2, -0.17), look.get("hat_color", "cloth_blue"))
		"scarf":
			MeshKit.sphere(_head, 0.195, Vector3(0, 0.16, 0.04), look.get("hat_color", "cloth_red"), Vector3(1.04, 0.95, 1.05), 12, 6)
			MeshKit.sphere(_head, 0.06, Vector3(0, 0.03, 0.17), look.get("hat_color", "cloth_red"), Vector3.ONE, 7, 4)
		"hood":
			MeshKit.sphere(_head, 0.21, Vector3(0, 0.12, 0.05), look.get("hat_color", "monk_brown"), Vector3(1.05, 1.05, 1.08), 12, 6)


func _backpack(color: String) -> void:
	var pack := MeshKit.capsule(_torso, 0.15, 0.42, Vector3(0, 0.3, 0.2), color)
	pack.scale = Vector3(1.1, 1.0, 0.65)
	MeshKit.box(_torso, Vector3(0.28, 0.13, 0.2), Vector3(0, 0.46, 0.22), "leather")
	MeshKit.box(_torso, Vector3(0.18, 0.12, 0.05), Vector3(0, 0.2, 0.31), "leather")
	for side: float in [-1.0, 1.0]:
		MeshKit.box(_torso, Vector3(0.04, 0.4, 0.03), Vector3(side * 0.12, 0.33, -0.15), "leather")


func _basket() -> void:
	_carrying = true
	var hand := _elbows[1]
	var basket := Node3D.new()
	basket.position = Vector3(0, -0.36, -0.05)
	hand.add_child(basket)
	MeshKit.cylinder(basket, 0.16, 0.12, 0.14, Vector3(0, -0.06, 0), "roof_thatch", 10)
	var handle := MeshKit.cylinder(basket, 0.13, 0.13, 0.015, Vector3(0, 0.04, 0), "wood_dark", 12)
	handle.rotation.x = PI / 2.0
	for i in 3:
		MeshKit.sphere(basket, 0.05, Vector3(-0.06 + i * 0.06, 0.02, 0.0), ["cloth_red", "leaf_light", "flower_yellow"][i], Vector3.ONE, 6, 3)


## Turns the head toward a world point (e.g. the child during conversation).
func look_at_point(point: Variant) -> void:
	_look_target = point


## 0..1 how much the character is speaking; drives mouth and hands.
func set_talking(amount: float) -> void:
	_talk = amount


## Raises the near arm in a small greeting or explaining gesture (0..1).
func gesture(amount: float) -> void:
	_gesture = clampf(amount, 0.0, 1.0)


## Call every frame with the current ground speed (m/s).
func animate(delta: float, speed: float, reduced_motion := false) -> void:
	_time += delta
	var walk := clampf(speed / 2.6, 0.0, 1.0)
	if walk > 0.05:
		_phase += delta * (5.0 + speed * 2.2)
	var s := sin(_phase)
	# Legs: swing from the hip, bend the knee on the forward swing.
	for i in 2:
		var dir := 1.0 if i == 0 else -1.0
		_legs[i].rotation.x = s * 0.55 * walk * dir
		_knees[i].rotation.x = -maxf(0.0, -s * dir) * 0.9 * walk - 0.05
	# Arms swing opposite the legs; elbows stay a little soft.
	for i in 2:
		var dir := -1.0 if i == 0 else 1.0
		var swing := s * 0.5 * walk * dir
		if i == 1 and _gesture > 0.01:
			_arms[i].rotation.x = lerpf(swing, -1.1 - sin(_time * 3.0) * 0.15, _gesture)
			_elbows[i].rotation.x = lerpf(-0.25, -0.9, _gesture)
		elif i == 1 and _carrying:
			_arms[i].rotation.x = -0.15
			_elbows[i].rotation.x = -0.6
		else:
			_arms[i].rotation.x = swing
			_elbows[i].rotation.x = -0.2 - 0.25 * walk
		_arms[i].rotation.z = (0.12 if i == 0 else -0.12)
	if reduced_motion:
		_hips.position.y = 0.78
	else:
		var breathe := sin(_time * 1.8) * 0.006
		_hips.position.y = 0.78 + absf(s) * 0.035 * walk + breathe
		_torso.rotation.y = s * 0.08 * walk
		_torso.rotation.x = 0.06 * walk
	# Head: gentle idle look-around, or toward a target.
	var yaw := sin(_time * 0.37) * 0.25 * (1.0 - walk)
	var pitch := 0.0
	if _look_target != null:
		var to: Vector3 = (_look_target as Vector3) - _head.global_position
		var local := global_transform.basis.inverse() * to
		yaw = clampf(atan2(-local.x, -local.z), -0.9, 0.9)
		pitch = clampf(atan2(local.y, Vector2(local.x, local.z).length()), -0.4, 0.4)
	_head.rotation.y = lerp_angle(_head.rotation.y, yaw, minf(delta * 4.0, 1.0))
	_head.rotation.x = lerpf(_head.rotation.x, pitch, minf(delta * 4.0, 1.0))
	# Blink every few seconds; open the mouth in time with speech.
	_blink -= delta
	var closed := _blink < 0.0 and _blink > -0.12
	if _blink < -0.12:
		_blink = randf_range(2.0, 5.0)
	_eyes.scale.y = 0.1 if closed else 1.0
	var open := 0.0 if _talk <= 0.0 else (0.5 + 0.5 * sin(_time * 14.0)) * _talk
	_mouth.scale = Vector3(1.0 - open * 0.25, 1.0 + open * 2.2, 1.0)
