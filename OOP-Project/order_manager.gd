extends Node

signal order_ready(item_name: String)

func _ready() -> void:
	pass
	
func place_order(order_name: String):
	print("Car ordered: ", order_name)
	# Spawn the requested item in the kitchen area
	emit_signal("order_ready", order_name)
