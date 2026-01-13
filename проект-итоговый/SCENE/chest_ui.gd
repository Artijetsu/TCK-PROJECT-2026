extends Control

signal closed

@onready var grid: GridContainer = $Panel/MarginContainer/VBox/Grid
@onready var panel: Panel = $Panel
const BASE_SLOT := 96
const BASE_SEP := 8

func _ready() -> void:
	add_to_group("ChestUI")
	visible = false
	_update_scale()
	_update_position()
	for child in grid.get_children():
		if child is Button:
			(child as Button).pressed.connect(_on_slot_pressed.bind(child))

func open() -> void:
	visible = true
	_update_scale()
	_update_position()
	_update_chest_content()

func _update_chest_content() -> void:
	var slot1 = grid.get_node_or_null("Slot1")
	if slot1:
		if not Global.chest_coin_taken:
			var tex: Texture2D = preload("res://IMG/pixel-coin.png")
			slot1.icon = tex
			if "item_texture" in slot1:
				slot1.item_texture = tex
				slot1.item_id = "coin"
			slot1.expand_icon = true
			slot1.modulate = Color.WHITE
			slot1.tooltip_text = "Coin"
			slot1.disabled = false
		else:
			slot1.icon = null
			if "item_texture" in slot1:
				slot1.item_texture = null
				slot1.item_id = ""
			slot1.modulate = Color.WHITE
			slot1.tooltip_text = ""
			slot1.disabled = true

func close() -> void:
	visible = false
	closed.emit()

func _on_close_pressed() -> void:
	close()

func _update_scale() -> void:
	var factor: float = 1.0
	var ui := get_node_or_null("/root/UISettings")
	if ui:
		factor = ui.current_factor
	if grid:
		var mul := 0.6666667
		var sep: int = int(round(BASE_SEP * factor * mul))
		var slot: int = int(round(BASE_SLOT * factor * mul))
		grid.add_theme_constant_override("h_separation", sep)
		grid.add_theme_constant_override("v_separation", sep)
		for child in grid.get_children():
			if child is Button:
				(child as Button).custom_minimum_size = Vector2(slot, slot)
		var total_slots: int = 0
		for child in grid.get_children():
			if child is Button:
				total_slots += 1
		var cols: int = max(grid.columns, 1)
		var rows: int = int(ceil(float(total_slots) / float(cols)))
		var w: int = cols * slot + (cols - 1) * sep
		var h: int = rows * slot + max(rows - 1, 0) * sep
		if panel:
			panel.custom_minimum_size = Vector2(w + 24, h + 24 + 60 - 40)
			self.custom_minimum_size = panel.custom_minimum_size

func _update_position() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var size: Vector2 = panel.custom_minimum_size
	var pos := Vector2((viewport_size.x - size.x) / 2.0, (viewport_size.y - size.y) / 2.0)
	var hotbar := get_tree().get_first_node_in_group("Hotbar")
	if hotbar:
		var hb_panel := (hotbar as Node).get_node_or_null("Panel")
		if hb_panel:
			var hb_top := (hotbar as Control).position.y
			var bottom := pos.y + size.y
			var margin := 32.0
			if bottom > hb_top - margin:
				pos.y = hb_top - margin - size.y
				# Дополнительное приподнятие для надежности
				pos.y -= 16.0
	position = pos

func _input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

func _on_slot_pressed(btn: Button) -> void:
	return
