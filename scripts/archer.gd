extends PlayerBase

const ARROW = preload("res://scenes/arrow.tscn")
const FIRE_INTERVAL = 0.5

#@export var bow: Node2D
@onready var bow: Node2D = $weapon

var fire_timer = FIRE_INTERVAL

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right") or \
	   Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down"):
		fire_timer += delta
		if fire_timer >= FIRE_INTERVAL:
			fire_timer = 0.0
			fire_arrow()
	else:
		fire_timer = FIRE_INTERVAL

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
