class_name CharacterModel
extends Node3D
## Storybook person: the custom protagonist and NPC style called for by
## ART_DIRECTION (big friendly heads, readable faces, simple clothes). The body
## is one smooth skinned mesh (BodyMesh) on a small skeleton, so limbs bend at
## blended joints; the head, hair, hats and accessories ride on bones.
## Animation is procedural. Faces -Z.
##
## A "look" is plain data (see content/world/characters.json):
##   skin, hair, hair_style (short|tousled|curly|bun|braid|long|bald|cropped),
##   beard (color), eyes (iris colour), shirt, sleeves (long|short), pants,
##   skirt, apron, vest, belt, collar, shoes, hat (straw|cap|scarf|hood),
##   hat_color, hat_band, backpack, carry (basket), height (1.0 = adult),
##   head_scale, build (width), age (child|adult|elder)
##
## Expressions are named moods (see MOODS); dialogue lines may set one.

const MOODS := {
	"smile": {"curve": 1.0, "open": 0.0, "lift": 0.0, "tilt": 0.0, "squint": 0.0, "narrow": 0.0},
	"joy": {"curve": 1.6, "open": 0.35, "lift": 0.01, "tilt": 0.0, "squint": 0.45, "narrow": 0.0},
	"gentle": {"curve": 0.6, "open": 0.0, "lift": 0.004, "tilt": 0.12, "squint": 0.2, "narrow": 0.1},
	"concern": {"curve": -0.6, "open": 0.0, "lift": 0.006, "tilt": 0.35, "squint": 0.0, "narrow": 0.15},
	"wonder": {"curve": 0.2, "open": 0.7, "lift": 0.018, "tilt": 0.0, "squint": 0.0, "narrow": 0.45},
	"thinking": {"curve": 0.2, "open": 0.0, "lift": 0.004, "tilt": -0.2, "squint": 0.15, "narrow": 0.3},
}

const B := BodyMesh.Bone

var _skeleton: Skeleton3D
var _head: Node3D
var _eyes: Node3D
var _mouth: Node3D
var _mouth_dots: Array[Node3D] = []
var _mouth_inside: Node3D
var _brows: Array[Node3D] = []
## Current and target expression: mouth curve and openness, brow lift and
## tilt (inner ends up = concern), and a happy squint.
var _expr := {"curve": 1.0, "open": 0.0, "lift": 0.0, "tilt": 0.0, "squint": 0.0, "narrow": 0.0}
var _expr_target := _expr.duplicate()
var _phase := 0.0
var _time := 0.0
var _blink := 2.0
var _talk := 0.0
var _gesture := 0.0
var _look_target: Variant = null # Vector3 in world space, or null
var _carrying := false
var _head_yaw := 0.0
var _head_pitch := 0.0


func build(look: Dictionary) -> CharacterModel:
	var h: float = look.get("height", 1.0)
	var w: float = look.get("build", 1.0)
	var child := h < 0.92
	var body := Node3D.new()
	body.scale = Vector3.ONE * h
	add_child(body)
	var skin: String = look.get("skin", "skin_1")

	# One smooth skinned body (see BodyMesh); clothes are colour regions on it.
	_skeleton = BodyMesh.make_skeleton(w)
	body.add_child(_skeleton)
	var mesh := MeshInstance3D.new()
	mesh.name = "Body"
	mesh.mesh = BodyMesh.build(look, w)
	mesh.material_override = Style.material("solid", {"use_vertex_color": true, "wrap": 0.45, "rim_strength": 0.1})
	_skeleton.add_child(mesh)
	mesh.skeleton = NodePath("..")
	mesh.skin = _skeleton.create_skin_from_rest_transforms()

	var hips := _attach("hips")
	if look.has("apron"):
		# A soft, slightly curved apron rather than a flat board.
		var apron := MeshKit.capsule(hips, 0.15 * w, 0.62, Vector3(0, -0.02, -0.12 * w), look["apron"])
		apron.scale = Vector3(1.0, 1.0, 0.22)
		apron.rotation.x = 0.08
	if look.has("backpack"):
		_backpack(_attach("chest"), look["backpack"])
	if look.get("carry", "") == "basket":
		_basket(_attach("r_hand"))

	# Head: big and friendly (bigger still for children), riding the head bone.
	_head = Node3D.new()
	_head.position.y = -0.02
	_head.scale = Vector3.ONE * float(look.get("head_scale", 1.25 if child else 1.05))
	_attach("head").add_child(_head)
	var skull := MeshKit.sphere(_head, 0.17, Vector3(0, 0.12, 0), skin, Vector3(1.0, 1.06, 0.98), 16, 10)
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
	# Merge each bone's static pieces (skull, hair, hat, ...) into one mesh;
	# the eyes, brows and mouth animate, so they stay separate.
	StaticBatch.mark_live(_eyes)
	StaticBatch.mark_live(_mouth)
	for brow in _brows:
		StaticBatch.mark_live(brow)
	for att in _skeleton.get_children():
		if att is BoneAttachment3D:
			StaticBatch.merge(att, INF)
	# The eyes blink as one, so their parts merge among themselves too.
	StaticBatch.merge(_eyes, INF)
	# Eyes, brows and mouth are too small to see from afar: skip drawing them there.
	var face_range: float = Quality.value("face_range")
	for part: Node in [_eyes, _mouth] + _brows:
		for g in part.find_children("*", "GeometryInstance3D", true, false):
			(g as GeometryInstance3D).visibility_range_end = face_range
	return self


## A node that follows one bone of the skeleton.
func _attach(bone: String) -> Node3D:
	var att := BoneAttachment3D.new()
	att.bone_name = bone
	_skeleton.add_child(att)
	return att


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
		var brow_pivot := Node3D.new()
		brow_pivot.name = "Brow"
		brow_pivot.position = Vector3(side * 0.064, 0.205, -0.15)
		brow_pivot.set_meta("side", side)
		_head.add_child(brow_pivot)
		MeshKit.capsule(brow_pivot, 0.008, 0.07, Vector3.ZERO, look.get("brows", look.get("hair", "hair_brown")), Vector3(0, 0, PI / 2.0))
		_brows.append(brow_pivot)
		MeshKit.sphere(_head, 0.03, Vector3(side * 0.1, 0.07, -0.13), "cheek", Vector3(1.0, 0.65, 0.4), 6, 4)
	MeshKit.sphere(_head, 0.026, Vector3(0, 0.09, -0.17), skin, Vector3(1.0, 0.9, 1.0), 6, 4)
	# A gentle smile: a few dots on an arc. Scaled open while talking.
	_mouth = Node3D.new()
	_mouth.position = Vector3(0, 0.035, -0.152)
	_head.add_child(_mouth)
	for i in 5:
		var dot := Node3D.new()
		dot.set_meta("t", (i - 2) / 2.0)
		_mouth.add_child(dot)
		MeshKit.sphere(dot, 0.011, Vector3.ZERO, "lips", Vector3.ONE, 5, 3)
		_mouth_dots.append(dot)
	# Dark inside of the mouth, shown only while it is open.
	_mouth_inside = MeshKit.sphere(_mouth, 0.016, Vector3(0, 0.002, -0.004), "dark", Vector3(1.5, 0.55, 0.4), 8, 4)
	_mouth_inside.visible = false
	_apply_expression()


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


func _backpack(chest: Node3D, color: String) -> void:
	var pack := MeshKit.capsule(chest, 0.14, 0.4, Vector3(0, -0.04, 0.19), color)
	pack.scale = Vector3(1.05, 1.0, 0.62)
	var flap := MeshKit.capsule(chest, 0.13, 0.26, Vector3(0, 0.1, 0.21), "leather", Vector3(0, 0, PI / 2.0))
	flap.scale = Vector3(0.6, 1.0, 0.65)
	var pocket := MeshKit.capsule(chest, 0.07, 0.16, Vector3(0, -0.13, 0.28), "leather", Vector3(0, 0, PI / 2.0))
	pocket.scale = Vector3(0.9, 1.0, 0.5)
	for side: float in [-1.0, 1.0]:
		var strap := MeshKit.capsule(chest, 0.016, 0.34, Vector3(side * 0.1, 0.02, -0.128), "leather", Vector3(-0.12, 0, 0))
		strap.scale = Vector3(1.4, 1.0, 0.6)


func _basket(hand: Node3D) -> void:
	_carrying = true
	var basket := Node3D.new()
	basket.position = Vector3(0, -0.12, -0.04)
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


## Sets the facial expression by mood name (see MOODS); eases into it.
func set_expression(mood: String) -> void:
	_expr_target = MOODS.get(mood, MOODS["smile"]).duplicate()


## Raises the near arm in a small greeting or explaining gesture (0..1).
func gesture(amount: float) -> void:
	_gesture = clampf(amount, 0.0, 1.0)


## Call every frame with the current ground speed (m/s). Drives the skeleton.
func animate(delta: float, speed: float, reduced_motion := false) -> void:
	_time += delta
	var walk := clampf(speed / 2.6, 0.0, 1.0)
	if walk > 0.05:
		_phase += delta * (5.0 + speed * 2.2)
	var s := sin(_phase)
	# Legs swing from the hip; the knee bends back on the forward swing.
	for i in 2:
		var dir := 1.0 if i == 0 else -1.0
		var thigh := B.L_THIGH if i == 0 else B.R_THIGH
		_pose(thigh, Vector3(s * 0.55 * walk * dir, 0, 0))
		_pose(thigh + 1, Vector3(-maxf(0.0, -s * dir) * 0.9 * walk - 0.04, 0, 0))
		_pose(thigh + 2, Vector3(maxf(0.0, s * dir) * 0.3 * walk, 0, 0))
	# Arms swing opposite the legs with soft elbows; the right arm may gesture or carry.
	for i in 2:
		var dir := -1.0 if i == 0 else 1.0
		var arm := B.L_ARM if i == 0 else B.R_ARM
		var out := 0.1 if i == 0 else -0.1
		var swing := s * 0.45 * walk * dir
		var arm_x := swing
		var elbow := 0.15 + 0.25 * walk
		if i == 1 and _gesture > 0.01:
			arm_x = lerpf(swing, 0.9 + sin(_time * 3.0) * 0.12, _gesture)
			elbow = lerpf(elbow, 1.0, _gesture)
		elif i == 1 and _carrying:
			arm_x = 0.12
			elbow = 0.55
		_pose(arm, Vector3(arm_x, 0, out))
		_pose(arm + 1, Vector3(elbow, 0, 0))
	var bob := 0.0
	if not reduced_motion:
		bob = absf(s) * 0.035 * walk + sin(_time * 1.8) * 0.005
		_pose(B.SPINE, Vector3(0.05 * walk, s * 0.08 * walk, 0))
		_pose(B.CHEST, Vector3(sin(_time * 1.8) * 0.01, 0, 0))
	_skeleton.set_bone_pose_position(B.HIPS, Vector3(0, 0.8 + bob, 0))
	# Head: gentle idle look-around, or toward a target.
	var yaw := sin(_time * 0.37) * 0.25 * (1.0 - walk)
	var pitch := 0.0
	if _look_target != null:
		var to: Vector3 = (_look_target as Vector3) - _head.global_position
		var local := global_transform.basis.inverse() * to
		yaw = clampf(atan2(-local.x, -local.z), -0.9, 0.9)
		pitch = clampf(atan2(local.y, Vector2(local.x, local.z).length()), -0.4, 0.4)
	_head_yaw = lerp_angle(_head_yaw, yaw, minf(delta * 4.0, 1.0))
	_head_pitch = lerpf(_head_pitch, pitch, minf(delta * 4.0, 1.0))
	_pose(B.NECK, Vector3(_head_pitch * 0.4, _head_yaw * 0.4, 0))
	_pose(B.HEAD, Vector3(_head_pitch * 0.6, _head_yaw * 0.6, 0))
	# Blink every few seconds; open the mouth in time with speech.
	_blink -= delta
	var closed := _blink < 0.0 and _blink > -0.12
	if _blink < -0.12:
		_blink = randf_range(2.0, 5.0)
	for k: String in _expr:
		_expr[k] = lerpf(float(_expr[k]), float(_expr_target[k]), minf(delta * 5.0, 1.0))
	_eyes.scale.y = 0.1 if closed else 1.0 - _expr["squint"] * 0.55
	var open := 0.0 if _talk <= 0.0 else (0.5 + 0.5 * sin(_time * 14.0)) * _talk
	open = maxf(open, _expr["open"] * 0.6)
	_mouth.scale = Vector3(1.0 - open * 0.25, 1.0 + open * 2.2, 1.0)
	_mouth_inside.visible = open > 0.08
	_apply_expression()


## Places the mouth dots on a curve and tilts the brows for the current expression.
func _apply_expression() -> void:
	for dot in _mouth_dots:
		var t: float = dot.get_meta("t")
		var width := 0.03 * (1.0 - float(_expr["narrow"]) * 0.5)
		dot.position = Vector3(t * width, t * t * 0.008 * _expr["curve"], 0)
	for brow in _brows:
		var side: float = brow.get_meta("side")
		brow.position.y = 0.205 + _expr["lift"]
		# Base tilt slopes the outer ends down; positive tilt raises the inner ends.
		brow.rotation.z = side * (0.15 - _expr["tilt"])


func _pose(bone: int, euler: Vector3) -> void:
	_skeleton.set_bone_pose_rotation(bone, Quaternion.from_euler(euler))
