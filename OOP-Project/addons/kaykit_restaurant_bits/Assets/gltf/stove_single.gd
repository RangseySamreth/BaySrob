# res://stove_single.gd
extends Node3D

@export var cook_interval: float = 5.0
@export var rice_scene: PackedScene
@export var max_stack: int = 3
@export var stack_step_y: float = 0.12

@onready var timer: Timer = $Timer
@onready var pickup_area: Area3D = $PickupArea
@onready var stack_point: Marker3D = $SpawnPoint1
@onready var cook_sound: AudioStreamPlayer = $CookSound

var stack: Array[Node3D] = []
var is_cooking := false

func _ready() -> void:
	timer.one_shot = true
	timer.wait_time = cook_interval
	if not timer.timeout.is_connected(_on_cook_done):
		timer.timeout.connect(_on_cook_done)

	if not pickup_area.body_entered.is_connected(_on_body_entered):
		pickup_area.body_entered.connect(_on_body_entered)

	_start_cooking()

func _start_cooking() -> void:
	if is_cooking: return
	if stack.size() >= max_stack: return
	if rice_scene == null:
		push_error("Stove: rice_scene not assigned")
		return
	is_cooking = true
	timer.start()

func _on_cook_done() -> void:
	is_cooking = false
	_spawn_rice()

	if cook_sound:
		cook_sound.stop()
		cook_sound.play()

	# keep filling until max
	if stack.size() < max_stack:
		_start_cooking()

func _spawn_rice() -> void:
	if stack.size() >= max_stack:
		return

	var rice := rice_scene.instantiate() as Node3D
	if rice == null:
		return

	add_child.call_deferred(rice)   # safer, attaches to stove node
	stack.append(rice)
	call_deferred("_reposition_stack")

	# ✅ Save stove state
	GameDataManager.data["cooking_stations"]["stove"] = stack.size()
	GameDataManager.save_game()

func _reposition_stack() -> void:
	if stack_point == null or not stack_point.is_inside_tree():
		return  # skip until stack_point is ready

	var base := stack_point.global_transform
	for i in range(stack.size()):
		var r := stack[i]
		if r and is_instance_valid(r) and r.is_inside_tree():
			r.global_transform = base
			r.global_position.y += stack_step_y * i

func _on_body_entered(body: Node) -> void:
	var player := _find_player(body)
	if player == null:
		return

	# only give if player doesn't already hold rice
	if player.held_rice != null:
		return

	_give_one(player)

func _give_one(player: Node) -> void:
	if stack.is_empty():
		return

	var rice := stack.pop_back() as Node3D  # LIFO
	if rice and is_instance_valid(rice):
		player.pick_up_rice(rice)
		# ✅ Update inventory in GameDataManager
		GameDataManager.add_item("rice")

		# ✅ Save stove state
		GameDataManager.data["cooking_stations"]["stove"] = stack.size()
		GameDataManager.save_game()

	_reposition_stack()

	# wait cook_interval before replacing the removed one
	_start_cooking()

func _find_player(n: Node) -> Node:
	var cur := n
	while cur:
		if cur.has_method("pick_up_rice"):
			return cur
		cur = cur.get_parent()
	return null
