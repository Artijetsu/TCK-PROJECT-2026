extends Button


# Функция _on_pressed вызывается при нажатии на кнопку
func _on_pressed() -> void:
	# Переходим на оптимизированную сцену главного меню
	get_tree().change_scene_to_file("res://SCENE/main_optimized.tscn")
