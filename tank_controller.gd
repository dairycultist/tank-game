extends RigidBody3D

# basic movement is you're just a floating box; the wheels/legs/treads are completely visual

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
	
	for ray in suspension_rays:
		
		if _apply_suspension(ray):
			grounded = true
	
	if grounded:
		
		var up      :=  global_basis.y
		var forward := -global_basis.z
		var right   :=  global_basis.x
		
		# controls
		if Input.is_action_pressed("forward"):
			apply_force(forward * drive_force * delta, -up * 0.2)
		
		if Input.is_action_pressed("backward"):
			apply_force(-forward * drive_force * delta, -up * 0.2)
		
		if Input.is_action_pressed("left"):
			apply_torque(up * turn_torque * delta)
			
		if Input.is_action_pressed("right"):
			apply_torque(up * -turn_torque * delta)
		
		# apply lateral drag
		var lateral_velocity := forward * linear_velocity.dot(forward) + right * linear_velocity.dot(right)
		
		apply_central_force(-lateral_velocity * drag * delta)
		
		# apply angular drag
		apply_torque(up * -angular_velocity.dot(up) * drag * delta)
	
func _apply_suspension(ray: RayCast3D) -> bool:
	
	# the raycast represents suspension; if the ray hits something before the point
	# of zero compression, it means the suspension is compressed ("grounded") and
	# we should apply a relevant upward force at the position of the raycast's origin
	if ray.is_colliding():
		
		var up := global_basis.y
		
		var compression_distance := ((ray.target_position + ray.global_position) - ray.get_collision_point()).length()
		var compression_fac := compression_distance / ray.target_position.length()
		
		# stiffness opposes compression
		var suspension_force := compression_fac * stiffness
		
		# dampening opposes vertical velocity at the raycast's origin
		var velocity_at_position := linear_velocity + angular_velocity.cross(ray.global_position - global_position)
		var vertical_velocity_at_position = velocity_at_position.dot(up)
		
		suspension_force -= vertical_velocity_at_position * dampening
		
		# apply force
		apply_force(suspension_force * up, ray.global_position - global_position)
		
		return true
		
	return false
