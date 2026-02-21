# res://car_spawner.gd
extends Node

@export var car_scene: PackedScene
@export var spawn_delay := 0.2  # small delay after a car disappears

@onready var path3d: Path3D = get_parent() as Path3D

var current_car: PathFollow3D = null
var restoring_from_save: bool = false


func _ready() -> void:
	if path3d == null:
		push_error("CarSpawner must be under Car_Path (Path3D).")
		return

	# If restoring from save, don't spawn a new car automatically
	if restoring_from_save:
		print("DEBUG: CarSpawner restoring from save, skipping initial spawn")
		return

	# ✅ Use existing car in scene (ANY name) if found
	current_car = _find_existing_car()

	if current_car != null:
		_connect_finished(current_car)
	else:
		_spawn_new_car()


func _find_existing_car() -> PathFollow3D:
	for c in path3d.get_children():
		if c is PathFollow3D:
			return c as PathFollow3D
	return null


func _connect_finished(car: PathFollow3D) -> void:
	if car == null:
		return

	if car.has_signal("car_finished"):
		if not car.is_connected("car_finished", Callable(self, "_on_car_finished")):
			car.connect("car_finished", Callable(self, "_on_car_finished"))
	else:
		push_error("Car missing signal car_finished. Attach car_path_follow.gd to PathFollow3D root.")


func _on_car_finished() -> void:
	# the car script will queue_free() itself
	current_car = null

	# ✅ wait a bit so the old car fully disappears
	await get_tree().create_timer(spawn_delay).timeout

	_spawn_new_car()


func _spawn_new_car() -> void:
	if restoring_from_save:
		print("DEBUG: Skipping spawn because restoring_from_save = true")
		return

	if car_scene == null:
		push_error("car_scene is empty in CarSpawner!")
		return

	# ✅ prevent double spawn
	if current_car != null and is_instance_valid(current_car):
		return

	var car = car_scene.instantiate()
	if not (car is PathFollow3D):
		push_error("car_scene root must be PathFollow3D!")
		return

	current_car = car as PathFollow3D
	path3d.add_child(current_car)

	# ✅ reset properly
	current_car.progress = 0.0
	current_car.progress_ratio = 0.0

	_connect_finished(current_car)
