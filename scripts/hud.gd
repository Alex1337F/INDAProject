extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBarContainer/BarArea/HealthBar
@onready var damage_bar: ProgressBar = $HealthBarContainer/BarArea/DamageBar
@onready var health_label: Label = $HealthBarContainer/BarArea/HealthLabel
@onready var heart_icon: Label = $HealthBarContainer/HeartIcon
@onready var bar_container: Control = $HealthBarContainer

# Coin HUD
@onready var coin_label: Label = $CoinContainer/Panel/HBox/CoinLabel
@onready var coin_icon: Label = $CoinContainer/Panel/HBox/CoinIcon

# Upgrade HUD
var _upgrade_labels: Dictionary = {}
const UPGRADE_ICONS := {
	"attack": "⚔",
	"defence": "🛡",
	"speed": "🏃",
	"firerate": "🏹",
}

var previous_health: int = 100
var shake_intensity: float = 0.0
var original_bar_pos: Vector2
var heart_pulse_tween: Tween
var is_low_health: bool = false

func _ready() -> void:
	original_bar_pos = bar_container.position

	# --- Coin counter ---
	GameState.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(GameState.coins)

	# --- Upgrade level display ---
	_create_upgrade_display()

	# Wait one frame so game.gd has time to spawn the player
	await get_tree().process_frame

	# Connect to upgrades node
	_connect_upgrade_signal()

	# Find the player node (dynamically spawned) via group
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
		# Initialize
		previous_health = player.current_health
		damage_bar.max_value = player.MAX_HEALTH
		damage_bar.value = player.current_health
		_on_health_changed(player.current_health, player.MAX_HEALTH)

func _process(delta: float) -> void:
	# Shake decay
	if shake_intensity > 0:
		shake_intensity = lerp(shake_intensity, 0.0, 8.0 * delta)
		bar_container.position = original_bar_pos + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		if shake_intensity < 0.3:
			shake_intensity = 0.0
			bar_container.position = original_bar_pos

func _on_health_changed(current_hp: int, max_hp: int) -> void:
	var took_damage = current_hp < previous_health

	# --- Smooth health bar tween ---
	health_bar.max_value = max_hp
	damage_bar.max_value = max_hp

	var bar_tween = create_tween()
	bar_tween.tween_property(health_bar, "value", float(current_hp), 0.15).set_ease(Tween.EASE_OUT)

	# --- Damage ghost bar (trails behind) ---
	if took_damage:
		# Delay, then smoothly catch up
		var dmg_tween = create_tween()
		dmg_tween.tween_interval(0.4)
		dmg_tween.tween_property(damage_bar, "value", float(current_hp), 0.6).set_ease(Tween.EASE_IN_OUT)

		# --- Shake ---
		var damage_amount = previous_health - current_hp
		shake_intensity = clampf(float(damage_amount) * 0.5, 3.0, 12.0)

		# --- Flash the label red briefly ---
		health_label.modulate = Color(1.0, 0.3, 0.3)
		var label_tween = create_tween()
		label_tween.tween_property(health_label, "modulate", Color.WHITE, 0.4)

		# --- Heart icon bounce ---
		var heart_tween = create_tween()
		heart_icon.scale = Vector2(1.0, 1.0)
		heart_tween.tween_property(heart_icon, "scale", Vector2(1.6, 1.6), 0.08)
		heart_tween.tween_property(heart_icon, "scale", Vector2(0.85, 0.85), 0.1)
		heart_tween.tween_property(heart_icon, "scale", Vector2(1.0, 1.0), 0.15)
	else:
		# Healing / respawn – damage bar catches up immediately
		damage_bar.value = current_hp
		# Reset heart icon (in case we respawned after death)
		heart_icon.modulate = Color(0.95, 0.25, 0.25, 1.0)

	# --- Update label ---
	health_label.text = str(current_hp) + " / " + str(max_hp)

	# --- Color the fill bar based on health ---
	var percent = float(current_hp) / float(max_hp)
	var fill_style = health_bar.get_theme_stylebox("fill").duplicate()
	if percent > 0.5:
		fill_style.bg_color = Color(0.2, 0.9, 0.3)    # Green
	elif percent > 0.25:
		fill_style.bg_color = Color(1.0, 0.75, 0.1)   # Yellow/Orange
	else:
		fill_style.bg_color = Color(0.9, 0.15, 0.15)  # Red
	health_bar.add_theme_stylebox_override("fill", fill_style)

	# --- Low health pulsing heart ---
	if percent <= 0.25 and not is_low_health:
		is_low_health = true
		_start_heart_pulse()
	elif percent > 0.25 and is_low_health:
		is_low_health = false
		_stop_heart_pulse()

	previous_health = current_hp

func _start_heart_pulse() -> void:
	if heart_pulse_tween:
		heart_pulse_tween.kill()
	heart_pulse_tween = create_tween().set_loops()
	heart_pulse_tween.tween_property(heart_icon, "modulate:a", 0.4, 0.4).set_ease(Tween.EASE_IN_OUT)
	heart_pulse_tween.tween_property(heart_icon, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_IN_OUT)

func _stop_heart_pulse() -> void:
	if heart_pulse_tween:
		heart_pulse_tween.kill()
		heart_pulse_tween = null
	heart_icon.modulate.a = 1.0

func _on_player_died() -> void:
	health_label.text = "DEAD"
	_stop_heart_pulse()
	# Heart shatters
	var death_tween = create_tween()
	death_tween.tween_property(heart_icon, "modulate", Color(0.5, 0.5, 0.5, 0.4), 0.5)

func _on_coins_changed(total: int) -> void:
	coin_label.text = str(total)
	# Pop animation on the icon
	var pop = create_tween()
	coin_icon.scale = Vector2(1.0, 1.0)
	pop.tween_property(coin_icon, "scale", Vector2(1.5, 1.5), 0.1).set_ease(Tween.EASE_OUT)
	pop.tween_property(coin_icon, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN)
	# Brief golden flash on the label
	coin_label.modulate = Color(1.0, 1.0, 0.4)
	var flash = create_tween()
	flash.tween_property(coin_label, "modulate", Color.WHITE, 0.3)

# ── Upgrade Level Display ───────────────────────────────

func _create_upgrade_display() -> void:
	# Container panel — positioned below the health bar
	var panel = Panel.new()
	panel.name = "UpgradePanel"
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.08, 0.85)
	panel_style.border_color = Color(0.4, 0.35, 0.2, 0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.position = Vector2(12, 42)
	panel.size = Vector2(220, 28)
	add_child(panel)

	# HBoxContainer for the upgrade entries
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 6
	hbox.offset_right = -6
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(hbox)

	# Create each upgrade indicator: icon + level number
	for key in ["attack", "defence", "speed", "firerate"]:
		var entry = HBoxContainer.new()
		entry.add_theme_constant_override("separation", 1)

		var icon_lbl = Label.new()
		icon_lbl.text = UPGRADE_ICONS[key]
		icon_lbl.add_theme_font_size_override("font_size", 14)
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		entry.add_child(icon_lbl)

		var lvl_lbl = Label.new()
		lvl_lbl.text = "0"
		lvl_lbl.add_theme_font_size_override("font_size", 12)
		lvl_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
		lvl_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		entry.add_child(lvl_lbl)

		hbox.add_child(entry)
		_upgrade_labels[key] = lvl_lbl

func _connect_upgrade_signal() -> void:
	# Find the Upgrades node in the scene tree
	var upgrades_node = get_tree().get_first_node_in_group("upgrades_menu")
	if upgrades_node and upgrades_node.has_signal("upgrade_changed"):
		upgrades_node.upgrade_changed.connect(_on_upgrade_changed)
		return
	# Fallback: search all children of current scene
	for child in get_tree().current_scene.get_children():
		if child.has_signal("upgrade_changed"):
			child.upgrade_changed.connect(_on_upgrade_changed)
			return
	# Try finding via the HUD's siblings (if Upgrades is inside HUD CanvasLayer)
	if get_parent():
		for sibling in get_parent().get_children():
			if sibling.has_signal("upgrade_changed"):
				sibling.upgrade_changed.connect(_on_upgrade_changed)
				return

func _on_upgrade_changed(levels: Dictionary) -> void:
	for key in levels:
		if key in _upgrade_labels:
			var lbl: Label = _upgrade_labels[key]
			var old_text = lbl.text
			lbl.text = str(levels[key])
			# Pop animation if level actually changed
			if lbl.text != old_text:
				lbl.modulate = Color(0.3, 1.0, 0.4)
				var tween = create_tween()
				tween.tween_property(lbl, "modulate", Color.WHITE, 0.4)
