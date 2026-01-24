extends Button

@export var item_id: String = ""
@export var item_texture: Texture2D

var slot_index: int = -1

func _ready() -> void:
    expand_icon = true
    if item_texture != null:
        icon = item_texture
    
    # Вычисляем индекс слота из имени (Slot1 -> 0)
    var n = name.replace("Slot", "")
    if n.is_valid_int():
        slot_index = n.to_int() - 1
    
    _update_tooltip()

func _update_tooltip() -> void:
    if item_id == "wardrobe_coins":
        tooltip_text = "5 Монет"
    elif item_id == "coin":
        tooltip_text = "Монета"
    elif item_id == "clothes":
        tooltip_text = "Одежда"
    elif item_id != "":
        tooltip_text = item_id
    else:
        tooltip_text = ""

func _get_drag_data(at_position: Vector2):
    if disabled:
        return null
    if item_texture == null:
        return null
    var data := {
        "type": "item",
        "id": item_id,
        "texture": item_texture
    }
    var preview := TextureRect.new()
    preview.texture = item_texture
    preview.stretch_mode = TextureRect.STRETCH_SCALE
    preview.custom_minimum_size = Vector2(64, 64)
    set_drag_preview(preview)
    return data

func _set_carry_cursor(tex: Texture2D) -> void:
    if tex == null:
        Input.set_custom_mouse_cursor(null)
        return
    var img := tex.get_image()
    if img:
        var size := 32
        img.resize(size, size, Image.INTERPOLATE_NEAREST)
        var itex := ImageTexture.create_from_image(img)
        Input.set_custom_mouse_cursor(itex, Input.CURSOR_ARROW, Vector2(size * 0.5, size * 0.5))

func _is_in_chest_ui() -> bool:
    var ui := get_tree().get_first_node_in_group("ChestUI")
    if ui == null:
        return false
    var p: Node = self
    while p != null:
        if p == ui:
            return true
        p = p.get_parent()
    return false

func _is_in_wardrobe_ui() -> bool:
    var ui := get_tree().get_first_node_in_group("WardrobeUI")
    if ui == null:
        return false
    var p: Node = self
    while p != null:
        if p == ui:
            return true
        p = p.get_parent()
    return false

func _is_in_hotbar_ui() -> bool:
    var ui := get_tree().get_first_node_in_group("Hotbar")
    if ui == null:
        return false
    var p: Node = self
    while p != null:
        if p == ui:
            return true
        p = p.get_parent()
    return false

func _get_container_name() -> String:
    if _is_in_chest_ui(): return "Chest"
    if _is_in_wardrobe_ui(): return "Wardrobe"
    if _is_in_hotbar_ui(): return "Hotbar"
    return ""

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        # Мгновенное зачисление монеты по клику
        if item_id == "coin" and item_texture != null:
            Global.add_coins(1)
            
            # Удаляем из сохранения
            var container = _get_container_name()
            if container != "":
                Global.set_inventory_item(container, slot_index, "", "")
            
            item_texture = null
            icon = null
            item_id = ""
            tooltip_text = ""
            _set_carry_cursor(null)
            accept_event()
            return
            
        # Одежда теперь обрабатывается как обычный предмет (перенос)
        
        # Обычный перенос (Click to Pick Up / Click to Drop)
        if not event.shift_pressed:
            if Global.carry_item_texture == null:
                # PICK UP
                if item_texture != null:
                    Global.carry_item_texture = item_texture
                    Global.carry_item_id = item_id
                    
                    # Удаляем из текущего слота
                    item_texture = null
                    icon = null
                    item_id = ""
                    tooltip_text = ""
                    
                    var container = _get_container_name()
                    if container != "":
                        Global.set_inventory_item(container, slot_index, "", "")
                    
                    _set_carry_cursor(Global.carry_item_texture)
                    accept_event()
            else:
                # DROP (если слот пуст)
                if item_texture == null:
                    item_texture = Global.carry_item_texture
                    icon = item_texture
                    item_id = Global.carry_item_id
                    
                    var container = _get_container_name()
                    if container != "":
                        Global.set_inventory_item(container, slot_index, item_id, item_texture.resource_path)
                    
                    _update_tooltip()
                    
                    Global.carry_item_texture = null
                    Global.carry_item_id = ""
                    _set_carry_cursor(null)
                    accept_event()
                else:
                    # SWAP (если слот занят - пока не реализуем, или можно сделать)
                    # Для простоты: если занят, ничего не делаем или меняем местами.
                    # Сделаем простую смену
                    var temp_tex = item_texture
                    var temp_id = item_id
                    
                    item_texture = Global.carry_item_texture
                    icon = item_texture
                    item_id = Global.carry_item_id
                    
                    var container = _get_container_name()
                    if container != "":
                        Global.set_inventory_item(container, slot_index, item_id, item_texture.resource_path)
                    
                    _update_tooltip()
                    
                    Global.carry_item_texture = temp_tex
                    Global.carry_item_id = temp_id
                    _set_carry_cursor(Global.carry_item_texture)
                    accept_event()

func _can_drop_data(at_position: Vector2, data) -> bool:
    if typeof(data) == TYPE_DICTIONARY and data.has("texture"):
        return true
    return false

func _drop_data(at_position: Vector2, data) -> void:
    # Это для Drag&Drop (если понадобится), но мы используем Click-Carry.
    # Можно оставить для совместимости.
    pass
