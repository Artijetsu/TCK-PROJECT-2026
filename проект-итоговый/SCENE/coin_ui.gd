extends Control

@onready var label = $Panel/Label

func _ready():
	add_to_group("CoinUI")
	# Wait for the node to be ready and in tree before accessing Global if needed, 
	# but Global is an autoload so it should be fine.
	update_coins(Global.coins)

func update_coins(amount: int):
	if label:
		label.text = str(amount)
