extends Interactable
# Наследуемся от базового класса Interactable, который обеспечивает общую логику взаимодействия (например, сигнал interact)

# Переменная для хранения ссылки на узел Label с подсказкой
@onready var hint_label = $HintLabel

# Функция _ready вызывается автоматически, когда узел и его дети добавлены на сцену
func _ready():
	# Устанавливаем клавишу взаимодействия для сундука на "E"
	interaction_action = "key_e"
	
	# Проверяем, существует ли узел hint_label, чтобы избежать ошибок
	if hint_label:
		# Скрываем подсказку при запуске игры, так как игрок еще далеко
		hint_label.visible = false
		# Обновляем текст подсказки, чтобы игрок знал, какую кнопку жать
		hint_label.text = "Нажмите E"
	
	# Подключаем сигнал body_entered (вход тела в зону) к нашей функции _on_body_entered
	# Это нужно, чтобы отслеживать, когда игрок подходит к сундуку
	body_entered.connect(_on_body_entered)
	
	# Подключаем сигнал body_exited (выход тела из зоны) к нашей функции _on_body_exited
	# Это нужно, чтобы скрывать подсказку, когда игрок отходит
	body_exited.connect(_on_body_exited)

# Функция, которая вызывается, когда физическое тело входит в зону Area2D сундука
func _on_body_entered(body):
	# Проверяем, является ли вошедшее тело игроком (CharacterBody2D)
	# Также проверяем, что это не родительский объект (сам сундук), чтобы избежать самосрабатывания
	if body is CharacterBody2D and body != get_parent():
		# Если вошел игрок и метка существует
		if hint_label:
			# Делаем подсказку видимой
			hint_label.visible = true

# Функция, которая вызывается, когда физическое тело покидает зону Area2D сундука
func _on_body_exited(body):
	# Проверяем, является ли вышедшее тело игроком (CharacterBody2D)
	if body is CharacterBody2D and body != get_parent():
		# Если игрок ушел и метка существует
		if hint_label:
			# Скрываем подсказку
			hint_label.visible = false

# Функция interact вызывается из скрипта игрока при нажатии клавиши действия (например, E)
func interact(body):
	# Вызываем базовую реализацию interact из родительского класса Interactable (если она там есть)
	super.interact(body)
	
	# Выводим в консоль отладочное сообщение, что взаимодействие произошло
	print("Сундук открыт!")
	
	# Получаем ссылку на спрайт сундука. 
	# get_parent() возвращает узел Chest (StaticBody2D), а get_node("Sprite2D") ищет спрайт внутри него.
	var sprite = get_parent().get_node("Sprite2D")
	
	# Если спрайт найден (не null)
	if sprite:
		# Проверяем текущий цвет модуляции спрайта.
		# Color.WHITE (белый) означает, что цвет не изменен (сундук закрыт).
		if sprite.modulate == Color.WHITE:
			# Меняем цвет на желтый, имитируя открытие/свечение
			sprite.modulate = Color.YELLOW
			# Выводим сообщение в консоль
			print("Вы нашли сокровище!")
			var ui = get_tree().get_first_node_in_group("ChestUI")
			
			# Функция закрытия сундука (сброс цвета)
			var on_close = func():
				sprite.modulate = Color.WHITE
				print("Сундук закрылся (через UI).")
			
			if ui == null:
				var ps = load("res://SCENE/chest_ui.tscn")
				if ps:
					var inst = ps.instantiate()
					get_tree().current_scene.add_child(inst)
					var control = inst.get_node_or_null("CanvasLayer/Control")
					if control:
						if control.has_method("open"):
							control.open()
						# Подключаем сигнал закрытия одноразово
						if control.has_signal("closed"):
							control.closed.connect(on_close, CONNECT_ONE_SHOT)
			else:
				ui.open()
				# Подключаем сигнал закрытия одноразово
				if ui.has_signal("closed"):
					if not ui.closed.is_connected(on_close):
						ui.closed.connect(on_close, CONNECT_ONE_SHOT)
		else:
			sprite.modulate = Color.WHITE
			print("Сундук закрылся.")
			var ui2 = get_tree().get_first_node_in_group("ChestUI")
			if ui2:
				ui2.close()
