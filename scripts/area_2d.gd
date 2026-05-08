extends Area2D

const SPEED = 600.0
const BASE_DAMAGE = 20
const EXPLOSION_RADIUS = 60.0
const EXPLOSION_DAMAGE = 30

var direction = Vector2.RIGHT
var hit_something: bool = false
var is_explosive: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func get_damage() -> int:
	return int(ceil(float(BASE_DAMAGE) * GameState.get_multiplier("attack")))

func set_direction(dir: Vector2) -> void:
	direction = dir

func set_explosive(val: bool) -> void:
	is_explosive = val

func _process(delta: float) -> void:
	position += direction * SPEED * delta
	if global_position.length() > 3000.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if hit_something:
		return
	if body.is_in_group("player"):
		return
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(get_damage(), global_position)
		if is_explosive:
			_explode(global_position)
		hit_something = true
		call_deferred("queue_free")
	else:
		if body is TileMapLayer or body is StaticBody2D:
			if is_explosive:
				_explode(global_position)
			hit_something = true
			call_deferred("queue_free")

# Static-like explosion — takes position as argument so arrow position
# is captured before it gets freed

func _explode(pos: Vector2) -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			if pos.distance_to(enemy.global_position) <= EXPLOSION_RADIUS:
				enemy.take_damage(EXPLOSION_DAMAGE, pos)
	
	var explosion = Node2D.new()
	explosion.set_script(preload("res://scripts/explosion.gd"))
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = pos
