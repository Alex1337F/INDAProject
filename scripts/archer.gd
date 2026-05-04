extends PlayerBase

const ARROW = preload("res://scenes/arrow.tscn")
const BASE_FIRE_INTERVAL: float = 0.5

@onready var bow: Node2D = $weapon
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var fire_timer: float = BASE_FIRE_INTERVAL

func _ready() -> void:
	register_sprite(animated_sprite_2d)
	super._ready()

func get_fire_interval() -> float:
	# Higher firerate multiplier = faster firing = shorter interval
	return BASE_FIRE_INTERVAL / GameState.get_multiplier("firerate")

func _process(delta: float) -> void:
	if Input.is_action_pressed("aim-left") or Input.is_action_pressed("aim-right") or \
	   Input.is_action_pressed("aim-up")   or Input.is_action_pressed("aim-down"):
		fire_timer += delta
		if fire_timer >= get_fire_interval():
			fire_timer = 0.0
			fire_arrow()
	else:
		fire_timer = get_fire_interval()

func fire_arrow() -> void:
	var arrow = ARROW.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = bow.global_position
	arrow.rotation = bow.aim_direction.angle()
	arrow.scale.x = 1.0
	if arrow.has_method("set_direction"):
		arrow.set_direction(bow.aim_direction)
	elif "direction" in arrow:
		arrow.direction = bow.aim_direction
