extends Control

@onready var panel: Panel = $Panel
@onready var hbox: HBoxContainer = $Panel/MarginContainer/HBox
const BASE_SLOT := 96
const BASE_SEP := 8
var slots: Array[Button] = []
var active_index: int = 0

func _ready() -> void:
	add_to_group("Hotbar")
	visible = true
	# Убираем фон панели хотбара
	if panel:
		var empty := StyleBoxEmpty.new()
		panel.add_theme_stylebox_override("panel", empty)
	for child in hbox.get_children():
		if child is Button:
			slots.append(child)
	_update_scale()
	_update_position()
	_update_active_slot_style()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update_position()

func _update_scale() -> void:
	var factor: float = 1.0
	var ui := get_node_or_null("/root/UISettings")
	if ui:
		factor = ui.current_factor
	var mul := 0.5
	var sep: int = int(round(BASE_SEP * factor * mul))
	var slot: int = int(round(BASE_SLOT * factor * mul))
	hbox.add_theme_constant_override("separation", sep)
	for b in slots:
		b.custom_minimum_size = Vector2(slot, slot)
		b.expand_icon = true
	var cols: int = slots.size()
	var w: int = cols * slot + (cols - 1) * sep
	var h: int = slot
	panel.custom_minimum_size = Vector2(w + 24, h + 24)
	self.custom_minimum_size = panel.custom_minimum_size
	_update_active_slot_style()

func _update_position() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var width: float = panel.custom_minimum_size.x
	var height: float = panel.custom_minimum_size.y
	position = Vector2((viewport_size.x - width) / 2.0, viewport_size.y - height - 24)

func add_item(texture: Texture2D) -> bool:
	for b in slots:
		if b.icon == null:
			b.icon = texture
			return true
	return false

func _update_active_slot_style() -> void:
	for i in range(slots.size()):
		var b := slots[i]
		if i == active_index:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0, 0, 0, 0)
			sb.border_color = Color(1, 1, 1, 0.7)
			sb.border_width_left = 2
			sb.border_width_top = 2
			sb.border_width_right = 2
			sb.border_width_bottom = 2
			b.add_theme_stylebox_override("normal", sb)
		else:
			b.remove_theme_stylebox_override("normal")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_active_index(active_index + 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_active_index(active_index - 1)
	elif event is InputEventKey and event.pressed and not event.echo:
		var code: int = (event as InputEventKey).keycode
		if code >= KEY_1 and code <= KEY_9:
			var idx: int = code - KEY_1
			if idx < slots.size():
				_set_active_index(idx)

func _set_active_index(idx: int) -> void:
	if slots.size() == 0:
		return
	var n := slots.size()
	active_index = ((idx % n) + n) % n
	_update_active_slot_style()
