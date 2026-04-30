
extends Node2D

const SCENES = {
	"archer":  preload("res://scenes/archer.tscn"),
	"warrior": preload("res://scenes/warrior.tscn"),
}

const COIN_SCENE = preload("res://scenes/coin.tscn")
const COIN_DROP_CHANCE = 1.0  # 100% chance to drop a coin

func _ready():
	var player_scene

	if GameState.chosen_class == "archer":
		player_scene = preload("res://scenes/archer.tscn")
	else:
		player_scene = preload("res://scenes/warrior.tscn")

	var player = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector2(0, 0)

	# Hook up coin drops for all enemies (after they're in the tree)
	await get_tree().process_frame
	_connect_enemy_drops()

func _connect_enemy_drops() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.tree_exiting.is_connected(_on_enemy_dying):
			enemy.tree_exiting.connect(_on_enemy_dying.bind(enemy))

func _on_enemy_dying(enemy: Node) -> void:
	if randf() < COIN_DROP_CHANCE:
		var pos = enemy.global_position
		call_deferred("_spawn_coin_at", pos)

func _spawn_coin_at(pos: Vector2) -> void:
	var coin = COIN_SCENE.instantiate()
	add_child(coin)
	coin.global_position = pos

func _on_archer_button_pressed() -> void:
	pass # Replace with function body.


func _on_warrior_button_pressed() -> void:
	pass # Replace with function body.

