extends Interactable
# Наследуемся от Interactable, чтобы объект мог взаимодействовать с игроком

# Экспортируемая переменная имени NPC. По умолчанию "NPC". 
# Можно менять в редакторе Godot для каждого экземпляра.
@export var npc_name: String = "NPC"

# Текст диалога по умолчанию, если не задан массив строк.
# @export_multiline позволяет удобно редактировать многострочный текст в редакторе.
@export_multiline var dialogue_text: String = "Привет! Я просто NPC."

# Массив строк диалога. Экспортируемая переменная позволяет редактировать диалоги прямо в инспекторе.
# Используем тип Array[String] для удобства
@export var dialogue_lines: Array[String] = [
	"Привет, путник!", 
	"Это деревня новичков.",
	"Здесь можно найти много интересного.",
	"Осторожнее в лесу.",
    "Ты ищешь приключения?",
	"Сходи к выходу внизу, там тебя ждет курьер."
]

# Ссылка на узел HintLabel (надпись над головой).
# @onready гарантирует, что переменная инициализируется только когда узел готов (после _ready).
@onready var hint_label = $HintLabel

# Индекс текущей реплики для последовательного диалога
var current_dialogue_index: int = 0

# Функция инициализации скрипта. Вызывается при появлении объекта на сцене.
func _ready():
	add_to_group("NPC")
	# Для NPC оставляем взаимодействие на Е
	interaction_action = "key_e"
	
	# Скрываем подсказку при запуске игры, чтобы она не висела постоянно
	if hint_label:
		hint_label.visible = false
		hint_label.text = "Нажмите Е чтобы поговорить"
	
	# Подключаем сигналы зоны (Area2D):
	# body_entered срабатывает, когда физическое тело входит в зону
	body_entered.connect(_on_body_entered)
	# body_exited срабатывает, когда физическое тело выходит из зоны
	body_exited.connect(_on_body_exited)

# Обработчик входа тела в зону взаимодействия
func _on_body_entered(body):
	# Проверяем, что вошедшее тело - это игрок (CharacterBody2D)
	# Также проверяем body != get_parent(), чтобы NPC не реагировал сам на себя (если бы у него была коллизия в родителе)
	if body is CharacterBody2D and body != get_parent():
		# Если условие выполнено и метка существует, показываем её
		if hint_label:
			hint_label.visible = true

# Обработчик выхода тела из зоны взаимодействия
func _on_body_exited(body):
	# Аналогичная проверка: если игрок вышел
	if body is CharacterBody2D and body != get_parent():
		# Скрываем метку
		if hint_label:
			hint_label.visible = false

# Основная функция взаимодействия. Вызывается игроком (скрипт character_body_2d.gd)
func interact(body):
	if Global.is_cutscene_playing or Global.is_smart_watch_open:
		return
		
	# Вызываем родительский метод (если там есть логика)
	super.interact(body)
	# Пишем в консоль для отладки
	print("Говорим с NPC...")
	
	# Ищем узел интерфейса диалогов в дереве сцены по группе "DialogueUI"
	# Это позволяет не привязывать жесткие пути к узлам
	var dialogue_ui = get_tree().get_first_node_in_group("DialogueUI")
	
	# Если UI диалога найден
	if dialogue_ui:
		# Создаем временный массив для структур данных диалога
		# Явно указываем тип Array[Dictionary] для строгости типов
		var lines: Array[Dictionary] = []
		
		if not Global.npc_coin_given:
			Global.add_coins(1)
			Global.npc_coin_given = true
			lines.append({
				"name": npc_name,
				"text": "Держи монету! Она пригодится тебе для умных часов."
			})
		
		# Проверяем, заполнен ли массив dialogue_lines в редакторе
		if dialogue_lines.size() > 0:
			# Берем только ОДНУ текущую реплику по индексу
			var line = dialogue_lines[current_dialogue_index]
			
			# Если это реплика про курьера, активируем зону
			if "курьер" in line:
				Global.courier_zone_active = true
				print("Зона курьера активирована!")
				
			lines.append({
				"name": npc_name,
				"text": line
			})
			
			# Переключаем индекс на следующую реплику
			# Используем остаток от деления (%), чтобы зациклить диалог
			current_dialogue_index = (current_dialogue_index + 1) % dialogue_lines.size()
		else:
			# Иначе используем одну дефолтную строку dialogue_text
			lines.append({
				"name": npc_name,
				"text": dialogue_text
			})
			
		# Запускаем диалог через метод start_dialogue UI-компонента, передавая и реплики, и того, кто говорит
		dialogue_ui.start_dialogue(lines, body)
	else:
		# Если UI не найден, выводим ошибку в консоль
		print("ОШИБКА: Не найден UI диалога! Убедитесь, что dialogue_box.tscn добавлен в сцену.")

# Функция исчезновения NPC
func vanish():
	var parent = get_parent()
	if parent:
		# Устанавливаем режим работы ALWAYS, чтобы анимация играла даже при паузе (во время интро)
		parent.process_mode = Node.PROCESS_MODE_ALWAYS
		
		if parent.has_node("AnimatedSprite2D"):
			var sprite = parent.get_node("AnimatedSprite2D")
			var tween = create_tween()
			tween.tween_property(sprite, "scale", Vector2.ZERO, 0.5)
			tween.parallel().tween_property(sprite, "rotation_degrees", 360, 0.5)
			tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.5)
			await tween.finished
		
		parent.queue_free()
