extends Area2D

## Value of this coin when picked up.
@export var value: int = 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var bob_time: float = 0.0
var is_picked_up: bool = false

func _ready() -> void:
	# Play the spinning animation immediately
	anim.play("default")
	# Randomise bob offset so coins placed together don't bob in sync
	bob_time = randf() * TAU
	# Connect the pickup detection
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_picked_up:
		return
	# Gentle floating bob
	bob_time += delta * 3.0
	anim.position.y = sin(bob_time) * 1.5

func _on_body_entered(body: Node) -> void:
	if is_picked_up:
		return
	if body is PlayerBase:
		_collect()

func _collect() -> void:
	is_picked_up = true
	GameState.add_coins(value)
	# Pick-up animation: scale up + fade out
	var tween = create_tween().set_parallel(true)
	tween.tween_property(anim, "scale", Vector2(1.8, 1.8), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(anim, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(anim, "position:y", anim.position.y - 10.0, 0.2).set_ease(Tween.EASE_OUT)
	await tween.finished
	queue_free()

## Convenience: spawn a coin at a world position.
## Call from anywhere:  Coin.spawn(global_position, get_tree().current_scene)
static func spawn(pos: Vector2, parent: Node, coin_value: int = 1) -> void:
	var scene = preload("res://scenes/coin.tscn")
	var coin = scene.instantiate()
	coin.value = coin_value
	parent.add_child(coin)
	coin.global_position = pos
