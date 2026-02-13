extends Node3D

var resting_pos: Vector3

func _ready() -> void:
	resting_pos = position

func _lerp_angle3(target: Vector3, delta: float):
	rotation.x = lerp_angle(rotation.x, target.x, 3.0 * delta)
	rotation.y = lerp_angle(rotation.y, target.y, 3.0 * delta)
	rotation.z = lerp_angle(rotation.z, target.z, 3.0 * delta)

func _process(delta: float) -> void:
	
	var tank := get_parent_node_3d().get_parent_node_3d()
	
	var query = PhysicsRayQueryParameters3D.create(
		tank.global_position + tank.basis * resting_pos + tank.global_basis.y * 0.5,
		tank.global_position + tank.basis * resting_pos
	)
	query.exclude = [tank]
	
	var ray_result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if ray_result:
		
		global_position = ray_result.position
		
		var prev_rotation = rotation
		look_at(global_position + ray_result.normal, -tank.global_basis.z)
		var target_rotation = rotation
		rotation = prev_rotation
		_lerp_angle3(target_rotation, delta)
		
	else:
		position = lerp(position, resting_pos, 3.0 * delta)
		_lerp_angle3(Vector3(PI / 2.0, PI, 0.0), delta)
