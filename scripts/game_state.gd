extends Node

var chosen_class: String = "warrior"
var player_sprite = null

# --- Currency ---
signal coins_changed(total: int)
var coins: int = 0

# --- Upgrades (0–10 each) ---
signal upgrades_changed()

var upgrade_levels: Dictionary = {
	"firerate": 0,
	"speed": 0,
	"attack": 0,
	"defence": 0,
}

const MAX_UPGRADE_LEVEL: int = 10

## Cost to upgrade from current level → next level.
func get_upgrade_cost(stat: String) -> int:
	var level = upgrade_levels.get(stat, 0)
	return 5 + level * 5  # 5, 10, 15, 20 …

## Returns the multiplier for a stat. Each level = +10%.
## Attack/Speed/Firerate: 1.0  →  2.0 at level 10
## Defence: damage taken multiplier 1.0  →  0.0 at level 10 (invincible)
func get_multiplier(stat: String) -> float:
	var level = upgrade_levels.get(stat, 0)
	match stat:
		"defence":
			return 1.0 - level * 0.10  # 1.0, 0.9, 0.8 …
		_:
			return 1.0 + level * 0.10  # 1.0, 1.1, 1.2 …

func try_upgrade(stat: String) -> bool:
	var level = upgrade_levels.get(stat, 0)
	if level >= MAX_UPGRADE_LEVEL:
		return false
	var cost = get_upgrade_cost(stat)
	if spend_coins(cost):
		upgrade_levels[stat] = level + 1
		upgrades_changed.emit()
		return true
	return false

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
