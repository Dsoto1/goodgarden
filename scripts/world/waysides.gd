class_name Waysides
extends Node3D
## Life along the roads between the valley and the places beyond it, as in
## the concept's painted map: farmsteads, windmills, a watermill, hamlets,
## a shepherd's hut, and a stone bridge where the monastery road crosses
## the river. Scenery only; the forest keeps clear (Terrain.WAYSIDES).


func build() -> void:
	for w: Array in Terrain.WAYSIDES:
		var at: Vector2 = w[0]
		var kind := str(w[1])
		var yaw: float = w[2]
		var pos := Vector3(at.x, _ground(at, 3.0), at.y)
		match kind:
			"cottage":
				CraftedProps.cottage(self, pos, yaw, int(at.x * 7 + at.y), Vector2(4.0, 4.6), "roof_thatch")
			"woodpile":
				CraftedProps.woodpile(self, pos, yaw)
			"haystack":
				CraftedProps.haystack(self, pos)
			"field":
				CraftedProps.grain_field(self, pos, Vector2(12, 7), yaw, int(at.x + at.y * 3))
			"bridge":
				var bank := minf(Terrain.height(at.x, at.y - 5.0), Terrain.height(at.x, at.y + 5.0))
				var b := StoneBridge.build(self, Vector3(at.x, bank - 0.1, at.y), yaw)
				b.scale = Vector3.ONE * 1.5
			_:
				Props.place(self, kind, pos, yaw, 1.25)


## The lowest ground under a building's footprint, so it never floats.
static func _ground(at: Vector2, r: float) -> float:
	var h := Terrain.height(at.x, at.y)
	for k in 6:
		var a := k * TAU / 6.0
		h = minf(h, Terrain.height(at.x + cos(a) * r, at.y + sin(a) * r))
	return h - 0.1
