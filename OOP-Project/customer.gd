extends Node3D

@onready var area = $Area3D
@onready var anim_player: AnimationPlayer = $Walking_ani/AnimationPlayer
var is_waiting: bool = false   # track whether customer is waiting

func _ready():
	area.body_entered.connect(_on_body_entered)

func _process(_delta):
	# Only play walk animation if not waiting
	if not is_waiting:
		if anim_player and not anim_player.is_playing():
			anim_player.play("ArmatureAction")
	else:
		# If waiting, make sure animation is stopped
		if anim_player and anim_player.is_playing():
			anim_player.stop()


func _on_body_entered(body):
	if body.name == "Player" and body.held_item != null:
		receive_item(body.held_item)
		body.held_item.queue_free()
		body.held_item = null
		#stop_walking()   # stop animation when delivering

func start_walking():
	if anim_player and not anim_player.is_playing():
		anim_player.play("ArmatureAction")
		
func receive_item(item: Node3D):
	print("Customer received: ", item.name)
	# Stop briefly while receiving
	stop_walking()
	# After receiving item, customer should leave (walk again)
	is_waiting = false
	start_walking()

func stop_walking():
	is_waiting = true
	if anim_player and anim_player.is_playing():
		anim_player.stop()
