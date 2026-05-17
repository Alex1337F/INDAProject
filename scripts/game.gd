extends Node2D

const SCENES = {
	"archer": preload("res://scenes/archer.tscn"),
	"warrior": preload("res://scenes/warrior.tscn"),
}
const POWERUP_DROP_SCENE = preload("res://scenes/powerup_drop.tscn")
const POWERUP_DROP_CHANCE = 0.15 # 25% chance

const COIN_SCENE = preload("res://scenes/coin.tscn")
const COIN_DROP_CHANCE = 1.0 # 100% chance to drop a coin

func _ready():
	var player_scene

	if GameState.chosen_class == "archer":
		player_scene = preload("res://scenes/archer.tscn")
	else:
		player_scene = preload("res://scenes/warrior.tscn")

	var player = player_scene.instantiate()
	if GameState.chosen_class == "archer":
		player.MAX_HEALTH = 100 # archer is squishier
	else:
		player.MAX_HEALTH = 150 # warrior is tankier
	add_child(player)
	player.global_position = Vector2(0, 0)

	# Hook up coin drops for all enemies (after they're in the tree)
	await get_tree().process_frame
	_connect_enemy_drops()

func _connect_enemy_drops() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.tree_exiting.is_connected(_on_enemy_dying):
			enemy.tree_exiting.connect(_on_enemy_dying.bind(enemy))
		
func _connect_single_enemy(enemy: Node) -> void:
	await get_tree().process_frame # wait for enemy to be fully in tree
	if is_instance_valid(enemy) and not enemy.tree_exiting.is_connected(_on_enemy_dying):
		enemy.tree_exiting.connect(_on_enemy_dying.bind(enemy))
func _on_enemy_dying(enemy: Node) -> void:
	# Capture position while still valid
	var pos = Vector2.ZERO
	if is_instance_valid(enemy):
		pos = enemy.global_position
	else:
		return
		
	if randf() < COIN_DROP_CHANCE:
		call_deferred("_spawn_coin_at", pos)
	if randf() < POWERUP_DROP_CHANCE:
		call_deferred("_spawn_powerup_at", pos)
func _spawn_powerup_at(pos: Vector2) -> void:
	var pickup = POWERUP_DROP_SCENE.instantiate()
	add_child(pickup)
	pickup.global_position = pos
func _spawn_coin_at(pos: Vector2) -> void:
	var coin = COIN_SCENE.instantiate()
	add_child(coin)
	coin.global_position = pos

func _on_archer_button_pressed() -> void:
	pass # Replace with function body.


func _on_warrior_button_pressed() -> void:
	pass # Replace with function body.
