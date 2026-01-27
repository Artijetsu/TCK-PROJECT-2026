extends Control

signal closed

@onready var grid: GridContainer = $Panel/MarginContainer/VBox/Grid
@onready var panel: Panel = $Panel
const BASE_SLOT := 64
const BASE_SEP := 4

func _ready() -> void:
	add_to_group("WardrobeUI")
	visible = false
	_update_scale()
	_update_position()
	# Removed signal connection loop as slot_button.gd handles input

func open() -> void:
	visible = true
	Global.init_wardrobe_data()
	_update_scale()
	_update_position()
	_update_content()

func _update_content() -> void:
	for child in grid.get_children():
		if child is Button:
			# Get index from name (Slot1 -> 0)
			var n = child.name.replace("Slot", "")
			if n.is_valid_int():
				var idx = n.to_int() - 1
				
				# Check global data
				if Global.wardrobe_data.has(idx):
					var item = Global.wardrobe_data[idx]
					var tex_path = item["texture_path"]
					# Ensure resource exists before loading to avoid errors
					if ResourceLoader.exists(tex_path):
						var tex = load(tex_path)
						child.icon = tex
						if "item_texture" in child:
							child.item_texture = tex
							child.item_id = item["id"]
						child.expand_icon = true
						child.modulate = Color.WHITE
						
						# Tooltip
						if item["id"] == "coin":
							child.tooltip_text = "Монета"
						elif item["id"] == "clothes":
							child.tooltip_text = "Одежда"
						else:
							child.tooltip_text = item["id"]
					else:
						# Fallback if texture missing
						child.icon = null
						child.tooltip_text = "Error: Missing Texture"
				else:
					child.icon = null
					if "item_texture" in child:
						child.item_texture = null
						child.item_id = ""
					child.tooltip_text = ""
				
				# Always enable to allow interaction (drop/swap)
				child.disabled = false

func close() -> void:
	visible = false
	closed.emit()

func _on_close_pressed() -> void:
	close()

func _update_scale() -> void:
	# Simplified scale logic
	pass

func _update_position() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var size: Vector2 = panel.custom_minimum_size
	if size == Vector2.ZERO: size = panel.size
	var pos := Vector2((viewport_size.x - size.x) / 2.0, (viewport_size.y - size.y) / 2.0)
	position = pos

func _input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
