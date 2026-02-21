# res://audio.gd
extends Node

signal music_volume_changed(value: float)

const MUSIC_BUS := "Music"
var music_linear: float = 0.5

func _ready() -> void:
	# Initialize from current bus value, then apply (keeps consistent)
	music_linear = get_music_volume()
	set_music_volume(music_linear)

func set_music_volume(v: float) -> void:
	music_linear = clamp(v, 0.0, 1.0)

	var id := AudioServer.get_bus_index(MUSIC_BUS)
	if id == -1:
		push_warning("Audio bus not found: " + MUSIC_BUS)
		return

	AudioServer.set_bus_volume_db(id, linear_to_db(music_linear))
	emit_signal("music_volume_changed", music_linear)

func get_music_volume() -> float:
	var id := AudioServer.get_bus_index(MUSIC_BUS)
	if id == -1:
		return music_linear

	return db_to_linear(AudioServer.get_bus_volume_db(id))
