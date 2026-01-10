extends Control
# Переменная, куда будем складывать весь диалог. Видна в редакторе, пока пустая
@export var dialogues: Array[Dictionary] = []
@export var type_speed: float = 14.0 # скорость печати (символов в секунду)
# Ссылка на картинку с портретом персонажа (TextureRect)
@onready var portrait: TextureRect = get_node_or_null("Portrait")
# Ссылка на текст с именем персонажа (обычный Label)
@onready var name_label: Label = $NameLabel
# Ссылка на поле, где будет появляться текст реплики по буквам
@onready var text_label: RichTextLabel = $Panel/MarginContainer/HBoxContainer/VBoxContainer/RichTextLabel
# Номер текущей строки диалога. Начинаем с 0
var current_index: int = 0
# Переменная для анимации печатания текста (пока пустая)
var tween: Tween = null
# Правда ли сейчас буквы появляются по одной?
var is_typing: bool = false
# Специальный сигнал, который скажет игре: «Диалог полностью закончился»
signal dialogue_ended
# Сигнал о смене реплики (передает индекс новой реплики)
signal dialogue_line_changed(index: int)

func _ready() -> void:
	# Добавляем в группу для легкого поиска
	add_to_group("DialogueUI")
	visible = false # Скрываем диалог при старте
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	text_label.bbcode_enabled = true
	text_label.scroll_following = true

	text_label.add_theme_color_override("default_color", Color.WHITE) # делаем текст белым, чтобы он точно был виден
	text_label.custom_minimum_size = Vector2(600, 140) # задаём минимальный размер области текста
	text_label.visible = true # убеждаемся, что метка текста отображается
	# text_label.fit_content = true # (опционально) авторазмер по содержимому, если нужно

# Главная функция, которую ты будем вызывать, когда нужно начать разговор
func start_dialogue(dialog_array: Array[Dictionary]):
	dialogues = dialog_array # Запоминаем переданный список реплик
	current_index = 0 # Сбрасываем счётчик на первую строку
	visible = true # Показываем окно диалога на экране
	
	# Замораживаем игру (останавливаем физику и процесс обработки игрока)
	get_tree().paused = true
	
	show_next_line() # Показываем первую реплику
	
# Функция, которая показывает одну строку диалога
func show_next_line() -> void:
	if current_index >= dialogues.size(): # Если реплики закончились
		end_dialogue() # закрываем диалог
		return # и выходим из функции

	var entry = dialogues[current_index] # Берём текущую строку диалога
	
	# Сообщаем о смене реплики
	dialogue_line_changed.emit(current_index)
	
	name_label.text = entry["name"] # Пишем имя персонажа в поле имени
	if portrait and entry.has("portrait"): # Если в этой строке есть портрет и узел портрета существует
		portrait.texture = entry["portrait"] # ставим его картинку
	# если портрета нет — оставляем старый или пустой

	text_label.text = String(entry.get("text", "")) # безопасно превращаем текст в строку
	text_label.visible_characters = 0 # начинаем с пустой строки

	var total: int = int(max(text_label.get_total_character_count(), text_label.text.length())) # считаем символы
	var duration: float = float(clamp(float(total) / max(type_speed, 1.0), 0.05, 10.0)) # время анимации
	
	tween = create_tween() # создаём анимацию набора текста
	tween.tween_property(text_label, "visible_characters", total, duration) # показываем буквы по одной до конца строки
	tween.finished.connect(_on_tween_finished)
	is_typing = true # запоминаем, что сейчас идёт печать

func _on_tween_finished() -> void:
	is_typing = false

# Функция, которая закрывает диалог
func end_dialogue() -> void:
	visible = false # Прячем окно
	dialogue_ended.emit() # Говорим всем: «Диалог кончился!»
	
	# Размораживаем игру
	get_tree().paused = false
	
# Эта функция вызывается каждый раз, когда игрок что-то нажимает
func _input(event):
	if not visible: # Если диалог скрыт — ничего не делаем
		return
	
	# Выход из диалога на клавишу Q
	if event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		end_dialogue()
		get_viewport().set_input_as_handled()
		return
	
	# Space (пробел) теперь обрабатывается как ui_accept (далее), 
	# чтобы переключать диалог, а не закрывать его.

	if not event.is_action_pressed("ui_accept"):  # Если нажата НЕ пробел и НЕ Enter
		return                                         

	if is_typing and tween: # Если сейчас идёт печать текста
		tween.kill() # Останавливаем анимацию
		text_label.visible_characters = -1 # Показываем весь текст сразу
		is_typing = false # Больше не печатаем
	else:  # Если текст уже весь виден
		# Проверяем, есть ли следующая фраза
		if current_index + 1 >= dialogues.size():
			# Если это была последняя реплика, то при следующем нажатии закрываем диалог
			end_dialogue()
			return 
		
		# Если фразы еще есть, переходим к следующей
		current_index += 1 
		show_next_line() 
		
	# Говорим Godot: «Мы уже обработали нажатие, не передавай дальше»
	get_viewport().set_input_as_handled()
