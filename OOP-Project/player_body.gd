extends CharacterBody3D

@export var speed: float = 6.0

#Offsets relative to the slot 
@export var rice_offset: Vector3  = Vector3(0.0, 0.0, 0.0)

#default for holding cup in hand
@export var drink_offset: Vector3 = Vector3.ZERO

#Make it visible in hand
@export var drink_hold_scale: Vector3 = Vector3(5, 5, 5)

@onready var anim_player: AnimationPlayer = $Main_Character/AnimationPlayer
@onready var rice_slot: Node3D  = $Main_Character/HandSlot
@onready var drink_slot: Node3D = $Main_Character/RightHandSlot

#control the car movement
var move_target: Vector3 = Vector3.ZERO
var has_target: bool = false

#drag 
var dragging: bool = false

var held_rice: Node3D = null
var held_drink: Node3D = null
var held_rice_scale: Vector3 = Vector3.ONE
#var money: int = 0
#var levels_unlocked: int = 1
var restoring_from_save: bool = true 

func _ready() -> void:
	set_process_unhandled_input(true)  
	if rice_slot == null:
		push_error("Player: rice_slot not found: $Main_Character/HandSlot")
	if drink_slot == null:
		push_error("Player: drink_slot not found. Create RightHandSlot under HandSlot.")
	# after restore_state runs, set this to false
	#restoring_from_save = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
		else:
			dragging = false

	if event is InputEventMouseMotion and dragging:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * 1000.0

			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(from, to)
			var result = space_state.intersect_ray(query)

			if result.has("position"):
				move_target = result.position
				has_target = true

func _physics_process(_delta: float) -> void:
	if has_target:
		print("Moving toward: ", move_target)

		var direction = (move_target - global_position)
		direction.y = 0  # ignore vertical difference
		if direction.length() > 0.1:
			direction = direction.normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			# Rotate player toward the target
			look_at(Vector3(move_target.x, global_position.y, move_target.z), Vector3.UP)

			move_and_slide()

			# play walk animation
			if anim_player and (not anim_player.is_playing() or anim_player.current_animation != "ArmatureAction"):
				anim_player.play("ArmatureAction")
		else:
			# reached target
			velocity = Vector3.ZERO
			has_target = false
	else:
		velocity = Vector3.ZERO
		move_and_slide()
	# keep rice following slot 
	_follow_rice()

	# Only update JSON after restore is complete
	if not restoring_from_save:
		GameDataManager.data["scene"]["player_position"] = [
			global_position.x,
			global_position.y,
			global_position.z
		]
		print("DEBUG: PlayerBody writing position to GameDataManager:", global_position)

# Debug helper to confirm after restore
func _print_position_after_restore() -> void:
	print("DEBUG: PlayerBody actual global_position after restore:", global_position)

func _follow_rice() -> void:
	if held_rice == null or not is_instance_valid(held_rice) or rice_slot == null:
		return

	held_rice.global_transform = rice_slot.global_transform
	held_rice.global_position += rice_slot.global_transform.basis * rice_offset
	held_rice.scale = held_rice_scale

#Rice pickup
func pick_up_rice(item: Node3D) -> void:
	if item == null or held_rice != null:
		return

	held_rice = item
	held_rice_scale = item.scale
	_reparent_keep_world(item, self)

	# Update inventory in GameDataManager
	GameDataManager.add_item("rice")

#Drink pickup
func pick_up_drink(cup: Node3D) -> void:
	if cup == null or held_drink != null:
		return
	if drink_slot == null:
		push_error("Player: RightHandSlot missing.")
		return

	held_drink = cup

	# Put cup under RightHandSlot
	_reparent_keep_world(cup, drink_slot)

	# Place and size it in the hand
	cup.position = drink_offset
	cup.rotation_degrees = Vector3(0, 90, 0)
	cup.scale = drink_hold_scale

	# Update inventory in GameDataManager
	GameDataManager.add_item("drink")

func _reparent_keep_world(n: Node3D, new_parent: Node) -> void:
	var t := n.global_transform
	if n.get_parent() != null:
		n.get_parent().remove_child(n)
	new_parent.add_child(n)
	n.global_transform = t

func get_held_item_name() -> String:
	if held_rice != null and is_instance_valid(held_rice):
		return "rice"
	if held_drink != null and is_instance_valid(held_drink):
		return "drink"
	return ""

func consume_held_item() -> void:
	# remove rice first if holding it else drink
	if held_rice != null and is_instance_valid(held_rice):
		held_rice.queue_free()
		held_rice = null
		# Update inventory
		GameDataManager.consume_item("rice")

		return

	if held_drink != null and is_instance_valid(held_drink):
		held_drink.queue_free()
		held_drink = null
		# Update inventory
		GameDataManager.consume_item("drink")

		return
func consume_held_item_by_name(item_name: String) -> void:
	if item_name == "rice" and held_rice != null and is_instance_valid(held_rice):
		held_rice.queue_free()
		held_rice = null
		GameDataManager.consume_item("rice")
	elif item_name == "drink" and held_drink != null and is_instance_valid(held_drink):
		held_drink.queue_free()
		held_drink = null
		GameDataManager.consume_item("drink")
