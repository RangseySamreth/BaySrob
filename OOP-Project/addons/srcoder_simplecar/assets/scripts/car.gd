extends VehicleBody3D

@export_category("Visual / Stability Settings")
@export var front_wheel_grip := 4.0
@export var rear_wheel_grip := 4.5

@onready var driving_wheels: Array[VehicleWheel3D] = [
	$WheelBackLeft,
	$WheelBackRight
]

@onready var steering_wheels: Array[VehicleWheel3D] = [
	$WheelFrontLeft,
	$WheelFrontRight
]

func _ready():
	# Set grip (visual only now)
	for wheel in steering_wheels:
		wheel.wheel_friction_slip = front_wheel_grip
	for wheel in driving_wheels:
		wheel.wheel_friction_slip = rear_wheel_grip

	# IMPORTANT: Disable physics response
	sleeping = true

func _physics_process(delta):
	# Completely disable physics movement
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	# Lock rotation to upright (2.5D)
	rotation.x = 0.0
	rotation.z = 0.0
