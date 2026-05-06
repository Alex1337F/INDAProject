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
@export var wave_interval: float = 10.0
@export var total_waves: int = 5  # change per level
@export var spawn_radius: float = 200.0  # how far from center enemies spawn
@export var miniboss_scene: PackedScene = null  # assign later in inspector

var current_wave: int = 0
var miniboss_spawned: bool = false
var miniboss_dead: bool = false
var wave_timer: Timer
var player: CharacterBody2D

signal level_complete

func _ready() -> void:
	# Wait a frame so player exists
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	wave_timer = Timer.new()
	add_child(wave_timer)
	wave_timer.wait_time = wave_interval
	wave_timer.timeout.connect(_on_wave_timer)
	
	# Start first wave after short delay
	await get_tree().create_timer(2.0).timeout
	_spawn_wave()
	wave_timer.start()

func _on_wave_timer() -> void:
	if current_wave < total_waves:
		_spawn_wave()
	else:
		wave_timer.stop()
		# Wait for all regular enemies to die before spawning miniboss
		_wait_for_clear_then_miniboss()

func _spawn_wave() -> void:
	current_wave += 1
	print("Wave ", current_wave, " / ", total_waves)
	for i in range(enemies_per_wave):
		_spawn_random_enemy()
	# Connect coin drops for newly spawned enemies
	await get_tree().process_frame
	get_parent()._connect_enemy_drops()

const SPAWN_POINTS = [
	Vector2(-100, 70),
	Vector2(-150, -230),
	Vector2(200, -230),
	Vector2(320, 20),
]

func _spawn_random_enemy() -> void:
	var scene = ENEMY_SCENES[randi() % ENEMY_SCENES.size()]
	var enemy = scene.instantiate()
	get_parent().add_child(enemy)
	var spawn = SPAWN_POINTS[randi() % SPAWN_POINTS.size()]
	enemy.global_position = spawn

func _wait_for_clear_then_miniboss() -> void:
	# Poll until all enemies are gone
	while get_tree().get_nodes_in_group("enemy").size() > 0:
		await get_tree().create_timer(0.5).timeout
	
	if miniboss_scene != null and not miniboss_spawned:
		_spawn_miniboss()
	else:
		# No miniboss assigned yet, just complete level
		level_complete.emit()

func _spawn_miniboss() -> void:
	miniboss_spawned = true
	print("Miniboss spawning!")
	var boss = miniboss_scene.instantiate()
	get_parent().add_child(boss)
	if player:
		boss.global_position = player.global_position + Vector2(150, 0)
	# Wait for miniboss to die
	_wait_for_miniboss_death(boss)

func _wait_for_miniboss_death(boss: Node) -> void:
	while is_instance_valid(boss):
		await get_tree().create_timer(0.5).timeout
	print("Miniboss dead!")
	level_complete.emit()
