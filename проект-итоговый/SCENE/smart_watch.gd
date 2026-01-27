extends Control

# --- ССЫЛКИ НА ЭЛЕМЕНТЫ ИНТЕРФЕЙСА ---
# Ссылка на главную панель (первая вкладка меню)
@onready var main_panel = $MainPanel
# Ссылка на панель рандомайзера (вторая вкладка меню)
@onready var randomizer_panel = $RandomizerPanel
# Ссылка на текстовое поле диалога помощника
@onready var helper_label = $MainPanel/DialogueBox/RichTextLabel
# Ссылки на слоты для картинок в рандомайзере
@onready var slot1 = $RandomizerPanel/Slots/Slot1/Image
@onready var slot2 = $RandomizerPanel/Slots/Slot2/Image
@onready var slot3 = $RandomizerPanel/Slots/Slot3/Image
# Ссылки на кнопки управления рандомайзером
@onready var spin_btn = $RandomizerPanel/SpinBtn
@onready var teleport_btn = $RandomizerPanel/TeleportBtn

# --- ДАННЫЕ ДЛЯ ДИАЛОГА ---
# Массив фраз помощника, которые можно пролистывать
var helper_lines = [
    "Привет! Я твой умный помощник.",
    "Нажми 'Выбор вселенной', чтобы испытать удачу.",
    "Если выпадут три одинаковые картинки, ты сможешь переместиться!",
    "Не забывай проверять сундуки.",
    "Удачи в путешествиях!"
]
# Индекс текущей отображаемой фразы
var current_line_index = 0

# Счетчик попыток прокрутки
var spin_attempts = 0

# --- ДАННЫЕ ДЛЯ РАНДОМАЙЗЕРА ---
# Загружаем картинки для слотов (предварительная загрузка)
var images = [
    preload("res://IMG/супермэн.webp"),
    preload("res://IMG/умный человек.webp"),
    preload("res://IMG/вселеная.webp")
]

# Функция инициализации при запуске сцены
func _ready():
    # Важно: часы должны обрабатывать ввод даже при паузе (чтобы закрыться)
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    # Скрываем все меню при старте
    visible = false
    # Показываем главную панель по умолчанию
    main_panel.visible = true
    # Скрываем панель рандомайзера
    randomizer_panel.visible = false
    # Блокируем кнопку телепортации до выигрыша
    teleport_btn.disabled = true
    # Обновляем текст помощника
    update_helper_text()
    
    # Подключаем сигнал изменения видимости для паузы
    if not visibility_changed.is_connected(_on_visibility_changed):
        visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
    get_tree().paused = visible
    Global.is_smart_watch_open = visible
    
    # Если меню стало видимым и интро еще не пройдено
    if visible and not Global.smart_watch_intro_completed:
        start_intro_sequence()

func start_intro_sequence():
    Global.is_cutscene_playing = true
    # Блокируем взаимодействие с интерфейсом часов пока идет интро
    main_panel.visible = false # Скрываем пока панели
    
    # 1. Диалог от часов
    var dialogue_ui = get_tree().get_first_node_in_group("DialogueUI")
    if dialogue_ui:
        var lines: Array[Dictionary] = [
            {
                "name": "Smart Watch",
                "text": "Здравствуй, пользователь! Я твой компаньон в путешествиях между вселенными."
            },
            {
                "name": "Smart Watch",
                "text": "Перед тем как мы начнем наше увлекательное путешествие, ты должен подписать пользовательское соглашение."
            }
        ]
        dialogue_ui.start_dialogue(lines, null)
        await dialogue_ui.dialogue_ended
        
        # 2. Окно пользовательского соглашения
        var eula_scene = preload("res://SCENE/eula_ui.tscn").instantiate()
        get_parent().add_child(eula_scene) # Добавляем в UI слой
        await eula_scene.agreement_signed
        
        # 3. Диалог "Отлично..."
        lines = [{
            "name": "Smart Watch",
            "text": "Отлично, да начнется великое путешествие!"
        }]
        dialogue_ui.start_dialogue(lines, null)
        await dialogue_ui.dialogue_ended
        
        # 4. Исчезновение NPC
        var npcs = get_tree().get_nodes_in_group("NPC")
        if npcs.size() > 0:
            # Берем первого попавшегося NPC (обычно ближайший или единственный)
            # Нужно убедиться что вызываем vanish у скрипта взаимодействия (Area2D), а не у тела
            # Но в группу NPC мы добавляли именно Area2D (скрипт npc.gd)
            npcs[0].vanish()
            # Ждем немного для эффекта (таймер работает даже на паузе)
            await get_tree().create_timer(1.0, true, false, true).timeout
            
        # 5. Диалог игрока "Какого черта?"
        lines = [{
            "name": "Игрок",
            "text": "Какого черта? Где он? Жестянка! Верни моего друга!"
        }]
        dialogue_ui.start_dialogue(lines, null)
        await dialogue_ui.dialogue_ended
        
        # Завершаем интро
        Global.smart_watch_intro_completed = true
        Global.is_cutscene_playing = false
        
        # Возвращаем интерфейс часов
        main_panel.visible = true

# Обработка ввода (Z для открытия/закрытия)
func _input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_TAB or event.keycode == KEY_Z:
             # Блокируем часы во время катсцен
            if Global.is_cutscene_playing:
                return

            # Блокируем часы, если еще не поговорили с курьером
            if not Global.courier_dialogue_completed:
                return

            # Если часы закрыты, но игра на паузе (например, диалог) - не открываем
            if not visible and get_tree().paused:
                return
                
            visible = not visible

# --- ФУНКЦИИ ГЛАВНОЙ ПАНЕЛИ ---

# Нажатие на кнопку закрытия
func _on_close_pressed():
    visible = false

# Нажатие на кнопку "Выбор вселенной"
func _on_universe_select_pressed():
    # Скрываем главную панель
    main_panel.visible = false
    # Показываем панель рандомайзера
    randomizer_panel.visible = true

# Нажатие на кнопку "Назад" (<) в диалоге
func _on_prev_line_pressed():
    # Если это не первая фраза
    if current_line_index > 0:
        # Уменьшаем индекс
        current_line_index -= 1
        # Обновляем текст
        update_helper_text()

# Нажатие на кнопку "Вперед" (>) в диалоге
func _on_next_line_pressed():
    # Если это не последняя фраза
    if current_line_index < helper_lines.size() - 1:
        # Увеличиваем индекс
        current_line_index += 1
        # Обновляем текст
        update_helper_text()

# Функция обновления текста в лейбле
func update_helper_text():
    helper_label.text = helper_lines[current_line_index]

# --- ФУНКЦИИ ПАНЕЛИ РАНДОМАЙЗЕРА ---

# Нажатие на кнопку "Назад" (возврат в главное меню часов)
func _on_back_pressed():
    # Скрываем рандомайзер
    randomizer_panel.visible = false
    # Показываем главную панель
    main_panel.visible = true

# Нажатие на кнопку "Крутить"
func _on_spin_pressed():
    if not Global.spend_coins(1):
        randomizer_panel.visible = false
        main_panel.visible = true
        helper_label.text = "Недостаточно монет для запуска! Поищи их в мире."
        return

    # Блокируем кнопку кручения, чтобы не нажимали повторно
    spin_btn.disabled = true
    # Блокируем телепорт на время вращения
    teleport_btn.disabled = true
    
    # Цикл анимации прокрутки (20 шагов)
    for i in range(20):
        # Ставим случайную картинку в каждый слот
        slot1.texture = images.pick_random()
        slot2.texture = images.pick_random()
        slot3.texture = images.pick_random()
        # Ждем 0.1 секунды (асинхронно)
        await get_tree().create_timer(0.1).timeout
        
    # Увеличиваем счетчик попыток
    spin_attempts += 1
    
    var result1
    var result2
    var result3
    
    # Если 5-я попытка или больше - гарантированный выигрыш
    if spin_attempts >= 5:
        var guaranteed_img = images.pick_random()
        result1 = guaranteed_img
        result2 = guaranteed_img
        result3 = guaranteed_img
        print("Гарантированный выигрыш! Попытка: ", spin_attempts)
    else:
        # Определяем финальный результат (случайный выбор)
        result1 = images.pick_random()
        result2 = images.pick_random()
        result3 = images.pick_random()
    
    # Устанавливаем финальные картинки
    slot1.texture = result1
    slot2.texture = result2
    slot3.texture = result3
    
    # Разблокируем кнопку кручения
    spin_btn.disabled = false
    
    # Проверяем на совпадение (Джекпот)
    if result1 == result2 and result2 == result3:
        # Разблокируем кнопку телепортации
        teleport_btn.disabled = false
        print("Джекпот! Перемещение разблокировано.")

# Нажатие на кнопку "Переместиться"
func _on_teleport_pressed():
    print("Телепортация...")
    
    # Скрываем часы и снимаем паузу
    visible = false
    get_tree().paused = false
    Global.is_smart_watch_open = false
    
    # Меняем сцену
    get_tree().change_scene_to_file("res://SCENE/teleport_location.tscn")
