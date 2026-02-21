extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Car.ai_enabled = true
	$Car.ai_state = "drive_to_window"
	$Car.current_wp = 0
	$Car.wait_timer = 2.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
