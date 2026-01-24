extends CharacterBody2D

# Настройки скорости передвижения
@export var speed: float = 130.0
# Параметр для ускорения (бег)
@export var run_speed: float = 210.0
# Ускорение и трение для плавности
@export var acceleration: float = 1500.0
@export var friction: float = 1500.0

# Ссылка на анимационный спрайт. 
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Переменная-состояние, которая показывает, занят ли персонаж диалогом или другим взаимодействием.
var is_interacting: bool = false

# Зона взаимодействия
var interaction_area: Area2D

# Эту функцию будут вызывать другие объекты (диалоги, сундуки), когда они закончат свою работу.
func on_interaction_finished():
	is_interacting = false
	print("Взаимодействие завершено, можно снова нажимать E.")

func _ready() -> void:
	# Устанавливаем фильтрацию текстур на Nearest (Ближайший сосед), чтобы пиксели были четкими и не размывались
	# Это стандарт для пиксель-арта
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
	# Если игра на паузе, не обрабатываем физику движения
	if get_tree().paused:
		return
		
	# Получаем вектор ввода через вспомогательную функцию
	# Это обеспечивает поддержку и WASD, и стрелок, и геймпада
	var direction = get_input_direction()
	
	var current_speed = speed
	# Можно добавить проверку на бег (например, Shift)
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = run_speed
	
	if direction:
		# Плавное ускорение
		velocity = velocity.move_toward(direction * current_speed, acceleration * delta)
		update_animation(direction)
	else:
		# Плавная остановка (friction)
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		# Останавливаем анимацию, если персонаж почти остановился
		if animated_sprite.is_playing():
			animated_sprite.stop()
			# Сбрасываем кадр на первый (обычно стоячая поза), чтобы не замирать в странной позе
			animated_sprite.frame = 0 

	move_and_slide()

# Вспомогательная функция для получения ввода
func get_input_direction() -> Vector2:
	# Эта функция объединяет ввод от стрелок/геймпада и от клавиш WASD.
	# Таким образом, персонажем можно управлять и так, и так.
	var vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Добавляем к вектору ввод от WASD.
	# int(true) - это 1, int(false) - это 0.
	# Поэтому, если нажать D, к иксу прибавится 1. Если A - вычтется 1.
	vector.x += int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
	vector.y += int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	
	# normalized() делает так, чтобы при движении по диагонали (например, зажаты W и D)
	# персонаж не двигался быстрее, чем при движении прямо.
	return vector.normalized()

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
	# Проверяем, не занят ли персонаж уже чем-то. Если да - выходим.
	if is_interacting:
		return

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
		var target = candidates[0]
		target.interact(self)
		
		# Устанавливаем флаг, что мы начали взаимодействие.
		# Теперь повторные нажатия E будут игнорироваться до вызова on_interaction_finished().
		is_interacting = true
		print("Начато взаимодействие с ", target.name)

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
