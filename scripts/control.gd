extends Control

const BORDER_COLOR := Color(0.6, 0.5, 0.35, 0.6)

@onready var archer_card = $Layout/CardsCenter/CardsHBox/ArcherCard
@onready var warrior_card = $Layout/CardsCenter/CardsHBox/WarriorCard
@onready var archer_sprite = $Layout/CardsCenter/CardsHBox/ArcherCard/VBox/SpriteCenter/ArcherSprite
@onready var warrior_sprite = $Layout/CardsCenter/CardsHBox/WarriorCard/VBox/SpriteCenter/WarriorSprite
@onready var overlay = $TransitionOverlay

var picked := false
var bob_time := 0.0

func _ready() -> void:
	# Gentle idle bob on both icons (offset so they don't move in sync)
	_start_bob(archer_sprite, 0.0)
	_start_bob(warrior_sprite, 1.5)

func _start_bob(sprite: Control, delay: float) -> void:
	var base_y = sprite.position.y
	var tw = create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "position:y", base_y - 4.0, 1.2).set_delay(delay)
	tw.tween_property(sprite, "position:y", base_y, 1.2)

# ── Hover: smoothly fade border in/out ──────────────────────────
func _on_archer_card_mouse_entered() -> void:
	_hover(archer_card, true)
func _on_archer_card_mouse_exited() -> void:
	_hover(archer_card, false)
func _on_warrior_card_mouse_entered() -> void:
	_hover(warrior_card, true)
func _on_warrior_card_mouse_exited() -> void:
	_hover(warrior_card, false)

func _hover(card: Panel, entered: bool) -> void:
	if picked:
		return
	var s: StyleBoxFlat = card.get_theme_stylebox("panel")
	var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if entered:
		tw.tween_method(func(a): s.border_color.a = a; s.bg_color.a = a * 0.6, s.border_color.a, 0.6, 0.2)
	else:
		tw.tween_method(func(a): s.border_color.a = a; s.bg_color.a = a * 0.6, s.border_color.a, 0.0, 0.25)

# ── Click ────────────────────────────────────────────────────────
func _on_archer_card_gui_input(event: InputEvent) -> void:
	_try_pick(event, "archer")
func _on_warrior_card_gui_input(event: InputEvent) -> void:
	_try_pick(event, "warrior")

func _try_pick(event: InputEvent, cls: String) -> void:
	if picked:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	picked = true
	GameState.chosen_class = cls

	var tw = create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.5)
	await tw.finished
	get_tree().change_scene_to_file("res://scenes/game.tscn")
