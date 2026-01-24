extends Interactable

@onready var hint_label = $HintLabel

func _ready():
	interaction_action = "key_e"
	
	if hint_label:
		hint_label.visible = false
		hint_label.text = "Нажмите E что бы открыть"
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody2D and body != get_parent():
		if hint_label:
			hint_label.visible = true

func _on_body_exited(body):
	if body is CharacterBody2D and body != get_parent():
		if hint_label:
			hint_label.visible = false

func interact(body: CharacterBody2D):
	super.interact(body)
	print("Шкаф открыт!")
	
	var sprite = get_parent().get_node("Sprite2D")
	
	if sprite:
		if sprite.modulate == Color.WHITE:
			sprite.modulate = Color.GRAY # Затемняем, типа открыт
			var ui = get_tree().get_first_node_in_group("WardrobeUI")
			
			var on_close = func():
				sprite.modulate = Color.WHITE
				print("Шкаф закрылся.")
				if body:
					body.on_interaction_finished()
			
			if ui == null:
				var ps = load("res://SCENE/wardrobe_ui.tscn")
				if ps:
					var inst = ps.instantiate()
					get_tree().current_scene.add_child(inst)
					var control = inst.get_node_or_null("CanvasLayer/Control")
					if control:
						if control.has_method("open"):
							control.open()
						if control.has_signal("closed"):
							control.closed.connect(on_close, CONNECT_ONE_SHOT)
			else:
				ui.open()
				if ui.has_signal("closed"):
					if not ui.closed.is_connected(on_close):
						ui.closed.connect(on_close, CONNECT_ONE_SHOT)
		else:
			sprite.modulate = Color.WHITE
			var ui2 = get_tree().get_first_node_in_group("WardrobeUI")
			if ui2:
				ui2.close()
			if body:
				body.on_interaction_finished()
