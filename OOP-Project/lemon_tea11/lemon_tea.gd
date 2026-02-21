extends Node3D

@onready var area = $Area3D
var is_picked = false

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player" and not is_picked:
		body.pick_up(self)
		is_picked = true
