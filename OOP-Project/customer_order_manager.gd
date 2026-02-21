extends Node

signal order_placed(item_name: String, customer: Node)
signal order_ready(item_name: String, customer: Node)

@export var queue_manager: Node

func _ready():
	queue_manager.connect("customer_left", Callable(self, "_on_customer_left"))

func place_order(order, customer):
	print("Received order:", order, "from", customer.name)
	emit_signal("order_placed", order, customer)

	# ✅ Save pending order state
	#GameDataManager.data["queue"]["line"].append({
		#"order": order,
		#"customer_name": customer.name
	#})
	GameDataManager.save_game()

func serve_order(order, customer):
	print("Order is ready for", customer.name)
	emit_signal("order_ready", order, customer)
	# ✅ Update persistent stats
	GameDataManager.serve_customer(order)

	# ✅ Remove from queue state
	for i in range(GameDataManager.data["queue"]["line"].size()):
		var entry = GameDataManager.data["queue"]["line"][i]
		if entry["customer_name"] == customer.name:
			GameDataManager.data["queue"]["line"].remove_at(i)
			break

	GameDataManager.save_game()

func _on_customer_left():
	print("Customer served, next one can step forward")
	GameDataManager.save_game()
