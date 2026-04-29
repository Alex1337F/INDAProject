extends Camera2D

var shake_intensity: float = 0.0
var shake_decay: float = 5.0
var target_zoom: Vector2
var target: Node2D = null
var _last_health: int = 100

func _ready() -> void:
	target_zoom = zoom
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
		if target.has_signal("health_changed"):
			target.health_changed.connect(_on_player_health_changed)
		if "current_health" in target:
			_last_health = target.current_health

func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		global_position = target.global_position
	if shake_intensity > 0:
		offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = lerp(shake_intensity, 0.0, shake_decay * delta)
		if shake_intensity < 0.1:
			shake_intensity = 0.0
			offset = Vector2.ZERO
	zoom = zoom.lerp(target_zoom, 5.0 * delta)

func shake(intensity: float = 2.0) -> void:
	shake_intensity = max(shake_intensity, intensity)

func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	if current_hp < _last_health:
		var damage = _last_health - current_hp
		var intensity = clampf(float(damage) * 0.15, 1.0, 5.0)
		shake(intensity)
		if damage >= 20:
			zoom = target_zoom * 1.04
	_last_health = current_hp
