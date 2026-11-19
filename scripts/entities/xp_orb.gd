extends Area2D

var xp_value: int = 3
var _collected: bool = false

@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	visual.color = Palette.AMBER
	body_entered.connect(_on_body_entered)
	var tw := create_tween().set_loops()
	tw.tween_property(visual, "scale", Vector2(1.2, 1.2), 0.35)
	tw.tween_property(visual, "scale", Vector2.ONE, 0.35)

func _physics_process(delta: float) -> void:
	if _collected:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var magnet: float = 80.0
	if "magnet_radius" in player:
		magnet = player.magnet_radius
	var dist := global_position.distance_to(player.global_position)
	if dist < magnet:
		global_position = global_position.move_toward(player.global_position, 420.0 * delta)
	if dist < 18.0:
		_collect(player)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect(body)

func _collect(player: Node) -> void:
	if _collected:
		return
	_collected = true
	if player.has_method("add_xp"):
		player.add_xp(xp_value)
	queue_free()
