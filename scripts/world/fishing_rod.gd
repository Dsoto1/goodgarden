class_name FishingRod
extends Node3D
## A rod held in a character's hand. Its line hangs from the tip straight
## down to a float resting on the water, wherever the hand moves it.

const LENGTH := 2.1

var water_y := 0.0
var _line: MeshInstance3D
var _float: Node3D


static func create(water_level: float) -> FishingRod:
	var rod := FishingRod.new()
	rod.water_y = water_level
	CraftedProps.fishing_rod_mesh(rod, LENGTH)
	rod._line = MeshKit.box(rod, Vector3.ONE, Vector3.ZERO, "white")
	rod._line.top_level = true
	rod._float = CraftedProps.fishing_float(rod, Vector3.ZERO)
	rod._float.top_level = true
	return rod


func _process(_delta: float) -> void:
	var tip := global_transform * Vector3(0, 0, -LENGTH)
	var bob := Vector3(tip.x, water_y + 0.02, tip.z)
	_float.global_position = bob + Vector3(0, sin(Time.get_ticks_msec() * 0.0021) * 0.008, 0)
	var drop := maxf(tip.y - bob.y, 0.01)
	_line.global_transform = Transform3D(Basis.from_scale(Vector3(0.006, drop, 0.006)), (tip + bob) / 2.0)
