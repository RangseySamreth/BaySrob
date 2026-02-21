extends Node3D

var customers: Array = []
signal customer_left

func register_customer(customer):
	print("Registering customer:", customer.name, " id=", customer.get_instance_id())
	customers.append(customer)
	customer.queue_offset = customers.size() - 1  # 0 for first, 1 for second, etc.
	update_queue_positions()
	# Optional: connect to a signal so we know when they leave
	if not customer.is_connected("tree_exited", Callable(self, "_on_customer_left")):
		customer.connect("tree_exited", Callable(self, "_on_customer_left"))

	# ✅ Save queue state
	#GameDataManager.data["queue"]["line"] = []
	#for cust in customers:
		#GameDataManager.data["queue"]["line"].append(cust.get_save_data())
	GameDataManager.save_game()

# Called when a customer leaves (queue_free or despawn)
func _on_customer_left():
	# Remove any customers that are no longer in the tree
	customers = customers.filter(func(cust): return cust.is_inside_tree())
	print("Customer left, active count:", customers.size())
	# ✅ Save queue state
	#GameDataManager.data["queue"]["line"] = []
	#for cust in customers:
		#GameDataManager.data["queue"]["line"].append(cust.get_save_data())
	GameDataManager.call_deferred("save_game")

# Utility: get the next customer in line
func get_next_customer() :
	if customers.size() > 0:
		return customers[0]

func unregister_customer(customer: PathFollow3D):
	if customers.has(customer):
		customers.erase(customer)
		update_queue_positions()
		emit_signal("customer_left")
		customer.call_deferred("queue_free")
		# ✅ Save queue state
		#GameDataManager.data["queue"]["line"] = []
		#for cust in customers:
			#GameDataManager.data["queue"]["line"].append(cust.get_save_data())
		GameDataManager.save_game()

func update_queue_positions():
	for i in range(customers.size()):
		customers[i].queue_offset = i
