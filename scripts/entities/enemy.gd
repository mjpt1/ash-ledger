extends CharacterBody2D

signal killed(enemy: Node)

var max_hp: float = 30.0
var hp: float = 30.0
var move_speed: float = 90.0
var touch_damage: float = 12.0
var xp_value: int = 3
var is_boss: bool = false
var is_dead: bool = false
var net_id: int = 0

var _player: Node2D
var _wobble: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var sprite: Sprite2D = $Sprite
@onready var shadow: Polygon2D = $Shadow
@onready var aura: CPUParticles2D = $Aura

func setup(p_hp: float, p_speed: float, p_damage: float, p_xp: int, boss: bool = false) -> void:
	max_hp = p_hp
	hp = p_hp
	move_speed = p_speed
	touch_damage = p_damage
	xp_value = p_xp
	is_boss = boss

func _ready() -> void:
	add_to_group("enemies")
	visual.visible = false
	if is_boss:
		sprite.texture = load("res://assets/art/boss.png")
		sprite.scale = Vector2(0.16, 0.16)
		aura.amount = 28
		aura.color = Color(Palette.EMBER.r, Palette.EMBER.g, Palette.EMBER.b, 0.55)
	else:
		sprite.texture = load("res://assets/art/enemy.png")
		sprite.scale = Vector2(0.09, 0.09)
		aura.color = Color(Palette.ASH.r, Palette.ASH.g, Palette.ASH.b, 0.4)
	scale = Vector2(0.15, 0.15)
	var target := Vector2.ONE
	var tw := create_tween()
	tw.tween_property(self, "scale", target, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_wobble += delta * 5.0
	sprite.rotation = sin(_wobble) * 0.08
	shadow.scale = Vector2(1.1 + sin(_wobble) * 0.08, 0.5)

	# Host (or offline) simulates AI
	var simulate := (not NetLobby.is_online) or multiplayer.is_server()
	if simulate:
		if _player == null or not is_instance_valid(_player):
			_player = _nearest_player()
		if _player == null:
			return
		var dir := (_player.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()
		if global_position.distance_to(_player.global_position) < (40.0 if is_boss else 24.0):
			if _player.has_method("take_damage"):
				_player.take_damage(touch_damage * delta * 2.4)
		if NetLobby.is_online:
			_rpc_enemy_pose.rpc(global_position, hp)

@rpc("authority", "unreliable_ordered")
func _rpc_enemy_pose(pos: Vector2, current_hp: float) -> void:
	if multiplayer.is_server():
		return
	global_position = global_position.lerp(pos, 0.4)
	hp = current_hp

func _nearest_player() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("players"):
		if not is_instance_valid(n):
			continue
		var d := global_position.distance_squared_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	if best == null:
		best = get_tree().get_first_node_in_group("player") as Node2D
	return best

func get_touch_damage() -> float:
	return touch_damage

func take_damage(amount: float) -> void:
	if is_dead:
		return
	if NetLobby.is_online and not multiplayer.is_server():
		_rpc_request_damage.rpc_id(1, amount)
		return
	_apply_damage(amount)

@rpc("any_peer", "reliable")
func _rpc_request_damage(amount: float) -> void:
	if multiplayer.is_server():
		_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	hp -= amount
	sprite.modulate = Palette.CREAM
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	if hp <= 0.0:
		_die()

func _die() -> void:
	is_dead = true
	killed.emit(self)
	_spawn_xp()
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ZERO, 0.18)
	tw.parallel().tween_property(sprite, "modulate:a", 0.0, 0.18)
	tw.tween_callback(queue_free)

func _spawn_xp() -> void:
	if NetLobby.is_online and not multiplayer.is_server():
		return
	var orb_scene: PackedScene = preload("res://scenes/run/xp_orb.tscn")
	var orb := orb_scene.instantiate()
	orb.global_position = global_position
	orb.xp_value = xp_value
	get_tree().current_scene.add_child(orb, true)
