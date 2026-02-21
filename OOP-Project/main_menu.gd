extends Node3D   # Attach this to the root of Main.tscn

@onready var gameplay_root: Node3D = $GameplayRoot
@onready var hud_layer: CanvasLayer = $HUDLayer
@onready var player: CharacterBody3D = $GameplayRoot/PlayerBody
@onready var main_menu: Control = $MainMenu

func _ready() -> void:
	# If starting fresh, show menu
	if GameDataManager.data["stats"]["customers_served"] == 0:
		# Fresh start → show menu
		gameplay_root.visible = false
		hud_layer.visible = false
		main_menu.visible = true
	else:
		# Loaded game → let restore_state handle visibility
		main_menu.visible = false

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#GameDataManager.call_deferred("restore_state", self)
	print("DEBUG: Main ready -> menu visible =", main_menu.visible)
	print("DEBUG: Gameplay visible =", gameplay_root.visible)
	print("DEBUG: HUD visible =", hud_layer.visible)

func _exit_tree() -> void:
	pass

func _restore_player_position(pos: Array) -> void:
	if player:
		player.global_transform.origin = Vector3(pos[0], pos[1], pos[2])
