extends Node

@export var queue_spacing: float = 1.5     # distance between customers
@export var counter_fraction: float = 0.8  # fraction along curve for counter
@export var auto_serve: bool = true        # toggle auto-serving
@export var serve_interval: float = 3.0    # time between serving customers

var customers: Array[PathFollow3D] = []
var path: Path3D

func _ready():
	path = get_parent() as Path3D
	if path == null or path.curve == null:
		push_error("QueueManager must be child of Path3D with a Curve3D")
		return

	if auto_serve:
		var timer = Timer.new()
		timer.wait_time = serve_interval
		timer.autostart = true
		timer.one_shot = false
		add_child(timer)
		timer.timeout.connect(serve_next_customer)

func register_customer(customer: PathFollow3D):
	customers.append(customer)
	update_queue_positions()

func unregister_customer(customer: PathFollow3D):
	customers.erase(customer)
	update_queue_positions()
	# Force remaining customers to walk forward
	for c in customers:
		if c.ai_state == "waiting":
			c.ai_state = "walking"

func update_queue_positions():
	for i in range(customers.size()):
		var offset = get_target_offset(i)
		print("Customer %d assigned offset: %.2f" % [i, offset])
		customers[i].set_queue_index(i, offset)

func get_target_offset(index: int) -> float:
	if path == null or path.curve == null:
		return 0.0

	var curve: Curve3D = path.curve
	var total_length := curve.get_baked_length()

	# Place counter near end of path (fraction of total length)
	var base_offset := total_length * counter_fraction

	# Each customer stands behind the counter point by queue_spacing
	var offset := base_offset - index * queue_spacing

	# Clamp so it's always inside the curve range
	return clamp(offset, 0.1, curve.get_baked_length() - 0.1)

func serve_next_customer():
	if customers.size() > 0:
		var first_customer = customers[0]
		first_customer.receive_order()
