extends CharacterBody3D

var speed = 6.0
var mouse_sensitivity = 0.003

var target_position: Vector3
var has_target := false

@onready var pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# Mouse look
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	# Click-to-move
	if event.is_action_pressed("mouse_click"):
		var mouse_pos = event.position
		var space_state = get_world_3d().direct_space_state
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_dir = camera.project_ray_normal(mouse_pos)

		var query = PhysicsRayQueryParameters3D.new()
		query.from = ray_origin
		query.to = ray_origin + ray_dir * 2000
		query.exclude = [self]

		var result = space_state.intersect_ray(query)

		if result:
			target_position = result.position
			has_target = true

func _physics_process(delta):
	# WASD movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# Click-to-move movement
	if has_target:
		var move_dir = (target_position - global_transform.origin).normalized()
		velocity = move_dir * speed

		if global_transform.origin.distance_to(target_position) < 0.5:
			has_target = false
			velocity = Vector3.ZERO

	move_and_slide()
