extends Control

@onready var title: Label = $VBox/Title
@onready var tagline: Label = $VBox/Tagline
@onready var play_btn: Button = $VBox/PlayButton
@onready var online_btn: Button = $VBox/OnlineButton
@onready var portrait: TextureRect = $Portrait
@onready var glow: Polygon2D = $Glow

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BG)
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	title.text = Locale.t("app_title")
	tagline.text = Locale.t("tagline")
	play_btn.text = Locale.t("solo")
	online_btn.text = Locale.t("online")
	title.add_theme_color_override("font_color", Palette.CREAM)
	tagline.add_theme_color_override("font_color", Palette.ASH_LIGHT)
	if ResourceLoader.exists("res://assets/ui_theme.tres"):
		theme = load("res://assets/ui_theme.tres")
	if ResourceLoader.exists("res://assets/art/hero.png"):
		portrait.texture = load("res://assets/art/hero.png")
	play_btn.pressed.connect(func() -> void:
		NetLobby.reset_offline()
		get_tree().change_scene_to_file("res://scenes/ui/hub.tscn")
	)
	online_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/online_lobby.tscn")
	)
	glow.color = Color(Palette.AMBER.r, Palette.AMBER.g, Palette.AMBER.b, 0.14)
	var tw := create_tween().set_loops()
	tw.tween_property(glow, "scale", Vector2(1.1, 1.1), 1.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "scale", Vector2.ONE, 1.8).set_trans(Tween.TRANS_SINE)
	portrait.modulate.a = 0.0
	title.modulate.a = 0.0
	var intro := create_tween()
	intro.tween_property(portrait, "modulate:a", 1.0, 0.55)
	intro.parallel().tween_property(title, "modulate:a", 1.0, 0.55)
