class_name Zone
extends Area3D
## Trigger volume the avatar walks into. Regions use zones to mark discovery,
## interiors (hide roofs, change ambience/mood) and camera framing changes.

signal player_entered
signal player_exited

var inside := false


static func create(parent: Node3D, center: Vector3, size: Vector3) -> Zone:
	var z := Zone.new()
	z.position = center
	parent.add_child(z)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	z.add_child(shape)
	return z


func _ready() -> void:
	collision_layer = MeshKit.LAYER_TRIGGER
	collision_mask = MeshKit.LAYER_PLAYER
	monitorable = false
	body_entered.connect(func(body: Node3D) -> void:
		if body is Player:
			inside = true
			player_entered.emit())
	body_exited.connect(func(body: Node3D) -> void:
		if body is Player:
			inside = false
			player_exited.emit())
