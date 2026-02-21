extends Panel

#soda machine UI
@onready var soda_btn: BaseButton = $"Soda Machine/Buy_Item2"
@onready var soda_price: Label = $"Soda Machine/Buy_Item2/Lemon"
@onready var soda_lock: Panel = $"Soda Machine/Panel"

#stove ui
@onready var stove_btn: BaseButton = $Stove/Buy_Item1
@onready var stove_price: Label = $"Stove/Buy_Item1/Rice"
@onready var stove_lock: Panel = $Stove.get_node_or_null("Panel") as Panel

func _ready() -> void:
	# Make overlays not steal clicks
	if soda_lock:
		soda_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if stove_lock:
		stove_lock.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Button signals
	if not soda_btn.pressed.is_connected(_on_soda_pressed):
		soda_btn.pressed.connect(_on_soda_pressed)
	if not stove_btn.pressed.is_connected(_on_stove_pressed):
		stove_btn.pressed.connect(_on_stove_pressed)

	# Refresh when state changes
	if not GameManager.money_changed.is_connected(_refresh):
		GameManager.money_changed.connect(_refresh)
	if not GameManager.level_changed.is_connected(_refresh):
		GameManager.level_changed.connect(_refresh)
	if not GameManager.item_state_changed.is_connected(_refresh):
		GameManager.item_state_changed.connect(_refresh)

	_refresh()

#  Click control
func _set_clickable(ctrl: Control, clickable: bool) -> void:
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP if clickable else Control.MOUSE_FILTER_IGNORE

func _set_label_fade(lbl: Label, fade: bool) -> void:
	lbl.modulate = Color(1, 1, 1, 0.45) if fade else Color(1, 1, 1, 1.0)

# Button actions
func _on_soda_pressed() -> void:
	if GameManager.buy_item("soda"):
		_refresh()

func _on_stove_pressed() -> void:
	# level 5+ buy stove_2
	if GameManager.buy_item("stove_2"):
		_refresh()

# UI Refresh
func _refresh(_x = null) -> void:
	_refresh_soda()
	_refresh_stove()

#SODA 
func _refresh_soda() -> void:
	var id := "soda"
	var unlock_lv := GameManager.get_item_unlock_level(id) # 3
	var price := GameManager.get_item_price(id)            # 250

	var owned := GameManager.is_item_owned(id)
	var unlocked := GameManager.is_item_unlocked(id)
	var can_buy := GameManager.can_buy(id)

	# keep button style
	soda_btn.text = ""

	# lock overlay only when locked + not owned
	if soda_lock:
		soda_lock.visible = (not unlocked) and (not owned)

	if owned:
		_set_clickable(soda_btn, false)
		soda_price.text = "Owned"
		_set_label_fade(soda_price, false)
		return

	if not unlocked:
		_set_clickable(soda_btn, false)
		soda_price.text = "Lv " + str(unlock_lv)
		_set_label_fade(soda_price, true)
		return

	# unlocked
	soda_price.text = str(price) + " $"
	_set_clickable(soda_btn, can_buy)
	_set_label_fade(soda_price, not can_buy)

# stove
func _refresh_stove() -> void:
	var stove2 := "stove_2"
	var unlock_lv2 := GameManager.get_item_unlock_level(stove2) # 5
	var price2 := GameManager.get_item_price(stove2)            # 300

	var owned2 := GameManager.is_item_owned(stove2)
	var unlocked2 := GameManager.is_item_unlocked(stove2)
	var can_buy2 := GameManager.can_buy(stove2)

	stove_btn.text = ""

	# lock overlay for stove 
	if stove_lock:
		stove_lock.visible = (not unlocked2) and (not owned2)

	# before level 5
	if not unlocked2:
		_set_clickable(stove_btn, false)
		stove_price.text = "Owned"
		_set_label_fade(stove_price, false)
		return

	# level 5+ -> stove_2
	if owned2:
		_set_clickable(stove_btn, false)
		stove_price.text = "Owned"
		_set_label_fade(stove_price, false)
		return

	stove_price.text = str(price2) + " $"
	_set_clickable(stove_btn, can_buy2)
	_set_label_fade(stove_price, not can_buy2)
