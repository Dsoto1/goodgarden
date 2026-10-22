extends Node3D
## Keeps a small flat thing (a heart) turned toward the camera.


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam:
		var to := cam.global_position - global_position
		rotation.y = atan2(to.x, to.z) - get_parent_node_3d().global_rotation.y
