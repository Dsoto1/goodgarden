class_name AnimalModel
extends RefCounted
## Ambient animals, each a Node3D facing -Z. Farm animals (sheep, lamb, cow,
## horse, pig, dog) are animated models (FarmAnimal); hens, the cats, birds
## and butterflies are built from primitives.


static func make(kind: String) -> Node3D:
	if FarmAnimal.is_kind(kind):
		return FarmAnimal.make(kind)
	var root := Node3D.new()
	match kind:
		"chicken":
			MeshKit.sphere(root, 0.18, Vector3(0, 0.25, 0), "white", Vector3(0.9, 0.9, 1.2), 8, 4)
			MeshKit.sphere(root, 0.1, Vector3(0, 0.42, -0.14), "white", Vector3.ONE, 7, 4)
			MeshKit.box(root, Vector3(0.03, 0.07, 0.08), Vector3(0, 0.52, -0.14), "cloth_red")
			var beak := MeshKit.cone(root, 0.03, 0.08, Vector3(0, 0.42, -0.25), "gold", 5)
			beak.rotation.x = -PI / 2
			for side: float in [-0.06, 0.06]:
				MeshKit.cylinder(root, 0.012, 0.012, 0.14, Vector3(side, 0.07, 0), "gold", 4)
		"cat":
			MeshKit.sphere(root, 0.16, Vector3(0, 0.16, 0), "cloth_gold", Vector3(0.9, 0.7, 1.6), 8, 4)
			MeshKit.sphere(root, 0.11, Vector3(0, 0.25, -0.22), "cloth_gold", Vector3.ONE, 8, 4)
			for side: float in [-0.06, 0.06]:
				MeshKit.cone(root, 0.04, 0.08, Vector3(side, 0.36, -0.22), "cloth_gold", 4)
			var tail := MeshKit.cylinder(root, 0.025, 0.03, 0.3, Vector3(0, 0.22, 0.3), "cloth_gold", 5)
			tail.rotation.x = 0.9
		"bird":
			MeshKit.sphere(root, 0.07, Vector3(0, 0.08, 0), "cloth_blue", Vector3(0.9, 0.9, 1.3), 6, 3)
			MeshKit.sphere(root, 0.045, Vector3(0, 0.14, -0.06), "cloth_blue", Vector3.ONE, 6, 3)
			var b := MeshKit.cone(root, 0.015, 0.04, Vector3(0, 0.14, -0.11), "gold", 4)
			b.rotation.x = -PI / 2
		"deer":
			# A slender red deer: body, neck, head, white tail, thin legs, antlers.
			MeshKit.sphere(root, 0.32, Vector3(0, 0.78, 0), "trunk", Vector3(0.8, 0.85, 1.6), 9, 5)
			var neck := MeshKit.capsule(root, 0.09, 0.5, Vector3(0, 1.08, -0.42), "trunk", Vector3(-0.7, 0, 0))
			neck.name = "Neck"
			MeshKit.sphere(root, 0.13, Vector3(0, 1.32, -0.6), "trunk", Vector3(0.8, 0.85, 1.35), 8, 4)
			MeshKit.sphere(root, 0.04, Vector3(0, 1.28, -0.77), "dark", Vector3.ONE, 5, 3)
			MeshKit.sphere(root, 0.07, Vector3(0, 0.86, 0.5), "white", Vector3(1, 1.2, 0.7), 6, 3)
			for x: float in [-0.12, 0.12]:
				for z: float in [-0.32, 0.32]:
					MeshKit.cylinder(root, 0.03, 0.04, 0.62, Vector3(x, 0.31, z), "trunk", 5)
				MeshKit.sphere(root, 0.05, Vector3(x * 0.8, 1.44, -0.56), "trunk", Vector3(0.6, 1.2, 0.4), 5, 3)
				var antler := MeshKit.cylinder(root, 0.012, 0.018, 0.34, Vector3(x * 0.7, 1.58, -0.56), "wood_light", 4)
				antler.rotation.z = signf(x) * -0.45
				var tine := MeshKit.cylinder(root, 0.01, 0.014, 0.16, Vector3(x * 1.4, 1.66, -0.6), "wood_light", 4)
				tine.rotation = Vector3(-0.6, 0, signf(x) * -0.2)
		"butterfly":
			for side: float in [-1.0, 1.0]:
				var wing := MeshKit.box(root, Vector3(0.09, 0.005, 0.07), Vector3(0.05 * side, 0, 0), "flower_yellow")
				wing.name = "Wing%d" % (0 if side < 0 else 1)
	return root
