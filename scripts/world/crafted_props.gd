class_name CraftedProps
extends RefCounted
## Small hand-built props for the bread and sheepfold stories, made from
## simple shapes in the storybook palette (no imported files). Each returns
## its root node, faces -Z like the packs' props, and blocks the player.


## A wooden kneading trough on splayed legs, a risen mound of dough inside,
## flour dusted on the rim and a cloth folded over one end (the Leaven).
static func kneading_trough(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "KneadingTrough", pos, rot_y)
	MeshKit.box(r, Vector3(1.3, 0.08, 0.58), Vector3(0, 0.62, 0), "wood")
	for side: float in [-1.0, 1.0]:
		# Sloped long sides with a lighter rim, and end boards bound with iron.
		var board := MeshKit.box(r, Vector3(1.38, 0.22, 0.06), Vector3(0, 0.75, side * 0.31), "wood")
		board.rotation.x = side * 0.25
		var rim := MeshKit.box(r, Vector3(1.42, 0.04, 0.09), Vector3(0, 0.865, side * 0.345), "wood_light")
		rim.rotation.x = side * 0.25
		MeshKit.box(r, Vector3(0.07, 0.24, 0.72), Vector3(side * 0.67, 0.75, 0), "wood_dark")
		MeshKit.box(r, Vector3(0.075, 0.04, 0.74), Vector3(side * 0.67, 0.7, 0), "dark")
		for z: float in [-0.21, 0.21]:
			var leg := MeshKit.box(r, Vector3(0.08, 0.66, 0.08), Vector3(side * 0.5, 0.31, z), "wood_dark")
			leg.rotation.z = side * 0.12
		MeshKit.box(r, Vector3(0.06, 0.05, 0.44), Vector3(side * 0.53, 0.18, 0), "wood_dark")
	MeshKit.sphere(r, 0.42, Vector3(0.12, 0.78, 0), "dough", Vector3(1.12, 0.5, 0.6), 20, 10)
	MeshKit.sphere(r, 0.18, Vector3(-0.3, 0.84, 0.03), "dough", Vector3(1.0, 0.7, 0.9), 14, 7)
	MeshKit.sphere(r, 0.09, Vector3(0.36, 0.92, -0.06), "flour", Vector3(1.4, 0.25, 1.0), 8, 4)
	for x: float in [-0.2, 0.42]:
		MeshKit.box(r, Vector3(0.16, 0.012, 0.06), Vector3(x, 0.888, 0.35), "flour")
	var cloth := MeshKit.box(r, Vector3(0.26, 0.03, 0.74), Vector3(-0.56, 0.89, 0), "cloth_blue")
	cloth.rotation.z = 0.1
	MeshKit.box(r, Vector3(0.26, 0.2, 0.03), Vector3(-0.56, 0.79, 0.375), "cloth_blue")
	MeshKit.solid(r, Vector3(1.45, 0.9, 0.75), Vector3(0, 0.45, 0))
	return r


## A round woven basket heaped with scored bread rolls, a cloth tucked in.
static func bread_basket(parent: Node3D, pos: Vector3, rot_y := 0.0, rolls := 7) -> Node3D:
	var r := _root(parent, "BreadBasket", pos, rot_y)
	MeshKit.cylinder(r, 0.42, 0.33, 0.32, Vector3(0, 0.16, 0), "roof_thatch", 20)
	for y: float in [0.09, 0.2]:
		MeshKit.cylinder(r, 0.39 + y * 0.12, 0.39 + y * 0.12, 0.03, Vector3(0, y, 0), "wood", 20)
	MeshKit.cylinder(r, 0.445, 0.445, 0.05, Vector3(0, 0.32, 0), "wood", 20)
	var spots := [Vector3(0, 0.42, 0), Vector3(0.2, 0.36, 0.08), Vector3(-0.18, 0.37, 0.12), Vector3(0.05, 0.37, -0.22),
		Vector3(-0.16, 0.36, -0.15), Vector3(0.22, 0.35, -0.12), Vector3(0.0, 0.36, 0.24)]
	for i in mini(rolls, spots.size()):
		var p: Vector3 = spots[i]
		var yaw := i * 1.3
		var roll := MeshKit.sphere(r, 0.13, p, "bread", Vector3(1.25, 0.68, 0.9), 14, 7)
		roll.rotation.y = yaw
		var score := MeshKit.box(r, Vector3(0.16, 0.01, 0.022), p + Vector3(0, 0.086, 0), "dough")
		score.rotation.y = yaw
	var cloth := MeshKit.sphere(r, 0.22, Vector3(-0.3, 0.36, 0.22), "cloth_red", Vector3(0.9, 0.35, 0.7), 12, 6)
	cloth.rotation.z = 0.6
	return r


## A sheepfold gate between two stout posts: three rails, a diagonal brace,
## iron hinges and a latch (the Good Shepherd: "I am the gate for the sheep").
static func fold_gate(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "FoldGate", pos, rot_y)
	for x: float in [-0.8, 0.8]:
		MeshKit.box(r, Vector3(0.17, 1.3, 0.17), Vector3(x, 0.65, 0), "wood_dark")
		MeshKit.cylinder(r, 0.06, 0.11, 0.12, Vector3(x, 1.36, 0), "wood_dark", 8)
	for y: float in [0.3, 0.65, 1.0]:
		MeshKit.box(r, Vector3(1.44, 0.1, 0.06), Vector3(0, y, 0), "wood")
	for x: float in [-0.69, 0.69]:
		MeshKit.box(r, Vector3(0.08, 0.86, 0.065), Vector3(x, 0.65, 0), "wood")
	var brace := MeshKit.box(r, Vector3(1.5, 0.09, 0.05), Vector3(0, 0.65, 0.045), "wood_light")
	brace.rotation.z = 0.46
	for y: float in [0.3, 1.0]:
		MeshKit.box(r, Vector3(0.18, 0.05, 0.08), Vector3(-0.68, y, 0.0), "dark")
	MeshKit.box(r, Vector3(0.14, 0.05, 0.08), Vector3(0.72, 0.65, -0.05), "dark")
	MeshKit.solid(r, Vector3(1.8, 1.3, 0.3), Vector3(0, 0.65, 0))
	return r


static func _root(parent: Node3D, node_name: String, pos: Vector3, rot_y: float) -> Node3D:
	var r := Node3D.new()
	r.name = node_name
	r.position = pos
	r.rotation.y = rot_y
	parent.add_child(r)
	return r
