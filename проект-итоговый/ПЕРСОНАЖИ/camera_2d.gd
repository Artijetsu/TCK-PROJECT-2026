extends Camera2D


func _ready() -> void:
	# Включаем сглаживание
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0 # Делаем камеру более плавной и "ленивой"
	
	
	# Приближение камеры
	zoom = Vector2(4.0, 4.0)
	
	# Убираем лимиты карты (ставим очень большие значения), чтобы камера следила везде
	limit_left = 35
	limit_right = 317
	limit_top = 32
	limit_bottom = 304
	
	# Делаем эту камеру активной
	make_current()
	
	# Включаем небольшую "мертвую зону", чтобы камера не дергалась от каждого микро-движения
	drag_horizontal_enabled = true
	drag_vertical_enabled = true
	drag_left_margin = 0.05
	drag_right_margin = 0.05
	drag_top_margin = 0.05
	drag_bottom_margin = 0.05
	
	# Сбрасываем смещение
	offset = Vector2.ZERO
	
	# Гарантируем, что камера привязана к родителю
	top_level = false
	
	# Синхронизируем обновление камеры с физикой
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
