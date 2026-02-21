extends Node3D

@export var dispense_interval: float = 5.0
@export var drink_scene: PackedScene
@export var max_stack: int = 3

#cup size when sitting on machine 
@export var machine_cup_scale: Vector3 = Vector3(0.65,0.65, 0.65)

@onready var timer: Timer = $Timer
@onready var pickup_area: Area3D = $PickupArea
@onready var sp1: Node3D = $SpawnPoint1
@onready var sp2: Node3D = $SpawnPoint2
@onready var sp3: Node3D = $SpawnPoint3

# Add sound node
@onready var dispense_sound: AudioStreamPlayer = $DispenseSound

var stack: Array[Node3D] = []
var is_making: bool = false

func _ready() -> void:
	if drink_scene == null:
		push_error("DrinkMachine: Assign drink_scene in Inspector.")
		return

	pickup_area.monitoring = true
	pickup_area.monitorable = true

	timer.stop()
	timer.one_shot = true
	timer.wait_time = dispense_interval
	if not timer.timeout.is_connected(_on_make_done):
		timer.timeout.connect(_on_make_done)

	if not pickup_area.body_entered.is_connected(_on_body_entered):
		pickup_area.body_entered.connect(_on_body_entered)

	_start_making()

func _start_making() -> void:
	if is_making: return
	if stack.size() >= max_stack: return
	is_making = true
	timer.start()

func _on_make_done() -> void:
	is_making = false
	_spawn_one()
	# Play sound when drink is ready
	if dispense_sound:
		dispense_sound.stop()
		dispense_sound.play()

	if stack.size() < max_stack:
		_start_making()

func _spawn_one() -> void:
	if stack.size() >= max_stack:
		return

	var marker: Node3D = _marker_for_index(stack.size())
	if marker == null:
		return

	var cup := drink_scene.instantiate() as Node3D
	if cup == null:
		push_error("DrinkMachine: drink_scene root must be Node3D.")
		return

	add_child(cup)
	cup.global_transform = marker.global_transform
	cup.scale = machine_cup_scale

	stack.append(cup)
	# Save machine state
	GameDataManager.data["cooking_stations"]["soda_fountain"] = stack.size()
	GameDataManager.save_game()

func _marker_for_index(i: int) -> Node3D:
	match i:
		0: return sp1
		1: return sp2
		2: return sp3
		_: return null

func _on_body_entered(body: Node) -> void:
	var player := _find_player(body)
	if player == null:
		return
	if not player.has_method("pick_up_drink"):
		return
	if not ("held_drink" in player):
		return

	# already holding drink don't take new one
	if player.held_drink != null:
		return

	if stack.is_empty():
		return

	var cup: Node3D = stack.pop_back()
	if cup != null and is_instance_valid(cup):
		player.pick_up_drink(cup) 
		# Update inventory in GameDataManager
		GameDataManager.add_item("drink")

		# Save machine state
		GameDataManager.data["cooking_stations"]["soda_fountain"] = stack.size()
		GameDataManager.save_game()

	_start_making()

func _find_player(n: Node) -> Node:
	var cur: Node = n
	while cur != null:
		if cur.has_method("pick_up_drink"):
			return cur
		cur = cur.get_parent()
	return null
