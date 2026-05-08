extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBarContainer/BarArea/HealthBar
@onready var damage_bar: ProgressBar = $HealthBarContainer/BarArea/DamageBar
@onready var health_label: Label = $HealthBarContainer/BarArea/HealthLabel
@onready var heart_icon: TextureRect = $HealthBarContainer/HeartIcon
@onready var bar_container: Control = $HealthBarContainer

# Coin HUD
@onready var coin_label: Label = $CoinContainer/Panel/HBox/CoinLabel
@onready var coin_icon: Sprite2D = $CoinContainer/Panel/HBox/CoinIcon

# Wave HUD
@onready var wave_counter: Label = $WaveCounter

# Radar HUD
@onready var enemy_radar: Sprite2D = $EnemyRadar

var previous_health: int = 100
var shake_intensity: float = 0.0
var original_bar_pos: Vector2
var heart_pulse_tween: Tween
var is_low_health: bool = false

# Wave announcement label (created in code so it's centered + fancy)
var wave_announce_label: Label

# --- Upgrade stat display ---
var stat_container: HBoxContainer

func _ready() -> void:
	original_bar_pos = bar_container.position

	# --- Coin counter ---
	GameState.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(GameState.coins)

	# --- Build upgrade stats strip ---
	_build_stat_strip()
	GameState.upgrades_changed.connect(_refresh_stats)
	_refresh_stats()

	# --- Wave counter initial state ---
	wave_counter.text = ""

	# --- Create the big centered wave announcement label ---
	_create_wave_announcement_label()

	# Wait one frame so game.gd has time to spawn the player
	await get_tree().process_frame
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

	# Connect to the wave manager
	await get_tree().process_frame
	var wave_mgr = get_tree().get_first_node_in_group("wave_manager")
	if wave_mgr == null:
		# Try finding it as a sibling (child of game node)
		var parent = get_parent()
		for child in parent.get_children():
			if child.has_signal("wave_started"):
				wave_mgr = child
				break
	if wave_mgr:
		if wave_mgr.has_signal("wave_started"):
			wave_mgr.wave_started.connect(_on_wave_started)

func _create_wave_announcement_label() -> void:
	wave_announce_label = Label.new()
	wave_announce_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_announce_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_announce_label.anchors_preset = Control.PRESET_CENTER
	wave_announce_label.set_anchors_preset(Control.PRESET_CENTER)
	wave_announce_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	wave_announce_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	wave_announce_label.offset_left = -400
	wave_announce_label.offset_right = 400
	wave_announce_label.offset_top = -100
	wave_announce_label.offset_bottom = 100
	wave_announce_label.add_theme_font_size_override("font_size", 64)
	wave_announce_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
	wave_announce_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	wave_announce_label.add_theme_constant_override("shadow_offset_x", 3)
	wave_announce_label.add_theme_constant_override("shadow_offset_y", 3)
	wave_announce_label.modulate.a = 0.0
	wave_announce_label.text = ""
	add_child(wave_announce_label)

func _on_wave_started(wave_number: int, total: int) -> void:
	# Update the persistent wave counter in the corner
	wave_counter.text = "Wave: " + str(wave_number) + " / " + str(total)

	# Punch animation on the wave counter
	var counter_tween = create_tween()
	wave_counter.scale = Vector2(1.3, 1.3)
	wave_counter.modulate = Color(1.0, 0.85, 0.3)
	counter_tween.tween_property(wave_counter, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	counter_tween.parallel().tween_property(wave_counter, "modulate", Color.WHITE, 0.5)

	# Big centered announcement
	_play_wave_announcement(wave_number, total)

func _play_wave_announcement(wave_number: int, total: int) -> void:
	wave_announce_label.text = "⚔  WAVE " + str(wave_number) + "  ⚔"

	# Reset state
	wave_announce_label.modulate = Color(1.0, 0.9, 0.5, 0.0)
	wave_announce_label.scale = Vector2(0.3, 0.3)
	wave_announce_label.pivot_offset = wave_announce_label.size / 2.0

	var tween = create_tween()

	# Phase 1: Slam in (scale up + fade in)
	tween.tween_property(wave_announce_label, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(wave_announce_label, "scale", Vector2(1.1, 1.1), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Phase 2: Settle to normal scale
	tween.tween_property(wave_announce_label, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN_OUT)

	# Phase 3: Hold for a moment
	tween.tween_interval(1.2)

	# Phase 4: Slide up + fade out
	tween.tween_property(wave_announce_label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(wave_announce_label, "position:y", wave_announce_label.position.y - 40, 0.5).set_ease(Tween.EASE_IN)

	# Phase 5: Reset position for next wave
	await tween.finished
	wave_announce_label.position.y += 40

# ====== Everything below is unchanged ======

func _build_stat_strip() -> void:
	stat_container = HBoxContainer.new()
	stat_container.anchors_preset = Control.PRESET_BOTTOM_LEFT
	stat_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stat_container.position = Vector2(12, -48)
	stat_container.add_theme_constant_override("separation", 16)
	add_child(stat_container)

	_add_stat_icon("⚔", "attack",   Color(1.0, 0.35, 0.25))
	_add_stat_icon("🛡", "defence",  Color(0.3, 0.6, 1.0))
	_add_stat_icon("⚡", "speed",    Color(1.0, 0.85, 0.2))
	_add_stat_icon("🏹", "firerate", Color(0.5, 1.0, 0.5))

func _add_stat_icon(icon_text: String, stat: String, color: Color) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 2)

	var icon = Label.new()
	icon.text = icon_text
	icon.add_theme_font_size_override("font_size", 18)
	icon.add_theme_color_override("font_color", color)
	hbox.add_child(icon)

	var lbl = Label.new()
	lbl.name = "Stat_" + stat
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	hbox.add_child(lbl)

	stat_container.add_child(hbox)

func _refresh_stats() -> void:
	if not stat_container:
		return
	for stat in ["attack", "defence", "speed", "firerate"]:
		var lbl = stat_container.find_child("Stat_" + stat, true, false)
		if lbl:
			var level = GameState.upgrade_levels[stat]
			var pct = level * 10
			if stat == "defence":
				lbl.text = "Lv%d -%d%%" % [level, pct]
			else:
				lbl.text = "Lv%d +%d%%" % [level, pct]

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

	_update_enemy_radar()

func _update_enemy_radar() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		enemy_radar.visible = false
		return

	var target_pos = Vector2.ZERO
	var is_portal = false
	
	var portals = get_tree().get_nodes_in_group("portal")
	var active_portal = null
	for p in portals:
		if p.portal_open:
			active_portal = p
			break
			
	if active_portal:
		target_pos = active_portal.global_position
		is_portal = true
	else:
		var enemies = get_tree().get_nodes_in_group("enemy")
		if enemies.is_empty():
			enemy_radar.visible = false
			return

		var closest_enemy = null
		var min_dist = INF
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_enemy = enemy

		if not closest_enemy:
			enemy_radar.visible = false
			return
		target_pos = closest_enemy.global_position

	var cam = get_viewport().get_camera_2d()
	if not cam:
		enemy_radar.visible = false
		return

	# Check if target is on screen
	var screen_rect = get_viewport().get_visible_rect()
	# The camera position is at the center of the screen
	var cam_pos = cam.get_screen_center_position()
	var half_size = screen_rect.size / 2.0 / cam.zoom
	var view_rect = Rect2(cam_pos - half_size, half_size * 2.0)

	# If the target is on screen, hide the radar
	if view_rect.has_point(target_pos):
		enemy_radar.visible = false
		return

	# Target is offscreen - show and point radar
	enemy_radar.visible = true
	
	if is_portal:
		enemy_radar.texture = preload("res://assets/sprites/Ui/Arrow.png")
	else:
		enemy_radar.texture = preload("res://assets/sprites/Ui/Skull.png")

	var dir_to_target = player.global_position.direction_to(target_pos)
	
	# The bottom of the sprite corresponds to the DOWN direction (PI/2).
	# So we subtract PI/2 from the direction angle so that the bottom points at the target.
	enemy_radar.rotation = dir_to_target.angle() - PI/2

	# Calculate screen position for the arrow (clamp to screen edges with margin)
	var margin = 60.0
	var center = screen_rect.size / 2.0

	# Find intersection with screen bounds
	# We treat the center of the screen as (0,0) for this math
	var x_bound = center.x - margin
	var y_bound = center.y - margin

	var t_x = INF
	if abs(dir_to_target.x) > 0.001:
		t_x = x_bound / abs(dir_to_target.x)

	var t_y = INF
	if abs(dir_to_target.y) > 0.001:
		t_y = y_bound / abs(dir_to_target.y)

	var t = min(t_x, t_y)

	var offset = dir_to_target * t
	enemy_radar.position = center + offset

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
		var heart_base_scale = Vector2(0.675, 0.675)
		heart_icon.scale = heart_base_scale
		heart_tween.tween_property(heart_icon, "scale", heart_base_scale * 1.6, 0.08)
		heart_tween.tween_property(heart_icon, "scale", heart_base_scale * 0.85, 0.1)
		heart_tween.tween_property(heart_icon, "scale", heart_base_scale, 0.15)
	else:
		# Healing / respawn – damage bar catches up immediately
		damage_bar.value = current_hp
		# Reset heart icon (in case we respawned after death)
		heart_icon.modulate = Color.WHITE

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
	var base_scale = Vector2(2.285, 2.285) # Base scale from editor
	coin_icon.scale = base_scale
	pop.tween_property(coin_icon, "scale", base_scale * 1.5, 0.1).set_ease(Tween.EASE_OUT)
	pop.tween_property(coin_icon, "scale", base_scale, 0.15).set_ease(Tween.EASE_IN)
	# Brief golden flash on the label
	coin_label.modulate = Color(1.0, 1.0, 0.4)
	var flash = create_tween()
	flash.tween_property(coin_label, "modulate", Color.WHITE, 0.3)
