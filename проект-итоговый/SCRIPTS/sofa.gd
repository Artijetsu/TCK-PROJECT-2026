extends Area2D

@onready var label = $Label
var is_player_near = false
var is_sitting = false
var sitting_player: CharacterBody2D = null
var pre_sit_position = Vector2.ZERO

# Integration with Player's interaction system
var interaction_action = "key_e"

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
		
	label.visible = false
	label.text = "Нажмите Е, чтобы сесть"

func _on_body_entered(body):
	if body is CharacterBody2D:
		is_player_near = true
		if not is_sitting:
			label.visible = true

func _on_body_exited(body):
	if body is CharacterBody2D:
		is_player_near = false
		if not is_sitting:
			label.visible = false

# Called by player_controller.gd when pressing E near this object
func interact(body):
	if not is_sitting:
		sit_down(body)

func _unhandled_input(event):
	if is_sitting and sitting_player:
		if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
			stand_up()
			get_viewport().set_input_as_handled()

func sit_down(player_body):
	is_sitting = true
	sitting_player = player_body
	label.visible = false
	pre_sit_position = sitting_player.global_position
	
	# Move player to center of sofa
	# Use get_parent().global_position because this script is now on the InteractionArea child node
	sitting_player.global_position = get_parent().global_position
	
	# Ensure player is rendered on top (z_index)
	sitting_player.z_index = 10 
	
	# Disable movement logic in player
	sitting_player.set_physics_process(false)
	
	# Stop any residual velocity
	sitting_player.velocity = Vector2.ZERO
	
	# Play sitting animation if available, or idle
	if sitting_player.has_node("AnimatedSprite2D"):
		sitting_player.get_node("AnimatedSprite2D").play("idel")

func stand_up():
	if sitting_player:
		# Move player back
		sitting_player.global_position = pre_sit_position
		
		# Reset z_index (assuming default is 0 or handled by Y-sort)
		sitting_player.z_index = 0
		
		# Enable movement
		sitting_player.set_physics_process(true)
		
		# Notify player that interaction is finished (resets is_interacting flag)
		if sitting_player.has_method("on_interaction_finished"):
			sitting_player.on_interaction_finished()
		
		sitting_player = null
		
	is_sitting = false
	
	# Show label again if player is still near (which they should be after teleporting back)
	# We check overlap manually or rely on signals. 
	# Note: Teleporting might not trigger body_entered immediately if within same frame/physics tick logic
	# But pre_sit_position should be within the area usually.
	label.visible = true
