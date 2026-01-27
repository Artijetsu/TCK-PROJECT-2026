extends Area2D

# Текст диалога с курьером
var dialogue_lines: Array[Dictionary] = [
	{
		"name": "Курьер",
		"text": "Привет! Я тебя заждался."
	},
	{
		"name": "Курьер",
		"text": "Вот твоя посылка — Умные Часы."
	},
	{
		"name": "Курьер",
		"text": "С их помощью ты сможешь путешествовать. Нажми Z, чтобы открыть их."
	},
	{
		"name": "Курьер",
		"text": "Удачи!"
	}
]

var dialog_started = false

func _ready():
	# Подключаем сигнал входа в зону
	body_entered.connect(_on_body_entered)
	# Убедимся, что зона сканирует игрока
	collision_mask = 1 # Слой игрока обычно 1
	monitoring = true

func _on_body_entered(body):
	# Если диалог уже был - выходим
	# По просьбе пользователя убрали проверку Global.courier_zone_active, 
	# чтобы диалог запускался сразу при входе
	if Global.courier_dialogue_completed:
		return
		
	# Если диалог уже запущен прямо сейчас - выходим
	if dialog_started:
		return

	# Проверяем, что вошел игрок
	if body is CharacterBody2D:
		print("Игрок вошел в зону курьера. Начинаем диалог.")
		start_courier_dialogue(body)

func start_courier_dialogue(player):
	var dialogue_ui = get_tree().get_first_node_in_group("DialogueUI")
	if dialogue_ui:
		dialog_started = true
		# Запускаем диалог
		dialogue_ui.start_dialogue(dialogue_lines, null) # null, потому что курьера как объекта нет, мы просто говорим
		
		# Ждем окончания диалога
		await dialogue_ui.dialogue_ended
		
		# Когда диалог кончился:
		print("Диалог с курьером завершен.")
		Global.courier_dialogue_completed = true
		
		# Разблокируем игрока вручную, так как передали null
		if player.has_method("on_interaction_finished"):
			player.on_interaction_finished()
			
		# Удаляем зону, чтобы диалог не повторялся
		queue_free()
	else:
		print("ОШИБКА: DialogueUI не найден!")
