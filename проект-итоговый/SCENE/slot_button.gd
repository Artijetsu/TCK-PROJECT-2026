extends Button

@export var item_id: String = ""
@export var item_texture: Texture2D

func _ready() -> void:
	expand_icon = true
	if item_texture != null:
		icon = item_texture

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

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Мгновенное зачисление монеты по клику
		if item_id == "coin" and item_texture != null:
			Global.add_coins(1)
			# Если монета была в сундуке, отмечаем как взятую
			if _is_in_chest_ui():
				Global.chest_coin_taken = true
				var ui = get_tree().get_first_node_in_group("ChestUI")
				if ui and ui.has_method("_update_chest_content"):
					ui._update_chest_content()
			item_texture = null
			icon = null
			item_id = ""
			_set_carry_cursor(null)
			accept_event()
			return
		# Обычный перенос для остальных предметов
		if not event.shift_pressed:
			if Global.carry_item_texture == null:
				if item_texture != null:
					Global.carry_item_texture = item_texture
					Global.carry_item_id = item_id
					item_texture = null
					icon = null
					item_id = ""
					_set_carry_cursor(Global.carry_item_texture)
					accept_event()
			else:
				if item_texture == null:
					item_texture = Global.carry_item_texture
					icon = item_texture
					item_id = Global.carry_item_id
					Global.carry_item_texture = null
					Global.carry_item_id = ""
					_set_carry_cursor(null)
					accept_event()

func _can_drop_data(at_position: Vector2, data) -> bool:
	if typeof(data) == TYPE_DICTIONARY and data.has("texture"):
		return true
	return false

func _drop_data(at_position: Vector2, data) -> void:
	if not _can_drop_data(at_position, data):
		return
	if item_texture == null:
		var tex: Texture2D = data.get("texture")
		item_texture = tex
		icon = tex
		item_id = str(data.get("id", ""))
