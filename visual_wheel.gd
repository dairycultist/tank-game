extends Node3D

@export var steer_invert: bool = false

var resting_pos: Vector3

var base_yaw: float

func _ready() -> void:
	resting_pos = position
	base_yaw = rotation.y

func _process(delta: float) -> void:
	
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
	else:
		position = lerp(position, resting_pos, 3.0 * delta)
	
	# visual
	var dir := Input.get_vector("right", "left", "backward", "forward")
	
	rotation.y = lerp_angle(rotation.y, base_yaw + PI / 8 * (-dir.x if steer_invert else dir.x), 4.0 * delta)
	
	
