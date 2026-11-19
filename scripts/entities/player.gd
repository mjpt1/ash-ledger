extends CharacterBody2D

signal died
signal health_changed(current: int, maximum: int)
signal leveled_up(new_level: int)

const MOVE_SPEED := 230.0

var max_hp: int = 100
var hp: int = 100
var level: int = 1
var xp: int = 0
var xp_to_next: int = 20

var damage: float = 12.0
var fire_rate: float = 0.48
var projectile_speed: float = 460.0
var magnet_radius: float = 95.0
var has_orbit: bool = false
var orbit_damage: float = 10.0
var blast_on_hit: bool = false
var multishot: int = 1

var peer_id: int = 1
var display_name: String = ""
var _fire_cd: float = 0.0
var _hurt_cd: float = 0.0
var _orbit_angle: float = 0.0
var _paused: bool = false
var _touch_dir := Vector2.ZERO
var _bob: float = 0.0

@onready var body_visual: Polygon2D = $BodyVisual
@onready var sprite: Sprite2D = $Sprite
@onready var shadow: Polygon2D = $Shadow
@onready var glow: Sprite2D = $Glow
@onready var orbit_visual: Node2D = $OrbitVisual
@onready var light: PointLight2D = $Light
@onready var name_label: Label = $NameLabel
@onready var trail: CPUParticles2D = $Trail

func _ready() -> void:
	max_hp = GameState.base_max_hp()
	hp = max_hp
	damage = GameState.base_damage()
	has_orbit = GameState.start_with_orbit()
	orbit_visual.visible = has_orbit
	add_to_group("player")
	add_to_group("players")
	health_changed.emit(hp, max_hp)
	body_visual.visible = false
	if sprite.texture == null:
		sprite.texture = load("res://assets/art/hero.png")
	sprite.scale = Vector2(0.11, 0.11)
	glow.modulate = Color(Palette.AMBER.r, Palette.AMBER.g, Palette.AMBER.b, 0.35)
	light.color = Palette.AMBER
	light.energy = 0.85
	name_label.add_theme_color_override("font_color", Palette.CREAM)
	if display_name != "":
		name_label.text = display_name
	_setup_trail()
	sprite.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 1.0, 0.35)

func _setup_trail() -> void:
	trail.emitting = true
	trail.amount = 18
	trail.lifetime = 0.35
	trail.direction = Vector2(0, 1)
	trail.spread = 30.0
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 10.0
	trail.initial_velocity_max = 30.0
	trail.scale_amount_min = 1.5
	trail.scale_amount_max = 3.0
	trail.color = Color(Palette.AMBER.r, Palette.AMBER.g, Palette.AMBER.b, 0.45)

func is_local_authority() -> bool:
	if not NetLobby.is_online:
		return true
	return multiplayer.get_unique_id() == peer_id

func set_run_paused(value: bool) -> void:
	_paused = value

func set_touch_direction(dir: Vector2) -> void:
	_touch_dir = dir

func _physics_process(delta: float) -> void:
	if _paused or hp <= 0:
		velocity = Vector2.ZERO
		trail.emitting = false
		return

	_bob += delta * 6.0
	sprite.position.y = sin(_bob) * 2.0
	shadow.scale = Vector2(1.0 + sin(_bob) * 0.05, 0.55)

	if is_local_authority():
		var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input_dir == Vector2.ZERO:
			input_dir = _touch_dir
		velocity = input_dir.limit_length(1.0) * MOVE_SPEED
		move_and_slide()
		global_position = global_position.clamp(Vector2(40, 40), Vector2(680, 1240))
		trail.emitting = velocity.length() > 20.0
		if NetLobby.is_online:
			_rpc_sync_pose.rpc(global_position, velocity)
	else:
		trail.emitting = velocity.length() > 20.0

	_hurt_cd = maxf(_hurt_cd - delta, 0.0)
	_fire_cd = maxf(_fire_cd - delta, 0.0)
	if is_local_authority() and _fire_cd <= 0.0:
		_try_fire()

	if has_orbit:
		_orbit_angle += delta * 3.4
		orbit_visual.rotation = _orbit_angle
		_damage_orbit_enemies()

@rpc("any_peer", "unreliable_ordered")
func _rpc_sync_pose(pos: Vector2, vel: Vector2) -> void:
	if is_local_authority():
		return
	global_position = global_position.lerp(pos, 0.45)
	velocity = vel

func _try_fire() -> void:
	var target := _nearest_enemy()
	if target == null:
		return
	_fire_cd = fire_rate
	var base_dir := (target.global_position - global_position).normalized()
	for i in multishot:
		var spread := 0.0
		if multishot > 1:
			spread = lerpf(-0.28, 0.28, float(i) / float(multishot - 1))
		_spawn_projectile(base_dir.rotated(spread))

func _spawn_projectile(dir: Vector2) -> void:
	var proj_scene: PackedScene = preload("res://scenes/run/projectile.tscn")
	var proj := proj_scene.instantiate()
	proj.global_position = global_position + dir * 22.0
	proj.setup(dir, projectile_speed, damage, blast_on_hit)
	get_tree().current_scene.add_child(proj, true)

func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or n.get("is_dead"):
			continue
		var d := global_position.distance_squared_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best

func _damage_orbit_enemies() -> void:
	for n in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n):
			continue
		if global_position.distance_to(n.global_position) < 58.0 and n.has_method("take_damage"):
			n.take_damage(orbit_damage * get_physics_process_delta_time() * 9.0)

func take_damage(amount: float) -> void:
	if _paused or hp <= 0 or _hurt_cd > 0.0:
		return
	hp = max(hp - int(ceil(amount)), 0)
	_hurt_cd = 0.35
	sprite.modulate = Palette.EMBER
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.22)
	if is_local_authority():
		var cam := get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.offset = Vector2(randf_range(-6, 6), randf_range(-6, 6))
			var ctw := create_tween()
			ctw.tween_property(cam, "offset", Vector2.ZERO, 0.12)
	health_changed.emit(hp, max_hp)
	if hp <= 0:
		died.emit()

func add_xp(amount: int) -> void:
	if not is_local_authority():
		return
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = int(20 + level * 12)
		leveled_up.emit(level)

func apply_upgrade(id: String) -> void:
	match id:
		"fire_rate":
			fire_rate = maxf(fire_rate * 0.85, 0.16)
		"damage":
			damage *= 1.25
		"magnet":
			magnet_radius += 60.0
		"orbit":
			has_orbit = true
			orbit_visual.visible = true
			orbit_damage *= 1.2
		"blast":
			blast_on_hit = true
		"multishot":
			multishot = mini(multishot + 1, 5)
		"max_hp":
			max_hp += 25
			hp += 25
			health_changed.emit(hp, max_hp)
