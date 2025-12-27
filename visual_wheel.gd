extends Node3D

var resting_pos: Vector3

func _ready() -> void:
	resting_pos = position

func _process(_delta: float) -> void:
	
	var tank := get_parent_node_3d()
	
	# raycast somewhere decently above the wheel's lowest contact position
	var query = PhysicsRayQueryParameters3D.create(
		tank.global_position + tank.basis * resting_pos + tank.global_basis.y * 0.5,
		tank.global_position + tank.basis * resting_pos
	)
	query.exclude = [tank]
	
	var ray_result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if ray_result:
		global_position = ray_result.position
