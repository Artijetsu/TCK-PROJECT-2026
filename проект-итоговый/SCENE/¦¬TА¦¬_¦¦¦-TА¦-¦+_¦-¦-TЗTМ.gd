extends Node2D
# Заранее загружаем сцену с диалоговым окном. 
@onready var dialogue_box_scene = preload("res://SCENE/dialogue_box.tscn")
# Эта функция запускается автоматически один раз, когда сцена появляется в игре
func _ready():
# Создаём реальное окно диалога из заготовки (как будто нажал "дублировать сцену")
    var dialog = dialogue_box_scene.instantiate()
    # Добавляем созданное окно в текущий уровень 
    add_child(dialog)
     # Запускаем диалог и сразу передаём ему список всех реплик
    var dialog_control = dialog.get_node("CanvasLayer/Control")
    dialog_control.call_deferred("start_dialogue", [
       {"name": "Антон", "portrait": preload("res://IMG/Антон.png"), "text": "Я уже красный, культурно не получится!"}
    ] as Array[Dictionary], null) # ← ВАЖНО: передаем null как второй аргумент (interactor)
