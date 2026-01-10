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
    for child in grid.get_children():
        if child is Button:
            (child as Button).pressed.connect(_on_slot_pressed.bind(child))

func open() -> void:
    visible = true
    _update_scale()
    _update_chest_content()

func _update_chest_content() -> void:
    var slot1 = grid.get_node_or_null("Slot1")
    if slot1:
        if not Global.chest_coin_taken:
            slot1.icon = preload("res://icon.svg")
            slot1.expand_icon = true
            slot1.modulate = Color(1, 0.84, 0, 1)
            slot1.tooltip_text = "Coin"
            slot1.disabled = false
        else:
            slot1.icon = null
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
        var sep: int = int(round(BASE_SEP * factor))
        var slot: int = int(round(BASE_SLOT * factor))
        grid.add_theme_constant_override("h_separation", sep)
        grid.add_theme_constant_override("v_separation", sep)
        for child in grid.get_children():
            if child is Button:
                (child as Button).custom_minimum_size = Vector2(slot, slot)
        var cols: int = max(grid.columns, 1)
        var w: int = cols * slot + (cols - 1) * sep
        var h: int = slot
        if panel:
            panel.custom_minimum_size = Vector2(w + 24, h + 24 + 60)
            self.custom_minimum_size = panel.custom_minimum_size

func _input(event):
    if not visible:
        return
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        close()
        get_viewport().set_input_as_handled()

func _on_slot_pressed(btn: Button) -> void:
    if btn.name == "Slot1" and not Global.chest_coin_taken:
        Global.add_coins(1)
        Global.chest_coin_taken = true
        _update_chest_content()
        return

    var hotbar: Node = get_tree().get_first_node_in_group("Hotbar") as Node
    if hotbar and hotbar.has_method("add_item"):
        var tex: Texture2D = preload("res://icon.svg")
        var ok: bool = hotbar.add_item(tex)
        if ok:
            btn.disabled = true
