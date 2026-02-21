extends Node

signal money_changed(money: int)
signal stars_changed(stars_in_level: int)
signal level_changed(level: int)
signal win_reached()
signal item_state_changed(item_id: String)

var money: int = 0
var level: int = 1
var stars_in_level: int = 0
var stars_needed: int = 1

var owned := {
	"stove_1": false,
	"soda": false,
	"stove_2": false,
}

func _ready() -> void:
	_update_stars_needed()
	# ✅ Load persistent values
	money = GameDataManager.data["player"]["money"]
	level = GameDataManager.data["player"]["levels_unlocked"]
	stars_in_level = GameDataManager.data["stats"].get("stars_in_level", 0)
	stars_needed = GameDataManager.data["stats"].get("stars_needed", 1)

	# Load owned items
	for item in GameDataManager.data["upgrades"]["menu_items"]:
		owned[item] = true
	print("DEBUG: Loaded money:", money)
	print("DEBUG: Loaded level:", level)
	print("DEBUG: Loaded stars_in_level:", stars_in_level)
	print("DEBUG: Loaded stars_needed:", stars_needed)

func play_money_sound():
	var sound = get_node_or_null("/root/Main/MoneySound")
	if sound:
		sound.play()

func _update_stars_needed() -> void:
	stars_needed = 10 + (level - 1) * 5

func set_money(value: int) -> void:
	money = value
	GameDataManager.data["player"]["money"] = money
	GameDataManager.save_game()
	emit_signal("money_changed", money)


func add_money(amount: int) -> void:
	set_money(money + amount)
	play_money_sound()

func add_stars(amount: int) -> void:
	stars_in_level += amount

	while stars_in_level >= stars_needed:
		stars_in_level -= stars_needed
		level += 1

		_update_stars_needed()
		emit_signal("level_changed", level)

		if level >= 5:
			emit_signal("win_reached")
	GameDataManager.data["stats"]["stars_in_level"] = stars_in_level
	GameDataManager.data["stats"]["stars_needed"] = stars_needed
	GameDataManager.save_game()

	emit_signal("stars_changed", stars_in_level)

func get_item_unlock_level(item_id: String) -> int:
	match item_id:
		"stove_1": return 1
		"soda": return 3
		"stove_2": return 5
		_: return 999

func get_item_price(item_id: String) -> int:
	match item_id:
		"stove_1": return 100
		"soda": return 250
		"stove_2": return 300
		_: return 999999

func is_item_unlocked(item_id: String) -> bool:
	return level >= get_item_unlock_level(item_id)

func is_item_owned(item_id: String) -> bool:
	return owned.get(item_id, false)

func can_buy(item_id: String) -> bool:
	if is_item_owned(item_id):
		return false
	if not is_item_unlocked(item_id):
		return false
	return money >= get_item_price(item_id)

func buy_item(item_id: String) -> bool:
	if not can_buy(item_id):
		return false

	set_money(money - get_item_price(item_id))
	owned[item_id] = true
		# ✅ Save ownership in GameDataManager
	if not GameDataManager.data["upgrades"]["menu_items"].has(item_id):
		GameDataManager.data["upgrades"]["menu_items"].append(item_id)
	GameDataManager.save_game()

	emit_signal("item_state_changed", item_id)
	return true
