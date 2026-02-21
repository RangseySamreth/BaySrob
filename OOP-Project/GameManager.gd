extends Node

signal money_changed(money: int)
signal stars_changed(stars_in_level: int)
signal level_changed(level: int)
signal win_reached()
signal item_state_changed(item_id: String)

var money: int = 0
var level: int = 1
var stars_in_level: int = 0
var stars_needed: int = 10


var owned := {
	"stove_1": false,
	"soda": false,
	"stove_2": false,
}

func set_money(value: int) -> void:
	money = value
	emit_signal("money_changed", money)

func add_money(amount: int) -> void:
	set_money(money + amount)

func add_stars(amount: int) -> void:
	stars_in_level += amount

	if stars_in_level >= stars_needed:
		level += 1
		stars_in_level = 0              # RESET stars each level
		stars_needed = int(stars_needed * 2)

		emit_signal("level_changed", level)

		if level >= 5:
			emit_signal("win_reached")

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
	emit_signal("item_state_changed", item_id)
	return true
