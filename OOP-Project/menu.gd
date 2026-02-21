extends Control

@onready var main_buttons: VBoxContainer = $main_buttons
@onready var settings: Panel = $Settings
@onready var how_to_play: Panel = $Panel

func _ready() -> void:
	main_buttons.visible = true
	settings.visible = false
	how_to_play.visible = false

	GameDataManager.load_game()
	print("DEBUG: Auto-restore on startup")

func _on_start_pressed() -> void:
	main_buttons.visible = false
	settings.visible = false
	how_to_play.visible = false
	self.visible = false

	var main_scene = get_parent()
	main_scene.gameplay_root.visible = true
	main_scene.hud_layer.visible = true

	GameDataManager.restore_state(main_scene)
	print("DEBUG: Gameplay started and state restored")

func _on_setting_pressed() -> void:
	main_buttons.visible = false
	settings.visible = true
	how_to_play.visible = false

func _on_back_settings_pressed() -> void:
	main_buttons.visible = true
	settings.visible = false
	how_to_play.visible = false

func _on_how_to_play_pressed() -> void:
	main_buttons.visible = false
	settings.visible = false
	how_to_play.visible = true

func _on_back_pressed() -> void:
	main_buttons.visible = true
	settings.visible = false
	how_to_play.visible = false

func _on_quit_pressed() -> void:
	GameDataManager.save_game()
	get_tree().quit()
