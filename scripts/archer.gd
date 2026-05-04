extends PlayerBase

const ARROW = preload("res://scenes/arrow.tscn")
const BASE_FIRE_INTERVAL = 0.5

@onready var bow: Node2D = $weapon
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var fire_interval: float = BASE_FIRE_INTERVAL
var fire_timer: float = BASE_FIRE_INTERVAL

func _ready() -> void:
	register_sprite(animated_sprite_2d)
	super._ready()

func _process(delta: float) -> void:
	if Input.is_action_pressed("aim-left") or Input.is_action_pressed("aim-right") or \
	   Input.is_action_pressed("aim-up")   or Input.is_action_pressed("aim-down"):
		fire_timer += delta
		if fire_timer >= fire_interval:
			fire_timer = 0.0
			fire_arrow()
	else:
		fire_timer = fire_interval

func fire_arrow() -> void:
	var arrow = ARROW.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = bow.global_position
	arrow.rotation = bow.aim_direction.angle()
	arrow.scale.x = 1.0
	# Apply attack multiplier to arrow damage
	var atk_mult: float = GameState.get_meta("attack_multiplier", 1.0) if GameState.has_meta("attack_multiplier") else 1.0
	if "DAMAGE" in arrow:
		arrow.DAMAGE = roundi(arrow.DAMAGE * atk_mult)
	if arrow.has_method("set_direction"):
		arrow.set_direction(bow.aim_direction)
	elif "direction" in arrow:
		arrow.direction = bow.aim_direction

func apply_firerate_upgrade(level: int) -> void:
	# Each level reduces fire interval by 10%
	fire_interval = BASE_FIRE_INTERVAL * pow(0.90, level)

