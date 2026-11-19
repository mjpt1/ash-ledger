extends Control

@onready var ash_label: Label = $Margin/VBox/Header/AshLabel
@onready var chapters_box: VBoxContainer = $Margin/VBox/Chapters
@onready var meta_box: VBoxContainer = $Margin/VBox/MetaBox
@onready var status_label: Label = $Margin/VBox/StatusLabel
@onready var title: Label = $Margin/VBox/Header/Title
@onready var chapters_title: Label = $Margin/VBox/ChaptersTitle
@onready var portrait: TextureRect = $Portrait

func _ready() -> void:
	RenderingServer.set_default_clear_color(Palette.BG)
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	if ResourceLoader.exists("res://assets/ui_theme.tres"):
		theme = load("res://assets/ui_theme.tres")
	title.text = Locale.t("hub_title")
	chapters_title.text = Locale.t("chapters")
	if ResourceLoader.exists("res://assets/art/hero.png"):
		portrait.texture = load("res://assets/art/hero.png")
	GameState.meta_changed.connect(_refresh)
	_refresh()
	_build_chapters()
	_build_meta()

func _refresh() -> void:
	ash_label.text = Locale.ash_label(GameState.ash)
	ash_label.add_theme_color_override("font_color", Palette.AMBER)
	status_label.add_theme_color_override("font_color", Palette.ASH_LIGHT)
	status_label.text = "%s: %s" % [Locale.t("highest_page"), Locale.digits(GameState.highest_chapter)]
	_build_meta()

func _build_chapters() -> void:
	for child in chapters_box.get_children():
		child.queue_free()
	for id in StoryLoader.list_chapters():
		var unlocked := GameState.is_chapter_unlocked(id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var info := Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.text = "فصل %s — %s" % [Locale.digits(id), StoryLoader.chapter_title(id)]
		info.add_theme_color_override("font_color", Palette.CREAM if unlocked else Palette.ASH)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(info)
		var play := Button.new()
		play.text = Locale.t("survive") if unlocked else Locale.t("locked")
		play.disabled = not unlocked
		play.custom_minimum_size = Vector2(100, 44)
		play.pressed.connect(_start_run.bind(id))
		row.add_child(play)
		var read := Button.new()
		read.text = Locale.t("read")
		read.disabled = not unlocked
		read.custom_minimum_size = Vector2(90, 44)
		read.pressed.connect(_read_chapter.bind(id))
		row.add_child(read)
		chapters_box.add_child(row)

func _build_meta() -> void:
	for child in meta_box.get_children():
		child.queue_free()
	var meta_title := Label.new()
	meta_title.text = Locale.t("meta_title")
	meta_title.add_theme_color_override("font_color", Palette.CREAM)
	meta_title.add_theme_font_size_override("font_size", 22)
	meta_box.add_child(meta_title)
	_add_meta_row("hp", Locale.t("meta_hp"), GameState.meta_hp)
	_add_meta_row("damage", Locale.t("meta_damage"), GameState.meta_damage)
	_add_meta_row("orbit", Locale.t("meta_orbit"), GameState.meta_orbit)

func _add_meta_row(stat: String, label_text: String, level: int) -> void:
	var row := HBoxContainer.new()
	var lab := Label.new()
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.text = "%s  [%s/۵]" % [label_text, Locale.digits(level)]
	lab.add_theme_color_override("font_color", Palette.ASH_LIGHT)
	row.add_child(lab)
	var btn := Button.new()
	var cost := GameState.meta_cost(level)
	btn.text = Locale.t("max") if level >= 5 else "%s %s" % [Locale.t("buy"), Locale.digits(cost)]
	btn.disabled = not GameState.can_buy_meta(stat)
	btn.pressed.connect(func() -> void:
		GameState.buy_meta(stat)
		_build_chapters()
	)
	row.add_child(btn)
	meta_box.add_child(row)

func _start_run(chapter_id: String) -> void:
	NetLobby.reset_offline()
	GameState.reset_run_flags()
	GameState.pending_story_chapter = chapter_id
	get_tree().change_scene_to_file("res://scenes/run/run.tscn")

func _read_chapter(chapter_id: String) -> void:
	GameState.pending_story_chapter = chapter_id
	GameState.run_won = false
	get_tree().change_scene_to_file("res://scenes/ui/story_reader.tscn")
