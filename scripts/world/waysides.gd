class_name Waysides
extends Node3D
## Life along the roads between the valley and the places beyond it, as in
## the concept's painted map: farmsteads, windmills, a watermill, hamlets,
## a shepherd's hut, and a stone bridge where the monastery road crosses
## the river. Scenery only; the forest keeps clear (Terrain.WAYSIDES).
##
## For the wider-world map it also sets out big painted landmarks (each
## place's signature building, and the wayside buildings enlarged) on a
## render layer only the map's camera draws, so the map reads like the
## concept's at a glance while the world itself is unchanged.

const MAP_LAYER := 1 << 19

## Each place's landmark on the map: world x/z, prop, yaw, scale, and
## whether it floats on the sea or the lake.
const LANDMARKS := [
	[Vector2(26, -138), "cathedral", 0.0, 2.6, ""],
	[Vector2(12, -128), "tower_red", 0.3, 3.0, ""],
	[Vector2(40, -128), "tower_blue", -0.3, 3.0, ""],
	[Vector2(108, -72), "church_yellow", 0.0, 3.2, ""],
	[Vector2(212, 30), "ship_large", 1.7, 2.6, "sea"],
	[Vector2(84, 44), "rowboat_small", 0.6, 3.5, "lake"],
	[Vector2(-8, 74), "barn_big", PI, 2.4, ""],
	[Vector2(2, 74), "silo", 0.0, 2.4, ""],
	[Vector2(122, -156), "mine", -0.8, 2.6, ""],
	[Vector2(-80, 30), "grove_a_large", 0.0, 4.0, ""],
	[Vector2(-64, 26), "twisted_tree", 1.0, 3.5, ""],
]


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
				_landmark(kind, pos, yaw, 2.8)
	for l: Array in LANDMARKS:
		var at: Vector2 = l[0]
		var y := _ground(at, 4.0)
		if l[4] == "sea":
			y = Terrain.SEA_LEVEL - 0.9 * float(l[3])
		elif l[4] == "lake":
			y = Terrain.LAKE_LEVEL - 0.2 * float(l[3])
		_landmark(str(l[1]), Vector3(at.x, y, at.y), l[2], l[3])


## A map-only copy of a prop, enlarged: no collision, no shadow, drawn only
## by the map's camera.
func _landmark(kind: String, pos: Vector3, yaw: float, scale_mul: float) -> void:
	var root := Props.place(self, kind, pos, yaw, scale_mul)
	for body in root.find_children("*", "CollisionObject3D", true, false):
		body.queue_free()
	for vi in root.find_children("*", "VisualInstance3D", true, false):
		(vi as VisualInstance3D).layers = MAP_LAYER
		if vi is GeometryInstance3D:
			(vi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## The lowest ground under a building's footprint, so it never floats.
static func _ground(at: Vector2, r: float) -> float:
	var h := Terrain.height(at.x, at.y)
	for k in 6:
		var a := k * TAU / 6.0
		h = minf(h, Terrain.height(at.x + cos(a) * r, at.y + sin(a) * r))
	return h - 0.1
