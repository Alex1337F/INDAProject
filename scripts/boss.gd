extends CharacterBody2D

const MAX_HEALTH = 2500
const PHASE_THRESHOLDS = [0.75, 0.5, 0.25]
var p1_timer: float = 0.0
var p2_timer: float = 0.0
var p3_timer: float = 0.0
const SHOOT_INTERVAL_P1 = 0.5
const SHOOT_INTERVAL_P2 = 1.0
const SPAWN_INTERVAL_P3 = 3.0
const SPAWN_INTERVAL_P4 = 3.0
const MOVE_SPEED = 35.0

const BOSS_PROJECTILE = preload("res://scenes/boss_projectile.tscn")
const ENEMY_SCENES = [
	preload("res://scenes/YellowBatEnemy.tscn"),
	preload("res://scenes/eyeEnemy.tscn"),
	preload("res://scenes/skeletonEnemy.tscn"),
	preload("res://scenes/bambooEnemy.tscn"),
	preload("res://scenes/enemy.tscn"),
]

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var current_health: int = MAX_HEALTH
var current_phase: int = 1
var player: CharacterBody2D
var boss_hud: CanvasLayer
var boss_bar: ProgressBar
var boss_name_label: Label
var phase_label: Label
var _boss_grass_positions: Array[Vector2] = []

signal boss_died

func _ready() -> void:
	add_to_group("enemy")
	current_health = MAX_HEALTH
	player = get_tree().get_first_node_in_group("player")
	_cache_boss_grass()
	call_deferred("_create_boss_hud")

func _cache_boss_grass() -> void:
	var grass_layer = get_tree().current_scene.get_node_or_null("GrassLayer")
	if grass_layer == null:
		return

	var used_set: Dictionary = {}
	for cell in grass_layer.get_used_cells():
		used_set[cell] = true

	for cell in grass_layer.get_used_cells():
		var is_interior = true
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not used_set.has(cell + offset):
				is_interior = false
				break
		if is_interior:
			_boss_grass_positions.append(grass_layer.to_global(grass_layer.map_to_local(cell)))

func _create_boss_hud() -> void:
	boss_hud = CanvasLayer.new()
	get_tree().current_scene.add_child(boss_hud)

	var container = Control.new()
	container.name = "BossHUDContainer"
	container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	container.offset_bottom = 80
	boss_hud.add_child(container)

	var panel = ColorRect.new()
	panel.color = Color(0.0, 0.0, 0.0, 0.7)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 80
	panel.offset_right = -80
	container.add_child(panel)

	boss_name_label = Label.new()
	boss_name_label.text = "DAIDALOS"
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_name_label.offset_top = 8
	boss_name_label.offset_bottom = 28
	boss_name_label.offset_left = 80
	boss_name_label.offset_right = -80
	boss_name_label.add_theme_font_size_override("font_size", 14)
	boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	container.add_child(boss_name_label)

	boss_bar = ProgressBar.new()
	boss_bar.max_value = MAX_HEALTH
	boss_bar.value = MAX_HEALTH
	boss_bar.show_percentage = false
	boss_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_bar.offset_top = 30
	boss_bar.offset_bottom = 54
	boss_bar.offset_left = 90
	boss_bar.offset_right = -90
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.05, 0.05)
	bg_style.corner_radius_top_left = 6
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6
	boss_bar.add_theme_stylebox_override("background", bg_style)
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.9, 0.15, 0.15)
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_left = 6
	fill_style.corner_radius_bottom_right = 6
	boss_bar.add_theme_stylebox_override("fill", fill_style)
	container.add_child(boss_bar)

	phase_label = Label.new()
	phase_label.text = "Phase 1"
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	phase_label.offset_top = 56
	phase_label.offset_bottom = 70
	phase_label.offset_left = 80
	phase_label.offset_right = -80
	phase_label.add_theme_font_size_override("font_size", 11)
	phase_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	container.add_child(phase_label)

	container.position.y = -80
	var tween = create_tween()
	tween.tween_property(container, "position:y", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _update_boss_bar() -> void:
	if not boss_bar:
		return
	var tween = create_tween()
	tween.tween_property(boss_bar, "value", float(current_health), 0.2).set_ease(Tween.EASE_OUT)
	var fill_style = StyleBoxFlat.new()
	fill_style.corner_radius_top_left = 6
	fill_style.corner_radius_top_right = 6
	fill_style.corner_radius_bottom_left = 6
	fill_style.corner_radius_bottom_right = 6
	match current_phase:
		1: fill_style.bg_color = Color(0.046, 0.599, 0.185, 1.0)
		2: fill_style.bg_color = Color(0.9, 0.5, 0.1)
		3: fill_style.bg_color = Color(0.876, 0.1, 0.214, 1.0)
		4: fill_style.bg_color = Color(0.293, 0.037, 0.414, 1.0)
	boss_bar.add_theme_stylebox_override("fill", fill_style)

func take_damage(amount: int, knockback_origin: Vector2) -> void:
	current_health -= amount
	current_health = max(current_health, 0)
	anim.modulate = Color(1.0, 0.2, 0.2, 1.0)
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.WHITE, 0.2)
	_update_boss_bar()
	_check_phase()
	if current_health <= 0:
		_die()

func _check_phase() -> void:
	var hp_ratio = float(current_health) / float(MAX_HEALTH)
	var new_phase = 1
	if hp_ratio <= 0.25:
		new_phase = 4
	elif hp_ratio <= 0.5:
		new_phase = 3
	elif hp_ratio <= 0.75:
		new_phase = 2
	if new_phase != current_phase:
		current_phase = new_phase
		print("Boss entered phase ", current_phase)
		_on_phase_changed()

func _on_phase_changed() -> void:
	if phase_label:
		phase_label.text = "Phase " + str(current_phase)
		phase_label.modulate = Color(1.0, 0.85, 0.3)
		var tween = create_tween()
		tween.tween_property(phase_label, "modulate", Color.WHITE, 0.6)
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color(2.0, 2.0, 0.2), 0.1)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.4)

func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	# Phase timers
	match current_phase:
		1:
			p1_timer -= delta
			if p1_timer <= 0:
				p1_timer = SHOOT_INTERVAL_P1
				_phase1_shoot()
		2:
			p2_timer -= delta
			if p2_timer <= 0:
				p2_timer = SHOOT_INTERVAL_P2
				_phase2_circle_shoot()
		3:
			p3_timer -= delta
			if p3_timer <= 0:
				p3_timer = SPAWN_INTERVAL_P3
				_phase3_spawn_enemies()
		4:
			p1_timer -= delta
			p2_timer -= delta
			p3_timer -= delta
			if p1_timer <= 0:
				p1_timer = SHOOT_INTERVAL_P1
				_phase1_shoot()
			if p2_timer <= 0:
				p2_timer = SHOOT_INTERVAL_P2
				_phase2_circle_shoot()
			if p3_timer <= 0:
				p3_timer = SPAWN_INTERVAL_P3
				_phase3_spawn_enemies()
				_phase4_spawn_all()

	# Movement toward player — inside _physics_process, after match
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * MOVE_SPEED
	move_and_slide()

func _phase1_shoot() -> void:
	if player == null:
		return
	var dir = (player.global_position - global_position).normalized()
	_spawn_projectile(dir)

func _phase2_circle_shoot() -> void:
	for i in range(8):
		var angle = deg_to_rad(i * 45.0)
		var dir = Vector2(cos(angle), sin(angle))
		_spawn_projectile(dir)

func _phase3_spawn_enemies() -> void:
	for i in range(3):
		var scene = ENEMY_SCENES[randi() % ENEMY_SCENES.size()]
		_spawn_enemy(scene)

func _phase4_spawn_all() -> void:
	for i in range(5):
		var scene = ENEMY_SCENES[randi() % ENEMY_SCENES.size()]
		_spawn_enemy(scene)

func _spawn_projectile(dir: Vector2) -> void:
	var proj = BOSS_PROJECTILE.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.direction = dir

func _spawn_enemy(scene: PackedScene) -> void:
	var enemy = scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = _pick_nearby_grass()
	var game = get_tree().current_scene
	if game.has_method("_connect_single_enemy"):
		game._connect_single_enemy(enemy)

func _pick_nearby_grass() -> Vector2:
	if _boss_grass_positions.is_empty():
		# Fallback: random offset around boss
		var angle = randf() * TAU
		return global_position + Vector2(cos(angle), sin(angle)) * 80.0

	# Find grass tiles near the boss (within 200px)
	var nearby: Array[Vector2] = []
	for pos in _boss_grass_positions:
		if pos.distance_to(global_position) <= 200.0:
			nearby.append(pos)

	if nearby.size() > 0:
		return nearby[randi() % nearby.size()]

	# Fallback: any grass tile
	return _boss_grass_positions[randi() % _boss_grass_positions.size()]

func _die() -> void:
	# Kill all remaining enemies first
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and enemy != self:
			enemy.queue_free()

	if boss_hud:
		var container = boss_hud.get_node_or_null("BossHUDContainer")
		if container:
			var tween = create_tween()
			tween.tween_property(container, "position:y", -80.0, 0.4).set_ease(Tween.EASE_IN)
			await tween.finished
		boss_hud.queue_free()

	boss_died.emit()
	_show_victory_screen()
	queue_free()

func _show_victory_screen() -> void:
	var screen = preload("res://scenes/VictoryScreen.tscn").instantiate()
	get_tree().current_scene.add_child(screen)
