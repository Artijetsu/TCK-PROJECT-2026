extends Control

signal agreement_signed

@onready var agree_btn = $Panel/ButtonsContainer/AgreeBtn
@onready var refuse_btn = $Panel/ButtonsContainer/RefuseBtn
@onready var panel = $Panel

# Картинки для слайд-шоу
var ending_images = [
	load("res://IMG/фон-дом.jpg"),
	load("res://IMG/фон-деревня.jpg"),
	load("res://IMG/фон-школа.jpg"),
	load("res://IMG/фон-лес.jpg")
]

# Текст для слайд-шоу
var ending_lines: Array[Dictionary] = [
	{
		"name": "Рассказчик", 
		"text": "Герои отказались от рисковой затеи..."
	},
	{
		"name": "Рассказчик", 
		"text": "...и решили продать те часы..."
	},
	{
		"name": "Рассказчик", 
		"text": "...и их жизнь потекла по руслу, ничего не произошло..."
	},
	{
		"name": "Рассказчик", 
		"text": "...все жили долго и счастливо."
	}
]

var background_rect: TextureRect
var black_overlay: ColorRect

func _ready():
	# Устанавливаем режим работы ALWAYS, чтобы скрипт (и анимации) работал даже при паузе (которую включает диалог)
	process_mode = Node.PROCESS_MODE_ALWAYS
	agree_btn.pressed.connect(_on_agree_pressed)
	refuse_btn.pressed.connect(_on_refuse_pressed)

func _on_agree_pressed():
	agreement_signed.emit()
	queue_free()

func _on_refuse_pressed():
	start_bad_ending()

func start_bad_ending():
	# 1. Создаем черный фон для затемнения
	black_overlay = ColorRect.new()
	black_overlay.color = Color.BLACK
	black_overlay.color.a = 0.0
	black_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE # Чтобы не блокировал ввод
	add_child(black_overlay)
	
	# 2. Создаем элемент для картинок (сверху черного фона)
	background_rect = TextureRect.new()
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.modulate.a = 0.0 # Скрыт в начале
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Чтобы не блокировал ввод
	add_child(background_rect)
	
	# 3. Анимация затемнения (2 секунды)
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(black_overlay, "color:a", 1.0, 2.0)
	await tween.finished
	
	# 4. Скрываем панель EULA
	panel.visible = false
	
	# 5. Запускаем диалог
	var dialogue_ui = get_tree().get_first_node_in_group("DialogueUI")
	if dialogue_ui:
		# Подключаемся к сигналу смены строк
		if not dialogue_ui.dialogue_line_changed.is_connected(_on_dialogue_line_changed):
			dialogue_ui.dialogue_line_changed.connect(_on_dialogue_line_changed)
		
		# ВАЖНО: Поднимаем CanvasLayer диалога над черным фоном
		var dialog_layer = dialogue_ui.get_parent()
		var original_layer = 1
		if dialog_layer is CanvasLayer:
			original_layer = dialog_layer.layer
			dialog_layer.layer = 100
		
		# Поднимаем сам контрол тоже на всякий случай
		dialogue_ui.z_index = 100
		
		dialogue_ui.start_dialogue(ending_lines)
		
		# Ждем окончания диалога
		await dialogue_ui.dialogue_ended
		
		# Возвращаем слои обратно
		if dialog_layer is CanvasLayer:
			dialog_layer.layer = original_layer
		dialogue_ui.z_index = 0
		
		# Отключаем сигнал
		if dialogue_ui.dialogue_line_changed.is_connected(_on_dialogue_line_changed):
			dialogue_ui.dialogue_line_changed.disconnect(_on_dialogue_line_changed)
		
		# --- ФИНАЛЬНАЯ СЦЕНА ---
		
		# 1. Затемнение (скрываем картинку, под ней черный фон)
		var end_tween = create_tween()
		end_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		end_tween.tween_property(background_rect, "modulate:a", 0.0, 1.0)
		await end_tween.finished
		
		# 2. Текст "Конец"
		var label = Label.new()
		label.text = "Конец"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# Растягиваем на весь экран, чтобы центрирование текста сработало идеально относительно экрана
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.add_theme_font_size_override("font_size", 64)
		label.modulate.a = 0.0 # Прозрачный в начале
		add_child(label)
		
		# Появление текста
		var text_tween = create_tween()
		text_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		text_tween.tween_property(label, "modulate:a", 1.0, 1.0)
		await text_tween.finished
		
		# 3. Небольшая пауза перед меню
		await get_tree().create_timer(2.0).timeout
		
		# 4. Переход в меню
		get_tree().change_scene_to_file("res://SCENE/main_optimized.tscn")

func _on_dialogue_line_changed(index: int):
	# Меняем картинку в зависимости от индекса фразы
	if index < ending_images.size():
		change_background_image(ending_images[index])

func change_background_image(new_texture: Texture):
	# Плавная, но быстрая смена картинки
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # Явно разрешаем работу в паузе
	
	# Если картинка уже видна, гасим её быстро (0.2 сек)
	if background_rect.modulate.a > 0.01:
		tween.tween_property(background_rect, "modulate:a", 0.0, 0.2)
	
	# Меняем текстуру
	tween.tween_callback(func(): background_rect.texture = new_texture)
	
	# Проявляем новую картинку быстро (0.2 сек)
	tween.tween_property(background_rect, "modulate:a", 1.0, 0.2)
