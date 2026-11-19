extends Control

var _chapter: Dictionary = {}
var _beat_index: int = 0
var _from_victory: bool = false

@onready var title_label: Label = $Margin/VBox/Title
@onready var setting_label: Label = $Margin/VBox/Setting
@onready var body_label: Label = $Margin/VBox/Body
@onready var choices: VBoxContainer = $Margin/VBox/Choices
@onready var next_btn: Button = $Margin/VBox/NextButton
@onready var fade: ColorRect = $Fade
@onready var art: TextureRect = $Art

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BG)
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	if ResourceLoader.exists("res://assets/ui_theme.tres"):
		theme = load("res://assets/ui_theme.tres")
	if ResourceLoader.exists("res://assets/art/hero.png"):
		art.texture = load("res://assets/art/hero.png")
	_from_victory = GameState.run_won
	var id := GameState.pending_story_chapter
	if id == "":
		id = GameState.highest_chapter
	_chapter = StoryLoader.load_chapter(id)
	title_label.text = str(_chapter.get("title", "فصل"))
	title_label.add_theme_color_override("font_color", Palette.CREAM)
	setting_label.text = str(_chapter.get("setting", ""))
	setting_label.add_theme_color_override("font_color", Palette.AMBER_DIM)
	body_label.add_theme_color_override("font_color", Palette.ASH_LIGHT)
	next_btn.text = Locale.t("continue")
	next_btn.pressed.connect(_on_next)
	fade.color = Palette.BG
	fade.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 0.0, 0.45)
	_show_beat()

func _show_beat() -> void:
	for child in choices.get_children():
		child.queue_free()
	var beats: Array = _chapter.get("beats", [])
	if _beat_index >= beats.size():
		_finish_chapter()
		return
	var beat: Dictionary = beats[_beat_index]
	var kind := str(beat.get("type", "narration"))
	if kind == "narration":
		body_label.text = str(beat.get("text", ""))
		next_btn.visible = true
	elif kind == "choice":
		body_label.text = str(beat.get("prompt", ""))
		next_btn.visible = false
		var options: Array = beat.get("options", [])
		for opt in options:
			var btn := Button.new()
			btn.text = str(opt)
			btn.custom_minimum_size = Vector2(0, 48)
			btn.pressed.connect(_on_choice.bind(str(opt)))
			choices.add_child(btn)

func _on_next() -> void:
	_beat_index += 1
	_show_beat()

func _on_choice(option: String) -> void:
	GameState.last_choice = option
	SaveSystem.save_game()
	_beat_index += 1
	_show_beat()

func _finish_chapter() -> void:
	var id := str(_chapter.get("chapter_id", ""))
	if _from_victory:
		GameState.unlock_next_after(id)
	GameState.run_won = false
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.35)
	tw.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/hub.tscn")
	)
