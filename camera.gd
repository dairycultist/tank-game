extends Camera3D

@export var mouse_sensitivity: float = 0.003

var camera_pitch := 0.0
var camera_yaw := 0.0
var camera_global_target_angle := 0.0

var prev_tank_yaw := 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	
	var camera_pivot := get_parent_node_3d()
	var tank := camera_pivot.get_parent_node_3d()
	
	camera_global_target_angle += tank.global_rotation.y - prev_tank_yaw
	prev_tank_yaw = tank.global_rotation.y
	
	camera_yaw = lerp_angle(camera_yaw, camera_global_target_angle, delta * 12.0)
	
	# ensure camera is always above the tank (even if tipped over) and
	# (generally) facing where the tank is facing
	camera_pivot.global_rotation = Vector3(camera_pitch, camera_yaw, 0)
	
	# speed fac
	var speed_fac = pow(min(tank.linear_velocity.length() * 0.05, 1.0), 0.8)
	
	# FOV (60 - 100)
	fov = 60 + speed_fac * 40

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		
		camera_pitch = clampf(camera_pitch - event.relative.y * mouse_sensitivity, -PI / 4, PI / 8)
		camera_global_target_angle += -event.relative.x * mouse_sensitivity
	
	if event.is_action_pressed("pause"):
		
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)
