extends Node2D

## Survivor run: waves, boss, HUD, level-up, win/lose, co-op sync.

const RUN_DURATION := 90.0
const EnemyScene: PackedScene = preload("res://scenes/run/enemy.tscn")
const PlayerScene: PackedScene = preload("res://scenes/run/player.tscn")

@export var chapter_id: String = "01"

var _elapsed: float = 0.0
var _spawn_cd: float = 1.0
var _paused: bool = false
var _finished: bool = false
var _boss_spawned: bool = false
var _rng := RandomNumberGenerator.new()
var _remote_players: Dictionary = {}

@onready var player: CharacterBody2D = $Player
@onready var world: Node2D = $World
@onready var hud: CanvasLayer = $HUD
@onready var hp_bar: ProgressBar = $HUD/Root/TopBar/HPBar
@onready var xp_bar: ProgressBar = $HUD/Root/TopBar/XPBar
@onready var timer_label: Label = $HUD/Root/TopBar/TimerLabel
@onready var level_label: Label = $HUD/Root/TopBar/LevelLabel
@onready var level_up_ui: Control = $HUD/Root/LevelUpUI
@onready var level_up_title: Label = $HUD/Root/LevelUpUI/Title
@onready var end_panel: Control = $HUD/Root/EndPanel
@onready var end_title: Label = $HUD/Root/EndPanel/VBox/Title
@onready var end_subtitle: Label = $HUD/Root/EndPanel/VBox/Subtitle
@onready var end_button: Button = $HUD/Root/EndPanel/VBox/ContinueButton
@onready var joystick_area: Control = $HUD/Root/JoystickArea
@onready var joystick_knob: Panel = $HUD/Root/JoystickArea/Knob
@onready var ground: Polygon2D = $World/Ground
@onready var root_hud: Control = $HUD/Root

var _joy_origin := Vector2.ZERO
var _joy_active: bool = false

func _ready() -> void:
	_rng.randomize()
	if GameState.pending_story_chapter != "":
		chapter_id = GameState.pending_story_chapter

	root_hud.layout_direction = Control.LAYOUT_DIRECTION_RTL
	if ResourceLoader.exists("res://assets/ui_theme.tres"):
		root_hud.theme = load("res://assets/ui_theme.tres")

	ground.color = Palette.BG_DEEP
	_draw_ash_field()
	_style_hud()
	level_up_ui.visible = false
	end_panel.visible = false
	level_up_title.text = Locale.t("choose_ember")

	_setup_local_player()
	_spawn_remote_players()

	player.health_changed.connect(_on_health_changed)
	player.leveled_up.connect(_on_leveled_up)
	player.died.connect(_on_player_died)
	end_button.pressed.connect(_on_end_continue)
	_on_health_changed(player.hp, player.max_hp)
	xp_bar.max_value = player.xp_to_next
	xp_bar.value = 0
	level_label.text = Locale.level_label(1)
	joystick_area.gui_input.connect(_on_joystick_input)

func _setup_local_player() -> void:
	if NetLobby.is_online:
		player.peer_id = multiplayer.get_unique_id()
		player.display_name = NetLobby.my_name
		player.name_label.text = NetLobby.my_name
	else:
		player.peer_id = 1
		player.display_name = ""
		player.name_label.text = ""

func _spawn_remote_players() -> void:
	if not NetLobby.is_online:
		return
	for entry in NetLobby.get_roster():
		var id: int = int(entry["id"])
		if id == multiplayer.get_unique_id():
			continue
		var remote := PlayerScene.instantiate()
		remote.peer_id = id
		remote.display_name = str(entry["name"])
		remote.global_position = player.global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		# Remote cameras off
		if remote.has_node("Camera2D"):
			remote.get_node("Camera2D").enabled = false
		world.add_child(remote)
		_remote_players[id] = remote

func _is_spawn_authority() -> bool:
	return (not NetLobby.is_online) or multiplayer.is_server()

func _draw_ash_field() -> void:
	var flecks := Node2D.new()
	flecks.z_index = -8
	flecks.name = "AshFlecks"
	world.add_child(flecks)
	for i in 64:
		var p := Polygon2D.new()
		p.position = Vector2(_rng.randf_range(20.0, 700.0), _rng.randf_range(20.0, 1260.0))
		p.color = Color(Palette.ASH.r, Palette.ASH.g, Palette.ASH.b, _rng.randf_range(0.08, 0.25))
		var s := _rng.randf_range(2.0, 5.5)
		p.polygon = PackedVector2Array([Vector2(-s, 0), Vector2(0, -s), Vector2(s, 0), Vector2(0, s)])
		flecks.add_child(p)

func _style_hud() -> void:
	hp_bar.modulate = Palette.EMBER
	xp_bar.modulate = Palette.AMBER
	timer_label.add_theme_color_override("font_color", Palette.ASH_LIGHT)
	level_label.add_theme_color_override("font_color", Palette.CREAM)

func _process(delta: float) -> void:
	if _paused or _finished:
		return
	_elapsed += delta
	var left := maxf(RUN_DURATION - _elapsed, 0.0)
	timer_label.text = Locale.timer_label(left)
	xp_bar.max_value = player.xp_to_next
	xp_bar.value = player.xp

	if _is_spawn_authority():
		_spawn_cd -= delta
		if _spawn_cd <= 0.0:
			_spawn_wave_chunk()
			_spawn_cd = maxf(1.1 - _elapsed * 0.008, 0.35)
		if not _boss_spawned and _elapsed >= RUN_DURATION * 0.75:
			_spawn_boss()
			_boss_spawned = true
		if _elapsed >= RUN_DURATION:
			if NetLobby.is_online:
				_rpc_win.rpc()
			else:
				_win()

func _spawn_wave_chunk() -> void:
	var count := 2 + int(_elapsed / 18.0)
	for _i in count:
		_spawn_enemy(false)

func _spawn_enemy(boss: bool) -> void:
	var enemy := EnemyScene.instantiate()
	var angle := _rng.randf() * TAU
	var radius := _rng.randf_range(320.0, 480.0)
	enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * radius
	enemy.global_position.x = clampf(enemy.global_position.x, 30, 690)
	enemy.global_position.y = clampf(enemy.global_position.y, 30, 1250)
	var t := _elapsed / RUN_DURATION
	if boss:
		enemy.setup(480.0, 72.0, 24.0, 45, true)
	else:
		enemy.setup(30.0 + t * 45.0, 82.0 + t * 42.0, 11.0 + t * 9.0, 3 + int(t * 3), false)
	world.add_child(enemy, true)

func _spawn_boss() -> void:
	_spawn_enemy(true)
	var flash := ColorRect.new()
	flash.color = Color(Palette.EMBER.r, Palette.EMBER.g, Palette.EMBER.b, 0.4)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.5)
	tw.tween_callback(flash.queue_free)

func _on_health_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current

func _on_leveled_up(new_level: int) -> void:
	level_label.text = Locale.level_label(new_level)
	_show_level_up()

func _show_level_up() -> void:
	_paused = true
	player.set_run_paused(true)
	level_up_ui.visible = true
	level_up_ui.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(level_up_ui, "modulate:a", 1.0, 0.2)
	for child in level_up_ui.get_node("Cards").get_children():
		child.queue_free()
	var picks: Array = UpgradeCatalog.pick_three(_rng)
	for upgrade in picks:
		level_up_ui.get_node("Cards").add_child(_make_upgrade_card(upgrade))

func _make_upgrade_card(upgrade: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(200, 150)
	btn.text = "%s\n\n%s" % [upgrade["title"], upgrade["desc"]]
	btn.add_theme_color_override("font_color", Palette.CREAM)
	btn.pressed.connect(_on_upgrade_picked.bind(str(upgrade["id"])))
	btn.scale = Vector2(0.85, 0.85)
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	return btn

func _on_upgrade_picked(id: String) -> void:
	player.apply_upgrade(id)
	level_up_ui.visible = false
	_paused = false
	player.set_run_paused(false)

func _on_player_died() -> void:
	if _finished:
		return
	# In co-op, only end if all local? For MVP end when local dies.
	_finished = true
	_paused = true
	player.set_run_paused(true)
	GameState.mark_run_defeat()
	end_title.text = Locale.t("ash_settles")
	end_subtitle.text = Locale.t("you_fell")
	end_button.text = Locale.t("return_hub")
	end_panel.visible = true
	end_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(end_panel, "modulate:a", 1.0, 0.3)

@rpc("authority", "call_local", "reliable")
func _rpc_win() -> void:
	_win()

func _win() -> void:
	if _finished:
		return
	_finished = true
	_paused = true
	player.set_run_paused(true)
	GameState.mark_run_victory(chapter_id)
	end_title.text = Locale.t("chapter_held")
	end_subtitle.text = Locale.t("page_turns")
	end_button.text = Locale.t("read_ledger")
	end_panel.visible = true
	end_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(end_panel, "modulate:a", 1.0, 0.3)

func _on_end_continue() -> void:
	if GameState.run_won:
		get_tree().change_scene_to_file("res://scenes/ui/story_reader.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/hub.tscn")

func _on_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_joy_active = true
			_joy_origin = st.position
			joystick_knob.position = st.position - joystick_knob.size * 0.5
		else:
			_joy_active = false
			player.set_touch_direction(Vector2.ZERO)
			joystick_knob.position = joystick_area.size * 0.5 - joystick_knob.size * 0.5
	elif event is InputEventScreenDrag and _joy_active:
		var sd := event as InputEventScreenDrag
		var delta_v: Vector2 = sd.position - _joy_origin
		var clamped := delta_v.limit_length(70.0)
		joystick_knob.position = _joy_origin + clamped - joystick_knob.size * 0.5
		player.set_touch_direction(clamped / 70.0)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_joy_active = true
				_joy_origin = mb.position
			else:
				_joy_active = false
				player.set_touch_direction(Vector2.ZERO)
				joystick_knob.position = joystick_area.size * 0.5 - joystick_knob.size * 0.5
	elif event is InputEventMouseMotion and _joy_active:
		var mm := event as InputEventMouseMotion
		var delta_v2: Vector2 = mm.position - _joy_origin
		var clamped2 := delta_v2.limit_length(70.0)
		joystick_knob.position = _joy_origin + clamped2 - joystick_knob.size * 0.5
		player.set_touch_direction(clamped2 / 70.0)
