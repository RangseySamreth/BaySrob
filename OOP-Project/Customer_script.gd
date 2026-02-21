extends PathFollow3D

@export var speed := 2.0
@export var stop_ratio := 0.65

@onready var serve_area: Area3D = $Walking_ani/Area3D

@export var order_options := ["drink", "rice"]
@export var food_icons := {
	"drink": preload("res://drink.png"),
	"rice": preload("res://rice.png")
}

@onready var anim_player: AnimationPlayer = $Walking_ani/AnimationPlayer
@onready var greet_player: AudioStreamPlayer = $AudioStreamPlayer   # greeting sound node

@onready var queue_manager = get_node("/root/Main/GameplayRoot/Walkin_Customer/QueueManagerC")
var queue_index : int = -1
var queue_offset: float = 0.0
var ai_state := "walking"   # "walking" or "waiting"
var waiting := false
var stopped := false
var order : String = ""
var player_level: int = 1   # track current level
var has_ordered: bool = false   # ✅ add this line
var served: bool = false
var spacing: float = 0.02  # adjust based on customer size

func _ready():
	#force to reset
	served = false
	has_ordered = false 
	stopped = false
	waiting = false
	ai_state = "walking"

	# Get player level from Control or GameManager
	var control_node = get_node("/root/Main/HUDLayer/Control")
	player_level = GameManager.level   # or control_node.current_level if you store it there

	# Build a filtered list of available orders
	var available_orders: Array = []
	for option in order_options:
		if option == "drink" and player_level < 3:
			continue  # skip drinks until level 4
		available_orders.append(option)

	# Pick random order from allowed options
	if available_orders.size() > 0:
		order = available_orders[randi() % available_orders.size()]
		print(name, " ordered: ", order)
	else:
		push_error("No available orders at current level!")

	# Connect to Control script for level changes
	if control_node.has_signal("level_changed"):
		if not control_node.is_connected("level_changed", Callable(self, "_on_level_changed")):
			control_node.connect("level_changed", Callable(self, "_on_level_changed"))

	# Connect to OrderManager
	var order_manager = get_node("/root/Main/GameplayRoot/Walkin_Customer/OrderManagerC")
	if order_manager.has_signal("order_ready"):
		order_manager.connect("order_ready", Callable(self, "_on_order_ready"))
	else:
		print("OrderManagerC has no 'order_ready' signal")

# Register with QueueManager
	queue_manager.register_customer(self)
	if not queue_manager.is_connected("customer_left", Callable(self, "_on_customer_left")):
		queue_manager.connect("customer_left", Callable(self, "_on_customer_left"))

	# ------------------ ADD: Serve area connect (blue box) ------------------
	if serve_area:
		if not serve_area.body_entered.is_connected(_on_serve_area_body_entered):
			serve_area.body_entered.connect(_on_serve_area_body_entered)
	else:
		push_error("serve_area not found: check path $Walking_ani/Area3D")
	
	# ✅ Start walking immediately
	start_walking()

	print(name, " spawned with served=", served, " has_ordered=", has_ordered)

func _on_level_changed(new_level: int) -> void:
	player_level = new_level
	# If level just reached 4, allow drinks in future orders
	if new_level >= 4:
		print("Customers can now order drinks at level 4+")
		
func _on_customer_left():
	pass

func _process(delta):
	match ai_state:
		"walking":
			# Move along the path
			progress += speed * delta

			# Play walk animation if not already playing
			if anim_player and not anim_player.is_playing():
				anim_player.play("ArmatureAction")

			var target_stop = stop_ratio - (queue_offset * spacing)
	
			# Check if it's time to stop at the counter
	# Keep walking until reaching the current target stop
			if not served:
				if progress_ratio < target_stop:
				# keep walking forward until reaching new target
					progress += speed * delta
					stopped = false
					ai_state = "walking"
				elif progress_ratio >= target_stop and not stopped:
					stop_walking()
					print(name, " is waiting for ", order)
	
					if greet_player:
						greet_player.play()
					else:
						push_error("GreetPlayer node not found!")
		# order placement logic...

				var order_manager = get_node("/root/Main/GameplayRoot/Walkin_Customer/OrderManagerC")
				if not has_ordered:
					has_ordered = true
					order_manager.place_order(order, self)
					show_order_icon(order)

				# ✅ Add this check at the end of walking logic
				if served:
					# Keep walking until reaching the end
					if progress_ratio < 1.0:
						progress += speed * delta
					else:
						print(name, " reached end of path and leaves")
					queue_manager.unregister_customer(self)   # unregister when leaving
					queue_free()

		"waiting":
			# Ensure walk animation is stopped
			if anim_player and anim_player.is_playing():
				anim_player.stop()
			# Optional: play idle animation if you have one
			# anim_player.play("Idle")
			var target_stop = stop_ratio - (queue_offset * spacing)
			# If my current position is behind the new target, resume walking
			if not served and progress_ratio < target_stop: 
				start_walking()

# --- Animation helpers ---
func start_walking():
	ai_state = "walking"
	waiting = false
	stopped = false
	if anim_player and not anim_player.is_playing():
		anim_player.play("ArmatureAction")

func stop_walking():
	ai_state = "waiting"
	waiting = true
	stopped = true
	if anim_player and anim_player.is_playing():
		anim_player.stop()

# ------------------ ADD: Serve when player enters blue box ------------------
func _on_serve_area_body_entered(body: Node) -> void:
	# only serve when customer is waiting at counter
	if ai_state != "waiting" or not waiting:
		return

	# must be player (add player to group "player")
	if not body.is_in_group("player"):
		return

	# ask player what item they are holding
	var held_name := ""
	if body.has_method("get_held_item_name"):
		held_name = body.get_held_item_name()

	# wrong item / empty hands → do nothing
	if held_name == "" or held_name != order:
		return

	# remove item from player
	if body.has_method("consume_held_item_by_name"):
		body.consume_held_item_by_name(held_name)
	elif body.has_method("consume_held_item"):
		body.consume_held_item()
	else:
		print("Player missing consume function. Add consume_held_item_by_name() to player.")
		return

	print("✅ Served", order, "to", name)

	# ------------------ ADD: REWARD MONEY + STAR ------------------
	if order == "rice":
		GameManager.add_money(10)
	elif order == "drink":
		GameManager.add_money(5)

	GameManager.add_stars(1)
	GameDataManager.add_stars(1)
	GameDataManager.serve_customer(order)

	# -------------------------------------------------------------
	_clear_order_icon()

	# customer leaves (same style as your order_ready)
	has_ordered = false
	waiting = false
	stopped = false
	served = true
	ai_state = "walking"

	if anim_player and not anim_player.is_playing():
		anim_player.play("ArmatureAction")

	# 🔑 Immediately unregister so offsets shift forward
	queue_manager.unregister_customer(self)


# keeps your function (not used by serve_area but ok to keep)
func receive_item(item: Node3D):
	print("Customer received: ", item.name)
	stop_walking()
	# After receiving item, customer should leave
	start_walking()

#func _on_order_ready(item_name: String, target_customer: Node):
	#if self == target_customer and waiting and item_name == order:
		#print("Order is ready for ", name, "! Customer leaves...")
		#waiting = false
		#stopped = false
		#has_ordered = false
		#ai_state = "walking"
#
		## Resume walking animation
		#if anim_player and not anim_player.is_playing():
			#anim_player.play("ArmatureAction")
#
		#queue_manager.unregister_customer(self)
		#queue_free()

func receive_order():
	if waiting:
		print("Order ready for ", name, "! Customer leaves...")
		waiting = false
		stopped = false
		ai_state = "walking"
		get_node("/root/Main/GameplayRoot/Walkin_Customer/QueueManagerC").unregister_customer(self)
		#queue_free()
		# At this point, the car will wait until the order_ready signal is received

func show_order_icon(order_name: String):
	var display_node = get_node_or_null("OrderBubble/OrderDisplay")
	if not display_node:
		push_error("OrderDisplay (Marker3D) not found under OrderBubble!")
		return

	# Clear old children
	for child in display_node.get_children():
		child.queue_free()

	# Frame
	var frame = MeshInstance3D.new()
	frame.mesh = QuadMesh.new()
	frame.scale = Vector3(0.3, 0.3, 0.3)
	frame.position = Vector3(0, 0.5, 0)
	display_node.add_child(frame)

	# Food icon
	var texture: Texture2D = food_icons.get(order_name)
	if texture:
		var icon = Sprite3D.new()
		icon.texture = texture
		icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # always face camera
		icon.scale = Vector3(0.1, 0.1, 0.1)

		display_node = get_node_or_null("OrderBubble/OrderDisplay")
		if display_node:
			display_node.add_child(icon)
			icon.position = Vector3.ZERO  # position relative to Marker3D
		else:
			push_error("OrderDisplay (Marker3D) not found under OrderBubble!")
	else:
		push_error("No icon found for order: " + order_name)


# ------------------ ADD: clear bubble after serving ------------------
func _clear_order_icon() -> void:
	var display_node = get_node_or_null("OrderBubble/OrderDisplay")
	if not display_node:
		return
	for child in display_node.get_children():
		child.queue_free()

# --- Save/Load Helpers ---
func get_save_data() -> Dictionary:
	return {
		"order": order,
		"progress_ratio": progress_ratio,
		"ai_state": ai_state
	}

func load_save_data(data: Dictionary) -> void:
	order = data.get("order", "")
	progress_ratio = data.get("progress_ratio", 0.0)
	ai_state = data.get("ai_state", "walking")
