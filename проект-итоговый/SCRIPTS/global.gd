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
# Флаг, активирующий зону с курьером после разговора с NPC
var courier_zone_active: bool = false
# Флаг, подтверждающий, что диалог с курьером прошел (разблокирует часы)
var courier_dialogue_completed: bool = false

# Данные инвентарей { slot_index: { "id": "...", "texture_path": "..." } }
var wardrobe_data: Dictionary = {}
var chest_data: Dictionary = {}
var hotbar_data: Dictionary = {}
var wardrobe_initialized: bool = false
var chest_initialized: bool = false

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

func init_wardrobe_data() -> void:
    if wardrobe_initialized:
        return
    wardrobe_initialized = true
    
    # Разбрасываем 5 монет по случайным слотам (для простоты - фиксированным, чтобы не искать пустые)
    # Слоты: 3, 12, 25, 40, 50 (индексы с 0: 2, 11, 24, 39, 49)
    var coin_slots = [2, 11, 24, 39, 49]
    for idx in coin_slots:
        wardrobe_data[idx] = {
            "id": "coin",
            "texture_path": "res://IMG/pixel-coin.png"
        }
    
    # Добавляем одежду (Шляпа) в слот 1 (индекс 1)
    wardrobe_data[1] = {
        "id": "clothes",
        "texture_path": "res://ДРУГОЕ/Mana Seed Farmer Sprite Free Sample/farmer base sheets/14head/fbas_14head_cowboyhat_00d.png"
    }

func init_chest_data() -> void:
    if chest_initialized:
        return
    chest_initialized = true
    
    # Если монета еще не взята по старой логике
    if not chest_coin_taken:
        chest_data[0] = {
            "id": "coin",
            "texture_path": "res://IMG/pixel-coin.png"
        }
    # Можно добавить ноутбук, если он нужен
    # chest_data[1] = { "id": "notebook", "texture_path": "res://IMG/notebook.png" }

func set_inventory_item(container: String, slot_idx: int, id: String, tex_path: String) -> void:
    var data: Dictionary
    if container == "Wardrobe":
        data = wardrobe_data
    elif container == "Chest":
        data = chest_data
    elif container == "Hotbar":
        data = hotbar_data
    else:
        return
        
    if id == "":
        data.erase(slot_idx)
    else:
        data[slot_idx] = {
            "id": id,
            "texture_path": tex_path
        }
