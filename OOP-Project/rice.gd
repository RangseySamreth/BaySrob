extends Node3D

#looks correct in HandSlot
@export var hold_offset: Vector3 = Vector3(0.0, 0.0, 0.0)
@export var hold_rotation_deg: Vector3 = Vector3(0.0, 0.0, 0.0)

func _ready() -> void:
	if not is_in_group("pickup"):
		add_to_group("pickup")
	if not is_in_group("plates"):
		add_to_group("plates")

func on_picked_up(_hand_slot: Node3D) -> void:
	position = hold_offset
	rotation_degrees = hold_rotation_deg
