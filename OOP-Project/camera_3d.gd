extends Camera3D

@export var target: Node3D
@export var offset: Vector3 = Vector3(9, 10, 5) #(how far, camera height, left/right swift)
@export var smooth_speed: float = 5.0

func _process(delta):
	if target:
		# Desired camera position
		var desired_pos = target.global_position + offset
		# Smoothly move camera to that position
		global_position = lerp(global_position, desired_pos, smooth_speed * delta)
		# Make camera always look at the character
		look_at(target.global_position, Vector3.UP)
