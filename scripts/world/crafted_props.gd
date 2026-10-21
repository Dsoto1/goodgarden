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


## A letterbox on a post at the home path, where the letters arrive.
static func letterbox(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "Letterbox", pos, rot_y)
	MeshKit.box(r, Vector3(0.1, 1.05, 0.1), Vector3(0, 0.52, 0), "wood_dark")
	MeshKit.box(r, Vector3(0.34, 0.26, 0.42), Vector3(0, 1.15, 0), "cloth_red")
	var lid := MeshKit.cylinder(r, 0.17, 0.17, 0.42, Vector3(0, 1.28, 0), "cloth_red", 12)
	lid.rotation.x = PI / 2.0
	MeshKit.box(r, Vector3(0.2, 0.03, 0.02), Vector3(0, 1.2, -0.215), "dark")
	MeshKit.box(r, Vector3(0.02, 0.18, 0.04), Vector3(0.19, 1.3, 0.1), "gold")
	MeshKit.box(r, Vector3(0.1, 0.07, 0.04), Vector3(0.19, 1.4, 0.12), "gold")
	MeshKit.solid(r, Vector3(0.3, 1.3, 0.3), Vector3(0, 0.65, 0))
	return r


## Split logs stacked between two stakes against a wall.
static func woodpile(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "Woodpile", pos, rot_y)
	for x: float in [-0.95, 0.95]:
		MeshKit.box(r, Vector3(0.08, 1.1, 0.08), Vector3(x, 0.55, 0), "wood_dark")
	for row in 4:
		for i in 7:
			if i == 6 and row % 2 == 1:
				continue
			var piece := MeshKit.cylinder(r, 0.12, 0.12, 0.6, Vector3(-0.78 + i * 0.26 + (row % 2) * 0.12, 0.13 + row * 0.22, 0), "wood_light" if (i + row) % 3 else "wood", 7)
			piece.rotation.x = PI / 2.0
	var roof := MeshKit.box(r, Vector3(2.1, 0.05, 0.85), Vector3(0, 1.12, 0.05), "roof_thatch")
	roof.rotation.x = -0.15
	MeshKit.solid(r, Vector3(2.0, 1.1, 0.7), Vector3(0, 0.55, 0))
	return r


## A sawn stump with an axe resting in it and a few split pieces nearby.
static func chopping_block(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "ChoppingBlock", pos, rot_y)
	MeshKit.cylinder(r, 0.26, 0.3, 0.42, Vector3(0, 0.21, 0), "trunk", 10)
	MeshKit.cylinder(r, 0.25, 0.25, 0.02, Vector3(0, 0.43, 0), "wood_light", 10)
	var handle := MeshKit.box(r, Vector3(0.05, 0.62, 0.05), Vector3(0.12, 0.66, 0), "wood")
	handle.rotation.z = -0.5
	MeshKit.box(r, Vector3(0.18, 0.05, 0.1), Vector3(0.02, 0.45, 0), "stone_dark")
	for i in 3:
		var piece := MeshKit.box(r, Vector3(0.1, 0.1, 0.42), Vector3(0.45 + i * 0.05, 0.05 + i * 0.1, -0.15 + i * 0.12), "wood_light")
		piece.rotation.y = 0.4 + i * 0.5
	MeshKit.solid(r, Vector3(0.6, 0.5, 0.6), Vector3(0, 0.25, 0))
	return r


## A washing line between two posts with clothes pegged out to dry.
static func clothesline(parent: Node3D, a: Vector3, b: Vector3) -> Node3D:
	var span := b - a
	var r := _root(parent, "Clothesline", a, atan2(-span.z, span.x))
	var length := Vector2(span.x, span.z).length()
	for x: float in [0.0, length]:
		MeshKit.box(r, Vector3(0.09, 1.9, 0.09), Vector3(x, 0.95, 0), "wood_dark")
		MeshKit.box(r, Vector3(0.09, 0.07, 0.5), Vector3(x, 1.8, 0), "wood_dark")
	for z: float in [-0.18, 0.18]:
		MeshKit.box(r, Vector3(length, 0.015, 0.015), Vector3(length / 2.0, 1.78, z), "white")
	var clothes := [["cloth_blue", Vector3(0.6, 0.7, 0.02)], ["white", Vector3(0.5, 0.45, 0.02)], ["cloth_red", Vector3(0.4, 0.55, 0.02)],
		["cloth_cream", Vector3(0.7, 0.5, 0.02)], ["cloth_green", Vector3(0.45, 0.6, 0.02)]]
	var x := 0.5
	for i in clothes.size():
		var size: Vector3 = clothes[i][1]
		if x + size.x > length - 0.3:
			break
		var cloth := MeshKit.box(r, size, Vector3(x + size.x / 2.0, 1.78 - size.y / 2.0, -0.18 if i % 2 == 0 else 0.18), clothes[i][0])
		cloth.rotation.x = 0.06
		x += size.x + 0.25
	for x2: float in [0.0, length]:
		MeshKit.solid(r, Vector3(0.25, 1.9, 0.25), Vector3(x2, 0.95, 0))
	return r


## Straw bee skeps on a low plank stand, the way old gardens kept bees.
static func bee_skeps(parent: Node3D, pos: Vector3, rot_y := 0.0, count := 3) -> Node3D:
	var r := _root(parent, "BeeSkeps", pos, rot_y)
	MeshKit.box(r, Vector3(0.75 * count + 0.2, 0.06, 0.7), Vector3(0, 0.42, 0), "wood")
	for x: float in [-(0.75 * count) / 2.0 + 0.1, (0.75 * count) / 2.0 - 0.1]:
		MeshKit.box(r, Vector3(0.08, 0.4, 0.6), Vector3(x, 0.2, 0), "wood_dark")
	for i in count:
		var x := (i - (count - 1) / 2.0) * 0.75
		MeshKit.sphere(r, 0.3, Vector3(x, 0.66, 0), "roof_thatch", Vector3(1.0, 1.15, 1.0), 14, 8)
		for k in 3:
			MeshKit.cylinder(r, 0.3 - k * 0.05, 0.3 - k * 0.05, 0.03, Vector3(x, 0.55 + k * 0.12, 0), "wood_light", 14)
		MeshKit.box(r, Vector3(0.12, 0.06, 0.04), Vector3(x, 0.5, -0.29), "dark")
	MeshKit.solid(r, Vector3(0.75 * count + 0.2, 1.0, 0.7), Vector3(0, 0.5, 0))
	return r


## A tin watering can with a long spout.
static func watering_can(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "WateringCan", pos, rot_y)
	MeshKit.cylinder(r, 0.13, 0.15, 0.28, Vector3(0, 0.14, 0), "stone", 12)
	MeshKit.cylinder(r, 0.135, 0.135, 0.03, Vector3(0, 0.27, 0), "stone_dark", 12)
	var spout := MeshKit.cylinder(r, 0.02, 0.035, 0.36, Vector3(0, 0.22, -0.24), "stone", 6)
	spout.rotation.x = -0.9
	MeshKit.cylinder(r, 0.05, 0.03, 0.04, Vector3(0, 0.34, -0.37), "stone_dark", 8).rotation.x = -0.9
	var handle := MeshKit.cylinder(r, 0.12, 0.12, 0.025, Vector3(0, 0.34, 0.03), "stone_dark", 12)
	handle.rotation.z = PI / 2.0
	handle.scale = Vector3(1.0, 1.0, 0.25)
	return r


## A signpost with one arm per destination. Each arm is [label, yaw] where
## yaw points the arm (0 = -Z). The words are real text, for reading.
static func signpost(parent: Node3D, pos: Vector3, arms: Array) -> Node3D:
	var r := _root(parent, "Signpost", pos, 0.0)
	MeshKit.box(r, Vector3(0.12, 2.1, 0.12), Vector3(0, 1.05, 0), "wood_dark")
	MeshKit.cone(r, 0.1, 0.14, Vector3(0, 2.17, 0), "wood_dark", 4)
	for i in arms.size():
		var arm := Node3D.new()
		arm.position.y = 1.85 - i * 0.32
		arm.rotation.y = float(arms[i][1])
		r.add_child(arm)
		MeshKit.box(arm, Vector3(0.05, 0.24, 1.0), Vector3(0, 0, -0.55), "wood_light")
		MeshKit.box(arm, Vector3(0.05, 0.17, 0.17), Vector3(0, 0, -1.05), "wood_light").rotation.x = PI / 4.0
		for side: float in [-1.0, 1.0]:
			var label := Label3D.new()
			label.text = str(arms[i][0]) # Label3D translates its text itself
			label.font = UiStyle.font()
			label.font_size = 64
			label.pixel_size = 0.0034
			label.modulate = Color("3b3430")
			label.outline_size = 0
			label.position = Vector3(side * 0.03, 0, -0.55)
			label.rotation.y = side * PI / 2.0
			arm.add_child(label)
	MeshKit.solid(r, Vector3(0.3, 2.0, 0.3), Vector3(0, 1.0, 0))
	return r


## A small plank jetty reaching from the bank over the water, on posts.
static func jetty(parent: Node3D, pos: Vector3, rot_y := 0.0, length := 3.0) -> Node3D:
	var r := _root(parent, "Jetty", pos, rot_y)
	var planks := int(length / 0.3)
	for i in planks:
		MeshKit.box(r, Vector3(1.3, 0.06, 0.27), Vector3(0, 0.18, -0.15 - i * 0.3), "wood_light" if i % 3 else "wood")
	for z: float in [-0.2, -length / 2.0, -length + 0.2]:
		for x: float in [-0.6, 0.6]:
			MeshKit.cylinder(r, 0.07, 0.08, 1.1, Vector3(x, -0.3, z), "wood_dark", 6)
	MeshKit.cylinder(r, 0.07, 0.07, 0.5, Vector3(0.6, 0.45, -length + 0.2), "wood_dark", 6)
	return r


## A little wooden rowboat with its oars shipped.
static func rowboat(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "Rowboat", pos, rot_y)
	var hull := MeshKit.sphere(r, 1.0, Vector3(0, 0.12, 0), "wood", Vector3(0.55, 0.3, 1.45), 14, 7)
	hull.name = "Hull"
	MeshKit.sphere(r, 1.0, Vector3(0, 0.2, 0), "wood_dark", Vector3(0.47, 0.18, 1.32), 14, 7)
	for z: float in [-0.5, 0.45]:
		MeshKit.box(r, Vector3(0.9, 0.05, 0.22), Vector3(0, 0.3, z), "wood_light")
	for side: float in [-1.0, 1.0]:
		var oar := MeshKit.box(r, Vector3(0.05, 0.04, 1.8), Vector3(side * 0.3, 0.36, 0.1), "wood_light")
		oar.rotation.y = side * 0.12
		MeshKit.box(r, Vector3(0.14, 0.02, 0.36), Vector3(side * 0.36, 0.36, -0.75), "wood_light")
	return r


## A round hay bale, lying on its side.
static func hay_bale(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "HayBale", pos, rot_y)
	var bale := MeshKit.cylinder(r, 0.55, 0.55, 1.0, Vector3(0, 0.55, 0), "roof_thatch", 14)
	bale.rotation.z = PI / 2.0
	for x: float in [-0.25, 0.25]:
		var band := MeshKit.cylinder(r, 0.56, 0.56, 0.04, Vector3(x, 0.55, 0), "cloth_tan", 14)
		band.rotation.z = PI / 2.0
	MeshKit.solid(r, Vector3(1.0, 1.1, 1.1), Vector3(0, 0.55, 0))
	return r


## A tall round haystack, thatched to shed the rain, with a pole up the middle.
static func haystack(parent: Node3D, pos: Vector3) -> Node3D:
	var r := _root(parent, "Haystack", pos, 0.0)
	MeshKit.cylinder(r, 1.05, 1.15, 1.3, Vector3(0, 0.65, 0), "roof_thatch", 14)
	MeshKit.cone(r, 1.12, 1.4, Vector3(0, 2.0, 0), "roof_thatch", 14)
	MeshKit.cylinder(r, 0.04, 0.04, 0.6, Vector3(0, 2.9, 0), "wood_dark", 6)
	MeshKit.solid(r, Vector3(2.2, 2.4, 2.2), Vector3(0, 1.2, 0))
	return r


## A long wooden water trough for the sheep.
static func water_trough(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "WaterTrough", pos, rot_y)
	MeshKit.box(r, Vector3(1.6, 0.06, 0.5), Vector3(0, 0.12, 0), "wood")
	for side: float in [-1.0, 1.0]:
		MeshKit.box(r, Vector3(1.6, 0.35, 0.06), Vector3(0, 0.3, side * 0.25), "wood")
		MeshKit.box(r, Vector3(0.06, 0.35, 0.56), Vector3(side * 0.8, 0.3, 0), "wood_dark")
		MeshKit.box(r, Vector3(0.1, 0.12, 0.6), Vector3(side * 0.6, 0.06, 0), "wood_dark")
	MeshKit.box(r, Vector3(1.48, 0.02, 0.42), Vector3(0, 0.4, 0), "water")
	MeshKit.solid(r, Vector3(1.7, 0.5, 0.6), Vector3(0, 0.25, 0))
	return r


## A two-wheeled hand cart loaded with sacks of flour.
static func hand_cart(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "HandCart", pos, rot_y)
	MeshKit.box(r, Vector3(1.0, 0.06, 1.4), Vector3(0, 0.55, 0), "wood")
	for side: float in [-1.0, 1.0]:
		MeshKit.box(r, Vector3(0.05, 0.28, 1.4), Vector3(side * 0.5, 0.72, 0), "wood")
		var wheel := MeshKit.cylinder(r, 0.42, 0.42, 0.07, Vector3(side * 0.6, 0.42, 0.15), "wood_dark", 12)
		wheel.rotation.z = PI / 2.0
		var hub := MeshKit.cylinder(r, 0.08, 0.08, 0.1, Vector3(side * 0.62, 0.42, 0.15), "dark", 8)
		hub.rotation.z = PI / 2.0
		var shaft := MeshKit.box(r, Vector3(0.06, 0.06, 1.2), Vector3(side * 0.35, 0.5, -1.15), "wood_dark")
		shaft.rotation.x = -0.25
	MeshKit.box(r, Vector3(0.76, 0.05, 0.05), Vector3(0, 0.36, -1.7), "wood_dark")
	for p: Vector3 in [Vector3(-0.2, 0.82, 0.3), Vector3(0.22, 0.82, 0.25), Vector3(0.0, 0.82, -0.3), Vector3(0.05, 1.12, 0.05)]:
		MeshKit.sphere(r, 0.26, p, "flour", Vector3(1.0, 0.85, 1.25), 10, 6)
	MeshKit.solid(r, Vector3(1.4, 1.1, 2.0), Vector3(0, 0.55, -0.2))
	return r


## A stone birdbath on a pedestal, with a little water and a visiting bird.
static func birdbath(parent: Node3D, pos: Vector3) -> Node3D:
	var r := _root(parent, "Birdbath", pos, 0.0)
	MeshKit.cylinder(r, 0.25, 0.3, 0.12, Vector3(0, 0.06, 0), "stone", 10)
	MeshKit.cylinder(r, 0.1, 0.13, 0.7, Vector3(0, 0.45, 0), "stone", 10)
	MeshKit.cylinder(r, 0.45, 0.2, 0.14, Vector3(0, 0.86, 0), "stone", 14)
	MeshKit.cylinder(r, 0.38, 0.38, 0.02, Vector3(0, 0.92, 0), "water", 14)
	MeshKit.sphere(r, 0.06, Vector3(0.36, 1.0, 0.05), "cloth_blue", Vector3(1.4, 1.0, 1.0), 8, 4)
	MeshKit.sphere(r, 0.04, Vector3(0.3, 1.06, 0.05), "cloth_blue", Vector3.ONE, 6, 3)
	MeshKit.cone(r, 0.015, 0.05, Vector3(0.25, 1.06, 0.05), "flower_yellow", 4).rotation.z = PI / 2.0
	MeshKit.solid(r, Vector3(0.9, 1.0, 0.9), Vector3(0, 0.5, 0))
	return r


## A clay flower pot with a little mound of leaves and blooms.
static func flower_pot(parent: Node3D, pos: Vector3, flower := "flower_pink", size := 1.0) -> Node3D:
	var r := _root(parent, "FlowerPot", pos, 0.0)
	r.scale = Vector3.ONE * size
	MeshKit.cylinder(r, 0.2, 0.15, 0.32, Vector3(0, 0.16, 0), "roof_red", 10)
	MeshKit.cylinder(r, 0.23, 0.23, 0.06, Vector3(0, 0.32, 0), "roof_red", 10)
	MeshKit.sphere(r, 0.22, Vector3(0, 0.42, 0), "leaf", Vector3(1.0, 0.7, 1.0), 9, 5)
	for i in 5:
		var a := TAU * i / 5.0
		MeshKit.sphere(r, 0.055, Vector3(cos(a) * 0.13, 0.52 + (i % 2) * 0.04, sin(a) * 0.13), flower, Vector3.ONE, 6, 3)
	return r


## A friendly scarecrow on a cross of poles: straw hat, patched shirt, a
## sack face with a stitched smile.
static func scarecrow(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "Scarecrow", pos, rot_y)
	MeshKit.box(r, Vector3(0.08, 1.9, 0.08), Vector3(0, 0.95, 0), "wood_dark")
	MeshKit.box(r, Vector3(1.3, 0.07, 0.07), Vector3(0, 1.45, 0), "wood_dark")
	var shirt := MeshKit.box(r, Vector3(0.5, 0.6, 0.26), Vector3(0, 1.3, 0), "cloth_blue")
	shirt.rotation.z = 0.04
	MeshKit.box(r, Vector3(0.14, 0.14, 0.02), Vector3(0.1, 1.38, -0.135), "cloth_red")
	for side: float in [-1.0, 1.0]:
		MeshKit.box(r, Vector3(0.36, 0.16, 0.18), Vector3(side * 0.42, 1.45, 0), "cloth_blue")
		MeshKit.sphere(r, 0.07, Vector3(side * 0.64, 1.42, 0), "roof_thatch", Vector3(1.3, 1.0, 1.0), 6, 3)
	MeshKit.box(r, Vector3(0.5, 0.06, 0.28), Vector3(0, 1.0, 0), "cloth_brown")
	MeshKit.sphere(r, 0.06, Vector3(0, 0.92, 0), "roof_thatch", Vector3(2.6, 1.0, 1.4), 6, 3)
	MeshKit.sphere(r, 0.17, Vector3(0, 1.78, 0), "cloth_tan", Vector3(1.0, 1.05, 0.95), 10, 6)
	for side: float in [-1.0, 1.0]:
		MeshKit.box(r, Vector3(0.05, 0.05, 0.02), Vector3(side * 0.06, 1.82, -0.16), "dark")
	for i in 5:
		MeshKit.box(r, Vector3(0.025, 0.012, 0.02), Vector3(-0.06 + i * 0.03, 1.72 - absf(i - 2) * -0.008, -0.165), "dark")
	MeshKit.cylinder(r, 0.3, 0.3, 0.03, Vector3(0, 1.9, 0), "roof_thatch", 12)
	MeshKit.cylinder(r, 0.13, 0.16, 0.14, Vector3(0, 1.98, 0), "roof_thatch", 10)
	MeshKit.solid(r, Vector3(0.4, 1.9, 0.4), Vector3(0, 0.95, 0))
	return r


## A net hung to dry on a frame of poles, a fish creel and a coil of rope:
## the fishermen's work by the river.
static func net_rack(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "NetRack", pos, rot_y)
	for x: float in [-0.9, 0.9]:
		MeshKit.box(r, Vector3(0.08, 1.6, 0.08), Vector3(x, 0.8, 0), "wood_dark")
	MeshKit.box(r, Vector3(2.0, 0.06, 0.06), Vector3(0, 1.58, 0), "wood")
	# The net: a slack mesh of cords sagging from the pole.
	for i in 9:
		var x := -0.8 + i * 0.2
		var cord := MeshKit.box(r, Vector3(0.015, 1.1, 0.015), Vector3(x, 1.02, 0.0), "cloth_tan")
		cord.rotation.z = (i - 4) * 0.02
	for k in 6:
		var y := 1.5 - k * 0.19
		var sag := 0.05 * sin(k * 0.6)
		MeshKit.box(r, Vector3(1.6 - k * 0.04, 0.015, 0.015), Vector3(0, y - sag, 0.0), "cloth_tan")
	for i in 4:
		MeshKit.sphere(r, 0.04, Vector3(-0.6 + i * 0.4, 0.46, 0.0), "cloth_red", Vector3.ONE, 6, 3)
	MeshKit.solid(r, Vector3(2.0, 1.6, 0.3), Vector3(0, 0.8, 0))
	return r


## A lidded fish creel and a coiled rope, to set on a jetty or the bank.
static func creel_and_rope(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "CreelAndRope", pos, rot_y)
	MeshKit.box(r, Vector3(0.42, 0.34, 0.3), Vector3(0, 0.17, 0), "roof_thatch")
	MeshKit.box(r, Vector3(0.44, 0.05, 0.32), Vector3(0, 0.36, 0), "wood")
	MeshKit.box(r, Vector3(0.04, 0.3, 0.32), Vector3(0.18, 0.5, 0), "leather").rotation.z = -0.3
	for k in 3:
		MeshKit.cylinder(r, 0.2 - k * 0.04, 0.2 - k * 0.04, 0.05, Vector3(0.6, 0.03 + k * 0.05, 0.05), "cloth_tan", 12)
	return r


## A market stall of bread: baskets of rolls and long loaves on the counter.
static func bread_stall_goods(parent: Node3D, pos: Vector3, rot_y := 0.0) -> Node3D:
	var r := _root(parent, "BreadGoods", pos, rot_y)
	for x: float in [-0.55, 0.55]:
		bread_basket(r, Vector3(x, 0, 0.08), x).scale = Vector3.ONE * 0.6
	for i in 3:
		var loaf := MeshKit.capsule(r, 0.08, 0.42, Vector3(-0.1 + i * 0.1, 0.07, -0.2), "bread", Vector3(0, 0, PI / 2.0))
		loaf.rotation.y = 0.3 - i * 0.1
		loaf.scale = Vector3(1.0, 1.0, 0.85)
	MeshKit.box(r, Vector3(0.36, 0.03, 0.22), Vector3(0, 0.015, 0.25), "wood_light")
	return r
