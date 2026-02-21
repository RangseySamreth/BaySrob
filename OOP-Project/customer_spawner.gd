extends Node

@export var path3d: Path3D
@export var queue_manager: Node
var customer_scene = load("res://walkinCustomer.tscn")
var restoring_from_save: bool = false

func _ready():
	queue_manager.connect("customer_left", Callable(self, "spawn_customer"))
	if not restoring_from_save:
		spawn_customer()        # spawn one immediately when the game starts
		$Timer.start()          # start the Timer so it keeps spawning customers
		$Timer.wait_time = 5.0   # spawn every 2 seconds
	print("Spawner ready, restoring_from_save =", restoring_from_save)
func spawn_customer():
	var customer = customer_scene.instantiate()

	# Make sure the customer follows the correct path
	path3d.add_child(customer)
	# Force reset state to avoid carry-over
	customer.progress_ratio = 0.0
	customer.served = false
	customer.has_ordered = false
	customer.stopped = false
	customer.waiting = false
	customer.ai_state = "walking"

	# Register with queue manager
	queue_manager.register_customer(customer)

	# Only save if this is a fresh spawn, not during restore
	if not restoring_from_save and customer.has_method("get_save_data"):
		#GameDataManager.data["customers"]["walk_in"].append(customer.get_save_data())
		GameDataManager.save_game()

	# Debug print to confirm
	print("Spawned new customer:", customer.name, " id=", customer.get_instance_id(), " served=", customer.served)

   # spawn a new customer every time the Timer fires
func _on_timer_timeout() -> void:
	spawn_customer() 
