extends Node

# Active powerups and their timers
var active_powerups: Dictionary = {}

const POWERUP_DURATION = 10.0  # seconds each powerup lasts

signal powerup_activated(type: String)
signal powerup_expired(type: String)

func activate(type: String) -> void:
	active_powerups[type] = POWERUP_DURATION
	powerup_activated.emit(type)
	print("Powerup activated: ", type)

func has_powerup(type: String) -> bool:
	return active_powerups.has(type)

func _process(delta: float) -> void:
	for type in active_powerups.keys():
		active_powerups[type] -= delta
		if active_powerups[type] <= 0:
			active_powerups.erase(type)
			powerup_expired.emit(type)
			print("Powerup expired: ", type)
