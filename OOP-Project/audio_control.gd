extends AudioStreamPlayer2D

@export var music_bus_name: String = "Music"

@onready var settings_panel: Node = get_node_or_null("../Settings") # Settings is sibling in your tree
var _music_slider: HSlider = null

func _ready() -> void:
	# Make sure this player uses the Music bus
	bus = music_bus_name

	# ✅ LOOP: when finished, play again
	if not finished.is_connected(_on_music_finished):
		finished.connect(_on_music_finished)

	# Start if not already
	if not playing:
		play()

	# Bind the first HSlider inside Settings (top slider = music)
	_music_slider = _find_first_hslider(settings_panel)
	if _music_slider:
		_music_slider.set_value_no_signal(_get_bus_linear())
		if not _music_slider.value_changed.is_connected(_on_slider_changed):
			_music_slider.value_changed.connect(_on_slider_changed)

func _on_music_finished() -> void:
	play() # loop forever

func _on_slider_changed(v: float) -> void:
	_set_bus_linear(v)

# ---------------- helpers ----------------

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

func _get_bus_linear() -> float:
	var id := AudioServer.get_bus_index(music_bus_name)
	if id == -1:
		return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(id))

func _set_bus_linear(v: float) -> void:
	var id := AudioServer.get_bus_index(music_bus_name)
	if id == -1:
		return
	AudioServer.set_bus_volume_db(id, linear_to_db(clamp(v, 0.0, 1.0)))
