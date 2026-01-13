extends Button


# Функция вызывается при нажатии на кнопку "Играть"
func _on_pressed():
	# Добавляем отладочное сообщение
	print("Кнопка Играть нажата. Попытка перехода на res://SCENE/scene1.tscn")
	
	if Global:
		Global.coins = 0
		Global.chest_coin_taken = false
		Global.npc_coin_given = false
		Global.smart_watch_intro_completed = false
		Global.is_cutscene_playing = false
		Global.is_smart_watch_open = false
		Global.selected_character_path = "res://ПЕРСОНАЖИ/character_body_2d.tscn"
	
	var target_scene = "res://SCENE/scene1.tscn"
	if ResourceLoader.exists(target_scene):
		# Переходим на новую сцену scene1.tscn
		get_tree().change_scene_to_file(target_scene)
	else:
		print("ОШИБКА: Сцена не найдена по пути: ", target_scene)
	

# Функция вызывается при нажатии на кнопку "Настройки"
func _on_settings_btn_pressed():
	# Переходим на сцену settings.tscn
	get_tree().change_scene_to_file("res://SCENE/settings.tscn")
  

# Функция вызывается при нажатии на кнопку "Выйти"
func _on_quit_btn_pressed():
	# Завершаем работу приложения
	get_tree().quit()
