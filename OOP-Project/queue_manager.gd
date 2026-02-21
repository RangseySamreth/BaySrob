# res://queue_manager.gd
extends Node
signal car_left

var cars: Array[PathFollow3D] = []
@export var spacing := 0.10

func register_car(car: PathFollow3D) -> void:
	if cars.has(car):
		return
	cars.append(car)
	_refresh()

func unregister_car(car: PathFollow3D) -> void:
	if not cars.has(car):
		return
	cars.erase(car)
	_refresh()
	emit_signal("car_left")

func _refresh() -> void:
	for i in range(cars.size()):
		var c := cars[i]
		c.queue_index = i
		c.queue_offset = -float(i) * spacing  # 0, -0.1, -0.2...

	# optional: update collision immediately
	for c in cars:
		if c and c.has_method("refresh_serve_collision"):
			c.refresh_serve_collision()
