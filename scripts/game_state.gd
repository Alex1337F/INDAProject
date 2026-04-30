extends Node

var chosen_class: String = "warrior"
var player_sprite = null

# --- Currency ---
signal coins_changed(total: int)
var coins: int = 0

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit(coins)
		return true
	return false

func reset_coins() -> void:
	coins = 0
	coins_changed.emit(coins)
