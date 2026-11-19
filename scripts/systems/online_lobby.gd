extends Control

@onready var name_edit: LineEdit = $Margin/VBox/NameEdit
@onready var ip_edit: LineEdit = $Margin/VBox/IpEdit
@onready var port_edit: LineEdit = $Margin/VBox/PortEdit
@onready var host_btn: Button = $Margin/VBox/HostButton
@onready var join_btn: Button = $Margin/VBox/JoinButton
@onready var start_btn: Button = $Margin/VBox/StartButton
@onready var back_btn: Button = $Margin/VBox/BackButton
@onready var roster: VBoxContainer = $Margin/VBox/Roster
@onready var status: Label = $Margin/VBox/Status
@onready var title: Label = $Margin/VBox/Title
@onready var hint: Label = $Margin/VBox/Hint

func _ready() -> void:
	layout_direction = Control.LAYOUT_DIRECTION_RTL
	if ResourceLoader.exists("res://assets/ui_theme.tres"):
		theme = load("res://assets/ui_theme.tres")
	title.text = Locale.t("online")
	hint.text = Locale.t("coop_hint")
	name_edit.placeholder_text = Locale.t("display_name")
	ip_edit.placeholder_text = Locale.t("room_code")
	port_edit.placeholder_text = Locale.t("port")
	host_btn.text = Locale.t("host")
	join_btn.text = Locale.t("join")
	start_btn.text = Locale.t("start_run")
	back_btn.text = Locale.t("back")
	name_edit.text = "مسافر"
	ip_edit.text = "127.0.0.1"
	port_edit.text = str(NetLobby.DEFAULT_PORT)
	ip_edit.layout_direction = Control.LAYOUT_DIRECTION_LTR
	port_edit.layout_direction = Control.LAYOUT_DIRECTION_LTR
	host_btn.pressed.connect(_on_host)
	join_btn.pressed.connect(_on_join)
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(func() -> void:
		NetLobby.reset_offline()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	NetLobby.lobby_changed.connect(_refresh)
	NetLobby.net_message.connect(func(msg: String) -> void: status.text = msg)
	NetLobby.start_coop_run.connect(_go_run)
	_refresh()

func _on_host() -> void:
	var port := int(port_edit.text)
	NetLobby.host_game(port, name_edit.text.strip_edges())
	_refresh()

func _on_join() -> void:
	var port := int(port_edit.text)
	NetLobby.join_game(ip_edit.text.strip_edges(), port, name_edit.text.strip_edges())
	_refresh()

func _on_start() -> void:
	GameState.reset_run_flags()
	GameState.pending_story_chapter = "01"
	NetLobby.request_start_run()

func _go_run() -> void:
	get_tree().change_scene_to_file("res://scenes/run/run.tscn")

func _refresh() -> void:
	for c in roster.get_children():
		c.queue_free()
	var header := Label.new()
	header.text = Locale.t("players")
	header.add_theme_color_override("font_color", Palette.AMBER)
	roster.add_child(header)
	if not NetLobby.is_online:
		var solo := Label.new()
		solo.text = "— هنوز متصل نیستید —"
		solo.add_theme_color_override("font_color", Palette.ASH)
		roster.add_child(solo)
		start_btn.disabled = true
		return
	for p in NetLobby.get_roster():
		var row := Label.new()
		row.text = "• %s" % str(p["name"])
		row.add_theme_color_override("font_color", Palette.CREAM)
		roster.add_child(row)
	start_btn.disabled = not NetLobby.is_host
	if NetLobby.is_host:
		status.text = Locale.t("hosting")
	elif status.text == "":
		status.text = Locale.t("waiting_host")
