extends Node

var selected_character_path: String = "res://ПЕРСОНАЖИ/character_body_2d.tscn"

# Coin system
var coins: int = 0
var chest_coin_taken: bool = false
var npc_coin_given: bool = false
var smart_watch_intro_completed: bool = false
var is_cutscene_playing: bool = false
var is_smart_watch_open: bool = false
var carry_item_id: String = ""
var carry_item_texture: Texture2D = null

func add_coins(amount: int) -> void:
	coins += amount
	# Update UI if it exists
	var coin_ui = get_tree().get_first_node_in_group("CoinUI")
	if coin_ui and coin_ui.has_method("update_coins"):
		coin_ui.update_coins(coins)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		var coin_ui = get_tree().get_first_node_in_group("CoinUI")
		if coin_ui and coin_ui.has_method("update_coins"):
			coin_ui.update_coins(coins)
		return true
	return false
