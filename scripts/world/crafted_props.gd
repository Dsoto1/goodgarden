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
## Open, the leaf swings back on its hinge (left post) and only the posts are
## solid, so children can walk through.
static func fold_gate(parent: Node3D, pos: Vector3, rot_y := 0.0, open := false) -> Node3D:
	var r := _root(parent, "FoldGate", pos, rot_y)
	for x: float in [-0.8, 0.8]:
		MeshKit.box(r, Vector3(0.17, 1.3, 0.17), Vector3(x, 0.65, 0), "wood_dark")
		MeshKit.cylinder(r, 0.06, 0.11, 0.12, Vector3(x, 1.36, 0), "wood_dark", 8)
	var leaf := Node3D.new()
	leaf.name = "Leaf"
	leaf.position = Vector3(-0.8, 0, 0)
	leaf.rotation.y = -1.75 if open else 0.0 # swung in, against the inside of the fence
	r.add_child(leaf)
	for y: float in [0.3, 0.65, 1.0]:
		MeshKit.box(leaf, Vector3(1.44, 0.1, 0.06), Vector3(0.8, y, 0), "wood")
	for x: float in [-0.69, 0.69]:
		MeshKit.box(leaf, Vector3(0.08, 0.86, 0.065), Vector3(0.8 + x, 0.65, 0), "wood")
	var brace := MeshKit.box(leaf, Vector3(1.5, 0.09, 0.05), Vector3(0.8, 0.65, 0.045), "wood_light")
	brace.rotation.z = 0.46
	for y: float in [0.3, 1.0]:
		MeshKit.box(leaf, Vector3(0.18, 0.05, 0.08), Vector3(0.12, y, 0.0), "dark")
	MeshKit.box(leaf, Vector3(0.14, 0.05, 0.08), Vector3(1.52, 0.65, -0.05), "dark")
	if open:
		for x: float in [-0.8, 0.8]:
			MeshKit.solid(r, Vector3(0.2, 1.3, 0.2), Vector3(x, 0.65, 0))
	else:
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
## A little painted name sign on a stake, the child's own lettering ("hen"),
## readable from both sides.
static func name_sign(parent: Node3D, pos: Vector3, rot_y: float, word: String) -> Node3D:
	var r := _root(parent, "NameSign_" + word, pos, rot_y)
	MeshKit.box(r, Vector3(0.08, 0.9, 0.08), Vector3(0, 0.45, 0), "wood_dark")
	MeshKit.box(r, Vector3(0.8, 0.36, 0.05), Vector3(0, 0.92, 0), "wood_light")
	for side: float in [-1.0, 1.0]:
		var label := Label3D.new()
		label.text = word
		label.font = UiStyle.font()
		label.font_size = 96
		label.pixel_size = 0.0042
		label.modulate = Color("8a2f26")
		label.outline_size = 0
		label.position = Vector3(0, 0.9, side * 0.03)
		label.rotation.y = 0.0 if side > 0 else PI
		r.add_child(label)
	return r


## Puts up the name signs the child has made (the `fact` lists the words,
## "home.signs" by default) at this region's spots: {word: [position, rot_y]}.
## Safe to call again.
static func sync_name_signs(holder: Node3D, spots: Dictionary, fact := "home.signs") -> void:
	var made: Variant = WorldState.get_fact(fact, [])
	for word: String in spots:
		var have := holder.get_node_or_null("NameSign_" + word)
		var want: bool = made is Array and word in made
		if want and have == null:
			name_sign(holder, spots[word][0], spots[word][1], word)
		elif not want and have:
			have.free()


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
	# The water sits clearly above the bowl's top (0.93), not level with it,
	# or the two surfaces flicker against each other.
	MeshKit.cylinder(r, 0.38, 0.38, 0.02, Vector3(0, 0.945, 0), "water", 14)
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
	# Along the front, left to right: a basket of buns, jars of jam, a bowl of
	# eggs and a bowl of nuts (the things the child labels).
	bread_basket(r, Vector3(-0.58, 0, 0.08), -0.5).scale = Vector3.ONE * 0.6
	for k in 3:
		var jar := Vector3(-0.24 + (k % 2) * 0.1, 0, 0.1 - (k / 2) * 0.1)
		MeshKit.cylinder(r, 0.045, 0.045, 0.11, jar + Vector3(0, 0.055, 0), "cloth_red", 8)
		MeshKit.cylinder(r, 0.05, 0.05, 0.02, jar + Vector3(0, 0.12, 0), "cloth_cream", 8)
	for bowl: Array in [[Vector3(0.2, 0, 0.1), "white"], [Vector3(0.55, 0, 0.1), "trunk"]]:
		MeshKit.cylinder(r, 0.13, 0.09, 0.07, bowl[0] + Vector3(0, 0.035, 0), "wood_light", 10)
		for k in 5:
			var a := TAU * k / 5.0
			MeshKit.sphere(r, 0.035, bowl[0] + Vector3(cos(a) * 0.06, 0.08, sin(a) * 0.05), bowl[1], Vector3(1, 1.25 if bowl[1] == "white" else 1.0, 1), 6, 3)
	for i in 3:
		var loaf := MeshKit.capsule(r, 0.08, 0.42, Vector3(-0.1 + i * 0.1, 0.07, -0.2), "bread", Vector3(0, 0, PI / 2.0))
		loaf.rotation.y = 0.3 - i * 0.1
		loaf.scale = Vector3(1.0, 1.0, 0.85)
	MeshKit.box(r, Vector3(0.36, 0.03, 0.22), Vector3(0, 0.015, 0.25), "wood_light")
	return r


## A tall bookcase full of books: four shelves of coloured spines, some
## leaning, one lying flat. Faces -Z.
static func bookcase(parent: Node3D, pos: Vector3, rot_y := 0.0, seed_value := 1) -> Node3D:
	var r := _root(parent, "Bookcase", pos, rot_y)
	MeshKit.box(r, Vector3(1.3, 1.9, 0.06), Vector3(0, 0.95, 0.17), "wood_dark")
	for x: float in [-0.62, 0.62]:
		MeshKit.box(r, Vector3(0.06, 1.9, 0.4), Vector3(x, 0.95, 0), "wood_dark")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var spines := ["cloth_red", "cloth_blue", "cloth_green", "cloth_gold", "cloth_cream", "cloth_purple", "leather", "cloth_tan"]
	for row in 4:
		var y := 0.06 + row * 0.46
		MeshKit.box(r, Vector3(1.24, 0.04, 0.38), Vector3(0, y, 0), "wood")
		var x := -0.56
		while x < 0.5:
			var w := rng.randf_range(0.04, 0.08)
			var h := rng.randf_range(0.26, 0.38)
			if rng.randf() < 0.08 and x < 0.3:
				# A book lying flat.
				MeshKit.box(r, Vector3(0.24, w, 0.26), Vector3(x + 0.12, y + 0.02 + w / 2.0, 0.02), spines[rng.randi() % spines.size()])
				x += 0.27
				continue
			var book := MeshKit.box(r, Vector3(w, h, 0.26), Vector3(x + w / 2.0, y + 0.02 + h / 2.0, 0.02), spines[rng.randi() % spines.size()])
			if rng.randf() < 0.1:
				book.rotation.z = -0.25
			x += w + 0.008
	MeshKit.box(r, Vector3(1.3, 0.05, 0.42), Vector3(0, 1.92, 0), "wood_dark")
	MeshKit.solid(r, Vector3(1.3, 1.9, 0.45), Vector3(0, 0.95, 0))
	return r


## A clump of reeds at the water's edge: slender blades leaning every way,
## a few with brown cattail heads. Sized by `spread` (metres across).
static func reeds(parent: Node3D, pos: Vector3, seed_value: int, spread := 0.9) -> Node3D:
	var r := _root(parent, "Reeds", pos, 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var greens := ["leaf", "leaf_light", "sprout", "grass_dark"]
	for i in rng.randi_range(9, 14):
		var at := Vector3(rng.randf_range(-spread, spread) * 0.5, 0, rng.randf_range(-spread, spread) * 0.5)
		var h := rng.randf_range(0.7, 1.35)
		var blade := MeshKit.box(r, Vector3(0.035, h, 0.02), at + Vector3(0, h / 2.0 - 0.05, 0), greens[rng.randi() % greens.size()])
		blade.rotation = Vector3(rng.randf_range(-0.22, 0.22), rng.randf() * TAU, rng.randf_range(-0.22, 0.22))
		if rng.randf() < 0.3:
			var head := MeshKit.capsule(r, 0.035, 0.22, Vector3.ZERO, "leather")
			head.position = blade.position + blade.transform.basis * Vector3(0, h / 2.0, 0)
			head.rotation = blade.rotation
	return r


## One flat, rounded stepping stone, its top just above the water.
static func stepping_stone(parent: Node3D, pos: Vector3, seed_value: int) -> Node3D:
	var r := _root(parent, "SteppingStone", pos, float(seed_value) * 1.7)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var w := rng.randf_range(0.5, 0.62)
	var d := w * rng.randf_range(0.75, 0.95)
	MeshKit.sphere(r, 0.5, Vector3(0, -0.04, 0), "stone_dark", Vector3(w * 1.08, 0.3, d * 1.08), 10, 5)
	MeshKit.sphere(r, 0.5, Vector3(0, 0.0, 0), "stone", Vector3(w, 0.22, d), 12, 6)
	return r


## A quiet fishing spot on a riverbank: a little plank landing over the
## water, a rod propped on a forked stick with its line down to a float, a
## creel, a coil of rope, a bucket and an upturned crate to sit on. Faces -Z
## (toward the water). Returns the root; the float's local position is in
## its "float" meta, for framing the view while the child sits and fishes.
## A small pond: still water in an uneven oval with a muddy rim, stones,
## reeds and lily pads. A collider keeps walkers on the bank.
static func pond(parent: Node3D, center: Vector3, radii: Vector2, seed: int) -> Node3D:
	var r := _root(parent, "Pond", center, 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var edge := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		var wob := 1.0 + sin(a * 3.0 + seed) * 0.08 + rng.randf_range(-0.03, 0.03)
		edge.append(Vector2(cos(a) * radii.x, sin(a) * radii.y) * wob)
	for layer: Array in [[1.16, 0.025, "soil_dark"], [1.0, 0.05, "water"]]:
		var pts := PackedVector2Array()
		for q in edge:
			pts.append(q * float(layer[0]))
		var tris := Geometry2D.triangulate_polygon(pts)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_normal(Vector3.UP)
		for i in tris.size():
			var q := pts[tris[i]]
			st.set_uv(q / 3.0)
			st.add_vertex(Vector3(q.x, float(layer[1]), q.y))
		MeshKit._instance(r, st.commit(), Vector3.ZERO, str(layer[2]))
	for i in range(0, edge.size(), 2):
		var q := edge[i] * 1.12
		if rng.randf() < 0.6:
			var stone := MeshKit.sphere(r, rng.randf_range(0.14, 0.26), Vector3(q.x, 0.06, q.y), "stone" if i % 3 else "stone_dark", Vector3(1.2, 0.6, 1.0), 6, 4)
			stone.rotation.y = rng.randf() * TAU
	for k in 3:
		var q := edge[(k * 9 + 3) % edge.size()] * 0.95
		reeds(r, Vector3(q.x, 0, q.y), seed + k, 0.5)
	for k in 5:
		var a := rng.randf() * TAU
		var q := Vector2(cos(a) * radii.x, sin(a) * radii.y) * rng.randf_range(0.2, 0.7)
		Props.place(r, "waterlily", Vector3(q.x, 0.06, q.y), rng.randf() * TAU, rng.randf_range(0.8, 1.2))
	MeshKit.solid(r, Vector3(radii.x * 1.7, 1.2, radii.y * 1.6), Vector3(0, 0.6, 0))
	return r


## A small village cottage like those in the concept art: warm plaster walls
## with a dark timber frame, a steep roof (thatch or tiles) with its gable to
## the front, a stone chimney, a plank door, shuttered windows with flower
## boxes, and a step. Front faces +Z. `size` is width by depth.
static func cottage(parent: Node3D, pos: Vector3, rot_y: float, seed: int, size := Vector2(3.6, 4.2), roof := "roof_thatch") -> Node3D:
	var r := _root(parent, "Cottage", pos, rot_y)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var w := size.x
	var d := size.y
	var h := 2.4
	MeshKit.box(r, Vector3(w + 0.3, 0.3, d + 0.3), Vector3(0, 0.15, 0), "stone_dark")
	MeshKit.box(r, Vector3(w, h, d), Vector3(0, 0.3 + h / 2.0, 0), "plaster_warm" if seed % 2 else "plaster")
	MeshKit.solid(r, Vector3(w + 0.3, 3.0, d + 0.3), Vector3(0, 1.5, 0))
	# Timber frame: corner posts, a sill and a beam round the top, braces at the front.
	for x: float in [-w / 2.0, w / 2.0]:
		for z: float in [-d / 2.0, d / 2.0]:
			MeshKit.box(r, Vector3(0.16, h, 0.16), Vector3(x, 0.3 + h / 2.0, z), "wood_dark")
	for z: float in [-d / 2.0 - 0.02, d / 2.0 + 0.02]:
		MeshKit.box(r, Vector3(w + 0.1, 0.14, 0.08), Vector3(0, 0.3 + h - 0.07, z), "wood_dark")
		MeshKit.box(r, Vector3(w + 0.1, 0.12, 0.08), Vector3(0, 0.36, z), "wood_dark")
	for x: float in [-w / 2.0 - 0.02, w / 2.0 + 0.02]:
		MeshKit.box(r, Vector3(0.08, 0.14, d + 0.1), Vector3(x, 0.3 + h - 0.07, 0), "wood_dark")
	for side: float in [-1.0, 1.0]:
		var brace := MeshKit.box(r, Vector3(0.1, 1.5, 0.06), Vector3(side * (w / 2.0 - 0.45), 0.3 + h * 0.62, d / 2.0 + 0.03), "wood_dark")
		brace.rotation.z = side * 0.6
	# Roof: a steep gable to the front, overhanging the walls, and a chimney.
	var rh := 1.9
	var roof_mesh := MeshKit.roof(r, w + 0.8, rh, d + 0.7, Vector3(0, 0.3 + h + rh / 2.0, 0), roof)
	roof_mesh.name = "Roof"
	MeshKit.box(r, Vector3(0.55, 1.6, 0.55), Vector3(w * 0.22, 0.3 + h + 1.1, -d * 0.2), "stone")
	MeshKit.box(r, Vector3(0.65, 0.12, 0.65), Vector3(w * 0.22, 0.3 + h + 1.92, -d * 0.2), "stone_dark")
	# Door, step and lantern.
	MeshKit.box(r, Vector3(0.9, 1.7, 0.08), Vector3(-w * 0.18, 0.3 + 0.85, d / 2.0 + 0.04), "wood_dark")
	MeshKit.box(r, Vector3(0.06, 0.06, 0.06), Vector3(-w * 0.18 + 0.3, 0.3 + 0.85, d / 2.0 + 0.1), "gold")
	MeshKit.box(r, Vector3(1.2, 0.14, 0.5), Vector3(-w * 0.18, 0.07, d / 2.0 + 0.4), "stone")
	MeshKit.box(r, Vector3(0.16, 0.22, 0.16), Vector3(-w * 0.18 + 0.75, 2.05, d / 2.0 + 0.12), "lantern")
	# Shuttered windows with flower boxes, front and sides.
	var shutter: String = ["awning_blue", "awning_green", "awning_red"][seed % 3]
	var windows := [[Vector3(w * 0.24, 1.6, d / 2.0 + 0.04), 0.0], [Vector3(w / 2.0 + 0.04, 1.6, 0), PI / 2.0], [Vector3(-w / 2.0 - 0.04, 1.6, 0), -PI / 2.0]]
	for win: Array in windows:
		var at: Vector3 = win[0]
		var yaw: float = win[1]
		var face := Basis(Vector3.UP, yaw)
		MeshKit.box(r, Vector3(0.7, 0.75, 0.05), at, "glass_blue", false, yaw)
		MeshKit.box(r, Vector3(0.78, 0.08, 0.08), at + face * Vector3(0, 0.42, 0.02), "wood_dark", false, yaw)
		for side: float in [-1.0, 1.0]:
			MeshKit.box(r, Vector3(0.3, 0.78, 0.04), at + face * Vector3(side * 0.52, 0, 0.03), shutter, false, yaw)
		MeshKit.box(r, Vector3(0.8, 0.18, 0.22), at + face * Vector3(0, -0.5, 0.12), "wood", false, yaw)
		for k in 4:
			MeshKit.sphere(r, 0.09, at + face * Vector3(-0.27 + k * 0.18, -0.36, 0.14), ["flower_pink", "flower_yellow", "flower_white", "flower_pink"][(k + seed) % 4], Vector3.ONE, 6, 3)
	return r


## A low dry-stone wall from `a` to `b`, of rounded stones in two courses.
static func stone_wall(parent: Node3D, a: Vector3, b: Vector3, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var span := b - a
	var n := int(span.length() / 0.42)
	for i in n:
		var t := (i + 0.5) / n
		for course in 2:
			var at := a + span * t + Vector3(0, 0.16 + course * 0.24, 0) + span.normalized().cross(Vector3.UP) * rng.randf_range(-0.04, 0.04)
			var stone := MeshKit.sphere(parent, 0.24, at, "stone" if (i + course) % 3 else "stone_dark", Vector3(1.1, 0.75, 0.9), 6, 4)
			stone.rotation.y = rng.randf() * TAU
	MeshKit.solid(parent, Vector3(0.5, 0.7, span.length()), a + span / 2.0 + Vector3(0, 0.35, 0), atan2(span.x, span.z))


## A field of ripe grain in rows, with soil furrows between them, a low
## fence along two sides and a few stooks of cut sheaves at one end, like the
## farmland in the concept art. `size` is width (along the rows) by depth.
static func grain_field(parent: Node3D, pos: Vector3, size: Vector2, rot_y: float, seed: int) -> Node3D:
	var r := _root(parent, "GrainField", pos, rot_y)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	MeshKit.box(r, Vector3(size.x, 0.04, size.y), Vector3(0, 0.02, 0), "soil")
	var rows := int(size.y / 0.55)
	for row in rows:
		var z := -size.y / 2.0 + 0.3 + row * 0.55
		MeshKit.box(r, Vector3(size.x - 0.4, 0.06, 0.2), Vector3(0, 0.05, z), "soil_dark")
		var x := -size.x / 2.0 + 0.4
		while x < size.x / 2.0 - 0.3:
			var h := rng.randf_range(0.5, 0.72)
			var at := Vector3(x + rng.randf_range(-0.05, 0.05), 0, z + 0.14)
			var stalk := MeshKit.box(r, Vector3(0.14, h, 0.1), at + Vector3(0, h / 2.0, 0), "roof_thatch")
			stalk.rotation.z = rng.randf_range(-0.12, 0.12)
			MeshKit.box(r, Vector3(0.12, 0.16, 0.12), at + Vector3(0, h + 0.04, 0), "flower_yellow")
			x += 0.32
	# Stooks: cut sheaves leaning together at the near end.
	for k in 3:
		var at := Vector3(-size.x / 2.0 + 1.0 + k * 1.3, 0, size.y / 2.0 + 0.9)
		for i in 4:
			var a := TAU * i / 4.0 + k
			var sheaf := MeshKit.cylinder(r, 0.06, 0.16, 0.9, at + Vector3(cos(a) * 0.12, 0.42, sin(a) * 0.12), "roof_thatch", 6)
			sheaf.rotation = Vector3(sin(a) * 0.25, 0, -cos(a) * 0.25)
	# A low post-and-rail fence on the two far sides.
	for side in 2:
		var length := size.x if side == 0 else size.y
		var n := int(length / 1.5) + 1
		for i in n + 1:
			var t := -length / 2.0 + i * length / n
			var at := Vector3(t, 0, -size.y / 2.0 - 0.3) if side == 0 else Vector3(size.x / 2.0 + 0.3, 0, t)
			MeshKit.box(r, Vector3(0.1, 0.8, 0.1), at + Vector3(0, 0.4, 0), "wood_dark")
		var rail := Vector3(length, 0.07, 0.06) if side == 0 else Vector3(0.06, 0.07, length)
		var mid := Vector3(0, 0, -size.y / 2.0 - 0.3) if side == 0 else Vector3(size.x / 2.0 + 0.3, 0, 0)
		for y: float in [0.38, 0.66]:
			MeshKit.box(r, rail, mid + Vector3(0, y, 0), "wood")
	return r


## A mustard plant grown tall: a slender stem that branches near the top, each
## branch ending in a loose cluster of small four-petalled yellow flowers with
## green seed pods below, and lobed leaves that shrink up the stem.
static func mustard_plant(parent: Node3D, pos: Vector3, seed: int, height := 1.7) -> Node3D:
	var r := _root(parent, "MustardPlant", pos, seed * 0.7)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	_stalk(r, Vector3.ZERO, Vector3.ZERO, height, 0.022)
	# Lobed leaves low on the stem, smaller and narrower as they climb.
	for i in 7:
		var t := i / 6.0
		var leaf := Node3D.new()
		leaf.position = Vector3(0, 0.08 + t * height * 0.55, 0)
		leaf.rotation = Vector3(0, i * 2.4 + rng.randf_range(-0.3, 0.3), 0)
		r.add_child(leaf)
		var size := lerpf(0.34, 0.12, t)
		var blade := Node3D.new()
		blade.rotation.x = lerpf(0.05, 0.4, t)
		leaf.add_child(blade)
		for k in 3: # three lobes along the blade, the tip lobe largest
			var at := (0.3 + k * 0.32) * size
			MeshKit.sphere(blade, 0.1, Vector3(0, 0, -at), "leaf" if k % 2 == 0 else "leaf_light", Vector3(lerpf(1.2, 2.0, k / 2.0) * size * 4.0, 0.25, size * 2.0), 6, 3)
	# Branches spread from the upper half, each topped with flowers.
	var tops: Array[Vector3] = [Vector3(0, height, 0)]
	for i in 6:
		var y := height * rng.randf_range(0.5, 0.88)
		var yaw := i * TAU / 6.0 + rng.randf_range(-0.4, 0.4)
		var lean := rng.randf_range(0.35, 0.65)
		var length := height * rng.randf_range(0.28, 0.42)
		var base := Vector3(0, y, 0)
		_stalk(r, base, Vector3(lean, yaw, 0), length, 0.012)
		tops.append(base + Basis.from_euler(Vector3(lean, yaw, 0), EULER_ORDER_YXZ) * Vector3(0, length, 0))
	for top in tops:
		_mustard_flowers(r, top, rng)
	return r


## A thin green stem from `base`, tipped by `euler` (pitch, yaw), `length` long.
static func _stalk(r: Node3D, base: Vector3, euler: Vector3, length: float, radius: float) -> void:
	var pivot := Node3D.new()
	pivot.position = base
	pivot.rotation_order = EULER_ORDER_YXZ
	pivot.rotation = Vector3(euler.x, euler.y, 0)
	r.add_child(pivot)
	var stem := MeshKit.cylinder(pivot, radius * 0.6, radius, 1.0, Vector3(0, 0.5, 0), "leaf", 6)
	stem.scale.y = length
	stem.position.y = length / 2.0


## A raceme: a dome of yellow flowers and buds, with seed pods below it.
static func _mustard_flowers(r: Node3D, top: Vector3, rng: RandomNumberGenerator) -> void:
	for k in 11:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.0, 0.09)
		var at := top + Vector3(cos(a) * d, 0.06 - d * 0.6 + rng.randf_range(-0.02, 0.02), sin(a) * d)
		MeshKit.sphere(r, 0.03, at, "flower_yellow" if k < 9 else "leaf_light", Vector3(1, 0.7, 1), 6, 3)
	for k in 3:
		var pod := Node3D.new()
		pod.position = top - Vector3(0, 0.06 + k * 0.04, 0)
		pod.rotation = Vector3(0.45, k * 2.3, 0)
		pod.rotation_order = EULER_ORDER_YXZ
		r.add_child(pod)
		MeshKit.cylinder(pod, 0.005, 0.008, 0.09, Vector3(0, 0.045, 0), "leaf_light", 4)


## A rod along -Z from the node's origin (the butt), with a reel near the grip.
static func fishing_rod_mesh(rod: Node3D, length: float) -> void:
	MeshKit.cylinder(rod, 0.012, 0.025, length, Vector3(0, 0, -length / 2.0), "wood", 6).rotation.x = PI / 2.0
	MeshKit.cylinder(rod, 0.035, 0.035, 0.08, Vector3(0.03, 0, -0.2), "dark", 8).rotation.z = PI / 2.0


## A red-and-white float resting on the water at `at`.
static func fishing_float(parent: Node3D, at: Vector3) -> Node3D:
	var f := Node3D.new()
	f.position = at
	parent.add_child(f)
	MeshKit.sphere(f, 0.045, Vector3(0, 0.02, 0), "cloth_red", Vector3(1, 0.8, 1), 8, 4)
	MeshKit.sphere(f, 0.03, Vector3(0, 0.06, 0), "white", Vector3.ONE, 6, 3)
	return f


static func fishing_spot(parent: Node3D, pos: Vector3, rot_y: float, water_y: float) -> Node3D:
	var r := _root(parent, "FishingSpot", pos, rot_y)
	var deck := 0.12
	for i in 5:
		MeshKit.box(r, Vector3(1.3, 0.06, 0.27), Vector3(0, deck, -0.15 - i * 0.3), "wood_light" if i % 2 else "wood")
	for z: float in [-0.2, -1.35]:
		for x: float in [-0.58, 0.58]:
			MeshKit.cylinder(r, 0.06, 0.07, 0.8, Vector3(x, deck - 0.4, z), "wood_dark", 6)
	# The rod, propped in a forked stick at the end of the landing.
	var stick := MeshKit.box(r, Vector3(0.04, 0.5, 0.04), Vector3(-0.35, deck + 0.25, -1.25), "wood_dark")
	stick.rotation.x = -0.15
	for side: float in [-1.0, 1.0]:
		var prong := MeshKit.box(r, Vector3(0.03, 0.14, 0.03), Vector3(-0.35 + side * 0.04, deck + 0.53, -1.3), "wood_dark")
		prong.rotation.z = side * 0.4
	# The rod rests with its butt on the planks and its shaft in the fork; it is
	# live so it can be put away while the child fishes with it.
	var resting := Node3D.new()
	resting.name = "RestingRod"
	StaticBatch.mark_live(resting)
	r.add_child(resting)
	var rod_len := 2.4
	var rod := Node3D.new()
	rod.position = Vector3(-0.35, deck + 0.04, -0.25)
	rod.rotation.x = 0.45
	resting.add_child(rod)
	fishing_rod_mesh(rod, rod_len)
	var tip := rod.transform * Vector3(0, 0, -rod_len)
	var bob := Vector3(tip.x, water_y - pos.y + 0.02, tip.z)
	MeshKit.box(resting, Vector3(0.006, tip.y - bob.y, 0.006), (tip + bob) / 2.0, "white")
	fishing_float(resting, bob)
	r.set_meta("float", bob)
	creel_and_rope(r, Vector3(0.3, deck, -0.55), 0.6)
	# An upturned crate to sit on, on the bank, and a bucket for the catch.
	MeshKit.box(r, Vector3(0.45, 0.36, 0.38), Vector3(0.1, 0.18, 0.55), "wood")
	MeshKit.box(r, Vector3(0.47, 0.04, 0.4), Vector3(0.1, 0.36, 0.55), "wood_dark")
	MeshKit.cylinder(r, 0.14, 0.12, 0.26, Vector3(-0.55, 0.13, 0.5), "stone", 10)
	MeshKit.cylinder(r, 0.12, 0.12, 0.01, Vector3(-0.55, 0.27, 0.5), "water", 10)
	return r
