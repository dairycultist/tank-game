extends RigidBody3D

@onready var CAMERA = $CameraPivot/Camera3D
@onready var BARREL_PIVOT = $TurretPivot/BarrelPivot

@export_category("Camera")
@export var mouse_sensitivity: float = 0.003

var camera_pitch := 0.0
var camera_yaw := 0.0
var camera_global_target_angle := 0.0

var prev_tank_yaw := 0.0

@export_category("Control")
## How much drag is applied when grounded (regardless of driving).
@export var drag: float = 50.0
## How much the tank resists slipping side-to-side (wheels and treads).
@export var lateral_drag: float = 0.0
@export var drive_force: float = 400.0
@export var turn_torque: float = 100.0

@export_category("Suspension")
## How much the suspension forces oppose compression.
@export var stiffness: float = 30.0
## How much vertical velocity (at the point of suspension) is diffused.
@export var dampening: float = 2.0

var suspension_rays: Array[Node]

func _ready() -> void:
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	suspension_rays = find_children("*", "RayCast3D", false)

func _process(delta: float) -> void:
	
	var grounded := false
	
	# apply "suspension" which allows the tank to float above the ground
	# (wheels/legs/treads/hoverplates are completely visual and are all
	# simulated the same way)
	for ray in suspension_rays:
		
		if _apply_suspension(ray):
			grounded = true
	
	# control
	if grounded:
		
		var up      :=  global_basis.y
		var forward := -global_basis.z
		var right   :=  global_basis.x
		
		# controls
		var dir := Input.get_vector("right", "left", "backward", "forward")
		
		apply_force(dir.y * forward * drive_force * delta, -up * 0.2)
		
		apply_torque(dir.x * up * turn_torque * delta)
		
		# apply planar drag
		var planar_velocity := forward * linear_velocity.dot(forward) + right * linear_velocity.dot(right)
		
		apply_central_force(-planar_velocity * drag * delta)
		
		# apply lateral drag
		apply_central_force(right * -linear_velocity.dot(right) * lateral_drag * delta)
		
		# apply angular drag
		apply_torque(up * -angular_velocity.dot(up) * drag * delta)
	
	# camera
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		
		camera_global_target_angle += global_rotation.y - prev_tank_yaw
		prev_tank_yaw = global_rotation.y
		
		camera_yaw = lerp_angle(camera_yaw, camera_global_target_angle, delta * 12.0)
		
		# ensure camera is always above the tank (even if tipped over) and
		# (generally) facing where the tank is facing
		$CameraPivot.global_rotation = Vector3(camera_pitch, camera_yaw, 0)
		
		# speed fac
		var speed_fac = pow(min(linear_velocity.length() * 0.05, 1.0), 0.8)
		
		# FOV (60 - 100)
		CAMERA.fov = 60 + speed_fac * 40
		
		# turret attempts to face towards camera direction
		var lerp_direction = sign(camera_global_target_angle - lerp_angle($TurretPivot.rotation.y + rotation.y, camera_global_target_angle, 0.5))
		$TurretPivot.rotation.y += lerp_direction * 2.0 * delta
		
		# barrel too
		var prev_pitch = BARREL_PIVOT.rotation.x
		BARREL_PIVOT.look_at(CAMERA.global_position - CAMERA.global_basis.z * 100.0)
		
		lerp_direction = sign(BARREL_PIVOT.rotation.x - lerp_angle(BARREL_PIVOT.rotation.x, prev_pitch, 0.5))
		
		BARREL_PIVOT.rotation.x = prev_pitch + lerp_direction * delta
		BARREL_PIVOT.rotation.y = 0.0
		BARREL_PIVOT.rotation.z = 0.0
	
func _apply_suspension(ray: RayCast3D) -> bool:
	
	ray.global_rotation = Vector3.ZERO
	
	# the raycast represents suspension; if the ray hits something before the point
	# of zero compression, it means the suspension is compressed ("grounded") and
	# we should apply a relevant upward force at the position of the raycast's origin
	if ray.is_colliding():
		
		var compression_distance := ((ray.target_position + ray.global_position) - ray.get_collision_point()).length()
		var compression_fac := compression_distance / ray.target_position.length()
		
		# stiffness opposes compression
		var suspension_force := compression_fac * stiffness
		
		# dampening opposes vertical velocity at the raycast's origin
		var velocity_at_position := linear_velocity + angular_velocity.cross(ray.global_position - global_position)
		var vertical_velocity_at_position = velocity_at_position.dot(Vector3.UP)
		
		suspension_force -= vertical_velocity_at_position * dampening
		
		# apply force
		apply_force(suspension_force * Vector3.UP, ray.global_position - global_position)
		
		return true
		
	return false

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		
		camera_pitch = clampf(camera_pitch - event.relative.y * mouse_sensitivity, -PI / 4, PI / 8)
		camera_global_target_angle += -event.relative.x * mouse_sensitivity
	
	if event.is_action_pressed("pause"):
		
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)
