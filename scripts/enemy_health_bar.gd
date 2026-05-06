extends Node2D
# Floating enemy health bar — add as child of any enemy node.
# Call update_health(current, max) whenever the enemy takes damage.

var max_health: float = 100.0
var current_health: float = 100.0
var ghost_health: float = 100.0

var bar_width: float = 24.0
var bar_height: float = 3.0
var border: float = 1.0
var y_offset: float = -16.0  # How far above the enemy

var is_visible_bar: bool = false
var hide_timer: float = 0.0
const HIDE_DELAY: float = 3.0
const FADE_SPEED: float = 4.0

var bar_alpha: float = 0.0
var ghost_tween: Tween

func _ready() -> void:
	# Start invisible — only show when damaged
	modulate.a = 0.0
	position.y = y_offset

func setup(max_hp: float, offset_y: float = -16.0) -> void:
	max_health = max_hp
	current_health = max_hp
	ghost_health = max_hp
	y_offset = offset_y
	position.y = y_offset

func update_health(current_hp: float, max_hp: float) -> void:
	max_health = max_hp
	current_health = clampf(current_hp, 0.0, max_hp)

	# Show the bar on first damage
	if not is_visible_bar:
		is_visible_bar = true

	# Reset the hide timer
	hide_timer = HIDE_DELAY

	# Animate the ghost bar (red damage trail)
	if ghost_tween:
		ghost_tween.kill()
	ghost_tween = create_tween()
	ghost_tween.tween_interval(0.3)
	ghost_tween.tween_property(self, "ghost_health", current_health, 0.5).set_ease(Tween.EASE_IN_OUT)

	queue_redraw()

func _process(delta: float) -> void:
	# Smoothly fade in/out
	if is_visible_bar and hide_timer > 0:
		bar_alpha = minf(bar_alpha + FADE_SPEED * delta, 1.0)
		hide_timer -= delta
	elif is_visible_bar and hide_timer <= 0:
		bar_alpha = maxf(bar_alpha - FADE_SPEED * delta, 0.0)
		if bar_alpha <= 0.0:
			is_visible_bar = false

	modulate.a = bar_alpha
	queue_redraw()

func _draw() -> void:
	if bar_alpha <= 0.0:
		return

	var total_w = bar_width + border * 2
	var total_h = bar_height + border * 2
	var origin = Vector2(-total_w / 2.0, -total_h / 2.0)

	# Outer border (dark)
	draw_rect(Rect2(origin, Vector2(total_w, total_h)), Color(0.0, 0.0, 0.0, 0.7))

	# Inner background
	var inner_origin = origin + Vector2(border, border)
	draw_rect(Rect2(inner_origin, Vector2(bar_width, bar_height)), Color(0.15, 0.1, 0.1, 0.85))

	# Ghost bar (damage trail — dark red)
	var ghost_pct = ghost_health / max_health if max_health > 0 else 0.0
	if ghost_pct > 0:
		draw_rect(Rect2(inner_origin, Vector2(bar_width * ghost_pct, bar_height)), Color(0.7, 0.15, 0.1, 0.8))

	# Main health bar
	var hp_pct = current_health / max_health if max_health > 0 else 0.0
	var fill_color: Color
	if hp_pct > 0.55:
		fill_color = Color(0.25, 0.85, 0.35)  # Green
	elif hp_pct > 0.25:
		fill_color = Color(1.0, 0.75, 0.15)   # Yellow/Orange
	else:
		fill_color = Color(0.9, 0.2, 0.15)    # Red

	if hp_pct > 0:
		draw_rect(Rect2(inner_origin, Vector2(bar_width * hp_pct, bar_height)), fill_color)

	# Bright highlight line on top (1px, subtle shine)
	if hp_pct > 0:
		var shine_color = Color(1.0, 1.0, 1.0, 0.25)
		draw_rect(Rect2(inner_origin, Vector2(bar_width * hp_pct, 1.0)), shine_color)
