extends Control

# Existing labels from the scene
@onready var firerate_label: Label = $FirerateLabel
@onready var speed_label: Label    = $SpeedLabel
@onready var attack_label: Label   = $AttackLabel
@onready var defence_label: Label  = $DefenceLabel

# Icon sprites from the scene
@onready var firerate_icon: Sprite2D = $FirerateIcon
@onready var speed_icon: Sprite2D    = $IronchestsRpgItemsPico8TransparentbgV1
@onready var attack_icon: Sprite2D   = $AttackIcon
@onready var defence_icon: Sprite2D  = $DefenceIcon

var _level_labels: Dictionary = {}   # stat → Label
var _cost_labels: Dictionary = {}    # stat → Label
var _icon_buttons: Dictionary = {}   # stat → Button
var _icons: Dictionary = {}          # stat → Sprite2D
var _icon_base_scales: Dictionary = {}  # stat → original scale

# Map stat → icon position (center), used for placing labels below icons
const LABEL_OFFSETS = {
	"firerate": Vector2(204, 280),
	"speed":    Vector2(790, 310),
	"attack":   Vector2(193, 540),
	"defence":  Vector2(760, 540),
}

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Keep original labels as just the stat name
	firerate_label.text = "Firerate"
	speed_label.text = "Speed"
	attack_label.text = "Attack"
	defence_label.text = "Defence"

	# Map stats to their icons
	_icons = {
		"firerate": firerate_icon,
		"speed":    speed_icon,
		"attack":   attack_icon,
		"defence":  defence_icon,
	}

	# Save original scales for hover animation
	for stat in _icons:
		_icon_base_scales[stat] = _icons[stat].scale

	# Create clickable overlay + labels for each stat
	for stat in _icons:
		var icon: Sprite2D = _icons[stat]
		var base_scale: Vector2 = _icon_base_scales[stat]

		# --- Invisible button over the icon ---
		var btn = Button.new()
		# Calculate icon pixel size on screen
		var tex = icon.texture
		var region_size: Vector2
		if icon.region_enabled:
			region_size = icon.region_rect.size
		else:
			region_size = tex.get_size()
		var icon_screen_size = region_size * base_scale
		btn.custom_minimum_size = icon_screen_size
		btn.size = icon_screen_size
		# Position: icon.position is center, button uses top-left
		btn.position = icon.position - icon_screen_size / 2.0
		# Make the button fully transparent
		var empty_style = StyleBoxFlat.new()
		empty_style.bg_color = Color(0, 0, 0, 0)
		empty_style.set_border_width_all(0)
		for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
			btn.add_theme_stylebox_override(style_name, empty_style)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		# Connect signals
		btn.pressed.connect(_on_upgrade_pressed.bind(stat))
		btn.mouse_entered.connect(_on_icon_hover.bind(stat, true))
		btn.mouse_exited.connect(_on_icon_hover.bind(stat, false))
		add_child(btn)
		_icon_buttons[stat] = btn

		# --- Level label below the stat name ---
		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 26)
		lbl.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
		lbl.position = LABEL_OFFSETS[stat]
		add_child(lbl)
		_level_labels[stat] = lbl

		# --- Cost label below the level ---
		var cost_lbl = Label.new()
		cost_lbl.add_theme_font_size_override("font_size", 20)
		cost_lbl.add_theme_color_override("font_color", Color(0.35, 0.25, 0.1))
		cost_lbl.position = LABEL_OFFSETS[stat] + Vector2(0, 34)
		add_child(cost_lbl)
		_cost_labels[stat] = cost_lbl

	GameState.upgrades_changed.connect(_refresh_ui)
	GameState.coins_changed.connect(func(_c): _refresh_ui())
	_refresh_ui()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_G:
			_toggle_menu()
			get_viewport().set_input_as_handled()

func _toggle_menu() -> void:
	visible = !visible
	get_tree().paused = visible

func _on_icon_hover(stat: String, hovering: bool) -> void:
	var icon = _icons[stat]
	var base = _icon_base_scales[stat]
	var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if hovering:
		tw.tween_property(icon, "scale", base * 1.15, 0.12)
	else:
		tw.tween_property(icon, "scale", base, 0.12)

func _on_upgrade_pressed(stat: String) -> void:
	if GameState.try_upgrade(stat):
		# Punch animation on the icon
		var icon = _icons[stat]
		var base = _icon_base_scales[stat]
		var tw = create_tween()
		tw.tween_property(icon, "scale", base * 1.3, 0.06)
		tw.tween_property(icon, "scale", base, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_refresh_ui()

func _refresh_ui() -> void:
	for stat in _icons:
		var level = GameState.upgrade_levels[stat]
		var pct = level * 10

		# Level text
		var lbl = _level_labels[stat]
		if stat == "defence":
			lbl.text = "Lv %d  (-%d%%)" % [level, pct]
		else:
			lbl.text = "Lv %d  (+%d%%)" % [level, pct]

		# Cost text
		var cost_lbl = _cost_labels[stat]
		if level >= GameState.MAX_UPGRADE_LEVEL:
			cost_lbl.text = "MAXED"
			cost_lbl.add_theme_color_override("font_color", Color(0.6, 0.45, 0.1))
		else:
			var cost = GameState.get_upgrade_cost(stat)
			if GameState.coins >= cost:
				cost_lbl.text = "Cost: %d ●" % cost
				cost_lbl.add_theme_color_override("font_color", Color(0.15, 0.4, 0.1))
			else:
				cost_lbl.text = "Cost: %d ●" % cost
				cost_lbl.add_theme_color_override("font_color", Color(0.5, 0.2, 0.1))

		# Dim the icon if can't afford or maxed
		var icon = _icons[stat]
		if level >= GameState.MAX_UPGRADE_LEVEL:
			icon.modulate = Color(1.0, 0.9, 0.4)  # Golden tint for maxed
		elif GameState.coins < GameState.get_upgrade_cost(stat):
			icon.modulate = Color(0.5, 0.5, 0.5)  # Grey out if too expensive
		else:
			icon.modulate = Color.WHITE  # Normal
