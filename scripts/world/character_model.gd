class_name CharacterModel
extends Node3D
## Low-poly storybook person built from primitives: placeholder for the custom
## protagonist and NPC models the art direction calls for. Faces -Z.

var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _body: Node3D
var _phase := 0.0
var _idle := 0.0


## look keys: skin, hair, hair_style ("short"|"bun"|"long"|"curly"), shirt,
## pants, apron, hat ("straw"|""), height (1.0 = child), build (width scale)
func build(look: Dictionary) -> CharacterModel:
	var h: float = look.get("height", 1.0)
	var w: float = look.get("build", 1.0)
	_body = Node3D.new()
	_body.scale = Vector3.ONE * h
	add_child(_body)
	for side: float in [-1.0, 1.0]:
		var hip := Node3D.new()
		hip.position = Vector3(0.1 * side * w, 0.5, 0)
		_body.add_child(hip)
		MeshKit.box(hip, Vector3(0.13, 0.48, 0.15), Vector3(0, -0.24, 0), look.get("pants", "cloth_blue"))
		MeshKit.box(hip, Vector3(0.14, 0.08, 0.2), Vector3(0, -0.46, -0.03), "dark")
		_legs.append(hip)
	var torso := MeshKit.cylinder(_body, 0.2 * w, 0.25 * w, 0.5, Vector3(0, 0.74, 0), look.get("shirt", "cloth_red"), 8)
	torso.scale = Vector3(1.0, 1.0, 0.75)
	if look.has("skirt"):
		MeshKit.cylinder(_body, 0.24 * w, 0.34 * w, 0.42, Vector3(0, 0.4, 0), look["skirt"], 8)
	if look.has("apron"):
		MeshKit.box(_body, Vector3(0.3 * w, 0.5, 0.04), Vector3(0, 0.55, -0.2 * w), look["apron"])
	for side: float in [-1.0, 1.0]:
		var shoulder := Node3D.new()
		shoulder.position = Vector3(0.27 * side * w, 0.95, 0)
		_body.add_child(shoulder)
		MeshKit.box(shoulder, Vector3(0.1, 0.42, 0.11), Vector3(0, -0.2, 0), look.get("shirt", "cloth_red"))
		MeshKit.sphere(shoulder, 0.06, Vector3(0, -0.43, 0), look.get("skin", "skin_1"), Vector3.ONE, 6, 3)
		_arms.append(shoulder)
	var skin: String = look.get("skin", "skin_1")
	MeshKit.cylinder(_body, 0.06, 0.07, 0.1, Vector3(0, 1.02, 0), skin, 6)
	var head := Node3D.new()
	head.position = Vector3(0, 1.22, 0)
	head.scale = Vector3.ONE * float(look.get("head_scale", 1.0))
	_body.add_child(head)
	MeshKit.sphere(head, 0.2, Vector3.ZERO, skin, Vector3(1.0, 1.05, 1.0), 10, 6)
	if look.has("backpack"):
		MeshKit.box(_body, Vector3(0.34, 0.4, 0.18), Vector3(0, 0.78, 0.25), look["backpack"])
		MeshKit.box(_body, Vector3(0.3, 0.12, 0.2), Vector3(0, 0.98, 0.26), "wood_dark")
		MeshKit.box(_body, Vector3(0.22, 0.14, 0.06), Vector3(0, 0.66, 0.36), "wood_dark")
		for side: float in [-1.0, 1.0]:
			MeshKit.box(_body, Vector3(0.05, 0.42, 0.05), Vector3(side * 0.13, 0.82, -0.17), "wood_dark")
	for side: float in [-1.0, 1.0]:
		MeshKit.sphere(head, 0.025, Vector3(0.07 * side, 0.03, -0.18), "dark", Vector3.ONE, 5, 3)
	var hair: String = look.get("hair", "hair_brown")
	MeshKit.sphere(head, 0.215, Vector3(0, 0.06, 0.03), hair, Vector3(1.0, 0.8, 1.0), 10, 5)
	match look.get("hair_style", "short"):
		"bun":
			MeshKit.sphere(head, 0.1, Vector3(0, 0.2, 0.14), hair, Vector3.ONE, 8, 4)
		"long":
			MeshKit.box(head, Vector3(0.36, 0.34, 0.12), Vector3(0, -0.12, 0.14), hair)
		"curly":
			for a in 6:
				var ang := TAU * a / 6.0
				MeshKit.sphere(head, 0.09, Vector3(cos(ang) * 0.17, 0.11, sin(ang) * 0.17 + 0.02), hair, Vector3.ONE, 6, 3)
		"tousled":
			for a in 7:
				var ang := TAU * a / 7.0
				MeshKit.sphere(head, 0.1, Vector3(cos(ang) * 0.15, 0.14 + 0.03 * sin(a * 2.0), sin(ang) * 0.15 + 0.02), hair, Vector3.ONE, 6, 3)
			MeshKit.sphere(head, 0.09, Vector3(0.05, 0.08, -0.15), hair, Vector3(1.4, 0.6, 0.8), 6, 3)
	if look.get("hat", "") == "straw":
		MeshKit.cylinder(head, 0.34, 0.34, 0.03, Vector3(0, 0.18, 0), "roof_thatch", 12)
		MeshKit.cylinder(head, 0.15, 0.18, 0.14, Vector3(0, 0.25, 0), "roof_thatch", 10)
		MeshKit.cylinder(head, 0.185, 0.185, 0.04, Vector3(0, 0.21, 0), look.get("hat_band", "cloth_green"), 10)
	return self


## Call every frame with the current ground speed (m/s) to swing limbs.
func animate(delta: float, speed: float, reduced_motion := false) -> void:
	var walk := clampf(speed / 3.0, 0.0, 1.0)
	_phase += delta * (4.0 + speed * 2.4) * (1.0 if walk > 0.05 else 0.0)
	_idle += delta
	var swing := sin(_phase) * 0.55 * walk
	if _legs.size() == 2:
		_legs[0].rotation.x = swing
		_legs[1].rotation.x = -swing
		_arms[0].rotation.x = -swing * 0.8
		_arms[1].rotation.x = swing * 0.8
	var bob := 0.0 if reduced_motion else absf(sin(_phase)) * 0.04 * walk + sin(_idle * 1.6) * 0.008
	_body.position.y = bob


## A small wave or gesture used during conversation.
func gesture(amount: float) -> void:
	if _arms.size() == 2:
		_arms[1].rotation.z = amount * 2.2
