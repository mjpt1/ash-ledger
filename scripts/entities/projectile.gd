extends Area2D

var direction := Vector2.RIGHT
var speed: float = 460.0
var damage: float = 12.0
var blast: bool = false
var lifetime: float = 1.5

@onready var visual: Polygon2D = $Visual
@onready var glow: Polygon2D = $Glow

func setup(dir: Vector2, p_speed: float, p_damage: float, p_blast: bool) -> void:
	direction = dir.normalized()
	speed = p_speed
	damage = p_damage
	blast = p_blast
	rotation = direction.angle()
	var col := Palette.EMBER if blast else Palette.AMBER
	visual.color = col
	glow.color = Color(col.r, col.g, col.b, 0.35)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	scale = Vector2(0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.08)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
	if global_position.x < -40 or global_position.x > 760 or global_position.y < -40 or global_position.y > 1320:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_hit(area.get_parent())

func _hit(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not target.is_in_group("enemies"):
		return
	if target.has_method("take_damage"):
		target.take_damage(damage)
	if blast:
		_do_blast()
	queue_free()

func _do_blast() -> void:
	for n in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n):
			continue
		if global_position.distance_to(n.global_position) < 78.0 and n.has_method("take_damage"):
			n.take_damage(damage * 0.55)
