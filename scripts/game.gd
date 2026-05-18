extends Node2D

const SCENES = {
	"archer": preload("res://scenes/archer.tscn"),
	"warrior": preload("res://scenes/warrior.tscn"),
}
const POWERUP_DROP_SCENE = preload("res://scenes/powerup_drop.tscn")
const POWERUP_DROP_CHANCE = 0.15 # 25% chance

const POWERUP_DROP_SCENE = preload("res://scenes/powerup_drop.tscn")
const COIN_SCENE = preload("res://scenes/coin.tscn")
const COIN_DROP_CHANCE = 1.0 # 100% chance to drop a coin

func _ready():
	var player_scene

	if GameState.chosen_class == "archer":
		player_scene = SCENES["archer"]
	else:
		player_scene = SCENES["warrior"]

	var player = player_scene.instantiate()

	if GameState.chosen_class == "archer":
		player.MAX_HEALTH = 100
	else:
		player.MAX_HEALTH = 150

	add_child(player)
	player.global_position = Vector2(0, 0)

	await get_tree().process_frame
	_connect_enemy_drops()


func _connect_enemy_drops() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		_connect_single_enemy(enemy)


func _connect_single_enemy(enemy: Node) -> void:
	await get_tree().process_frame

	if not is_instance_valid(enemy):
		return

	if not enemy.tree_exiting.is_connected(_on_enemy_dying):
		enemy.tree_exiting.connect(_on_enemy_dying.bind(enemy))


func _on_enemy_dying(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return

	var pos: Vector2 = enemy.global_position

	if randf() < COIN_DROP_CHANCE:
		call_deferred("_spawn_coin_at", pos)

	if randf() < POWERUP_DROP_CHANCE:
		call_deferred("_spawn_powerup_at", pos)


func _spawn_powerup_at(pos: Vector2) -> void:
	var pickup = POWERUP_DROP_SCENE.instantiate()

	var archer_powerups = ["triple_shot", "rapid_fire", "explosive_arrows"]
	var warrior_powerups = ["spin_attack", "triple_slash", "berserker"]

	if GameState.chosen_class == "archer":
		pickup.powerup_type = archer_powerups[randi() % archer_powerups.size()]
	else:
		pickup.powerup_type = warrior_powerups[randi() % warrior_powerups.size()]

	add_child(pickup)
	pickup.global_position = pos


func _spawn_coin_at(pos: Vector2) -> void:
	var coin = COIN_SCENE.instantiate()
	add_child(coin)
	coin.global_position = pos


func _on_archer_button_pressed() -> void:
	pass


func _on_warrior_button_pressed() -> void:
	pass
