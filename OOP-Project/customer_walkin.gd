extends PathFollow3D

@export var speed := 2.0
@export var stop_ratio := 0.5  # where the customer stops along the path
@export var order_options := ["drink", "rice"]
@export var food_prefabs := {
	"drink": preload("res://drink_icon.tscn"),
	"rice": preload("res://rice_icon.tscn")
}

var queue_offset: float = 0.0
var queue_index := 0
var is_blocked: bool = false
var waiting := false
var stopped := false
var order := ""

func _ready():
	order = order_options[randi() % order_options.size()]
	print(name, " ordered: ", order)

	var order_manager = get_node("/root/Main/GameplayRoot/Customer_Path/OrderManager")
	if not order_manager.is_connected("order_ready", Callable(self, "_on_order_ready")):
		order_manager.connect("order_ready", Callable(self, "_on_order_ready"))

func _process(delta):
	if waiting or is_blocked:
		return

	progress += speed * delta

	# Stop at the counter + queue offset
	if not stopped and progress_ratio >= stop_ratio - queue_offset:
		stopped = true
		waiting = true
		print(name, " is waiting for ", order)

		var order_manager = get_node("/root/Main/GameplayRoot/Customer_Path/OrderManager")
		order_manager.place_order(order, self)
		show_order_icon(order)

func show_order_icon(order_name: String):
	var prefab = food_prefabs.get(order_name)
	if prefab:
		var instance = prefab.instantiate()
		$OrderBubble/OrderDisplay.add_child(instance)
		instance.transform.origin = Vector3.ZERO
		instance.scale = Vector3(0.3, 0.3, 0.3)
		instance.visible = true
		instance.show()

func _on_order_ready(item_name: String, target_customer: Node):
	if self == target_customer and waiting and item_name == order:
		print("Order is ready for ", name, "! Customer leaves...")
		waiting = false
		stopped = false
		get_node("/root/Main/GameplayRoot/Customer_Path/QueueManager").unregister_customer(self)
