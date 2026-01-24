extends Node2D

@onready var hotbar_scene = preload("res://SCENE/hotbar.tscn")

const CHAR_SUPERMAN = "res://ПЕРСОНАЖИ/character_body_2d.tscn"
const CHAR_SMARTMAN = "res://ПЕРСОНАЖИ/character_body1_2d.tscn"

func _ready():
    print("Сцена 001 открыта")
    
    # Добавляем хотбар
    var hb = hotbar_scene.instantiate()
    add_child(hb)
    
    # Настройка персонажа
    _setup_character()
    
    # Настройка NPC (должен быть тем, кого не выбрали)
    _setup_npc()

func _setup_character():
    # Проверяем наличие глобальной переменной
    var selected_path = CHAR_SUPERMAN
    if Global and "selected_character_path" in Global:
        selected_path = Global.selected_character_path
    
    print("Выбранный персонаж: ", selected_path)
    
    # Ищем текущего персонажа на сцене
    var current_char = get_node_or_null("CharacterBody2D")
    
    if current_char:
        # Если путь совпадает с текущим, ничего не делаем
        if current_char.scene_file_path == selected_path:
            print("Персонаж уже на месте")
        else:
            print("Заменяем персонажа...")
            var char_pos = current_char.position
            
            # Загружаем нового
            if ResourceLoader.exists(selected_path):
                var new_scene = load(selected_path)
                var new_char = new_scene.instantiate()
                
                new_char.position = char_pos
                new_char.name = "CharacterBody2D" # Сохраняем имя
                
                # Удаляем старого
                current_char.queue_free()
                
                # Добавляем нового
                add_child(new_char)
                
                # Принудительно активируем камеру нового персонажа
                var cam = new_char.get_node_or_null("Camera2D")
                if cam:
                    cam.enabled = true
                    cam.make_current()
                    
                # Отключаем камеру сцены, если она есть, чтобы не мешала
                var scene_cam = get_node_or_null("Camera2D")
                if scene_cam:
                    scene_cam.enabled = false
            else:
                printerr("Файл персонажа не найден: ", selected_path)
    else:
        # Если персонажа нет на сцене, просто создаем
        if ResourceLoader.exists(selected_path):
            var new_scene = load(selected_path)
            var new_char = new_scene.instantiate()
            new_char.position = Vector2(100, 100) # Дефолтная позиция
            new_char.name = "CharacterBody2D"
            add_child(new_char)

func _setup_npc():
    # Определяем, кто игрок, а кто должен быть NPC
    var player_path = CHAR_SUPERMAN
    if Global and "selected_character_path" in Global:
        player_path = Global.selected_character_path
        
    var npc_path = CHAR_SMARTMAN
    var npc_name_display = "Умный человек"
    
    if player_path == CHAR_SMARTMAN:
        npc_path = CHAR_SUPERMAN
        npc_name_display = "Супермэн"
    
    # Ищем текущего NPC
    var current_npc = get_node_or_null("NPC")
    var npc_pos = Vector2(99, 157) # Дефолтная позиция NPC
    
    if current_npc:
        npc_pos = current_npc.position
        current_npc.queue_free() # Удаляем старого NPC
        
    # Создаем нового NPC на базе сцены персонажа
    if ResourceLoader.exists(npc_path):
        var npc_scene = load(npc_path)
        var npc_instance = npc_scene.instantiate()
        
        npc_instance.name = "NPC"
        npc_instance.position = npc_pos
        
        # ВАЖНО: Убираем скрипт управления игроком, чтобы NPC не бегал сам
        npc_instance.set_script(null)
        
        # Убираем камеру, если есть
        var camera = npc_instance.get_node_or_null("Camera2D")
        if camera:
            camera.queue_free()
            
        # Добавляем зону взаимодействия (как в npc.tscn)
        var interaction_area = Area2D.new()
        interaction_area.name = "InteractionArea"
        
        # Загружаем скрипт NPC
        var npc_script = load("res://SCRIPTS/npc.gd")
        interaction_area.set_script(npc_script)
        
        # Настраиваем параметры скрипта
        interaction_area.npc_name = npc_name_display
        var lines: Array[String] = [
            "Привет! Я " + npc_name_display + ".",
			"Ты выбрал другого героя, но я тоже тут."
        ]
        interaction_area.dialogue_lines = lines
        
        # Коллизия для зоны взаимодействия
        var shape = CollisionShape2D.new()
        var circle = CircleShape2D.new()
        circle.radius = 40
        shape.shape = circle
        interaction_area.add_child(shape)
        
        # Добавляем лейбл подсказки (HintLabel)
        var label = Label.new()
        label.name = "HintLabel"
        label.text = "Нажмите E"
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.position = Vector2(-50, -60)
        label.size = Vector2(100, 30)
        label.visible = false
        interaction_area.add_child(label)
        
        npc_instance.add_child(interaction_area)
        
        add_child(npc_instance)
