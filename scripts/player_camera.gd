extends Camera2D

# --- Shake ---
var shake_intensity: float = 0.0
var shake_decay: float = 5.0  # How fast the shake fades

# --- Smooth zoom ---
var target_zoom: Vector2

func _ready() -> void:
	target_zoom = zoom
	# Connect to the player's damage signal
	var player = get_parent()
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	# Store the initial health to detect damage
	if player and "current_health" in player:
		_last_health = player.current_health

var _last_health: int = 100

func _process(delta: float) -> void:
	# --- Screen shake ---
	if shake_intensity > 0:
		offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_intensity = lerp(shake_intensity, 0.0, shake_decay * delta)
		if shake_intensity < 0.1:
			shake_intensity = 0.0
			offset = Vector2.ZERO

	# --- Smooth zoom transitions ---
	zoom = zoom.lerp(target_zoom, 5.0 * delta)

func shake(intensity: float = 2.0) -> void:
	shake_intensity = max(shake_intensity, intensity)

func _on_player_health_changed(current_hp: int, max_hp: int) -> void:
	if current_hp < _last_health:
		# Took damage – shake proportional to damage
		var damage = _last_health - current_hp
		var intensity = clampf(float(damage) * 0.15, 1.0, 5.0)
		shake(intensity)

		# Brief zoom punch on big hits (>20 damage)
		if damage >= 20:
			zoom = target_zoom * 1.04
	elif current_hp > _last_health:
		# Healed – subtle zoom back
		pass

	_last_health = current_hp
