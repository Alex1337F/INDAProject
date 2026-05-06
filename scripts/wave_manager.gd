extends Node

# Fill these with your enemy scenes
const ENEMY_SCENES = [
	preload("res://scenes/YellowBatEnemy.tscn"),
	preload("res://scenes/eyeEnemy.tscn"),
	preload("res://scenes/skeletonEnemy.tscn"),
	preload("res://scenes/bambooEnemy.tscn"),
	preload("res://scenes/enemy.tscn"),
]

@export var enemies_per_wave: int = 4
@export var total_waves: int = 5
@export var spawn_radius: float = 200.0
@export var miniboss_scene: PackedScene = null

var current_wave: int = 0
var miniboss_spawned: bool = false
var player: CharacterBody2D

signal wave_started(wave_number: int, total: int)
signal all_waves_cleared
signal level_complete

const SPAWN_POINTS = [
	Vector2(-100, 70),
	Vector2(-150, -230),
	Vector2(200, -230),
	Vector2(320, 20),
]

func _ready() -> void:
	add_to_group("wave_manager")
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	# Start first wave after short delay
	await get_tree().create_timer(1.5).timeout
	_start_next_wave()

func _start_next_wave() -> void:
	if current_wave >= total_waves:
		all_waves_cleared.emit()
		_wait_for_clear_then_miniboss()
		return

	current_wave += 1
	wave_started.emit(current_wave, total_waves)

	# Small delay so the announcement shows before enemies spawn
	await get_tree().create_timer(0.8).timeout

	for i in range(enemies_per_wave):
		_spawn_random_enemy()

	# Connect coin drops for newly spawned enemies
	await get_tree().process_frame
	if get_parent().has_method("_connect_enemy_drops"):
		get_parent()._connect_enemy_drops()

	# Wait for all enemies in this wave to die, then start the next
	_wait_for_wave_clear()

func _wait_for_wave_clear() -> void:
	# Poll until all enemies from this wave are dead
	while get_tree().get_nodes_in_group("enemy").size() > 0:
		await get_tree().create_timer(0.4).timeout

	# Brief pause between waves
	await get_tree().create_timer(1.0).timeout
	_start_next_wave()

func _spawn_random_enemy() -> void:
	var scene = ENEMY_SCENES[randi() % ENEMY_SCENES.size()]
	var enemy = scene.instantiate()
	get_parent().add_child(enemy)
	var spawn = SPAWN_POINTS[randi() % SPAWN_POINTS.size()]
	enemy.global_position = spawn

func _wait_for_clear_then_miniboss() -> void:
	while get_tree().get_nodes_in_group("enemy").size() > 0:
		await get_tree().create_timer(0.5).timeout

	if miniboss_scene != null and not miniboss_spawned:
		_spawn_miniboss()
	else:
		level_complete.emit()

func _spawn_miniboss() -> void:
	miniboss_spawned = true
	var boss = miniboss_scene.instantiate()
	get_parent().add_child(boss)
	if player:
		boss.global_position = player.global_position + Vector2(150, 0)
	_wait_for_miniboss_death(boss)

func _wait_for_miniboss_death(boss: Node) -> void:
	while is_instance_valid(boss):
		await get_tree().create_timer(0.5).timeout
	level_complete.emit()
