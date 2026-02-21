extends Node

var save_path := "user://savegame.json"

# Persistent data structure (defaults)
var data := {
	"player": {
		"money": 0,
		"levels_unlocked": 1,
		#"stars_in_level": GameManager.stars_in_level,
	},
	"inventory": {
		"rice": 0,
		"drink": 0
	},
	"upgrades": {
		"queue_size": 10,
		"car_speed": 1.0,
		"menu_items": []
	},
	#"customers": {
		#"walk_in": [],
		#"drive_through": []
	#},
	#"queue": {
		#"line": []
	#},
	"cooking_stations": {
		"stove": 0,          # store counts, not arrays
		"soda_fountain": 0
	},
	"stats": {
		"customers_served": 0,
		"stars": 0,
		"stars_in_level": 0,# add this
		"stars_needed": 10    # add this
		#"stars_needed": GameManager.stars_needed
	},
	"settings": {
		"sound_volume": 1.0,
		"controls": {}
	},
	"scene": {
		"current_scene": "res://main.tscn",
		"player_position": [0, 0, 0]   # always store as array
	}
}

# ---------------- MERGE ----------------
func merge_defaults(defaults: Dictionary, loaded: Dictionary) -> Dictionary:
	var result = defaults.duplicate(true)
	for key in loaded.keys():
		if result.has(key):
			if typeof(result[key]) == TYPE_DICTIONARY and typeof(loaded[key]) == TYPE_DICTIONARY:
				result[key] = merge_defaults(result[key], loaded[key])
			else:
				result[key] = loaded[key]
		else:
			result[key] = loaded[key]
	return result

# ---------------- SAVE ----------------
func save_game():
	save_scene_state()
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("Game saved to:", save_path)
	
	# ✅ Print absolute OS path for debugging
	print("Game saved to:", save_path)
	print("Absolute path:", ProjectSettings.globalize_path(save_path))

func save_scene_state():
	var current_scene = get_tree().current_scene
	if current_scene == null:
		push_warning("No current scene to save.")
		return

	# Save player position
	var player = current_scene.get_node_or_null("GameplayRoot/PlayerBody")
	if player and player.is_inside_tree():
		data["scene"]["player_position"] = [
			player.global_transform.origin.x,
			player.global_transform.origin.y,
			player.global_transform.origin.z
		]

	## Save walk-in customers
	#var walk_in_manager = current_scene.get_node_or_null("GameplayRoot/Walkin_Customer/QueueManagerC")
	#if walk_in_manager:
		#data["customers"]["walk_in"] = []
		#for customer in walk_in_manager.get_children():
			#if customer.has_method("get_order"):
				#data["customers"]["walk_in"].append({
					#"order": customer.order,
					#"progress_ratio": customer.progress_ratio,
					#"ai_state": customer.ai_state
				#})

	## Save drive-through customers
	#var drive_manager = current_scene.get_node_or_null("GameplayRoot/Car_Path/QueueManager")
	#if drive_manager:
		#data["customers"]["drive_through"] = []
		#for customer in drive_manager.get_children():
			#data["customers"]["drive_through"].append({
				#"order": customer.order,
				#"progress_ratio": customer.progress_ratio,
				#"ai_state": customer.ai_state
			#})

	# Save cooking stations (counts only)
	var stove = current_scene.get_node_or_null("GameplayRoot/Cooking_Oven/stove_single2")
	if stove and stove.has_method("_spawn_rice"):
		data["cooking_stations"]["stove"] = stove.stack.size()

	var soda = current_scene.get_node_or_null("GameplayRoot/DrinkMachine")
	if soda and soda.has_method("_spawn_one"):
		data["cooking_stations"]["soda_fountain"] = soda.stack.size()
	
	var hud = current_scene.get_node_or_null("HUDLayer")
	if hud:
		var stars_label = hud.get_node_or_null("StarsLabel")
		if stars_label:
			data["stats"]["stars"] = int(stars_label.text)

# ---------------- LOAD ----------------
func load_game() -> bool:
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file == null:
			push_error("Failed to open save file")
			return false

		var text = file.get_as_text()
		file.close()

		var result = JSON.parse_string(text)
		if typeof(result) == TYPE_DICTIONARY:
			data = merge_defaults(data, result)
			print("Game loaded:", data)
		# ✅ Delay restore until after first frame
			call_deferred("load_scene_state")
			return true
		else:
			push_error("Failed to parse save file")
			return false
	else:
		print("No save file found, starting fresh")
		data = data.duplicate(true)   # reset to defaults
		return false

func load_scene_state():
	if not data.has("scene"):
		print("DEBUG: No scene data found in save file")
		return

	var scene_path = data["scene"]["current_scene"]
	var current_scene = get_tree().current_scene

	if current_scene and current_scene.scene_file_path == scene_path:
		print("DEBUG: Already in scene, restoring only")
		restore_state(current_scene)
		return

	# Otherwise, change scene (only if different)
	var packed_scene = load(scene_path)
	if packed_scene == null:
		push_error("Scene not found: " + scene_path)
		return

	var new_scene = packed_scene.instantiate()

## Set flags before adding to tree
	#var walk_in_spawner = new_scene.get_node_or_null("GameplayRoot/Walkin_Customer/CustomerSpawner")
	#if walk_in_spawner:
		#walk_in_spawner.restoring_from_save = true
#
	#var drive_spawner = new_scene.get_node_or_null("GameplayRoot/Car_Path/CarSpawner")
	#if drive_spawner:
		#drive_spawner.restoring_from_save = true

# Replace current scene safely
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()

	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene

	print("DEBUG: Scene instantiated and flags set, now restoring...")
	call_deferred("restore_state", new_scene)   # ✅ instead of direct call

func restore_state(new_scene: Node):
	if new_scene == null:
		print("DEBUG: restore_state called with null scene")
		return

	print("DEBUG: Restoring state for scene:", new_scene.name)
	
# ✅ Directly use the autoloaded GameManager singleton
	GameManager.set_money(data["player"]["money"])  # ensures HUD updates via signal
	GameManager.level = data["player"]["levels_unlocked"]
	GameManager.stars_in_level = data["stats"].get("stars_in_level", 0)
	GameManager.stars_needed = data["stats"].get("stars_needed", 1)

	GameManager.emit_signal("stars_changed", GameManager.stars_in_level)
	GameManager.emit_signal("level_changed", GameManager.level)

	# Restore player position
	if data["scene"].has("player_position"):
		var pos = data["scene"]["player_position"]
		print("DEBUG: Restoring player position:", pos)
		if typeof(pos) == TYPE_ARRAY and pos.size() == 3:
			var player = new_scene.get_node_or_null("GameplayRoot/PlayerBody")
			if player:
				var restored_pos = Vector3(pos[0], pos[1], pos[2])
			# ✅ Defer the assignment so it happens after physics tick
				player.call_deferred("set_global_position", restored_pos)
				print("DEBUG: Deferred set_global_position called with:", restored_pos)

			# ✅ Flip the guard flag AFTER restore
				player.call_deferred("set", "restoring_from_save", false)

			# Debug check
				player.call_deferred("_print_position_after_restore")
			else:
				print("DEBUG: PlayerBody node not found")
	 #--- Sync player stats into scene nodes (ADD HERE) ---
	#var player_node = new_scene.get_node_or_null("GameplayRoot/PlayerBody")
	#if player_node:
		#player_node.money = data["player"]["money"]
		#player_node.levels_unlocked = data["player"]["levels_unlocked"]

	#var stats_node = new_scene.get_node_or_null("GameplayRoot/StatsManager")
	#if stats_node:
		#if stats_node.has_variable("stars"):
			#stats_node.stars = data["stats"]["stars"]
		#if stats_node.has_variable("customers_served"):
			#stats_node.customers_served = data["stats"]["customers_served"]

	# --- Player stats ---
	var hud = new_scene.get_node_or_null("HUDLayer")
	if hud and hud.has_method("_refresh_all"):
		hud._refresh_all()
		var money_label = hud.get_node_or_null("MoneyLabel")
		var stars_label = hud.get_node_or_null("StarsLabel")
		var level_label = hud.get_node_or_null("LevelLabel")

		if money_label:
			money_label.text = str(data["player"]["money"])
		if stars_label:
			stars_label.text = str(data["stats"]["stars"])
		if level_label:
			level_label.text = str(data["player"]["levels_unlocked"])
	# --- Restore queue customers (ADD HERE) ---
	var queue_manager = new_scene.get_node_or_null("GameplayRoot/QueueManagerC")
	if queue_manager:
		print("DEBUG: Restoring queue customers:", data["queue"]["line"].size())
		for customer_data in data["queue"]["line"]:
			var customer_scene = preload("res://walkinCustomer.tscn").instantiate()
			customer_scene.order = customer_data["order"]
			customer_scene.progress_ratio = customer_data["progress_ratio"]
			customer_scene.ai_state = customer_data["ai_state"]
			queue_manager.call_deferred("add_child", customer_scene)
	else:
		print("DEBUG: Queue manager not found")

	# --- Inventory ---
	var inventory_ui = hud.get_node_or_null("InventoryPanel")
	if inventory_ui:
		var rice_label = inventory_ui.get_node_or_null("RiceLabel")
		var drink_label = inventory_ui.get_node_or_null("DrinkLabel")
		if rice_label:
			rice_label.text = str(data["inventory"]["rice"])
		if drink_label:
			drink_label.text = str(data["inventory"]["drink"])

	## Restore walk-in customers
	#var walk_in_manager = new_scene.get_node_or_null("GameplayRoot/Walkin_Customer/QueueManagerC")
	#if walk_in_manager:
		#print("DEBUG: Restoring walk-in customers:", data["customers"]["walk_in"].size())
		#for customer_data in data["customers"]["walk_in"]:
			#var customer_scene = preload("res://walkinCustomer.tscn").instantiate()
			#customer_scene.order = customer_data["order"]
			#customer_scene.progress_ratio = customer_data["progress_ratio"]
			#customer_scene.ai_state = customer_data["ai_state"]
			#walk_in_manager.call_deferred("add_child", customer_scene)
	#else:
		#print("DEBUG: Walk-in manager not found")

	## Restore drive-through customers
	#var drive_manager = new_scene.get_node_or_null("GameplayRoot/Car_Path/QueueManager")
	#if drive_manager:
		#print("DEBUG: Restoring drive-through customers:", data["customers"]["drive_through"].size())
		#for customer_data in data["customers"]["drive_through"]:
			#var customer_scene = preload("res://addons/srcoder_simplecar/car.tscn").instantiate()
			#customer_scene.order = customer_data["order"]
			#customer_scene.progress_ratio = customer_data["progress_ratio"]
			#customer_scene.ai_state = customer_data["ai_state"]
			#drive_manager.call_deferred("add_child", customer_scene)
	#else:
		#print("DEBUG: Drive-through manager not found")

	# Restore cooking stations
	var stove = new_scene.get_node_or_null("GameplayRoot/Cooking_Oven/stove_single2")
	if stove:
		var count = data["cooking_stations"]["stove"]
		print("DEBUG: Restoring stove with", count, "items")
		for i in range(count):
			stove._spawn_rice()
	else:
		print("DEBUG: Stove not found")

	var soda = new_scene.get_node_or_null("GameplayRoot/DrinkMachine")
	if soda:
		var count = data["cooking_stations"]["soda_fountain"]
		print("DEBUG: Restoring soda fountain with", count, "items")
		for i in range(count):
			soda._spawn_one()
	else:
		print("DEBUG: Soda fountain not found")

	# Restore HUD/gameplay visibility
	var gameplay_root = new_scene.get_node_or_null("GameplayRoot")
	var hud_layer = new_scene.get_node_or_null("HUDLayer")
	if gameplay_root:
		#gameplay_root.visible = true
		print("DEBUG: GameplayRoot set visible")
		if hud_layer:
			#hud_layer.visible = true
			print("DEBUG: HUDLayer set visible")

	print("DEBUG: Restored money:", data["player"]["money"])
	print("DEBUG: Restored stars:", data["stats"]["stars"])
	print("DEBUG: Restored level:", data["player"]["levels_unlocked"])
	#print("DEBUG: Restored walk-in customers:", data["customers"]["walk_in"].size())
	#print("DEBUG: Restored drive-through customers:", data["customers"]["drive_through"].size())
	
# ---------------- HELPERS ----------------
func add_money(amount: int) -> void:
	data["player"]["money"] += amount
	save_game()

func add_stars(amount: int) -> void:
	data["stats"]["stars"] += amount
	save_game()

func serve_customer(order_type: String) -> void:
	data["stats"]["customers_served"] += 1
	if data["inventory"].has(order_type):
		data["inventory"][order_type] = max(0, data["inventory"][order_type] - 1)
	save_game()

func add_item(item_type: String) -> void:
	if data["inventory"].has(item_type):
		data["inventory"][item_type] += 1
	save_game()

func consume_item(item_type: String) -> void:
	if data["inventory"].has(item_type):
		data["inventory"][item_type] = max(0, data["inventory"][item_type] - 1)
	save_game()
