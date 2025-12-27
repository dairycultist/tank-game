extends RigidBody3D

# basic movement is you're just a floating box; the wheels/legs/treads are completely visual

@export_category("Suspension")
## How much the suspension forces oppose compression.
@export var stiffness: float = 1500.0
## How much vertical velocity (at the point of suspension) is diffused.
@export var dampening: float = 150.0

var suspension_rays: Array[Node]

func _ready() -> void:
	
	suspension_rays = find_children("*", "RayCast3D", false)

func _process(_delta: float) -> void:
	
	for ray in suspension_rays:
		_apply_suspension(ray)
	
func _apply_suspension(ray: RayCast3D):
	
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
		var velocity_at_position := linear_velocity + angular_velocity.cross(ray.position)
		var vertical_velocity_at_position = velocity_at_position.dot(up)
		
		suspension_force -= vertical_velocity_at_position * dampening
		
		# apply force
		apply_force(suspension_force * up, ray.position)
