class_name AnimalModel
extends RefCounted
## Primitive-built ambient animals. Each returns a Node3D facing -Z.


static func make(kind: String) -> Node3D:
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
		"sheep":
			MeshKit.sphere(root, 0.32, Vector3(0, 0.45, 0), "white", Vector3(0.9, 0.85, 1.25), 8, 4)
			MeshKit.sphere(root, 0.14, Vector3(0, 0.55, -0.38), "dark", Vector3(0.8, 0.9, 1.1), 7, 4)
			for x: float in [-0.14, 0.14]:
				for z: float in [-0.18, 0.18]:
					MeshKit.cylinder(root, 0.035, 0.035, 0.3, Vector3(x, 0.15, z), "dark", 4)
		"lamb":
			# Smaller and creamier than its mother, with a bigger head for its size.
			MeshKit.sphere(root, 0.2, Vector3(0, 0.32, 0), "cloth_cream", Vector3(0.9, 0.85, 1.2), 8, 4)
			MeshKit.sphere(root, 0.11, Vector3(0, 0.42, -0.25), "cloth_cream", Vector3(0.85, 0.95, 1.05), 7, 4)
			for side: float in [-1.0, 1.0]:
				MeshKit.sphere(root, 0.04, Vector3(side * 0.1, 0.46, -0.24), "dark", Vector3(1.4, 0.6, 0.8), 5, 3)
			for x: float in [-0.09, 0.09]:
				for z: float in [-0.12, 0.12]:
					MeshKit.cylinder(root, 0.025, 0.025, 0.24, Vector3(x, 0.12, z), "dark", 4)
		"butterfly":
			for side: float in [-1.0, 1.0]:
				var wing := MeshKit.box(root, Vector3(0.09, 0.005, 0.07), Vector3(0.05 * side, 0, 0), "flower_yellow")
				wing.name = "Wing%d" % (0 if side < 0 else 1)
	return root
