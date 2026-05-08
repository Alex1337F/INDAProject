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
@export var min_spawn_distance: float = 80.0   # Don't spawn right on top of the player
@export var max_spawn_distance: float = 300.0   # Don't spawn too far away either
@export var miniboss_scene: PackedScene = null

var current_wave: int = 0
var miniboss_spawned: bool = false
var player: CharacterBody2D
var grass_positions: Array[Vector2] = []   # World positions of all grass tiles

signal wave_started(wave_number: int, total: int)
signal all_waves_cleared
signal level_complete

func _ready() -> void:
	add_to_group("wave_manager")

	# Collect all grass tile world positions once
	_cache_grass_positions()

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	# Start first wave after short delay
	await get_tree().create_timer(1.5).timeout
	_start_next_wave()

func _cache_grass_positions() -> void:
	var grass_layer: TileMapLayer = get_parent().get_node_or_null("GrassLayer")
	if grass_layer == null:
		push_warning("WaveManager: No GrassLayer found — falling back to origin.")
		grass_positions.append(Vector2.ZERO)
		return

	for cell in grass_layer.get_used_cells():
		grass_positions.append(grass_layer.map_to_local(cell))

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
	enemy.global_position = _pick_grass_spawn()

func _pick_grass_spawn() -> Vector2:
	if grass_positions.is_empty():
		return Vector2.ZERO

	# Try to find a grass tile within the ideal distance band from the player
	var player_pos = player.global_position if player else Vector2.ZERO
	var candidates: Array[Vector2] = []
	for pos in grass_positions:
		var dist = pos.distance_to(player_pos)
		if dist >= min_spawn_distance and dist <= max_spawn_distance:
			candidates.append(pos)

	if candidates.size() > 0:
		return candidates[randi() % candidates.size()]

	# Fallback: any grass tile that's at least min_spawn_distance away
	var fallback: Array[Vector2] = []
	for pos in grass_positions:
		if pos.distance_to(player_pos) >= min_spawn_distance:
			fallback.append(pos)

	if fallback.size() > 0:
		return fallback[randi() % fallback.size()]

	# Last resort: totally random grass tile
	return grass_positions[randi() % grass_positions.size()]

func _wait_for_clear_then_miniboss() -> void:
	while get_tree().get_nodes_in_group("enemy").size() > 0:
		await get_tree().create_timer(0.5).timeout

	if miniboss_scene != null and not miniboss_spawned:
		_spawn_miniboss()
	else:
		level_complete.emit()

func _spawn_miniboss() -> void:
	miniboss_spawned = true
	print("Miniboss spawning!")
	var boss = miniboss_scene.instantiate()
	get_parent().add_child(boss)
	if player:
		boss.global_position = player.global_position + Vector2(150, 0)
	if boss.has_signal("boss_died"):
		boss.boss_died.connect(_on_boss_died)

func _on_boss_died() -> void:
	print("Boss dead!")
	level_complete.emit()

func _wait_for_miniboss_death(boss: Node) -> void:
	while is_instance_valid(boss):
		await get_tree().create_timer(0.5).timeout
	level_complete.emit()

