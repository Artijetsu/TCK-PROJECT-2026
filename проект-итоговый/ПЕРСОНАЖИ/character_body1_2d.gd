extends CharacterBody2D

# Настройки скорости передвижения
@export var speed: float = 130.0
# Параметр для ускорения (бег)
@export var run_speed: float = 210.0

# Ссылка на анимационный спрайт. 
@onready var animated_sprite: AnimatedSprite2D = $CollisionShape2D/AnimatedSprite2D

# Зона взаимодействия
var interaction_area: Area2D

func _ready() -> void:
    # Устанавливаем фильтрацию текстур на Nearest (Ближайший сосед), чтобы пиксели были четкими
    if animated_sprite:
        animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

    # Создаем зону взаимодействия программно
    interaction_area = Area2D.new()
    interaction_area.name = "InteractionArea"
    add_child(interaction_area)
    
    var collision_shape = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = 60.0 # Радиус взаимодействия
    collision_shape.shape = shape
    interaction_area.add_child(collision_shape)

func _physics_process(delta: float) -> void:
    # Получаем вектор ввода через вспомогательную функцию
    # Это обеспечивает поддержку и WASD, и стрелок, и геймпада
    var direction = get_input_direction()
    
    var current_speed = speed
    # Можно добавить проверку на бег (например, Shift)
    if Input.is_key_pressed(KEY_SHIFT):
        current_speed = run_speed
    
    if direction:
        velocity = direction * current_speed
        update_animation(direction)
    else:
        # Плавная остановка (friction)
        velocity = velocity.move_toward(Vector2.ZERO, current_speed)
        # Останавливаем анимацию, если персонаж стоит
        if animated_sprite.is_playing():
            animated_sprite.stop()
            # Сбрасываем кадр на первый (обычно стоячая поза), чтобы не замирать в странной позе
            animated_sprite.frame = 0 

    move_and_slide()

# Вспомогательная функция для получения ввода
func get_input_direction() -> Vector2:
    # 1. Пробуем получить ввод через стандартные действия (стрелки, геймпад)
    # ui_left/right/up/down настроены в Godot по умолчанию
    var vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    
    # 2. Если вектор нулевой (игрок не жмет стрелки), проверяем WASD вручную
    # Это нужно, если в настройках проекта не добавлены маппинги для WASD
    if vector == Vector2.ZERO:
        var x = int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
        var y = int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
        vector = Vector2(x, y).normalized()
        
    return vector

# Обработка ввода, который не был перехвачен GUI
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        try_interact("ui_accept")
    
    # Обработка нажатия E (Interact)
    # Используем keycode для корректной работы
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_E:
            try_interact("key_e")

func try_interact(action_type: String):
    var areas = interaction_area.get_overlapping_areas()
    var candidates = []
    
    for area in areas:
        # Проверяем, есть ли у объекта свойство interaction_action
        var target_action = "ui_accept" # По умолчанию
        if "interaction_action" in area:
            target_action = area.interaction_action
        
        # Если действие совпадает и есть метод interact
        if target_action == action_type and area.has_method("interact"):
            candidates.append(area)
            
    # Если есть кандидаты, выбираем ближайшего
    if candidates.size() > 0:
        candidates.sort_custom(func(a, b): 
            return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
        )
        # Взаимодействуем с самым близким
        candidates[0].interact(self)

# Функция обновления анимации в зависимости от направления
func update_animation(dir: Vector2):
    # Приоритет боковой анимации
    if dir.x != 0:
        animated_sprite.play("right")
        # Отражаем спрайт если идем влево
        animated_sprite.flip_h = (dir.x < 0)
    elif dir.y != 0:
        if dir.y > 0:
            animated_sprite.play("down")
        else:
            animated_sprite.play("top")
