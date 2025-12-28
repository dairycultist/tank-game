extends RigidBody3D

# TODO rotating camera rig that's always upright; turret attempts to face
# towards camera direction

@export_category("Control")
@export var drag: float = 50.0
@export var drive_force: float = 400.0
@export var turn_torque: float = 100.0

@export_category("Suspension")
## How much the suspension forces oppose compression.
@export var stiffness: float = 30.0
## How much vertical velocity (at the point of suspension) is diffused.
@export var dampening: float = 2.0

var suspension_rays: Array[Node]

func _ready() -> void:
	
	suspension_rays = find_children("*", "RayCast3D", false)

func _process(delta: float) -> void:
	
	var grounded := false
	
	# apply "suspension" which allows the tank to float above the ground
	# (wheels/legs/treads/hoverplates are completely visual and are all simulated the same way)
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
		
		# apply lateral drag
		var lateral_velocity := forward * linear_velocity.dot(forward) + right * linear_velocity.dot(right)
		
		apply_central_force(-lateral_velocity * drag * delta)
		
		# apply angular drag
		apply_torque(up * -angular_velocity.dot(up) * drag * delta)
	
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
