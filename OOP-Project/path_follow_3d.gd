# res://car_path_follow.gd
extends PathFollow3D
signal car_finished

@export var speed := 7.0
@export var stop_ratio := 0.35
@export var end_remove_ratio := 0.98

@export var order_options := ["drink", "rice"]
@export var food_icons := {
	"drink": preload("res://drink.png"),
	"rice": preload("res://rice.png")
}
@onready var drive_sound: AudioStreamPlayer = get_node_or_null("DriveSound")
var waiting := false
var leaving := false
var order := ""
var order_placed := false

var car_visual: Node3D = null
var serve_area: Area3D = null
var serve_shape: CollisionShape3D = null
var sound_played := false

func _ready() -> void:
	loop = false
	set_process(true)

	_attach_car_visual_if_needed()
	_pick_order()

	if serve_area and not serve_area.body_entered.is_connected(_on_serve_body_entered):
		serve_area.body_entered.connect(_on_serve_body_entered)

	set_serve_enabled(false)


func _attach_car_visual_if_needed() -> void:
	# 1) If "car" is already a child of this PathFollow3D
	car_visual = get_node_or_null("car")

	# 2) If not, try to find sibling "car" under Car_Path (Path3D) and reparent it
	if car_visual == null:
		var p := get_parent()
		if p:
			var sibling := p.get_node_or_null("car")
			if sibling and sibling is Node3D:
				var t := (sibling as Node3D).global_transform
				p.remove_child(sibling)
				add_child(sibling)
				(sibling as Node3D).global_transform = t
				car_visual = sibling as Node3D

	# Get ServeArea refs
	serve_area = null
	serve_shape = null
	if car_visual:
		serve_area = car_visual.get_node_or_null("ServeArea")
		if serve_area:
			serve_shape = serve_area.get_node_or_null("CollisionShape3D")


func _pick_order() -> void:
	var lvl := GameManager.level
	var available: Array[String] = []
	for o in order_options:
		if o == "drink" and lvl < 3 :
			continue
		available.append(o)

	order = available.pick_random() if available.size() > 0 else "rice"
	order_placed = false  # reset for each new car
	print(name, " ordered:", order)


func _process(delta: float) -> void:
	if leaving:
		progress += speed * delta
		if progress_ratio >= end_remove_ratio:
			emit_signal("car_finished")
			queue_free()
		return

	if waiting:
		return

	# Play sound once when car starts moving
	if not sound_played and progress_ratio < stop_ratio:
		if drive_sound:
			drive_sound.stop()
			drive_sound.play()
		sound_played = true

	progress += speed * delta

	if progress_ratio >= stop_ratio:
		waiting = true
		progress_ratio = stop_ratio

		if not order_placed:
			order_placed = true
			show_order_icon(order)

		set_serve_enabled(true)

func set_serve_enabled(enable: bool) -> void:
	# deferred avoids "blocked during in/out signal"
	if serve_area:
		serve_area.set_deferred("monitoring", enable)
		serve_area.set_deferred("monitorable", enable)
	if serve_shape:
		serve_shape.set_deferred("disabled", not enable)
		serve_shape.set_deferred("visible", enable)


# body_entered gives child collider, so walk up parents until we find the real player script
func _find_player(node: Node) -> Node:
	var cur := node
	while cur != null:
		if cur.has_method("get_held_item_name") and cur.has_method("consume_held_item"):
			return cur
		cur = cur.get_parent()
	return null


func _on_serve_body_entered(body: Node) -> void:
	if not waiting or leaving:
		return

	var player := _find_player(body)
	if player == null:
		return

	# check + call() so editor never complains
	if not player.has_method("get_held_item_name"):
		return
	if not player.has_method("consume_held_item"):
		return

	var item := str(player.call("get_held_item_name"))
	if item != order:
		return

	player.call("consume_held_item")

	# REWARD SYSTEM 
	if order == "rice":
		if GameManager.has_method("add_money"):
			GameManager.add_money(10)
	elif order == "drink":
		if GameManager.has_method("add_money"):
			GameManager.add_money(5)

	if GameManager.has_method("add_stars"):
		GameManager.add_stars(1)

	# served -> leave (ALWAYS runs)
	waiting = false
	set_serve_enabled(false)
	clear_order_icon()
	leaving = true


func show_order_icon(order_name: String) -> void:
	var tex: Texture2D = food_icons.get(order_name)
	if tex == null:
		return

	var display = get_node_or_null("OrderBubble/OrderDisplay")
	if display == null and car_visual:
		display = car_visual.get_node_or_null("OrderBubble/OrderDisplay")
	if display == null:
		return

	for c in display.get_children():
		c.queue_free()

	var icon := Sprite3D.new()
	icon.texture = tex
	icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon.scale = Vector3(0.1, 0.1, 0.1)
	display.add_child(icon)


func clear_order_icon() -> void:
	var display = get_node_or_null("OrderBubble/OrderDisplay")
	if display == null and car_visual:
		display = car_visual.get_node_or_null("OrderBubble/OrderDisplay")
	if display == null:
		return

	for c in display.get_children():
		c.queue_free()
