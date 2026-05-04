extends Control

signal upgrade_changed(levels: Dictionary)

# Cost per upgrade level (gets more expensive)
const BASE_COST := 5
const COST_MULTIPLIER := 2

# Track upgrade levels
var upgrade_levels := {
	"firerate": 0,
	"speed": 0,
	"attack": 0,
	"defence": 0,
}
const MAX_LEVEL := 5

# Node references for the clickable areas (set up in _ready)
var _buttons: Dictionary = {}
var _level_labels: Dictionary = {}

func _ready() -> void:
	# Start hidden
	visible = false
	# Must keep processing input even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("upgrades_menu")

	# Create invisible TextureButton overlays for each upgrade quadrant
	_create_button("firerate", Rect2(175, 120, 280, 200))
	_create_button("speed",    Rect2(600, 120, 280, 200))
	_create_button("attack",   Rect2(175, 340, 280, 200))
	_create_button("defence",  Rect2(600, 340, 280, 200))

	# Create level indicator labels for each upgrade
	_create_level_label("firerate", Vector2(310, 295))
	_create_level_label("speed",    Vector2(740, 295))
	_create_level_label("attack",   Vector2(310, 530))
	_create_level_label("defence",  Vector2(740, 530))

func _create_button(upgrade_name: String, rect: Rect2) -> void:
	var btn = Button.new()
	btn.flat = true
	btn.position = rect.position
	btn.size = rect.size
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.focus_mode = Control.FOCUS_NONE
	# Semi-transparent hover effect
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(1, 1, 1, 0.15)
	hover_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("hover", hover_style)
	# Transparent normal
	var empty_style = StyleBoxFlat.new()
	empty_style.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	btn.pressed.connect(_on_upgrade_pressed.bind(upgrade_name))
	add_child(btn)
	_buttons[upgrade_name] = btn

func _create_level_label(upgrade_name: String, pos: Vector2) -> void:
	var lbl = Label.new()
	lbl.position = pos
	lbl.size = Vector2(200, 40)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.3, 0.2, 0.1))
	add_child(lbl)
	_level_labels[upgrade_name] = lbl
	_update_label(upgrade_name)

func _update_label(upgrade_name: String) -> void:
	var level = upgrade_levels[upgrade_name]
	var cost = _get_cost(upgrade_name)
	var lbl: Label = _level_labels[upgrade_name]
	if level >= MAX_LEVEL:
		lbl.text = "Lv %d  MAX" % level
	else:
		lbl.text = "Lv %d  [%d coins]" % [level, cost]

func _get_cost(upgrade_name: String) -> int:
	return BASE_COST + upgrade_levels[upgrade_name] * COST_MULTIPLIER

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_upgrades"):
		_toggle_menu()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("debug_coins"):
		GameState.add_coins(10)
		get_viewport().set_input_as_handled()

func _toggle_menu() -> void:
	visible = !visible
	if visible:
		_open_menu()
	else:
		_close_menu()

func _open_menu() -> void:
	get_tree().paused = true
	# Refresh all labels
	for key in upgrade_levels:
		_update_label(key)

func _close_menu() -> void:
	get_tree().paused = false

func _on_upgrade_pressed(upgrade_name: String) -> void:
	var level = upgrade_levels[upgrade_name]
	if level >= MAX_LEVEL:
		return

	var cost = _get_cost(upgrade_name)
	if not GameState.spend_coins(cost):
		# Not enough coins — flash the label red
		var lbl: Label = _level_labels[upgrade_name]
		lbl.add_theme_color_override("font_color", Color(0.8, 0.15, 0.1))
		var tween = create_tween()
		tween.tween_property(lbl, "theme_override_colors/font_color", Color(0.3, 0.2, 0.1), 0.4)
		return

	# Apply the upgrade
	upgrade_levels[upgrade_name] += 1
	_apply_upgrade(upgrade_name)
	upgrade_changed.emit(upgrade_levels.duplicate())
	_update_label(upgrade_name)

	# Visual feedback — pulse the button area
	var btn: Button = _buttons[upgrade_name]
	var flash_style = StyleBoxFlat.new()
	flash_style.bg_color = Color(0.2, 0.9, 0.3, 0.3)
	flash_style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", flash_style)
	await get_tree().create_timer(0.25).timeout
	var empty_style = StyleBoxFlat.new()
	empty_style.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("normal", empty_style)

func _apply_upgrade(upgrade_name: String) -> void:
	# Find the player (might be paused, so search directly)
	var player: PlayerBase = null
	for node in get_tree().get_nodes_in_group("player"):
		if node is PlayerBase:
			player = node
			break

	if not player:
		return

	var level = upgrade_levels[upgrade_name]

	match upgrade_name:
		"speed":
			# +10% speed per level (compounds from base)
			player.SPEED = player.SPEED * 1.10
		"attack":
			# +10% damage per level (stored as multiplier)
			GameState.set_meta("attack_multiplier", 1.0 + level * 0.10)
		"defence":
			# -10% damage taken per level (stored as multiplier)
			GameState.set_meta("defence_multiplier", 1.0 - level * 0.10)
		"firerate":
			# +10% faster fire per level
			GameState.set_meta("firerate_bonus", level)
			if player.has_method("apply_firerate_upgrade"):
				player.apply_firerate_upgrade(level)
