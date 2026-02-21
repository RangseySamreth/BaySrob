extends Control

@onready var settings_panel: Control = $Settings
@onready var shop_panel: Control = $Shop
@onready var money_label: Label = $Money/MoneyLabel

@onready var level_bar: ProgressBar = $ProgressBar
@onready var level_label: Label = $ProgressBar/Level
@onready var star_text: Label = $ProgressBar/Startext

@onready var congrats_panel: Control = $CongratsPanel
@onready var info_label: Label = $CongratsPanel/InfoLable
@onready var unlock_label: Label = $"CongratsPanel/Level unlock"
@onready var close_btn: Button = $CongratsPanel/cross
@onready var level_up_sound: AudioStreamPlayer2D = $CongratsPanel/LevelUpSound

# safer 
@onready var gameplay_root: Node = get_node_or_null("/root/Main/GameplayRoot")

var last_level: int = 1
var gameplay_paused := false

var _music_slider: HSlider = null


func _ready() -> void:
	settings_panel.visible = false
	shop_panel.visible = false
	congrats_panel.visible = false

	if not GameManager.money_changed.is_connected(_on_money):
		GameManager.money_changed.connect(_on_money)
	if not GameManager.stars_changed.is_connected(_on_stars):
		GameManager.stars_changed.connect(_on_stars)
	if not GameManager.level_changed.is_connected(_on_level):
		GameManager.level_changed.connect(_on_level)

	if close_btn and not close_btn.pressed.is_connected(_on_close_congrats_pressed):
		close_btn.pressed.connect(_on_close_congrats_pressed)

	_refresh_all()

	# bind music slider once (find it inside settings panel)
	_bind_music_slider()

	last_level = GameManager.level
	_show_level_message(1)


func _set_gameplay_paused(p: bool) -> void:
	gameplay_paused = p
	if not gameplay_root:
		return

	var mode := Node.PROCESS_MODE_DISABLED if p else Node.PROCESS_MODE_INHERIT
	gameplay_root.set_deferred("process_mode", mode)


func _refresh_all() -> void:
	_on_money(GameManager.money)
	_on_level(GameManager.level)
	_on_stars(GameManager.stars_in_level)


func _on_money(m: int) -> void:
	money_label.text = str(m)


func _on_stars(s: int) -> void:
	level_bar.value = clamp(s, 0, level_bar.max_value)
	_update_progress_text()


func _on_level(lv: int) -> void:
	level_bar.min_value = 0
	level_bar.max_value = max(1, GameManager.stars_needed)
	level_bar.value = GameManager.stars_in_level

	level_label.text = str(lv)
	_update_progress_text()

	if lv > last_level:
		_play_level_sound()
		_show_level_message(lv)
		GameDataManager.data["player"]["levels_unlocked"] = lv
		GameDataManager.save_game()

	last_level = lv


func _update_progress_text() -> void:
	star_text.text = str(GameManager.stars_in_level) + " / " + str(GameManager.stars_needed)


func _play_level_sound() -> void:
	if level_up_sound:
		level_up_sound.stop()
		level_up_sound.play()


func _show_level_message(lv: int) -> void:
	_set_gameplay_paused(true)

	congrats_panel.visible = true
	shop_panel.visible = false
	settings_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	match lv:
		1:
			unlock_label.text = "🎉 Welcome to Level 1!"
			info_label.text = """🍳 You already have a stove to cook Bay Srob 🍚

📜 Quick Rules:
• Rice = 💵 $10
• Each customer = ⭐ 1 star

✅ Serve customers to earn stars and level up!"""

		2:
			unlock_label.text = "🎉 Great job! Level 2!"
			info_label.text = """
⭐ Keep serving to collect more stars!
💪 You’re doing amazing — keep going!"""

		3:
			unlock_label.text = "🎉 Level 3!"
			info_label.text = """🧋 Lemon Tea is now available!

	• Drinks give 💵 $5  
	• And also ⭐ 1 star

	🔥 Keep going — you can do it!"""

		4:
			unlock_label.text = "🎉 Level 4 Unlocked!"
			info_label.text = """Keep serving to collect more stars!
	✨ You’re getting better — keep going!"""

		5:
			unlock_label.text = "🎉 Level 5 Unlocked!"
			info_label.text = """🔥 New Stove Available!

	You can now buy another stove to cook faster.
	More stoves = more food = more stars ⭐

	🚀 Upgrade your kitchen and keep growing!"""

		_:
			unlock_label.text = "🎉 Level " + str(lv) + "!"
			info_label.text = """⭐ Keep collecting stars  
	💵 Keep earning money  

	🔥 You’re doing great — keep going!"""



func _on_close_congrats_pressed() -> void:
	congrats_panel.visible = false
	_set_gameplay_paused(false)


func _on_shop_button_pressed() -> void:
	_set_gameplay_paused(true)
	shop_panel.visible = true
	settings_panel.visible = false
	congrats_panel.visible = false


func _on_cross2_pressed() -> void:
	shop_panel.visible = false
	_set_gameplay_paused(false)


func _on_gear_pressed() -> void:
	print("GEAR CLICKED") # DEBUG (remove later)
	_set_gameplay_paused(true)
	settings_panel.visible = true
	shop_panel.visible = false
	congrats_panel.visible = false

	# refresh slider value every time you open settings
	_sync_music_slider()


func _on_cross_pressed() -> void:
	settings_panel.visible = false
	_set_gameplay_paused(false)


func _on_buy_soda_pressed() -> void:
	if GameManager.buy_item("soda"):
		var soda_scene = preload("res://drink_machine.tscn").instantiate()
		if gameplay_root:
			gameplay_root.add_child(soda_scene)
			soda_scene.global_transform.origin = Vector3(-10, 1.75, -6)

		GameDataManager.data["upgrades"]["menu_items"].append("soda")
		GameDataManager.save_game()


func _on_buy_stove_pressed() -> void:
	if GameManager.buy_item("stove_1"):
		var stove_scene = preload("res://co.tscn").instantiate()
		if gameplay_root:
			gameplay_root.add_child(stove_scene)
			stove_scene.global_transform.origin = Vector3(0, 0, 3)

		GameDataManager.data["upgrades"]["menu_items"].append("stove_1")
		GameDataManager.save_game()


func _on_quit_pressed() -> void:
	GameDataManager.save_game()
	get_tree().quit()
	
# ✅ MUSIC SLIDER SYNC 
func _find_first_hslider(root: Node) -> HSlider:
	if root == null:
		return null

	for c in root.get_children():
		if c is HSlider:
			return c as HSlider
		var deeper := _find_first_hslider(c)
		if deeper:
			return deeper

	return null


func _bind_music_slider() -> void:
	# Find FIRST HSlider inside Settings panel (your top one = music)
	_music_slider = _find_first_hslider(settings_panel)

	if _music_slider == null:
		push_warning("No music slider (HSlider) found inside Settings panel.")
		return

	# Slider -> audio
	if not _music_slider.value_changed.is_connected(_on_music_slider_changed):
		_music_slider.value_changed.connect(_on_music_slider_changed)

	# Audio -> slider (sync between scenes)
	var audio := get_node_or_null("/root/Audio")
	if audio and not audio.music_volume_changed.is_connected(_on_music_volume_changed):
		audio.music_volume_changed.connect(_on_music_volume_changed)

	_sync_music_slider()


func _sync_music_slider() -> void:
	if _music_slider == null:
		return

	var audio := get_node_or_null("/root/Audio")
	if audio:
		_music_slider.set_value_no_signal(audio.get_music_volume())
	else:
		# fallback: read Music bus directly
		var id := AudioServer.get_bus_index("Music")
		if id != -1:
			_music_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(id)))


func _on_music_slider_changed(v: float) -> void:
	var audio := get_node_or_null("/root/Audio")
	if audio:
		audio.set_music_volume(v)
	else:
		var id := AudioServer.get_bus_index("Music")
		if id != -1:
			AudioServer.set_bus_volume_db(id, linear_to_db(clamp(v, 0.0, 1.0)))


func _on_music_volume_changed(v: float) -> void:
	if _music_slider:
		_music_slider.set_value_no_signal(v)
